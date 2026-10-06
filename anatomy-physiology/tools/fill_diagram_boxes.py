#!/usr/bin/env python3
"""Fills in the "box" of every diagram label in content/modules/*.json from OCR data.

A labeled diagram reuses a lesson figure and hides its printed labels. Authors write
only the label text; this script finds where that text is printed on the figure and
records a box (fractions of the image size) that the app covers with a blank.

    powershell.exe -File tools/ocr_figures.ps1 -ImageDir <images> -OutFile figure_ocr.json
    python3 tools/fill_diagram_boxes.py figure_ocr.json [--refresh] [--only m12]
    python3 tools/fill_diagram_boxes.py figure_ocr.json --show m12_hip_thigh.jpg

Labels that already have a box are left alone unless --refresh is passed. A label may
set "match" when the printed text differs from "text" (e.g. "Gluteus medius (cut)"),
and "near": [x, y] (fractions of the image) to pick one of several printed copies.
OCR is sometimes off by 10-30 px or misses words; then measure the box by hand and set
"manual": true so no run, --refresh included, ever replaces it.
The script also lists printed text inside each diagram's region that no label covers,
since a forgotten label gives an answer away.
"""

import json
import re
import sys
from pathlib import Path

MODULES_DIRECTORY = Path(__file__).resolve().parent.parent / "content" / "modules"
## Pixels added around the OCR word boxes so antialiased edges are covered too.
BOX_PADDING = 4
## OCR misreads the odd letter (l for I, rn for m); allow this many edits per token.
TOKEN_EDIT_TOLERANCE = 1


def normalize(text):
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


def edit_distance(first, second):
    previous_row = list(range(len(second) + 1))
    for first_index, first_char in enumerate(first, 1):
        current_row = [first_index]
        for second_index, second_char in enumerate(second, 1):
            current_row.append(min(previous_row[second_index] + 1, current_row[second_index - 1] + 1,
                                   previous_row[second_index - 1] + (first_char != second_char)))
        previous_row = current_row
    return previous_row[-1]


def tokens_match(printed, wanted):
    if printed == wanted:
        return True
    return len(wanted) >= 4 and edit_distance(printed, wanted) <= TOKEN_EDIT_TOLERANCE


class Word:
    def __init__(self, raw, line_index):
        self.text = raw[0]
        self.x, self.y, self.width, self.height = raw[1], raw[2], raw[3], raw[4]
        self.line_index = line_index
        # One OCR word can hold several tokens once punctuation is stripped ("(or" -> "or").
        self.tokens = normalize(self.text).split()

    @property
    def right(self):
        return self.x + self.width

    @property
    def bottom(self):
        return self.y + self.height


def load_lines(figure, region_pixels):
    """OCR lines as lists of Words, keeping only words whose centre is inside the region."""
    left, top, right, bottom = region_pixels
    lines = []
    for line in figure["lines"]:
        words = []
        for raw in line["words"]:
            word = Word(raw, len(lines))
            centre_x = word.x + word.width / 2
            centre_y = word.y + word.height / 2
            if left <= centre_x <= right and top <= centre_y <= bottom and word.tokens:
                words.append(word)
        if words:
            lines.append(words)
    for line_index, words in enumerate(lines):
        for word in words:
            word.line_index = line_index
    return lines


def stacked_below(lines, words_so_far):
    """Lines that could continue a label printed over several lines: just below and aligned."""
    last_line = [word for word in words_so_far if word.line_index == words_so_far[-1].line_index]
    left = min(word.x for word in last_line)
    right = max(word.right for word in last_line)
    bottom = max(word.bottom for word in last_line)
    height = max(word.height for word in last_line)
    candidates = []
    for line_index, words in enumerate(lines):
        line_top = min(word.y for word in words)
        if not (bottom - height * 0.5 <= line_top <= bottom + height * 1.2):
            continue
        line_left = min(word.x for word in words)
        line_right = max(word.right for word in words)
        overlaps = line_left <= right + height and line_right >= left - height
        if overlaps:
            candidates.append((line_index, words))
    return candidates


def find_matches(lines, wanted_tokens):
    """Every run of printed words that spells wanted_tokens, possibly across stacked lines."""
    matches = []

    def extend(line_index, word_index, token_index, used_words, token_offset):
        if token_index == len(wanted_tokens):
            matches.append(list(used_words))
            return
        words = lines[line_index]
        if word_index >= len(words):
            if used_words:
                for next_index, next_words in stacked_below(lines, used_words):
                    if next_index != line_index:
                        extend(next_index, 0, token_index, used_words, 0)
            return
        word = words[word_index]
        word_tokens = word.tokens[token_offset:]
        consumed = 0
        while consumed < len(word_tokens) and token_index + consumed < len(wanted_tokens):
            if not tokens_match(word_tokens[consumed], wanted_tokens[token_index + consumed]):
                return
            consumed += 1
        if consumed < len(word_tokens):
            # The label ends partway through an OCR word; only allowed for trailing junk.
            if token_index + consumed == len(wanted_tokens):
                matches.append(used_words + [word])
            return
        extend(line_index, word_index + 1, token_index + consumed, used_words + [word], 0)

    for line_index, words in enumerate(lines):
        for word_index in range(len(words)):
            extend(line_index, word_index, 0, [], 0)
    # The same words can be reached twice; keep each distinct set once.
    unique = {}
    for match in matches:
        unique[tuple(sorted(id(word) for word in match))] = match
    return list(unique.values())


