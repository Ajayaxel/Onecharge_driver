# Android Keystore Generation

## Quick Start

To generate the upload keystore, you need Java JDK installed first.

### Option 1: Install Java via Homebrew (Recommended)
```bash
brew install openjdk@17
```

Then run:
```bash
cd android/app
./generate_keystore_non_interactive.sh
```

### Option 2: Install Java from Oracle
Download and install from: https://www.oracle.com/java/technologies/downloads/

### Option 3: Use Android Studio's JDK
If you have Android Studio installed, you can use its bundled JDK:
```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
cd android/app
./generate_keystore_non_interactive.sh
```

## Scripts Available

1. **generate_keystore_non_interactive.sh** - Generates keystore with default passwords (quick setup)
2. **generate_keystore.sh** - Interactive script that prompts for all details

## Default Credentials (Change for Production!)

- **Keystore Password**: `android123`
- **Key Password**: `android123`
- **Alias**: `upload`

⚠️ **IMPORTANT**: Change these default passwords before using in production!

## Custom Passwords

To use custom passwords, set environment variables:
```bash
export KEYSTORE_PASSWORD="your_secure_password"
export KEY_PASSWORD="your_secure_password"
./generate_keystore_non_interactive.sh
```

## Next Steps

After generating the keystore, you'll need to:
1. Update `android/app/build.gradle.kts` to use this keystore for release builds
2. Store the keystore file and passwords securely
3. Never commit the keystore file to version control (add to `.gitignore`)

