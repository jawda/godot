# A&P Study Guide

An interactive study guide for **Anatomy & Physiology I** (Nashville State BIOL 2010,
which uses *Hole's Human Anatomy & Physiology*). Built with Godot 4.7.

Each module has up to four tabs:

- **Lesson**: the reading, a short page at a time. The outline on the left lists every
  section with a checkmark once you have finished it, and reopening a module resumes at
  the first unfinished section. Figures appear on a section's first page; click one to
  open the viewer: fit-to-window, a zoom-level menu (25% to 400%), a slider, and
  zoom buttons. The scroll wheel (or a trackpad pinch) zooms toward the pointer, dragging (or a
  two-finger swipe) pans, double-click
  toggles fit and 100%, and the keys are **+**/**-**, **0** to fit, and **Esc** to close. Memory tips and clinical connections close out each section.
  The **Left/Right arrow keys** turn pages.
- **Flashcards**: flip with Space or a click, then press **1** (still learning, the card
  goes to the back of the deck) or **2** (know it). "Definition first" reverses the cards;
  "Hide known cards" drills only the ones you haven't marked yet.
- **Quiz**: multiple choice, true/false, and ordering questions with an explanation after
  every answer. Keys **1 to 4** pick an answer and **Enter** continues. The results screen
  lists everything you missed with the explanation, and can rerun only those.
- **Diagrams**: label-the-figure practice. The lesson figures come back with their
  printed labels hidden behind blanks. In **Word bank** mode, click a label and then its
  blank, or drag it there (drag between two blanks to swap them; click a filled blank to
  take its label back). In **Type it** mode you write every label from memory; Enter or
  Tab moves on, and a slip of a letter or two counts but shows you the right spelling.
  **Check** (Ctrl/Cmd+Enter) marks blanks green or red; fix the red ones and check
  again, or **Show answers**. Only the first check of each attempt counts toward the
  best score shown in the diagram list. Zoom with the corner buttons, a trackpad pinch,
  or Ctrl/Cmd + scroll. The tab is hidden for modules with no diagrams.

From the home screen:

- **Mixed review**: 20 random questions from every module you've started.
- **Missed questions**: every question whose most recent answer was wrong. Getting it
  right clears it.
- **Medical terms**: a quick reference for students who haven't taken medical
  terminology. 763 entries: prefixes, roots, and suffixes; about 240 words from the
  lessons broken into their parts; body directions, planes, regions, and cavities; and
  abbreviations. Search by term or by meaning ("itis", "cardio", or "heart"), or filter
  by kind. A word's card links to its parts, and a part's card lists the words built
  from it. The **Flashcards** and **Quiz** tabs drill a practice set you pick (word
  parts by default). Quiz answers show up in Missed questions but don't count toward the
  module mastery numbers.

Terms in lesson text are underlined the first time they appear on a page. Hover one for
its meaning, or click it for the full card; **Open in Medical terms** jumps to the
reference, and its back button returns to the lesson. Content lives in
`content/terminology/` (see "Medical terminology schema" in `content/SCHEMA.md`).

## Profiles and saving

The app opens on **Who's studying?** Each profile has its own progress. Everything saves
the moment it happens (every answer, card, and page turned), and the home screen's
**Continue** button reopens the module, tab, and lesson page you were last on. Saves go
to a temporary file first and are then swapped in, so quitting or crashing mid-save
can't corrupt them.

Profiles live in:

- Windows: `%APPDATA%\Godot\app_userdata\A&P Study Guide\profiles\`
- macOS: `~/Library/Application Support/Godot/app_userdata/A&P Study Guide/profiles/`

To move a profile to another computer, click **Export** on its card, copy the `.json`
file over (OneDrive, AirDrop, USB), and click **Import…** on the other machine.

## Running on a Mac

`build/macos/AP Study Guide.zip` is a universal app (Apple Silicon and Intel). Rebuild it
with:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "macOS" "build/macos/AP Study Guide.zip"
```

It is ad-hoc signed, not notarized, so macOS blocks it the first time:

1. Unzip it and drag **A&P Study Guide.app** into Applications.
2. Open Terminal and run
   `xattr -dr com.apple.quarantine "/Applications/A&P Study Guide.app"`
3. Open it normally. (Alternatively: try to open it once, then System Settings → Privacy &
   Security → **Open Anyway**.)

A Windows build exports the same way with the "Windows Desktop" preset into
`build/windows/`.

## Modules

| # | Topic | Hole's chapter (approx.) |
|---|-------|--------------------------|
| 1 | Introduction: organization, homeostasis, terminology | 1 |
| 2 | Chemistry of life | 2 |
| 3 | Cells: structure, transport, division | 3 |
| 4 | Cellular metabolism and protein synthesis | 4 |
| 5 | Tissues (histology) | 5 |
| 6 | Integumentary system | 6 |
| 7 | Bone tissue and bone structure | 7 |
| 8 | Axial skeleton | 7 |
| 9 | Appendicular skeleton | 7 |
| 10 | Joints (articulations) | 8 |
| 11 | Muscle tissue and contraction | 9 |
| 12 | Major skeletal muscles | 9 |
| 13 | Nervous tissue and neurophysiology | 10 |
| 14 | Central nervous system | 11 |
| 15 | Peripheral and autonomic nervous system | 11 |
| 16 | General and special senses | 12 |

Module 16 may or may not be on the BIOL 2010 syllabus; check yours.

## Adding or editing content

All study material lives in `content/modules/*.json`, one file per module. The format is
documented in [`content/SCHEMA.md`](content/SCHEMA.md). Drop in a new file (for example
A&P II's cardiovascular system) and it appears on the home screen; no code changes.

Figures go in `content/images/` and are referenced from a section's `figure` field. Most
are from OpenStax *Anatomy & Physiology 2e* (CC BY 4.0) via Wikimedia Commons; each
figure's caption line carries its credit, and [`content/images/CREDITS.md`](content/images/CREDITS.md)
lists every one. After adding images, run the shrink tool so they stay around 1100 px:

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/shrink_figures.gd
```

Godot cannot read CMYK JPEGs (some print-oriented figures are saved that way); re-save
those as RGB before adding them.

### Labeled diagrams

A module's `diagrams` reuse its lesson figures. You write only each label's text and the
crop region; the box that hides each printed label comes from OCR:

1. `tools/figure_ocr.json` holds Windows OCR results for every figure. After adding
   figures, regenerate it (Windows only, uses the built-in OCR engine):
   `powershell.exe -File tools/ocr_figures.ps1 -ImageDir <path to content/images> -OutFile tools/figure_ocr.json`
2. `python3 tools/fill_diagram_boxes.py tools/figure_ocr.json --show m16_eye.jpg` lists the
   text found on a figure with positions, for choosing a region.
3. Write the diagram in the module JSON (see SCHEMA.md), then run
   `python3 tools/fill_diagram_boxes.py tools/figure_ocr.json --only m16`. It fills in the
   boxes and warns about labels it can't find and printed text you didn't label.
4. `Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/preview_diagrams.gd -- <folder> m16`
   saves each diagram with its boxes painted over so you can check nothing shows through.
   For the real thing, run the smoke test windowed with `-- --diagram-snaps m16`.

The content was written for this guide from standard intro A&P material. It has been
checked for structure, not proofread by an instructor, so when your textbook or professor
says something different, trust them and fix the JSON.

## Project layout

```
autoload/        ContentLibrary (loads the JSON), StudyProgress (save file)
data/            StudyModule, LessonSection, Flashcard, QuizQuestion, LabeledDiagram, DiagramLabel
main/            Root scene: swaps between the three screens
menu/            Home screen and the per-module tile
module_study/    Lesson / Flashcards / Quiz / Diagrams tabs for one module
diagrams/        Label-the-diagram tab: board (figure + blanks + zoom), blank, word-bank chip
lesson/          Paged reading view, outline entries, callouts, figure card and full-screen viewer
flashcards/      Flip-card drill
quiz/            Quiz runner, ordering widget, results panel (shared by modules and reviews)
review/          Mixed and missed-question review sessions
theme/           study_theme.tres (dark): every colour, font size, and style; icons/
tests/           Smoke test that drives the UI through every module
tools/           shrink_figures.gd (resize images), diagram tools: ocr_figures.ps1,
                 figure_ocr.json, fill_diagram_boxes.py, preview_diagrams.gd
profiles/        Profile picker screen and profile card
```

## Testing

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/smoke_test.tscn
```

It reads every lesson, works every flashcard deck, answers every quiz question, labels
every diagram (word bank with a deliberate swap, then typed with a deliberate typo), runs both
review modes, checks for broken BBCode, and exits non-zero on failure. It works in its own
`smoke_test_profiles` folder, so your real profiles are untouched. Drop `--headless` and
add `-- --screenshots` to save screenshots to `user://screenshots/`.

## Ideas for later

- Exam-prep sets that group modules by the course's exam schedule.
- A&P II modules for BIOL 2020.
