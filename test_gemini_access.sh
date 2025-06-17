#!/bin/bash

# Gemini Model Access Test Utility
# Tests which Gemini models are actually available with your API key

set -e

echo "🧪 Gemini Model Access Test"
echo "=========================="
echo ""

# Check if API key is set
if [ -z "$GOOGLE_GEMINI_API_KEY" ]; then
    echo "❌ GOOGLE_GEMINI_API_KEY environment variable not set"
    echo "💡 Set your API key: export GOOGLE_GEMINI_API_KEY=\"your-key-here\""
    exit 1
fi

echo "🔑 API key found (length: ${#GOOGLE_GEMINI_API_KEY} characters)"
echo ""

# List available models
echo "📋 Listing available models..."
echo "==============================="

curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=$GOOGLE_GEMINI_API_KEY" | \
    jq -r '.models[]? | select(.supportedGenerationMethods[]? == "generateContent") | "\(.name) - \(.displayName)"' || \
    echo "❌ Failed to list models or jq not available"

echo ""
echo "🧪 Testing specific model endpoints..."
echo "======================================"

# Test models that we're trying to use
MODELS=(
    "gemini-2.5-pro"
    "gemini-2.5-pro-preview"
    "gemini-2.5-pro-preview-06-05"
    "gemini-2.5-pro-exp"
    "gemini-1.5-pro"
    "gemini-1.5-flash"
    "gemini-2.0-flash-exp"
)

for model in "${MODELS[@]}"; do
    echo "Testing: $model"

    # Create minimal test request
    request_body='{
        "contents": [{
            "parts": [{"text": "Hello"}]
        }],
        "generationConfig": {
            "maxOutputTokens": 10
        }
    }'

    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -H "Content-Type: application/json" \
        -d "$request_body" \
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GOOGLE_GEMINI_API_KEY")

    # Extract HTTP status
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_STATUS:/d')

    case $http_status in
        200)
            echo "  ✅ $model: Available"
            ;;
        404)
            echo "  ❌ $model: Not found (404)"
            ;;
        429)
            echo "  ⚠️  $model: Quota exceeded (429)"
            # Try to extract quota information
            quota_info=$(echo "$response_body" | jq -r '.error.message' 2>/dev/null || echo "Quota limit reached")
            echo "     💡 $quota_info"
            ;;
        403)
            echo "  🔐 $model: Access denied (403)"
            ;;
        *)
            echo "  ❓ $model: HTTP $http_status"
            echo "     Response: $(echo "$response_body" | head -c 100)..."
            ;;
    esac
done

echo ""
echo "💡 Recommendations:"
echo "==================="
echo "✅ Use models that show 'Available'"
echo "⚠️  For quota issues (429), check your billing/usage limits"
echo "❌ Avoid models that show 'Not found'"
echo ""
echo "🔧 To fix tensor-kombat:"
echo "1. Update GeminiPro endpoint to use an available model"
echo "2. Consider using Gemini Flash if Pro has quota issues"
echo "3. Check Google AI Studio console for quota details"
