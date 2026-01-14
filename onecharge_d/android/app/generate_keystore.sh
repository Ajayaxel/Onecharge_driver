#!/bin/bash

# Script to generate Android upload keystore
# Make sure Java is installed before running this script

KEYSTORE_PATH="./upload-keystore.jks"
ALIAS="upload"

echo "Generating Android upload keystore..."
echo "You will be prompted to enter:"
echo "  - Keystore password (twice)"
echo "  - Key password (twice)"
echo "  - Your name and organization details"
echo ""

keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 100000 \
  -alias "$ALIAS"

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Keystore generated successfully at: $KEYSTORE_PATH"
  echo ""
  echo "IMPORTANT: Keep this keystore file and passwords safe!"
  echo "You'll need them to sign your app for Google Play Store."
else
  echo ""
  echo "✗ Failed to generate keystore. Make sure Java is installed."
  exit 1
fi

