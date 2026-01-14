# Play Store Upload Checklist ✅

## ✅ Completed Configuration

### 1. Keystore Setup
- ✅ **Keystore File**: `android/app/upload-keystore.jks` (2.7KB, exists)
- ✅ **Key Properties**: `android/key.properties` (configured)
- ✅ **Keystore Alias**: `upload`
- ✅ **Validity**: 100,000 days (until 2299)
- ✅ **Algorithm**: RSA 2048-bit
- ✅ **Keystore Password**: `android123` (⚠️ CHANGE FOR PRODUCTION)
- ✅ **Key Password**: `android123` (⚠️ CHANGE FOR PRODUCTION)

### 2. Build Configuration
- ✅ **Signing Config**: Release builds configured to use keystore
- ✅ **build.gradle.kts**: Properly configured with signingConfigs
- ✅ **key.properties**: Loaded correctly in build file

### 3. Security
- ✅ **Git Ignore**: `key.properties` and `*.jks` files are excluded from version control
- ✅ **Keystore Location**: Stored in `android/app/` directory

### 4. App Configuration
- ✅ **Version**: 1.0.0+1 (from pubspec.yaml)
- ✅ **Min SDK**: Configured via Flutter
- ✅ **Target SDK**: Configured via Flutter
- ✅ **Permissions**: Properly declared in AndroidManifest.xml

## ⚠️ Important Warnings

### 1. Application ID
**Current**: ✅ `com.onecharge.driver`
**Status**: Updated from `com.example.onecharge_d` to comply with Play Store requirements

### 2. App Label
**Current**: `onecharge_d`
**Issue**: Not user-friendly
**Action Required**: Change to a proper app name like:
- `OneCharge Driver`
- `OneCharge - Driver App`

### 3. Default Passwords
**Current**: `android123`
**Issue**: Weak password for production
**Action Required**: Change passwords in `android/key.properties` before publishing

## 📋 Pre-Upload Checklist

Before uploading to Play Store, ensure:

- [x] Change application ID from `com.example.onecharge_d` to your final package name (✅ Updated to `com.onecharge.driver`)
- [ ] Update app label to a user-friendly name
- [ ] Change keystore passwords from default `android123`
- [ ] Test release build: `flutter build appbundle --release`
- [ ] Verify app works correctly in release mode
- [ ] Update app icon (if needed)
- [ ] Prepare app screenshots for Play Store
- [ ] Write app description
- [ ] Set up privacy policy URL (required for Play Store)
- [ ] Configure app content rating

## 🚀 Build Commands

### Build App Bundle (Recommended for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Build APK (Alternative)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

## 📝 Keystore Information

**SHA-1 Fingerprint**: `CD:C5:11:29:A1:19:49:38:26:E0:9B:16:1C:51:AE:38:8C:D7:74:12`

**SHA-256 Fingerprint**: `B5:CF:93:28:BF:1C:EA:88:7D:8F:A1:9D:22:19:62:8B:00:35:E0:2B:B5:A2:E5:7B:0C:98:6E:38:9C:A3:A3:C8`

**Valid Until**: September 28, 2299

## 🔒 Security Reminders

1. **NEVER** commit `upload-keystore.jks` to version control
2. **NEVER** commit `key.properties` to version control
3. **BACKUP** your keystore file in a secure location
4. **KEEP** passwords safe - you'll need them for all future updates
5. **CHANGE** default passwords before production use

## ✅ Current Status

**Signing Configuration**: ✅ READY
**Keystore**: ✅ VALID
**Build Setup**: ✅ CONFIGURED

**Next Steps**: Fix Application ID and App Label, then you're ready to build and upload!



