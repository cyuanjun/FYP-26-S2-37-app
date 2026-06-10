# CONTROL layer

One class per use case (the mock's store actions, e.g. `EndWorkoutSession`,
`StartPremium`, `JoinChallenge`). A Control is the ONLY thing that mediates
between a Boundary (screen/gateway) and an Entity — screens never touch the
database directly. Implemented as a Riverpod Notifier the UI watches.

Instrument each Control with the `SEQ <useCase> <from> -> <to> : <message>`
logging convention (bce-design.md §6) for design↔implementation traceability.
