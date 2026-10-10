# Planning and recovery


## 4.6 Syllabus planning and completion engine

The planner determines the next learning activity and whether required
learning can realistically fit the remaining time.

### Inputs

- Complete curriculum graph.
- Student's current mastery state.
- Target completion date.
- Available learning days.
- Daily time budget.
- Estimated lesson durations.
- Revision requirements.
- Planned examinations.
- Child's recent pace and consistency.
- Dependencies between concepts.

### Planning algorithm

The planner should:

1. Identify unmastered learning objectives.
2. Resolve prerequisite dependencies.
3. Estimate the time required for teaching, practice and revision.
4. Prioritize essential and prerequisite concepts.
5. Distribute work across available sessions.
6. Reserve time for spaced revision and cumulative assessments.
7. Calculate whether the plan fits the deadline.
8. Publish a daily or weekly schedule.
9. Recalculate when meaningful events change the plan.

Use a dependency-aware scheduling algorithm rather than dividing the number of chapters by the number of remaining days.

Prerequisites must be resolved before publishing a dependent learning sequence.

### Example: the six-month recovery scenario

Suppose a student has missed six months of instruction and has six months remaining before an important examination.

The system should not blindly compress the original schedule by a factor of two.

Instead, it should:

1. Run a diagnostic to establish the child's current level.
2. Identify already-mastered concepts that do not need full reteaching.
3. Identify foundational gaps that could block future learning.
4. Classify the remaining curriculum by importance and prerequisites.
5. Combine related concepts into coherent learning sequences.
6. Reduce repetitive explanations when understanding is demonstrated.
7. Preserve sufficient practice and revision for important outcomes.
8. Generate an updated plan with realistic daily time requirements.
9. Show any learning objectives that may remain at risk by the deadline.

If the plan is infeasible, the product should explain the trade-off and propose alternatives, such as more available study time, targeted tutoring or prioritization agreed upon with the parent.

It must not silently skip essential concepts and report the syllabus as complete.

### Example schedule

Illustrative Week 1 schedule for a learner studying fractions (5 sessions):

| Day | Focus | Activity type |
| --- | --- | --- |
| Mon | Understand fractions | New learning |
| Tue | Visual models and number lines | New learning |
| Wed | Equivalent fractions | New learning |
| Thu | Guided and independent practice | Practice |
| Fri | Mixed quiz and error review | Assessment |

The schedule is a plan, not a rigid promise. If the child masters equivalent fractions quickly, the next session can move forward. If the child struggles with the prerequisite, the system can spend more time on visual models.

### Replanning triggers

- A missed learning session.
- Consecutive sessions with unresolved difficulties, using the approved
  [trigger setting](./README.md#configuration-registry).
- Faster-than-expected mastery.
- A change in exam date or availability.
- A low score on a cumulative assessment.
- A new prerequisite gap discovered in a later chapter.

Make local adjustments where possible, then periodically recalculate the full
plan rather than rebuilding it after every small event.

## 4.16 Notifications, reminders and missed sessions

The system should encourage consistency without creating anxiety.

When a session is missed:

1. Record the missed session.
2. Recalculate the remaining workload.
3. Identify whether the missed content blocks future learning.
4. Adjust the upcoming plan where possible.
5. Inform the parent only when an important intervention is needed.
6. Resume naturally when the child returns.

Do not display messages such as “You failed your learning streak.”

A better message is:

> Welcome back! Let's pick up where we left off. We'll adjust today's plan so you can continue at a comfortable pace.

For long absences, trigger a brief diagnostic review before resuming the old plan. The child may have retained most of the material, or may need to revisit some prerequisites.
