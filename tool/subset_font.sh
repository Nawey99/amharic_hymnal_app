#!/bin/bash
# Font subsetting script for NotoSansEthiopic
# Requires pyftsubset from fonttools: pip install fonttools

FONT_INPUT="assets/fonts/NotoSansEthiopic-Regular.ttf"
FONT_OUTPUT="assets/fonts/NotoSansEthiopic-Regular-subset.ttf"

echo "Subsetting NotoSansEthiopic font..."

# Subset to include only:
# - Amharic Unicode range: U+1200-U+137F
# - Latin (basic): U+0020-U+007F
# - Numbers: U+0030-U+0039
pyftsubset "$FONT_INPUT" \
  --output-file="$FONT_OUTPUT" \
  --unicodes="U+0020-007F,U+0030-0039,U+1200-137F" \
  --layout-features="*" \
  --flavor="woff2"

if [ $? -eq 0 ]; then
  echo "✅ Font subsetted successfully"
  echo "   Original: $(du -h "$FONT_INPUT" | cut -f1)"
  echo "   Subset: $(du -h "$FONT_OUTPUT" | cut -f1)"
  echo ""
  echo "⚠️  Remember to update pubspec.yaml to use the subset font"
else
  echo "❌ Font subsetting failed"
  echo "   Install fonttools: pip install fonttools"
  exit 1
fi





