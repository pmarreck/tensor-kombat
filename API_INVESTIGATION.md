# API Investigation and Documentation

This document captures the API structures, testing results, and integration details for all supported AI services in Tensor-Kombat.

## Current Status

### Working APIs
- ✅ **API Key Reading**: Fixed - using `printf "%s"` instead of `echo -n`
- ✅ **HTTP Client**: Functional with curl backend
- ❌ **Response Parsing**: FAILING - "Could not extract content from OpenAI response"

### Error Analysis
```
💭 ChatGPT 4 is thinking...
❌ Error: ParseError: Could not extract content from OpenAI response
Ending debate due to error.
```

## OpenAI API (ChatGPT 4)

### Expected Request Format
Based on OpenAI API v1 documentation:
```json
{
  "model": "gpt-4",
  "messages": [
    {
      "role": "system",
      "content": "You are a debate participant..."
    },
    {
      "role": "user",
      "content": "The debate topic is: AI vs Human Intelligence. Please argue the Pro position..."
    }
  ],
  "max_tokens": 500,
  "temperature": 0.7
}
```

### Expected Response Format
```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "gpt-4",
  "usage": {
    "prompt_tokens": 100,
    "completion_tokens": 200,
    "total_tokens": 300
  },
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "The actual debate response content here..."
      },
      "finish_reason": "stop",
      "index": 0
    }
  ]
}
```

### Current Implementation Issues
- **URL**: Check if using correct endpoint (`https://api.openai.com/v1/chat/completions`)
- **Headers**: Must include `Authorization: Bearer ${API_KEY}` and `Content-Type: application/json`
- **Parsing**: Current parser likely looking for wrong JSON path

## Anthropic API (Claude)

### Expected Request Format
```json
{
  "model": "claude-3-haiku-20240307",
  "max_tokens": 500,
  "messages": [
    {
      "role": "user",
      "content": "The debate topic is: AI vs Human Intelligence. Please argue the Pro position..."
    }
  ]
}
```

### Expected Response Format
```json
{
  "id": "msg_...",
  "type": "message",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "The actual debate response content here..."
    }
  ],
  "model": "claude-3-haiku-20240307",
  "stop_reason": "end_turn",
  "stop_sequence": null,
  "usage": {
    "input_tokens": 100,
    "output_tokens": 200
  }
}
```

### Implementation Notes
- **URL**: `https://api.anthropic.com/v1/messages`
- **Headers**: `x-api-key: ${API_KEY}`, `anthropic-version: 2023-06-01`, `content-type: application/json`
- **Content Extraction**: Response content is in array format under `content[0].text`

## Google Gemini API

### Expected Request Format
```json
{
  "contents": [
    {
      "parts": [
        {
          "text": "The debate topic is: AI vs Human Intelligence. Please argue the Pro position..."
        }
      ]
    }
  ],
  "generationConfig": {
    "maxOutputTokens": 500,
    "temperature": 0.7
  }
}
```

### Expected Response Format
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "The actual debate response content here..."
          }
        ],
        "role": "model"
      },
      "finishReason": "STOP",
      "index": 0,
      "safetyRatings": [...]
    }
  ],
  "usageMetadata": {
    "promptTokenCount": 100,
    "candidatesTokenCount": 200,
    "totalTokenCount": 300
  }
}
```

### Implementation Notes
- **URL**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${API_KEY}`
- **Headers**: `Content-Type: application/json`
- **Content Extraction**: Response content is in `candidates[0].content.parts[0].text`

## Grok API (X.AI)

### Status
- **API Key Available**: ✅
- **Documentation**: Limited - likely similar to OpenAI format
- **Testing Required**: Need to determine exact URL and format

### Suspected Format
```json
// Request (likely similar to OpenAI)
{
  "model": "grok-beta",
  "messages": [...],
  "max_tokens": 500
}

// Response (likely similar to OpenAI)
{
  "choices": [
    {
      "message": {
        "content": "..."
      }
    }
  ]
}
```

## Groq API

### Status
- **API Key Available**: ✅
- **Documentation**: OpenAI-compatible format
- **URL**: `https://api.groq.com/openai/v1/chat/completions`

### Format
Same as OpenAI but with different models:
- `llama2-70b-4096`
- `mixtral-8x7b-32768`
- `gemma-7b-it`

## Investigation Tasks

### Immediate Priority
1. **Debug OpenAI Response**:
   - Capture actual HTTP response
   - Check JSON structure matches expectations
   - Fix content extraction logic

2. **Test All APIs**:
   - Make test requests to each service
   - Document actual vs expected responses
   - Update parsing logic accordingly

### Current Code Locations
- **HTTP Client**: `src/Adapters/HTTP.idr`
- **AI Integration**: `src/Adapters/AI.idr`
- **Response Parsing**: Look for `extractContent` or similar functions

### Testing Commands
```bash
# Test with debug output
DEBUG=true KOMBAT_DEFAULT_SELECTIONS='Yes;AI vs Human Intelligence;ChatGPT 4;Claude 4;Gemini Pro' KOMBAT_SELECTION_TIMEOUT='0.01s' ./build/exec/tensor-kombat

# Test individual API with curl
curl -X POST https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4","messages":[{"role":"user","content":"Hello"}],"max_tokens":50}'
```

### Debug Strategy
1. Add HTTP response logging to see actual JSON
2. Create simple API test scripts for each service
3. Compare expected vs actual response structures
4. Update parsing functions accordingly
5. Test end-to-end debate flow

### Expected Files to Investigate
- Response parsing logic (likely in `src/Adapters/AI.idr`)
- HTTP request construction
- JSON parsing utilities
- Error handling for API responses

## Next Steps for New Context
1. Read this document
2. Find and examine the response parsing code
3. Add debug logging to capture actual API responses
4. Fix the JSON extraction logic
5. Test with each API service
6. Update this document with findings