def box_for(words, image_width, image_height):
    left = max(min(word.x for word in words) - BOX_PADDING, 0)
    top = max(min(word.y for word in words) - BOX_PADDING, 0)
    right = min(max(word.right for word in words) + BOX_PADDING, image_width)
    bottom = min(max(word.bottom for word in words) + BOX_PADDING, image_height)
    return [round(left / image_width, 4), round(top / image_height, 4),
            round((right - left) / image_width, 4), round((bottom - top) / image_height, 4)]


def centre_of(words):
    return (sum(word.x + word.width / 2 for word in words) / len(words),
            sum(word.y + word.height / 2 for word in words) / len(words))


def process_diagram(diagram, figure, refresh, report):
    width, height = figure["width"], figure["height"]
    region = diagram.get("region", [0, 0, 1, 1])
    region_pixels = (region[0] * width, region[1] * height,
                     (region[0] + region[2]) * width, (region[1] + region[3]) * height)
    lines = load_lines(figure, region_pixels)
    covered = set()
    problems = 0
    for label in diagram["labels"]:
        if label.get("manual"):
            continue
        wanted_tokens = normalize(label.get("match", label["text"])).split()
        matches = find_matches(lines, wanted_tokens)
        if "near" in label and matches:
            near_x, near_y = label["near"][0] * width, label["near"][1] * height
            matches.sort(key=lambda match: (centre_of(match)[0] - near_x) ** 2 + (centre_of(match)[1] - near_y) ** 2)
            matches = matches[:1]
        if not matches:
            if "box" not in label:
                report.append(f"  NOT FOUND: {label['text']!r}")
                problems += 1
            continue
        if len(matches) > 1:
            places = ", ".join(f"({centre_of(match)[0] / width:.2f}, {centre_of(match)[1] / height:.2f})" for match in matches)
            report.append(f"  AMBIGUOUS: {label['text']!r} printed {len(matches)} times at {places}; add \"near\"")
            problems += 1
            continue
        for word in matches[0]:
            covered.add(id(word))
        if refresh or "box" not in label:
            label["box"] = box_for(matches[0], width, height)
            label["lines"] = len({word.line_index for word in matches[0]})
    leftovers = []
    for words in lines:
        uncovered = [word.text for word in words if id(word) not in covered]
        if uncovered:
            leftovers.append(" ".join(uncovered))
    if leftovers:
        report.append("  uncovered text in region: " + " | ".join(leftovers))
    return problems


def show_figure(ocr, file_name):
    """Prints every OCR line with its position as fractions of the image, for choosing regions."""
    figure = ocr[file_name]
    width, height = figure["width"], figure["height"]
    print(f"{file_name}: {width} x {height} px")
    for line in figure["lines"]:
        words = line["words"]
        left = min(word[1] for word in words) / width
        top = min(word[2] for word in words) / height
        right = max(word[1] + word[3] for word in words) / width
        bottom = max(word[2] + word[4] for word in words) / height
        print(f"  x {left:.3f}-{right:.3f}  y {top:.3f}-{bottom:.3f}  {line['text']}")


def to_json(value, indent=0):
    """Two-space JSON like the hand-written files, with short lists kept on one line."""
    if isinstance(value, list):
        one_line = json.dumps(value, ensure_ascii=False)
        if indent + len(one_line) <= 100 and all(not isinstance(item, (list, dict)) for item in value):
            return one_line
    if isinstance(value, (list, dict)) and value:
        padding = " " * (indent + 2)
        if isinstance(value, list):
            items = [padding + to_json(item, indent + 2) for item in value]
            return "[\n" + ",\n".join(items) + "\n" + " " * indent + "]"
        items = [padding + json.dumps(key, ensure_ascii=False) + ": " + to_json(item, indent + 2) for key, item in value.items()]
        return "{\n" + ",\n".join(items) + "\n" + " " * indent + "}"
    return json.dumps(value, ensure_ascii=False)


def write_module(module_path, original_text, module):
    """Rewrites only the trailing "diagrams" block, leaving the rest of the file as written."""
    marker = original_text.find(',\n  "diagrams": ')
    head = original_text[:marker] if marker >= 0 else original_text.rstrip()[:-1].rstrip()
    new_text = head + ',\n  "diagrams": ' + to_json(module["diagrams"], 2) + "\n}\n"
    assert json.loads(new_text) == module, "rewrite changed the module"
    module_path.write_text(new_text, encoding="utf-8")


def main():
    arguments = sys.argv[1:]
    if not arguments:
        print(__doc__)
        return 2
    ocr_path = Path(arguments[0])
    refresh = "--refresh" in arguments
    only_prefix = arguments[arguments.index("--only") + 1] if "--only" in arguments else ""
    ocr = json.loads(ocr_path.read_text(encoding="utf-8-sig"))
    if "--show" in arguments:
        show_figure(ocr, arguments[arguments.index("--show") + 1])
        return 0
    total_problems = 0
    for module_path in sorted(MODULES_DIRECTORY.glob("*.json")):
        if not module_path.name.startswith(only_prefix):
            continue
        original_text = module_path.read_text(encoding="utf-8")
        module = json.loads(original_text)
        diagrams = module.get("diagrams", [])
        if not diagrams:
            continue
        for diagram in diagrams:
            report = []
            figure = ocr.get(diagram["file"])
            if figure is None:
                print(f"{diagram['id']}: no OCR data for {diagram['file']}")
                total_problems += 1
                continue
            total_problems += process_diagram(diagram, figure, refresh, report)
            print(f"{diagram['id']} ({diagram['file']}, {len(diagram['labels'])} labels)")
            for line in report:
                print(line)
        write_module(module_path, original_text, module)
    print(f"{total_problems} problem(s)")
    return 1 if total_problems else 0


if __name__ == "__main__":
    sys.exit(main())
