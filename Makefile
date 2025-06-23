.PHONY: build build-c build-static build-optimized test clean run run-c install check format lint

# Default target
all: build test

# Build the project (default: Chez Scheme backend)
build:
	idris2 --build tensor-kombat.ipkg

# Build with RefC (C) backend for static compilation
build-c:
	@echo "🔧 Building with RefC (C) backend..."
	@if ! command -v gcc > /dev/null 2>&1; then \
		echo "❌ GCC not found. RefC backend requires C compiler."; \
		echo "💡 Run 'nix develop' to enter development shell with all dependencies."; \
		exit 1; \
	fi
	@echo "🔧 Fixing Nix TMPDIR restrictions..."
	TMPDIR=/tmp idris2 --cg refc --build tensor-kombat.ipkg
	@if [ -f build/exec/tensor-kombat.c ]; then \
		echo "✅ C code generated successfully ($(du -h build/exec/tensor-kombat.c | cut -f1))"; \
		if [ ! -x build/exec/tensor-kombat ] || file build/exec/tensor-kombat | grep -q "script"; then \
			echo "⚠️  Native binary compilation failed. Check if GMP headers are available."; \
			echo "💡 Try: 'exit' then 'nix develop' to reload environment with GMP dependencies."; \
		else \
			echo "✅ Native binary compiled successfully"; \
			echo "📦 Binary size: $$(du -h build/exec/tensor-kombat | cut -f1)"; \
		fi \
	else \
		echo "❌ C code generation failed"; \
	fi

# Build optimized RefC binary with size optimization and stripping
build-optimized:
	@echo "🚀 Building optimized RefC binary..."
	@if ! command -v gcc > /dev/null 2>&1; then \
		echo "❌ GCC not found. RefC backend requires C compiler."; \
		exit 1; \
	fi
	@echo "⚙️  Setting optimization flags..."
	@echo "🔧 Fixing Nix TMPDIR restrictions..."
	TMPDIR=/tmp IDRIS2_CFLAGS="-O3 -DNDEBUG" \
	IDRIS2_LDFLAGS="-Wl,-dead_strip" \
	idris2 --cg refc -Xcase-tree-opt --build tensor-kombat.ipkg
	@if [ -f build/exec/tensor-kombat ] && [ -x build/exec/tensor-kombat ]; then \
		echo "✅ Optimized binary compiled successfully"; \
		echo "📦 Binary size: $$(du -h build/exec/tensor-kombat | cut -f1)"; \
		echo "📊 Libraries: $$(otool -L build/exec/tensor-kombat | tail -n +2 | wc -l | tr -d ' ') linked"; \
		if command -v strip > /dev/null 2>&1; then \
			echo "🪄 Stripping debug symbols..."; \
			strip build/exec/tensor-kombat; \
			echo "📦 Stripped size: $$(du -h build/exec/tensor-kombat | cut -f1)"; \
		fi \
	else \
		echo "⚠️  Optimized compilation failed, trying standard build..."; \
		$(MAKE) build-c; \
	fi

# Alias for build-c (clearer name)
build-static: build-c

# Run tests (main test suite only)
test: build
	idris2 --build test.ipkg
	KOMBAT_TEST_MODE=true ./build/exec/test-runner

# Test API key verification (requires valid API keys)
test-api-keys:
	@echo "🔑 Testing API Key Verification..."
	idris2 --build api-key-test.ipkg
	./build/exec/api-key-test

# Run all tests (main suite + API key verification)
test-all: test test-api-keys
	@echo "🎉 All tests completed!"



# Clean build artifacts
clean:
	rm -rf build/

# Run the main application (Chez Scheme version)
run: build
	./build/exec/tensor-kombat

# Run the C-compiled version
run-c: build-c
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
	@echo "  build          - Build the project (Chez Scheme backend, fast compilation)"
	@echo "  build-c        - Build with RefC backend (generates C code, static binary)"
	@echo "  build-static   - Alias for build-c"
	@echo "  build-optimized- Build RefC with aggressive optimizations & dead code elimination"
	@echo "  test           - Run main test suite"
	@echo "  test-api-keys  - Test API key verification (requires valid keys)"
	@echo "  test-all       - Run all tests (main suite + API verification)"
	@echo "  clean          - Clean build artifacts"
	@echo "  run            - Run the main application (Chez version)"
	@echo "  run-c          - Run the C-compiled version"
	@echo "  check          - Type check without building"
	@echo "  tdd            - Quick test cycle (clean + test)"
	@echo "  help           - Show this help"
	@echo ""
	@echo "Backend comparison:"
	@echo "  Chez Scheme:     Fast compilation, requires Scheme runtime, ~434B wrapper + ~128KB runtime"
	@echo "  RefC (C):        Slower compilation, generates C code, ~464KB static binary"
	@echo "  RefC Optimized:  Aggressive optimization, dead code elimination, smaller binary"
