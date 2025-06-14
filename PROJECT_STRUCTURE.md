# Project Structure

This document defines the canonical organization of the Tensor-Kombat project.

## Directory Structure

```
tensor-kombat/
├── src/                    # Source code (main application)
│   ├── Core/              # Core domain types and logic
│   │   └── Types.idr      # Main type definitions
│   ├── Adapters/          # External system adapters
│   │   ├── HTTP.idr       # HTTP client implementation
│   │   └── AI.idr         # AI service integrations
│   ├── Ports/             # Interface definitions and CLI
│   │   └── CLI.idr        # Command-line interface
│   └── Main.idr           # Application entry point
├── test/                  # All tests (mirrors src structure)
│   ├── Core/              # Tests for core functionality
│   │   └── TypesTest.idr  # Core types tests
│   ├── Adapters/          # Tests for adapters
│   │   ├── HTTPTest.idr   # HTTP client tests
│   │   └── AITest.idr     # AI integration tests
│   ├── Ports/             # Tests for ports
│   │   └── CLITest.idr    # CLI functionality tests
│   ├── Integration/       # End-to-end integration tests
│   │   └── DebateTest.idr # Full debate flow tests
│   └── TestRunner.idr     # Main test runner
├── assets/                # Static assets
├── build/                 # Build artifacts (generated, .gitignored)
├── docs/                  # Documentation
│   ├── API.md            # API documentation
│   ├── TESTING.md        # Testing guide
│   └── DEPLOYMENT.md     # Deployment instructions
├── tensor-kombat.ipkg     # Main package configuration
├── test.ipkg             # Test package configuration
├── Makefile              # Build system
├── flake.nix             # Nix development environment
├── README.md             # Project overview
└── PROJECT_STRUCTURE.md  # This file
```

## Package Organization

### Main Package (`tensor-kombat.ipkg`)

- **Purpose**: Production application code
- **Source**: `src/` directory
- **Executable**: `tensor-kombat`
- **Dependencies**: Core libraries only

### Test Package (`test.ipkg`)

- **Purpose**: All testing code
- **Source**: `test/` directory
- **Executable**: `test-runner`
- **Dependencies**: Main package + test libraries

## Code Organization Principles

### 1. Hexagonal Architecture

```
┌─────────────────┐
│   Ports/CLI     │ ← User Interface
└─────────────────┘
         │
┌─────────────────┐
│   Core/Types    │ ← Business Logic
└─────────────────┘
         │
┌─────────────────┐
│  Adapters/AI    │ ← External Services
│  Adapters/HTTP  │
└─────────────────┘
```

### 2. Dependency Rules

- **Core** depends on nothing (pure domain logic)
- **Ports** depend on Core (define interfaces)
- **Adapters** depend on Core and Ports (implement interfaces)
- **Main** depends on all (wires everything together)

### 3. Test Organization

- **Unit Tests**: Test individual modules in isolation
- **Integration Tests**: Test module interactions
- **End-to-End Tests**: Test complete user workflows

## Build System

### Make Targets

```bash
make build      # Build main application
make test       # Run all tests
make clean      # Clean build artifacts
make run        # Run the application
make check      # Type check without building
```

### Test Commands

```bash
make test                    # Run all tests
./build/exec/test-runner     # Run tests directly
```

## File Naming Conventions

### Source Files

- **PascalCase** for module names: `Core/Types.idr`
- **camelCase** for function names: `generateResponse`
- **PascalCase** for type names: `AIModel`, `DebateSession`

### Test Files

- **Module name + "Test"**: `TypesTest.idr`
- Mirror source directory structure
- One test file per source module

### Documentation Files

- **UPPERCASE.md** for important docs: `README.md`, `TESTING.md`
- **lowercase.md** for reference docs: `api.md`, `deployment.md`

## What NOT to Include in Root Directory

### ❌ Avoid These Patterns

- **Scattered test files**: All tests go in `test/` directory
- **Debug scripts**: Temporary debugging files should be deleted
- **Build artifacts**: Use `build/` directory only
- **Multiple test runners**: One canonical test system only

### ✅ Root Directory Should Only Contain

- Package configuration files (`.ipkg`)
- Build configuration (`Makefile`, `flake.nix`)
- Essential documentation (`README.md`)
- Project organization (`PROJECT_STRUCTURE.md`)

## Development Workflow

### 1. Adding New Features

1. Write tests in appropriate `test/` subdirectory
2. Implement feature in appropriate `src/` subdirectory
3. Run `make test` to ensure all tests pass
4. Update documentation if needed

### 2. Adding New Tests

1. Create test file in `test/` following directory structure
2. Add test module to `test.ipkg`
3. Import and call test in `TestRunner.idr`
4. Verify with `make test`

### 3. Refactoring

1. Always run `make test` before and after changes
2. Update tests to match new interfaces
3. Maintain the hexagonal architecture principles
4. Update documentation for significant changes

## Quality Standards

### Code Quality

- All code must compile without warnings
- All tests must pass before merging
- Follow established naming conventions
- Maintain clear separation of concerns

### Test Coverage

- Every public function should have tests
- Critical paths must have integration tests
- Error conditions must be tested
- End-to-end workflows must be verified

### Documentation

- All modules should have clear purpose documentation
- Public APIs should be documented
- Breaking changes require documentation updates
- Examples should be provided for complex features

## Current Status (✅ CLEAN)

The project has been cleaned up and now follows the proper structure:

### ✅ Completed Cleanup

1. **Removed scattered test files**: All loose test files deleted from root
2. **Restored proper test structure**: Only `test/` directory contains tests
3. **Working test suite**: `make test` runs cleanly with proper output
4. **Clean build system**: `make build` works without issues
5. **Documented structure**: This file defines the canonical organization

### ✅ Current Working State

- **Root directory**: Clean, only essential files (configs, docs, build files)
- **Test system**: Proper `test/TestRunner.idr` with organized test modules
- **Build system**: Standard `make` commands work correctly
- **Documentation**: Up-to-date and accurate

### 🚫 Enforced Standards

- **No scattered test files**: All tests must be in `test/` directory
- **No debug files in root**: Temporary files must be deleted after use
- **No duplicate test systems**: One canonical test runner only
- **No build artifacts in git**: Only generated files in `build/`

This structure ensures:

- ✅ Clear separation of concerns
- ✅ Scalable test organization
- ✅ Standard build process
- ✅ Maintainable codebase
- ✅ Easy onboarding for new developers
- ✅ **ENFORCED ORGANIZATION**
