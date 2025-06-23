# 🤖 Tensor-Kombat: AI Debate Platform

**Where Ideas Clash in Epic AI Intellectual Combat!** 🥊

Tensor-Kombat is a sophisticated AI debate platform that orchestrates intelligent discussions between different AI models, complete with judge evaluation and beautiful interactive presentation.

## ✨ Features

### 🎭 Epic AI Debates

- **6 AI Services Supported**: OpenAI, Anthropic, Google, X.ai, Groq, OpenRouter (unified access to multiple models)
- **Intelligent Side Assignment**: Judge AI fairly assigns Pro/Con positions
- **Turn-Based Conversations**: Structured debate flow with context awareness
- **Length Management**: Configurable turn limits with 90% warning system
- **Real-Time Progress**: Live debate display with beautiful markdown formatting

### 🎨 Beautiful Interactive CLI

- **Stunning TUI**: Interactive menus with `gum` and markdown rendering with `glow`
- **Topic Selection**: Curated debate topics + custom input option
- **Model Selection**: Choose any combination of AI participants and judges
- **Live Updates**: Real-time debate progress with turn-by-turn display
- **Progressive Flow**: Guided experience from setup to final scoring

### 📊 Comprehensive Scoring

- **4-Criteria Evaluation**: Relevance, Argument Quality, Source Usage, Coherence
- **Weighted Scoring**: Professional rubric with 30%/30%/20%/20% weighting
- **Judge AI Assessment**: Impartial evaluation by selected AI model
- **Final Rankings**: Clear winner declaration with detailed breakdowns

### 🏗️ Professional Architecture

- **Hexagonal Design**: Clean separation of core logic, adapters, and ports
- **Pure Functional Core**: Business logic in pure functions for reliability
- **HTTP Client**: Custom implementation using system `curl` for API calls
- **Error Handling**: Robust error management for network, auth, and parsing issues

## 🚀 Quick Start

### Prerequisites

- **Nix with flakes enabled** (all dependencies managed automatically)
- **API Keys** for at least one AI service (see Configuration below)

### Installation & Usage

```bash
# Clone and enter the project
git clone <repository-url>
cd tensor-kombat

# Enter development environment (auto-installs all dependencies)
nix develop

# Run the interactive debate platform
./build/exec/tensor-kombat
```

That's it! The beautiful interactive CLI will guide you through:

1. 🎯 **Topic Selection** - Choose from curated topics or enter custom
2. 🤖 **AI Model Selection** - Pick participants and judge
3. ⚙️ **Configuration** - Set debate length and warning thresholds
4. 🎬 **Live Debate** - Watch the AI intellectual combat unfold
5. 📊 **Final Scoring** - See comprehensive evaluation and winner

## 🔑 Configuration

Set up API keys as environment variables:

```bash
# At least one is required
export OPENAI_API_KEY="your-openai-key"           # For ChatGPT-4
export ANTHROPIC_API_KEY="your-anthropic-key"     # For Claude 4
export GOOGLE_GEMINI_API_KEY="your-gemini-key"    # For Gemini Pro
export GROK_API_KEY="your-grok-key"               # For Grok
export GROQ_API_KEY="your-groq-key"               # For Groq Llama
export OPENROUTER_API_KEY="your-openrouter-key"   # For OpenRouter (unified access to multiple models)
```

## 🛠️ Development

### Architecture Overview

```
tensor-kombat/
├── src/
│   ├── Core/           # Pure business logic (types, debate rules)
│   ├── Adapters/       # External integrations (HTTP, AI APIs)
│   └── Ports/          # Interface adapters (CLI, future web)
├── test/               # Comprehensive test suite
└── flake.nix          # Nix development environment
```

### Building & Testing

```bash
# Build the project
make build

# Run main test suite (47+ assertions)
make test

# Test API key verification (requires valid API keys)
make test-api-keys

# Run all tests (main suite + API verification)
make test-all

# Clean build artifacts
make clean
```

### Test-Driven Development

This project was built entirely using **TDD methodology**:

- ✅ **Red**: Write failing tests first
- ✅ **Green**: Implement minimal code to pass
- ✅ **Refactor**: Clean up and improve

Every feature has comprehensive test coverage with both unit and integration tests.

### API Key Verification

Test your API keys without running full debates:

```bash
# Test all configured API keys
make test-api-keys
```

This integration test:
- 🔍 **Detects** all configured API keys in environment variables
- 🧪 **Tests** each key with minimal requests (single "Hi" prompt)
- 📊 **Reports** which keys are working vs failing
- 💡 **Provides** troubleshooting guidance for failed keys
- 🎯 **Minimizes** token usage (only ~1-2 tokens per test)

## 🤖 Supported AI Models

