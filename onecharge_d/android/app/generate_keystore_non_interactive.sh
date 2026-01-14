#!/bin/bash

# Non-interactive script to generate Android upload keystore
# This script uses default passwords - CHANGE THEM FOR PRODUCTION!

KEYSTORE_PATH="./upload-keystore.jks"
ALIAS="upload"
STORE_PASS="${KEYSTORE_PASSWORD:-android123}"
KEY_PASS="${KEY_PASSWORD:-android123}"

echo "Generating Android upload keystore (non-interactive mode)..."
echo "Using default passwords. Change them for production use!"
echo ""

keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 1000000 \
  -alias "$ALIAS" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -dname "CN=OneCharge Driver, OU=Development, O=OneCharge, L=City, ST=State, C=US"

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Keystore generated successfully at: $KEYSTORE_PATH"
  echo ""
  echo "Keystore details:"
  echo "  Location: android/app/$KEYSTORE_PATH"
  echo "  Alias: $ALIAS"
  echo "  Store Password: $STORE_PASS"
  echo "  Key Password: $KEY_PASS"
  echo ""
  echo "⚠️  IMPORTANT: Change the default passwords for production!"
  echo "⚠️  Keep this keystore file and passwords safe - you'll need them for app updates!"
else
  echo ""
  echo "✗ Failed to generate keystore."
  echo "Make sure Java JDK is installed. Install it with:"
  echo "  brew install openjdk@17"
  echo "Or download from: https://www.oracle.com/java/technologies/downloads/"
  exit 1
fi

