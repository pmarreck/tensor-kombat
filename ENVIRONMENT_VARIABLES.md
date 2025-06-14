# Environment Variables Configuration

This document describes all supported environment variables for configuring Tensor-Kombat's AI model integrations.

## API Keys

### Required for Remote Models

These environment variables are required for accessing remote AI services:

```bash
export OPENAI_API_KEY="sk-..."              # OpenAI ChatGPT API key
export ANTHROPIC_API_KEY="sk-ant-api03-..."  # Anthropic Claude API key
export GOOGLE_GEMINI_API_KEY="..."          # Google Gemini API key
export GROK_API_KEY="xai-..."               # xAI Grok API key
export GROQ_API_KEY="gsk_..."               # Groq API key
```

### Optional for Local Models

```bash
export OLLAMA_API_KEY="..."                 # Optional: Ollama API key (usually not needed for local)
```

## Model Selection

### Default Model Names

Configure which specific model to use for each provider:

```bash
# OpenAI Models
export OPENAI_DEFAULT_MODEL="gpt-4o"        # Default: GPT-4o (latest)
export OPENAI_DEFAULT_MODEL="gpt-4-turbo"   # Alternative: GPT-4 Turbo
export OPENAI_DEFAULT_MODEL="gpt-4"         # Alternative: GPT-4.5
export OPENAI_DEFAULT_MODEL="o3-mini"       # Alternative: o3 mini
export OPENAI_DEFAULT_MODEL="gpt-4o-mini"   # Alternative: GPT-4o mini (cost-effective)

# Anthropic Models
export ANTHROPIC_DEFAULT_MODEL="claude-3-5-sonnet-20241022"  # Default
export ANTHROPIC_DEFAULT_MODEL="claude-3-haiku-20240307"     # Alternative: faster
export ANTHROPIC_DEFAULT_MODEL="claude-3-opus-20240229"      # Alternative: most capable

# Google Models
export GOOGLE_DEFAULT_MODEL="gemini-2.0-flash-exp" # Default: 2.0 Flash (due to Pro API limits)
export GOOGLE_DEFAULT_MODEL="gemini-2.5-pro"       # Alternative: stable 2.5 Pro version

# xAI Models
export GROK_DEFAULT_MODEL="grok-3"          # Default: Grok 3 (latest)
export GROK_DEFAULT_MODEL="grok-beta"       # Alternative: beta version (if available)

# Groq Models
export GROQ_DEFAULT_MODEL="llama-3.1-70b-versatile"  # Default
export GROQ_DEFAULT_MODEL="mixtral-8x7b-32768"       # Alternative: different model

# Ollama Local Models
export OLLAMA_DEFAULT_MODEL="llama3.3:70b"  # Default: high-quality model
export OLLAMA_DEFAULT_MODEL="llama3.2"      # Alternative: smaller/faster
export OLLAMA_DEFAULT_MODEL="mistral"       # Alternative: different model family
export OLLAMA_DEFAULT_MODEL="codellama"     # Alternative: code-focused model
```

## Context Length Configuration

### Per-Provider Context Limits

Configure maximum context length (tokens) for each provider:

```bash
# OpenAI Context Length
export OPENAI_CONTEXT_LENGTH="128000"       # Default: 128K tokens (GPT-4o)
export OPENAI_CONTEXT_LENGTH="65536"        # For o3 models (65K)
export OPENAI_CONTEXT_LENGTH="8192"         # For GPT-4.5 (8K)

# Anthropic Context Length
export ANTHROPIC_CONTEXT_LENGTH="200000"    # Default: 200K tokens (Claude 3)
export ANTHROPIC_CONTEXT_LENGTH="100000"    # Alternative: 100K for faster response

# Google Context Length
export GOOGLE_CONTEXT_LENGTH="1000000"      # Default: 1M tokens (Gemini 2.0 Flash)
export GOOGLE_CONTEXT_LENGTH="2097152"      # Gemini 2.5 Pro: 2M tokens
export GOOGLE_CONTEXT_LENGTH="32768"        # Alternative: 32K tokens for basic usage

# xAI Context Length
export GROK_CONTEXT_LENGTH="8192"           # Default: 8K tokens
export GROK_CONTEXT_LENGTH="32768"          # Alternative: Grok 3 may support larger context

# Groq Context Length
export GROQ_CONTEXT_LENGTH="8192"           # Default: 8K tokens
export GROQ_CONTEXT_LENGTH="32768"          # For larger context models

# Ollama Context Length
export OLLAMA_CONTEXT_LENGTH="16384"        # Default: 16K tokens
export OLLAMA_CONTEXT_LENGTH="32768"        # For models that support larger context
export OLLAMA_CONTEXT_LENGTH="4096"         # For smaller/faster inference
```

## Max Response Tokens Configuration

### Per-Provider Response Limits

Configure maximum response length (tokens) for AI-generated responses:

