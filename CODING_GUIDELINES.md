1. Lead with TDD: Write one failing test, run it to prove it fails (i.e., it is valid), then make it pass with a minimal implementation. Add additional test cases as needed.
2. Don't one-shot a code-dump of hundreds of lines; make small steps, led with a failing test (that you then make pass).
3. Code under test should not be aware it is being tested (I call this the Volkswagen Problem); debug modes are OK to gain visibility on code behavior and internal state, but instrumenting them in tests is brittle.
4. Maintain a project plan document and keep it updated as you go, to facilitate handoffs to fresh contexts.
5. There should be only 1 command necessary to run all unit tests (usually `make test` or `./test` or `mix test` etc., depending on the language and its conventions); keep integration tests, performance tests and fuzzing tests as separate suites, `./test_all` or `make test_all` (or, again, whatever the convention is) should additionally run those as well.
6. Rerun unit tests after every change. Rerun all tests after milestones are reached. Check in code changes after each milestone IF all tests pass.
7. Tabs preferred over spaces for indentation unless the language absolutely requires spaces.
8. When there is uncertainty on how to proceed, it is OK to ask me for help/guidance. Otherwise, press on, keeping project goals in mind.
9. Parsimony is godlike. No large-scale changes unless they are trivial refactorings.
10. Stop touching the disk unless you absolutely have to. SSD wear is real, disk access is slow and more difficult to parallelize, and only Linux has in-memory tmpfs; I code on macOS sometimes.
11. Use jj (jujutsu) if available, otherwise use git.
12. Use hexagonal design architecture to decouple components and improve maintainability and testability.
13. NEVER HARDCODE OR MOCK VALUES JUST TO SATISFY A TEST.