| Service        | Model      | API Endpoint                                | Status   |
| -------------- | ---------- | ------------------------------------------- | -------- |
| **OpenAI**     | GPT-4      | `/v1/chat/completions`                      | ✅ Ready |
| **Anthropic**  | Claude 4   | `/v1/messages`                              | ✅ Ready |
| **Google**     | Gemini Pro | `/v1beta/models/gemini-pro:generateContent` | ✅ Ready |
| **X.ai**       | Grok       | `/v1/chat/completions`                      | ✅ Ready |
| **Groq**       | Llama 3    | `/openai/v1/chat/completions`               | ✅ Ready |
| **OpenRouter** | Multiple   | `/api/v1/chat/completions`                  | ✅ Ready |

All models support the same debate interface with model-specific prompt formatting and response parsing.

## 📋 Example Debate Topics

**Curated Topics Available:**

- Artificial Intelligence Safety and Regulation
- Universal Basic Income
- Climate Change Policy Solutions
- Freedom of Speech vs Content Moderation
- Space Exploration vs Earth Problems
- Nuclear Energy vs Renewable Energy
- Genetic Engineering Ethics
- Cryptocurrency and Financial Systems
- Remote Work vs Office Work
- **Custom Topic** (enter your own)

## 🧪 Testing Philosophy

**Comprehensive Coverage:**

- **Core Logic**: Pure function testing with deterministic results
- **API Integration**: HTTP client tested with real endpoints (httpbin.org)
- **CLI Functions**: Interactive components tested independently
- **Error Handling**: Network, authentication, and parsing error scenarios
- **End-to-End**: Full debate flow from topic selection to scoring

**Token-Conscious Development:**

- Mock responses used during development to preserve API tokens
- Real API testing available but separated for conscious usage
- Environment-based configuration for safe testing

## 🔧 Technical Stack

- **Language**: Idris 2 (functional programming with dependent types)
- **Architecture**: Hexagonal/Clean Architecture
- **HTTP Client**: Custom implementation using system `curl`
- **TUI**: `gum` for interactive menus, `glow` for markdown rendering
- **Dependencies**: Managed via Nix flakes for reproducible builds
- **Version Control**: Jujutsu (jj) with Git backend
- **Testing**: Custom framework with 47+ assertions

## 🎯 Future Enhancements

Potential areas for expansion:

- **Web Interface**: HTTP server for browser-based debates
- **Multi-Round Tournaments**: Bracket-style AI competitions
- **Audience Participation**: Real-time voting and comments
- **Debate Archives**: Persistent storage and replay functionality
- **Advanced Analytics**: Detailed linguistic and argumentation analysis
- **Custom AI Integration**: Plugin system for additional AI services

## 🛠️ Development

### Project Organization

This project follows a clean, organized structure:

```
tensor-kombat/
├── src/                    # Source code
│   ├── Core/              # Domain types and logic
│   ├── Adapters/          # External system adapters
│   ├── Ports/             # Interface definitions
│   └── Main.idr           # Application entry point
├── test/                  # All tests
│   ├── Core/              # Core functionality tests
│   └── TestRunner.idr     # Test suite runner
├── tensor-kombat.ipkg     # Main package
├── test.ipkg             # Test package
└── Makefile              # Build system
```

### Build Commands

```bash
make build    # Build main application
make test     # Run all tests
make run      # Run the application
make clean    # Clean build artifacts
```

### Testing

The project uses a proper test structure with organized test modules:

```bash
# Run the complete test suite
make test

# Tests are located in test/ directory
# Main test runner: test/TestRunner.idr
# Core tests: test/Core/TypesTest.idr
```

### Architecture Principles

- **Hexagonal Architecture**: Clean separation of core logic, adapters, and ports
- **Pure Functional Core**: Business logic in pure functions
- **Dependency Injection**: Interfaces define contracts, adapters implement them
- **Test-Driven Development**: All code developed with tests first

## 📚 Documentation

- **Architecture**: Hexagonal design with clean separation of concerns
- **API Integration**: RESTful clients for all major AI services
- **CLI Design**: Progressive disclosure with beautiful presentation
- **Testing Strategy**: TDD with comprehensive coverage
- **Error Handling**: Graceful degradation and user feedback

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch following TDD methodology
3. **Write** failing tests first
4. **Implement** minimal code to pass tests
5. **Refactor** and improve
6. **Submit** pull request with test coverage

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- **Idris 2 Community** for the amazing functional programming language
- **AI Service Providers** for making their APIs accessible
- **Nix Community** for reproducible development environments
- **Open Source Contributors** for `gum`, `glow`, and other excellent tools

---

**Ready to watch AIs debate? Let the intellectual combat begin!** 🥊🤖
