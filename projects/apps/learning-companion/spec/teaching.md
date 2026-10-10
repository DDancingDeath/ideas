# Adaptive teaching and child experience


## 4.7 The adaptive teaching engine

The engine should learn from a child's actual interactions and decide which
teaching strategy is likely to help next.

### Teaching strategies to support

| Strategy | Teaching behavior |
| --- | --- |
| Visual explanation | Diagrams, number lines, shapes, animations and manipulable objects make abstract concepts concrete |
| Story-based learning | Characters, problems, discovery and cause-and-effect narratives introduce concepts |
| Game-based exploration | Puzzles, predictions and object manipulation let the child discover rules |
| Direct explanation | Clear explanation, worked example and guided practice |
| Real-world application | Familiar objects, everyday activities, nature, sports, machines or chosen interests provide context |

These are options the system can select among. Do not permanently classify a child as a “visual learner” or “story learner.” A student may benefit from different approaches for different subjects and concepts.

### The teaching loop

Every lesson should follow a controlled learning loop using the adaptation
rules below and the [Engagement-to-Mastery progression](#48-story-to-content-progression).
Progression evidence remains subject to the
[assessment criteria](./README.md#configuration-registry).

### Rules for adapting teaching

| Observed behavior                                   | Recommended response                                                  |
| --------------------------------------------------- | --------------------------------------------------------------------- |
| Correct answer with a sound explanation             | Introduce a slightly harder problem                                   |
| Correct answer after repeated hints                 | Test independent understanding                                        |
| Repeated misconception                              | Explain the specific misconception and try a different representation |
| Correct answer but cannot explain why               | Ask a reasoning question or provide a contrasting example             |
| Long hesitation                                     | Offer a small hint without assuming a lack of understanding           |
| Repeated requests for simpler language              | Simplify vocabulary and use concrete examples                         |
| Strong performance on several independent questions | Reduce scaffolding gradually                                          |
| Voluntary advanced questions                        | Offer optional deeper exploration                                     |
| Declining accuracy after initially succeeding       | Check retention, confusion and fatigue before advancing               |

Timing and hesitation should be treated as weak signals, not proof of ability. A child may pause because they are thinking carefully, distracted or interrupted.

### Personalization profile

Maintain an evolving profile containing:

- Preferred explanation language.
- Familiar vocabulary and reading level.
- Examples that have worked well.
- Examples that did not work.
- Need for diagrams or concrete objects on particular concepts.
- Appropriate starting difficulty.
- Typical response to hints.
- Independent problem-solving ability.
- Misconceptions and prerequisite gaps.
- Topics the child voluntarily explores.
- Confidence and uncertainty in each estimate.

The profile should be updated from observed evidence, not from a one-time questionnaire alone.

### A practical example

Suppose a student struggles with the equation `2x + 3 = 11`.

The tutor initially explains the idea of an unknown value and demonstrates how to isolate it.

If the child still struggles, the tutor might use a balance-scale visualization, with equal quantities on both sides.

If that works, the tutor asks the child to solve a similar problem independently.

If the child succeeds, the system records that a balance-scale explanation was useful for this concept. It can test that strategy again in future algebra lessons rather than assuming it will always work.

Important implementation rule: the language model proposes teaching actions, but a separate learning-state engine decides whether the evidence justifies advancing, repeating or revisiting a concept.

## 4.8 Story-to-content progression

Engagement-to-Mastery progresses from stories and games toward deeper academic content.

The tutor should adjust the amount of narrative, exploration and direct instruction based on the child's age, engagement and demonstrated understanding.

| Stage | Behavior | Illustrative fraction activity |
| --- | --- | --- |
| Hook | A story or puzzle introduces a question | A character needs to share a pizza fairly |
| Discover | The child predicts, explores and manipulates examples | Divide the pizza into equal pieces |
| Explain | Connect activity to the formal concept | Introduce numerator and denominator |
| Practice | Structured problems with gradually fewer hints | Identify and compare fractions |
| Transfer | Apply the idea in a new context | Solve a recipe or measurement problem |
| Explore further | Optional depth when ready | Explore equivalent fractions or ratios |

The transition must be gradual and evidence-driven, not purely time-based.

If the child is having fun but not understanding the concept, the system should change the explanation. If the child has mastered the concept, it should not force them through a long story again.

Similarly, a child who enjoys stories should still develop the ability to reason without them.

### Engagement signals

Useful signals include:

- Whether the child chooses to continue an optional activity.
- Whether they attempt a challenge.
- Whether they ask relevant follow-up questions.
- Whether they return to an unfinished puzzle.
- Whether they can explain what they discovered.
- Whether they complete a similar task without the story.

Do not equate screen time, number of taps or session length with learning quality.

## 4.13 Visual learning, videos and 3D experiences

Visuals should be a teaching tool, not a decorative layer.

### Rendering behavior

Use the simplest representation that communicates the concept effectively.

| Content type            | Preferred representation                                |
| ----------------------- | ------------------------------------------------------- |
| Counting and arithmetic | Interactive counters and number lines                   |
| Fractions               | Shapes, bars and divided objects                        |
| Algebra                 | Balance-scale models and step-by-step transformations   |
| Geometry                | Interactive shapes and manipulable diagrams             |
| Physics                 | Motion diagrams, simulations and simple experiments     |
| Biology                 | Labeled diagrams, animations and 3D models where useful |
| Chemistry               | Particle diagrams and safe conceptual simulations       |
| History                 | Timelines, maps and narrative sequences                 |
| Geography               | Maps, spatial relationships and visual comparisons      |

### Visualization contract

Use reusable visualizations described by validated structured data.

Each visualization should be described by structured data, such as:

- Visualization type.
- Concept identifier.
- Labels and values.
- Interactive controls.
- Expected learning outcome.
- Accessibility description.
- Validated content and constraints.

For example, a fraction visualization could support changing the numerator and denominator, highlighting equal-sized parts and showing equivalent fractions.

### When to use generative media

Use AI-generated images when an original illustration genuinely helps a story or concept. Use approved videos, existing media, diagrams and procedural animations when they are more reliable or less expensive.

Reserve advanced 3D and virtual labs for topics where three-dimensional relationships or experimental interaction materially improve understanding.

Media scope follows the [staged roadmap](../plan/roadmap.md); bespoke 3D for
every lesson is not a first-release requirement.

## 4.14 Child-friendly experience and gamification

The child should experience the product as a world of puzzles, stories and discoveries, not as a spreadsheet of schoolwork.

### Child experience

- A friendly companion character.
- A visual map of learning adventures.
- Short, self-contained activities.
- Interactive puzzles.
- Discoveries and achievements.
- Optional challenge paths.
- Gentle reminders to return.
- A sense of progress that does not depend only on marks.

### Game mechanics

Use rewards for meaningful learning behaviors:

- Solving a difficult problem independently.
- Revisiting a challenging concept.
- Explaining a concept clearly.
- Correcting a misconception.
- Completing a mixed revision.
- Exploring an optional challenge.

Avoid rewards that encourage random tapping, rushing through lessons, excessive screen time or repeated low-quality attempts.

### Sessions

Support adjustable short sessions with natural stopping points. The child
should be able to pause or stop, and the parent should be able to configure
reasonable daily limits. Duration and limit values are
[registry settings](./README.md#configuration-registry), not universal rules.

The tutor should never use guilt, fear, artificial scarcity or streak loss to pressure a child into continuing.

## 4.15 Voice-first and multilingual learning

Support:

- Text-to-speech narration.
- Speech input for answers.
- Tap-based responses.
- Drawing or selecting visual objects.
- Text input for older students.
- Adjustable narration speed.
- Captions and accessible alternatives.

Language rollout requires validated demand and quality; the proposed rollout
and unresolved selection are in [design notes](../plan/design-notes.md#initial-audience-and-expansion)
and the [decision registry](./README.md#open-decisions).

### Voice interaction requirements

The tutor should:

- Speak at an age-appropriate pace.
- Ask one question at a time.
- Allow interruptions and corrections.
- Repeat or rephrase when requested.
- Avoid interpreting speech recognition errors as knowledge gaps.
- Offer touch input when speech recognition fails.
- Keep spoken explanations concise and interactive.

Voice should feel like a conversation, not a lecture that happens to be read aloud.
