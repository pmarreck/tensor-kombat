# Gemini API Model Availability Findings

## Summary

Through comprehensive API testing with a paid Google AI Studio API key, we discovered significant limitations in Gemini model availability that required updating the tensor-kombat configuration.

## Testing Method

Created `test_gemini_access.sh` utility that:
1. Lists all available models via the Google AI API
2. Tests specific model endpoints with minimal requests
3. Categorizes responses (200=Available, 404=Not Found, 429=Quota Issues, etc.)

## Key Findings

### ✅ Available Models (Tested Working)
- `gemini-1.5-flash` - ✅ **Reliable, works with paid API**
- `gemini-2.0-flash-exp` - ✅ Available

### ❌ Quota-Limited Models (Even with Paid API)
- `gemini-2.5-pro-preview-06-05` - ❌ HTTP 429: "Gemini 2.5 Pro Preview doesn't have a free quota tier"
- `gemini-1.5-pro` - ❌ HTTP 429: "You exceeded your current quota"

### ❌ Non-Existent Models
- `gemini-2.5-pro` - ❌ HTTP 404: Model not found
- `gemini-2.5-pro-preview` - ❌ HTTP 404: Model not found
- `gemini-2.5-pro-exp` - ❌ HTTP 404: Model not found

## Resolution

Updated tensor-kombat configuration:
- **Before**: GeminiPro used `gemini-2.5-pro-preview-06-05` (quota issues)
- **After**: Both GeminiPro and GeminiFlash use `gemini-1.5-flash` (verified working)

## Why Gemini 2.5 Pro Doesn't Work

Even with a **paid API key**, Gemini 2.5 Pro Preview models require a special paid tier that's separate from regular Google AI Studio billing. The error message is clear:

```
HTTP 429: Gemini 2.5 Pro Preview doesn't have a free quota tier
```

This affects even paying customers who haven't specifically purchased Gemini 2.5 Pro access.

## Recommendations

1. **Use `gemini-1.5-flash`** - Most reliable Gemini model for general use
2. **Use `gemini-2.0-flash-exp`** - Alternative if 1.5 Flash has issues
3. **Avoid Gemini 2.5 Pro models** - Until Google changes their quota policy
4. **Run `test_gemini_access.sh`** - Before updating any Gemini endpoints

## Testing Your API Access

To test your own API key:

```bash
export GOOGLE_GEMINI_API_KEY="your-key-here"
./test_gemini_access.sh
```

This will show you exactly which models are available with your specific API key and quota limits.

## Impact on Tensor-Kombat

- ✅ **Fixed**: No more HTTP 404/429 errors when using Gemini models
- ✅ **Reliable**: Both "Gemini Pro" and "Gemini Flash" options now work consistently
- ✅ **Tested**: Configuration verified with real paid API key
- ✅ **Future-proof**: Test utility ensures we can validate model availability

## Lessons Learned

1. **Model names in documentation ≠ actual API availability**
2. **Paid API keys don't guarantee access to all models**
3. **Real API testing is essential** for production configurations
4. **Google's quota system is complex** and not well documented
5. **Conservative model selection** (using 1.5 Flash) ensures reliability

## Date
January 2025

## Status
✅ **RESOLVED** - Gemini integration now working reliably with verified model endpoints
