# Known Bugs

This document tracks currently known bugs in Tensor-Kombat that need to be fixed.

## Active Bugs

(No active bugs at this time)

## Fixed Bugs

### Bug #F1: Claude Selection Not Working

**Status:** ✅ Fixed
**Priority:** High
**Fixed:** 2024-01-XX

**Description:**
When user selects Claude as the 2nd debate participant, the system still uses ChatGPT 4 instead.

**Root Cause:**
The `getNextSelection` function in `src/Ports/CLI.idr` had a fallback behavior where when a scripted selection wasn't found in the available options list, it would fall back to the first available option instead of preserving the intended selection.

**Solution:**
Fixed the `getNextSelection` function to preserve the intended selection even when it's not found in the options list, allowing the TUI wrapper functions to handle the validation properly:

```idris
-- Before (buggy):
else case options of
       (first :: _) => (first, { currentIndex := state.currentIndex + 1 } state)
       [] => ("", { currentIndex := state.currentIndex + 1 } state)

-- After (fixed):
else -- Selection not found in options - preserve intended selection
     -- and let the TUI wrapper handle the validation
     (selection, { currentIndex := state.currentIndex + 1 } state)
```

**Verification:**

- ✅ Test `testFallbackToFirstOptionBug` now passes
- ✅ Claude selections are preserved correctly through the full flow
- ✅ Integration tests confirm different models use different API endpoints

### Bug #F2: NetworkError on Turn 3 - File Not Found

**Status:** ✅ Fixed
**Priority:** High
**Fixed:** 2024-01-XX

**Description:**
"NetworkError: Failed to read response: File Not Found" error occurred when temporary files had race conditions or cleanup issues.

**Root Cause:**
The HTTP adapter and CLI functions used fixed temporary file names that could cause conflicts when multiple processes or rapid successive calls tried to use the same file names:

- `getEnvVar` used `/tmp/tensor_kombat_env.txt`
- `glowMarkdown` used `/tmp/tensor_kombat_content.md`

**Solution:**
Fixed both functions to use unique timestamp-based filenames to prevent race conditions:

```idris
-- Before (problematic):
let envFile = "/tmp/tensor_kombat_env.txt"

-- After (fixed):
time <- clockTime UTC
let uniqueId = show (nanoseconds time)
let envFile = "/tmp/tensor_kombat_env_" ++ uniqueId ++ ".txt"
```

**Verification:**

- ✅ All tests passing with unique filename implementation
- ✅ No more temp file conflicts during concurrent operations
- ✅ Main HTTP POST requests already used process pipes (no temp files)

### Bug #F3: JSON Parsing Failure

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
