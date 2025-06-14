# Known Bugs

This document tracks currently known bugs in Tensor-Kombat that need to be fixed.

## Active Bugs

### Bug #1: Claude Selection Not Working

**Status:** 🔴 Confirmed
**Priority:** High
**Discovered:** User report

**Description:**
When user selects Claude as the 2nd debate participant, the system still uses ChatGPT 4 instead.

**Steps to Reproduce:**

1. Start tensor-kombat
2. Select "Yes" to start debate
3. Choose any topic
4. Select ChatGPT 4 as first participant
5. Select Claude 4 as second participant
6. Observe that both participants appear to use ChatGPT 4

**Investigation Status:**

- ✅ Model selection parsing logic verified working (DebugModelSelection.idr)
- ✅ Speaker assignment logic verified working
- ✅ Session creation preserves Claude4 correctly
- ✅ API endpoint selection working (Claude -> Anthropic endpoint)
- ✅ API key variable selection working (Claude -> ANTHROPIC_API_KEY)
- ❌ Need to check actual API calls during debate execution
- ❌ Need to check turn management in runDebate function

**Next Steps:**

- Bug is NOT in model selection pipeline - all steps verified ✅
- Bug must be in debate execution logic (runDebate or addTurn functions)
- Add debug output during actual debate turns
- Check if correct model is passed to generateResponse calls

### Bug #2: NetworkError on Turn 3 - File Not Found

**Status:** 🔴 Active
**Priority:** High
**Discovered:** User report

**Description:**

```
💭 ChatGPT 4 is thinking...
❌ Error: NetworkError: Failed to read response: File Not Found
Ending debate due to error.
```

**Analysis:**
The HTTP adapter uses temporary files for API requests/responses, which can cause race conditions or cleanup issues.

**Root Cause:**

- HTTP adapter creates temp files like `/tmp/tensor_kombat_response.txt`
- Multiple concurrent requests or cleanup timing can cause "File Not Found" errors

**Attempted Fix:**

- ✅ Added unique filenames using process ID: `/tmp/tensor_kombat_response_$$.txt`
- ❌ Need to test if this resolves the issue

**Alternative Solutions:**

- Use in-memory HTTP handling instead of temp files
- Add retry logic for file operations
- Better error handling for file cleanup

## Fixed Bugs

### Bug #F1: JSON Parsing Failure

**Status:** ✅ Fixed
**Priority:** High
**Fixed:** 2024-01-XX

**Description:**
"Could not extract content from OpenAI response" error due to mock JSON parsing.

**Solution:**
Implemented proper JSON string extraction in `src/Adapters/AI.idr`:

- Fixed `findJSONString` function to actually parse JSON instead of returning mock data
- Added proper escape character handling
- Verified with test cases for OpenAI, Claude, and Gemini response formats

## Bug Tracking Guidelines

### Status Indicators

- 🔴 Active/Confirmed - Bug exists and needs fixing
- 🟡 Investigating - Bug reported but needs verification
- 🟢 Fixed - Bug resolved and tested
- ⚪ Won't Fix - Bug acknowledged but won't be addressed

### Priority Levels

- **Critical** - System crashes, data loss, security issues
- **High** - Major functionality broken, affects primary use cases
- **Medium** - Minor functionality issues, workarounds exist
- **Low** - Cosmetic issues, nice-to-have fixes

### Adding New Bugs

When adding a new bug:

1. Assign a unique Bug ID (format: Bug #N for active, Bug #FN for fixed)
2. Include clear reproduction steps
3. Set appropriate status and priority
4. Document investigation progress
5. Update status as work progresses

### Investigation Process

For each bug:

1. Reproduce the issue consistently
2. Identify root cause through debugging
3. Implement minimal fix
4. Test fix thoroughly
5. Update documentation
6. Move to Fixed section when complete
