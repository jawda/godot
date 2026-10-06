# Module content schema

Every file in `content/modules/` is one study module, written as JSON. The app
discovers them automatically and sorts them by `order`. Add a module by adding a
file; no code changes needed.

```json
{
  "id": "m01_introduction",
  "order": 1,
  "course": "A&P I",
  "title": "Introduction to Anatomy & Physiology",
  "summary": "One sentence shown on the module tile.",
  "objectives": ["Learning objective, phrased as a skill", "..."],
  "lesson": [
    {
      "heading": "Levels of Organization",
      "body": [
        "A paragraph. Inline [b]bold[/b] and [i]italic[/i] are allowed.",
        "- A line starting with a dash and a space renders as a bullet.",
        "- Another bullet."
      ],
      "tip": "Optional memory aid or mnemonic.",
      "clinical": "Optional clinical connection.",
      "figure": {
        "file": "m07_long_bone.jpg",
        "caption": "Optional. What the student should notice in the figure.",
        "credit": "OpenStax Anatomy & Physiology 2e, Figure 6.7, CC BY 4.0",
        "source": "https://commons.wikimedia.org/wiki/File:..."
      }
    }
  ],
  "flashcards": [
    { "id": "m01_fc01", "term": "Homeostasis", "definition": "..." }
  ],
  "quiz": [
    {
      "id": "m01_q01",
      "type": "multiple_choice",
      "prompt": "Question text?",
      "choices": ["A", "B", "C", "D"],
      "answer": 2,
      "explanation": "Why the answer is right, and why the tempting wrong one is wrong."
    },
    {
      "id": "m01_q02",
      "type": "true_false",
      "prompt": "A statement to judge.",
      "answer": false,
      "explanation": "..."
    },
    {
      "id": "m01_q03",
      "type": "ordering",
      "prompt": "Put these in order from smallest to largest.",
      "items": ["listed", "in", "the", "correct", "order"],
      "explanation": "..."
    }
  ],
  "diagrams": [
    {
      "id": "m12_dg01",
      "title": "Superficial muscles of the hip and anterior thigh",
      "file": "m12_hip_thigh.jpg",
      "prompt": "Right leg, anterior view. Find the four quadriceps and the adductors.",
      "region": [0, 0, 0.52, 0.435],
      "labels": [
        { "text": "Rectus femoris", "box": [0.0064, 0.2577, 0.0773, 0.0387], "lines": 2 },
        { "text": "Tensor fasciae latae", "match": "Tensor fascia latae", "box": [...], "lines": 2 },
        { "text": "Quadriceps tendon", "match": "Quadriceps tendon (or patellar tendon)",
          "accept": ["Patellar tendon"], "box": [...], "lines": 2 }
      ]
    }
  ]
}
```

## Labeled diagrams

`diagrams` is optional. Each one shows `file` (a figure from `content/images/`, normally
one of the module's lesson figures, whose credit line it borrows) cropped to `region`,
with a blank over every label's `box`. Students fill the blanks from a word bank or by
typing.

- `region` and `box` are `[x, y, width, height]` as fractions of the whole image, so they
  survive resizing. One figure with several panels can give several diagrams.
- Write `text` (the answer) and let `tools/fill_diagram_boxes.py` fill in `box` and
  `lines` from OCR (see the README). Use `match` when the printed words differ from the
  answer, `accept` for alternates that also count when typed, and `near: [x, y]` to pick
  one copy of text printed twice.
- Every printed label inside the region should be a label, or it gives answers away.
- Ids are unique across all modules: `mNN_dgNN`.

## Rules

- `answer` for `multiple_choice` is a zero-based index into `choices`. Choices are
  shuffled at runtime, so never write "all of the above" / "both A and B".
- `ordering` items are written in the **correct** order; the app shuffles them.
  3 to 6 items.
- Ids are unique across all modules: `mNN_fcNN` and `mNN_qNN`.
- Text is rendered as Godot BBCode. The only square-bracket tags allowed are
  `[b]`, `[/b]`, `[i]`, `[/i]`. Never use square brackets for anything else
  (write "concentration of Ca²⁺", not "[Ca²⁺]").
- Unicode sub/superscripts are fine: H₂O, Ca²⁺, Na⁺/K⁺.
- Lessons are shown a page at a time. The app splits each section's `body` into short
  pages automatically (about 700 characters each). A body line of exactly `---` forces a
  page break there.
- `figure` is optional, at most one per section, and shows on the section's first page.
  `file` is a name inside `content/images/`. Images are JPG or PNG, about 1000 px wide.
  Only use images whose license allows reuse (CC BY, CC BY-SA, CC0, public domain) and
  record the license in `credit` and the original page in `source`.
