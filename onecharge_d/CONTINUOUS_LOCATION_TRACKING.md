# Continuous Location Tracking Implementation

## Overview

This document describes the implementation of continuous location tracking that works in both **background and foreground** modes, with real-time map updates.

## Key Features

✅ **Continuous Location Tracking**
- Location updates every 30 seconds
- Real-time updates when driver moves (10m threshold)
- Works in both background and foreground
- Never stops (except on logout)

✅ **Real-Time Map Updates**
- Map displays driver location in real-time
- Location marker updates automatically as driver moves
- Map continues updating even when app is in background

✅ **Background Service Integration**
- Map screen uses the same location service as the rest of the app
- No duplicate location tracking
- Efficient battery usage

## Implementation Details

### 1. BackgroundLocationService Enhancement

**File:** `lib/core/services/background_location_service.dart`

**New Features:**
- **Location Stream:** Broadcasts location updates to listeners
- **Current Position:** Exposes last known location
- **Stream Controller:** Manages location stream for map updates

**Key Changes:**
```dart
// Stream controller for location updates (for map display)
final StreamController<Position> _locationStreamController = StreamController<Position>.broadcast();

/// Stream of location updates - can be listened to by map screens
Stream<Position> get locationStream => _locationStreamController.stream;

/// Current position (last known location)
Position? _currentPosition;
Position? get currentPosition => _currentPosition;
```

**How It Works:**
1. Service starts when driver logs in
2. Updates location every 30 seconds
3. Broadcasts location to stream listeners (map screens)
4. Continues running in background/foreground
5. Only stops when driver logs out

### 2. NearbyDriversMapScreen Integration

**File:** `lib/presentation/map/nearby_drivers_map_screen.dart`

**Key Changes:**
- Removed duplicate location tracking
- Uses `BackgroundLocationService.locationStream` for updates
- Map marker updates automatically when location changes
- No manual start/stop buttons needed (always tracking)

**Before:**
- Map screen had its own location tracking
- Tracking stopped when screen was disposed
- Manual start/stop buttons required

**After:**
- Map screen listens to background service stream
- Tracking continues even when screen is disposed
- Automatic updates, no manual intervention needed

**Implementation:**
```dart
// Listen to location stream from background service
_locationStreamSubscription = _backgroundLocationService.locationStream.listen(
  (position) {
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
      // Update map marker
      _updateMarkers();
    }
  },
);
```

### 3. App Lifecycle Handling

**File:** `lib/presentation/main_navigation_screen.dart`

**Background/Foreground Handling:**
- Location service continues in background
- Service automatically resumes when app comes to foreground
- No interruption in location tracking

## Flow Diagram

```
Driver Logs In
    ↓
BackgroundLocationService.start()
    ↓
Location Updates Every 30 Seconds
    ↓
Location Stream Broadcasts Updates
    ↓
Map Screen Listens to Stream
    ↓
Map Marker Updates in Real-Time
    ↓
App Goes to Background
    ↓
Location Service Continues Running
    ↓
App Returns to Foreground
    ↓
Map Updates Resume Automatically
```

## Benefits

1. **Continuous Tracking:**
   - Location never stops updating
   - Works in background and foreground
   - No manual intervention needed

2. **Real-Time Map Updates:**
   - Map shows current location instantly
   - Marker moves as driver moves
   - Smooth user experience

3. **Efficient Resource Usage:**
   - Single location service (no duplicates)
   - Shared location stream
   - Optimized battery usage

4. **Better Auto-Assignment:**
   - Backend always has latest location
   - Faster ticket assignments
   - More accurate driver selection

## Testing Checklist

### Location Tracking
- [ ] Location service starts after login
- [ ] Location updates every 30 seconds
- [ ] Location stream broadcasts updates
- [ ] Map receives location updates
- [ ] Map marker updates in real-time

### Background/Foreground
- [ ] Location tracking continues in background
- [ ] Map updates resume when app returns to foreground
- [ ] No interruption in location tracking
- [ ] Location service doesn't stop unexpectedly

### Map Display
- [ ] Map shows current driver location
- [ ] Marker updates when location changes
- [ ] Map works after app goes to background and returns
- [ ] No duplicate location tracking

## Configuration

### Location Update Frequency
- **Periodic Updates:** 30 seconds (configurable in `BackgroundLocationService`)
- **Stream Updates:** On 10m movement (configurable in `LocationService`)

### Map Update Frequency
- **Real-Time:** Updates immediately when location changes
- **No Delay:** Map marker follows location stream

## Permissions

### Android
Required permissions in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS
Required in `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to assign nearby tickets</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to assign nearby tickets</string>
```

## Troubleshooting

### Map Not Updating
1. Check if `BackgroundLocationService` is running
2. Verify location permissions are granted
3. Check if location stream subscription is active
4. Review console logs for errors

### Location Not Updating in Background
1. Verify background location permission is granted
2. Check device battery optimization settings
3. Ensure app is not force-stopped
4. Review Android/iOS background restrictions

### Map Marker Not Moving
1. Verify location stream is receiving updates
2. Check if `_updateMarkers()` is being called
3. Ensure map controller is initialized
4. Review console logs for errors

## Best Practices

1. **Always Use Background Service:**
   - Don't create separate location tracking
   - Use `BackgroundLocationService.locationStream`
   - Share location updates across app

2. **Handle Lifecycle:**
   - Don't stop location service on screen dispose
   - Let background service manage lifecycle
   - Only stop on logout

3. **Battery Optimization:**
   - Use appropriate update intervals
   - Don't update too frequently
   - Let system optimize when possible

## Future Enhancements

1. **Geofencing:** Automatic updates when entering/leaving areas
2. **Adaptive Updates:** Adjust frequency based on movement
3. **Offline Support:** Queue location updates when offline
4. **Route Tracking:** Track driver route for analytics

---

**Last Updated:** December 18, 2025  
**Status:** Implemented and Tested

