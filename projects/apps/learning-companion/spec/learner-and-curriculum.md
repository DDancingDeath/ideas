# Learner setup and curriculum


## 4.3 End-to-end user journey

The application should support the following complete journey.

| Step | User/system outcome |
| --- | --- |
| Set up the learner | Grade, board, language, available time and goals |
| Import the curriculum | Books, syllabus, learning outcomes and prerequisites |
| Discover current ability | Short, adaptive baseline assessment |
| Build the learning plan | Lessons, practice, revision and exam milestones |
| Teach through discovery | Stories, visuals, questions, experiments and explanation |
| Measure understanding | Knowledge checks, independent problems and retention |
| Adapt and replan | Teaching methods, pace and upcoming lessons adjusted |
| Share useful insights | Progress, unresolved gaps, interests and next steps |

This journey should be continuous. A lesson is not an isolated chat; it contributes to the learner's knowledge model, curriculum status, future revision schedule and teaching preferences.

## 4.4 Learner setup and baseline assessment

The system needs to understand both where the student is supposed to be and where they actually are.

### Required setup information

| Field                               | Purpose                                                        |
| ----------------------------------- | -------------------------------------------------------------- |
| Grade and school board              | Select the correct curriculum                                  |
| Academic year                       | Determine the syllabus version                                 |
| Textbooks and syllabus              | Establish required content                                     |
| Exam date or target completion date | Calculate available time                                       |
| Days per week                       | Determine study frequency                                      |
| Daily time budget                   | Estimate realistic capacity                                    |
| Preferred language                  | Select explanation and narration language                      |
| Parent-selected goals               | For example, strengthen math fundamentals or prepare for exams |
| Accessibility preferences           | Reading, audio, display and interaction accommodations         |

Ask only for information needed to start. Other preferences can be learned through interaction.

### Baseline assessment

Do not begin with a long, intimidating examination. Start with a short diagnostic experience that gradually increases or decreases in difficulty.

For a mathematics learner, the diagnostic might include:

- Number recognition and arithmetic.
- Place value and number relationships.
- Fractions and basic visual reasoning.
- Relevant prerequisites for the current grade.
- A few questions from material the child has already studied.

The system should assess prerequisite concepts, not merely ask questions from the current textbook.

Diagnostic behavior:

1. Begin with easy, age-appropriate questions.
2. Increase difficulty after demonstrated success.
3. Use easier questions when repeated mistakes suggest a prerequisite gap.
4. Record confidence in the assessment, not just a proficiency score.
5. Allow the child to skip questions or stop.
6. Continue refining the baseline during normal lessons.

Do not assume that a child who answers a question incorrectly has no understanding. The error may be caused by reading difficulty, unfamiliar wording, a careless mistake or a language barrier.

The system should distinguish these possibilities where evidence permits.

## 4.5 Curriculum ingestion and knowledge modeling

The application must turn the source material into a structured, verifiable set of learning objectives.

### Supported source types

The curriculum ingestion capability supports these source types. Which of them
the first release must ingest, given the [roadmap](../plan/roadmap.md)'s
curated-content start, is an [open decision](./README.md#open-decisions).

- Official syllabus documents.
- Authorized textbook PDFs.
- Text-based PDFs and scanned pages.
- Curated lesson content.
- Parent-provided learning objectives.
- Question banks that the product has permission to use.

### Ingestion pipeline

| Stage | Output |
| --- | --- |
| Source document | PDF, text, approved content |
| Document extraction | Text, headings, tables, diagrams and page references |
| Curriculum parsing | Chapters, concepts, definitions, examples and outcomes |
| Prerequisite mapping | Concept dependencies and progression across grades |
| Validation | Schema checks, content review and source verification |
| Published curriculum | Versioned, searchable and ready for lesson planning |

### Curriculum hierarchy

Use a structured hierarchy:

- Board
- Academic year
- Grade
- Subject
- Unit
- Chapter
- Concept
- Learning objective
- Prerequisite
- Assessment item

Each learning objective should have a stable identifier.

A learning objective should describe an observable outcome, not merely repeat a chapter title.

### Sample learning objective: equivalent fractions

Illustrative identifier: `MATH.G4.FRACTIONS.EQUIVALENCE.01`.

Objective: The learner can identify and generate equivalent fractions and explain why two fractions represent the same quantity.

Prerequisites:

- Understand a fraction as part of a whole.
- Recognize numerator and denominator.
- Understand equal-sized parts.

Evidence of mastery:

- Correctly identifies equivalent fractions in visual representations.
- Solves numerical problems independently.
- Explains the relationship in their own words.
- Applies the concept in an unfamiliar problem.

### Required curriculum metadata

Each concept should contain:

- Concept ID and title.
- Grade, subject and chapter.
- Learning objectives.
- Prerequisite concepts.
- Difficulty level.
- Estimated teaching time.
- Importance for the target examination, where applicable.
- Common misconceptions.
- Approved explanations and example types.
- Assessment criteria.
- Source references and page numbers.
- Content version and validation status.

### Coverage versus mastery

The single concept learning-state vocabulary is:

| State | Evidence represented |
| --- | --- |
| Not started | No learning activity started for this concept |
| Introduced | The concept has been presented |
| Practiced with help | Performance relied on guidance or hints |
| Demonstrated independently | Independent performance meets the objective's assessment criteria |
| Retention confirmed | Later recall provides retention evidence |
| Needs revision | Evidence calls for revisiting the concept |

Exposure and retention remain distinct. Exact progression evidence and
transition criteria must be approved in the
[configuration registry](./README.md#configuration-registry).

A chapter must not be marked mastered just because the child watched a lesson or completed the associated quiz.

### Copyright and source integrity

Use appropriately licensed or public-domain curriculum sources and verify the terms of any uploaded material. Do not assume that uploading a copyrighted commercial textbook gives the product the right to reproduce its pages, illustrations or questions to every user.

Store source references, preserve attribution where required, and avoid distributing extracted textbook content beyond the permissions available to the product.