```bash
# OpenAI Max Response Tokens
export OPENAI_MAX_TOKENS="4000"             # Default: 4K response tokens (GPT-4o)
export OPENAI_MAX_TOKENS="2000"             # For GPT-4.5 and o4-mini (2K)
export OPENAI_MAX_TOKENS="1000"             # For shorter/faster responses

# Anthropic Max Response Tokens
export ANTHROPIC_MAX_TOKENS="3000"          # Default: 3K response tokens
export ANTHROPIC_MAX_TOKENS="4000"          # For comprehensive arguments
export ANTHROPIC_MAX_TOKENS="2000"          # For more concise responses

# Google Max Response Tokens
export GOOGLE_MAX_TOKENS="8192"             # Default: 8K response tokens (Gemini Flash)
export GOOGLE_MAX_TOKENS="8000"             # For Gemini 2.5 Pro (8K)
export GOOGLE_MAX_TOKENS="2000"             # For shorter responses

# xAI Max Response Tokens
export GROK_MAX_TOKENS="2000"               # Default: 2K response tokens
export GROK_MAX_TOKENS="4000"               # For detailed debate arguments

# Groq Max Response Tokens
export GROQ_MAX_TOKENS="2000"               # Default: 2K response tokens
export GROQ_MAX_TOKENS="8000"               # For longer responses (if supported)

# Ollama Max Response Tokens
export OLLAMA_MAX_TOKENS="2000"             # Default: 2K response tokens
export OLLAMA_MAX_TOKENS="4000"             # For longer local model responses
export OLLAMA_MAX_TOKENS="1000"             # For faster inference
```

## Testing and Automation

### Scripted Debate Configuration

Use these for automated testing and scripted debates:

```bash
# Automated Model Selection (bypasses interactive prompts)
export KOMBAT_DEFAULT_SELECTIONS="Yes;AI Ethics Debate;Ollama Local;Claude 4;ChatGPT 4o"

# Selection Timeout (for automated runs)
export KOMBAT_SELECTION_TIMEOUT="0.01s"     # Very fast timeout for scripts

# Debug Output
export DEBUG="true"                          # Enable detailed debug logging
```

## Example Configurations

### Local Development Setup

Perfect for privacy-focused development with local models:

```bash
# Local Ollama with large context
export OLLAMA_DEFAULT_MODEL="llama3.3:70b"
export OLLAMA_CONTEXT_LENGTH="32768"
export KOMBAT_DEFAULT_SELECTIONS="Yes;Privacy vs Security;Ollama Local;Ollama Local;Ollama Local"
```

### Production Cloud Setup

High-performance setup using best cloud models:

```bash
# Use premium models with large context and response capacity
export OPENAI_DEFAULT_MODEL="gpt-4-turbo"
export OPENAI_CONTEXT_LENGTH="128000"
export OPENAI_MAX_TOKENS="4000"
export ANTHROPIC_DEFAULT_MODEL="claude-3-5-sonnet-20241022"
export ANTHROPIC_CONTEXT_LENGTH="200000"
export ANTHROPIC_MAX_TOKENS="4000"
export GOOGLE_DEFAULT_MODEL="gemini-2.0-flash-exp"
export GOOGLE_CONTEXT_LENGTH="1000000"
export GOOGLE_MAX_TOKENS="8192"

# API Keys
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-api03-..."
export GOOGLE_GEMINI_API_KEY="..."
```

### Cost-Optimized Setup

Budget-friendly configuration using faster/cheaper models:

```bash
# Use cost-effective models with conservative response limits
export OPENAI_DEFAULT_MODEL="gpt-4o-mini"
export OPENAI_CONTEXT_LENGTH="128000"
export OPENAI_MAX_TOKENS="2000"
export ANTHROPIC_DEFAULT_MODEL="claude-3-haiku-20240307"
export ANTHROPIC_CONTEXT_LENGTH="100000"
export ANTHROPIC_MAX_TOKENS="2000"
export GROQ_DEFAULT_MODEL="llama-3.1-8b-instant"
export GROQ_CONTEXT_LENGTH="8192"
export GROQ_MAX_TOKENS="1000"
```

### Hybrid Setup

Mix of local and cloud models for optimal performance/cost:

```bash
# Use local model for one participant, cloud for others
export OLLAMA_DEFAULT_MODEL="llama3.3:70b"
export OLLAMA_CONTEXT_LENGTH="16384"
export OLLAMA_MAX_TOKENS="3000"
export ANTHROPIC_DEFAULT_MODEL="claude-3-5-sonnet-20241022"
export ANTHROPIC_MAX_TOKENS="3000"
export OPENAI_DEFAULT_MODEL="gpt-4o"
export OPENAI_MAX_TOKENS="4000"

# Scripted selection: Local vs Cloud with Cloud judge
export KOMBAT_DEFAULT_SELECTIONS="Yes;Local vs Cloud AI;Ollama Local;Claude 4;ChatGPT 4o"
```

## Environment Variable Priority

1. **Environment Variables**: Highest priority (what you set)
2. **Application Defaults**: Used when env vars not set
3. **Fallback Values**: Hardcoded minimums if parsing fails

## Validation and Testing

Run this command to test your environment variable configuration:

```bash
make test
```

Look for the "Context Length Configuration Tests" section to verify your settings are detected correctly.

## Troubleshooting

### Common Issues

1. **Invalid Context Length**: If you set an invalid number, the default will be used
2. **Missing API Keys**: Remote models will be skipped if API keys are missing
3. **Model Not Found**: If a custom model name isn't available, you'll get an API error

### Debug Mode

Enable debug mode to see exactly which values are being used:

```bash
export DEBUG=true
./build/exec/tensor-kombat
```

This will show you:

- Which environment variables were detected
- What default values are being used
- API endpoints and model names being used
- Context lengths configured for each provider

## Security Notes

- **Never commit API keys** to version control
- **Use `.env` files** for local development (add to `.gitignore`)
- **Use secure environment management** in production (AWS Secrets Manager, etc.)
- **Rotate API keys regularly** for security

## Future Enhancements

The environment variable system is designed to be extensible. Future additions may include:

- `*_MAX_TOKENS` for response length limits
- `*_TEMPERATURE` for creativity settings
- `*_TOP_P` for nucleus sampling
- `*_FREQUENCY_PENALTY` for repetition control
- Regional endpoint configuration (`*_REGION`, `*_ENDPOINT`)
