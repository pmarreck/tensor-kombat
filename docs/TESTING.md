# Testing Guide

## 🧪 Test Structure

Tests are organized to mirror the source code structure for consistency and maintainability:
```
test/
├── Core/        # Unit tests for core domain logic
├── Adapters/    # Adapter integration tests
├── Ports/       # Interface/CLI tests
├── Integration/ # End-to-end workflow tests
└── TestRunner.idr # Aggregates all tests
```

## 🛠️ Test Conventions

- **File Naming**: Use `ModuleTest.idr` for corresponding `Module.idr` files
- **Test Types**:
  - ✅ **Unit Tests**: Test single functions/classes in isolation
  - 🔁 **Integration Tests**: Validate module interactions
  - 🔄 **End-to-End Tests**: Verify full user workflows
- **Test Placement**: 1 test file per source module

## ⚙️ Execution

To run all tests:
```bash
make test
```

To run tests directly:
```bash
./build/exec/test-runner
```

## 🧑‍💻 Writing New Tests

1. Create test file in `test/<module>` following source structure
2. Add test imports to `test/TestRunner.idr`
3. Write tests covering:
   - Happy path scenarios
   - Edge cases
   - Error conditions
4. Verify with `make test`

## 📊 Coverage Requirements

All public functions must have:
- 100% unit test coverage
- 70%+ integration test coverage
- At least one end-to-end test for critical workflows

## 🧪 Special Cases

- **Integration Tests**: Use real HTTP/DB connections where appropriate
- **Mocking**: Use dependency injection rather than hardcoded mocks
- **Performance Tests**: Place in `test/performance/` directory

## 📌 Troubleshooting

If tests fail unexpectedly:
1. Check `build/logs/test.log` for detailed output
2. Run specific tests with:
```bash
./build/exec/test-runner <test_module>
```
3. Consult `docs/KNOWN_BUGS.md` for common issues
```

This file establishes a clear, maintainable testing workflow while aligning with the project's architectural principles and coding standards.
