.PHONY: build test clean run install check format lint

# Default target
all: build test

# Build the project
build:
	idris2 --build tensor-kombat.ipkg

# Run tests
test:
	idris2 --build test.ipkg
	KOMBAT_TEST_MODE=true ./build/exec/test-runner



# Clean build artifacts
clean:
	rm -rf build/

# Run the main application
run: build
	./build/exec/tensor-kombat

# Install dependencies (handled by Nix)
install:
	@echo "Dependencies managed by Nix flake"
	@echo "Run 'nix develop' to enter development shell"

# Check code (type checking without building executable)
check:
	idris2 --check src/Main.idr

# Format code (when available)
format:
	@echo "Code formatting not yet implemented"

# Lint code (basic check)
lint: check
	@echo "Linting completed via type checking"

# Development helpers
dev-shell:
	nix develop

# Quick test cycle
tdd: clean test
	@echo "TDD cycle complete"

# Show help
help:
	@echo "Available targets:"
	@echo "  build     - Build the project"
	@echo "  test      - Run all tests"
	@echo "  clean     - Clean build artifacts"
	@echo "  run       - Run the main application"
	@echo "  check     - Type check without building"
	@echo "  tdd       - Quick test cycle (clean + test)"
	@echo "  help      - Show this help"
