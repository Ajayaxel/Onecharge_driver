# Location Tracking Implementation Documentation

## Overview

This document describes the implementation of real-time location tracking for drivers in the Onecharge Driver app. The feature allows drivers to share their location and view nearby drivers on a Google Map.

## Features Implemented

### 1. Location Services
- ✅ Request location permissions (Android & iOS)
- ✅ Get current location with high accuracy
- ✅ Stream location updates
- ✅ Handle permission denials gracefully

### 2. API Integration
- ✅ Update driver location to server (`/api/driver/location/update`)
- ✅ Fetch nearby drivers (`/api/driver/location/nearby`)
- ✅ Automatic location updates every 15 seconds
- ✅ Automatic nearby drivers refresh every 30 seconds

### 3. Map Display
- ✅ Google Maps integration
- ✅ Display current driver location (blue marker)
- ✅ Display nearby drivers (red markers)
- ✅ Interactive map controls
- ✅ "My Location" button to center map
- ✅ Start/Stop tracking controls
- ✅ Manual refresh button

### 4. User Experience
- ✅ Loading states
- ✅ Error handling and display
- ✅ Permission request flow
- ✅ Real-time location updates
- ✅ Automatic map updates

---

## API Endpoints

### 1. Update Driver Location

**Endpoint:** `POST /api/driver/location/update`

**Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060
}
```

**Success Response (200/201):**
```json
{
  "success": true,
  "message": "Location updated successfully.",
  "data": {
    "driver": {
      "id": 3,
      "latitude": 40.7128,
      "longitude": -74.0060,
      "last_location_updated_at": "2025-12-17T05:28:49+00:00"
    }
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error message here"
}
```

---

### 2. Get Nearby Drivers

**Endpoint:** `GET /api/driver/location/nearby?radius={radius}`

**Headers:**
```
Accept: application/json
Authorization: Bearer {token}
```

**Query Parameters:**
- `radius` (optional): Radius in kilometers (default: 10.0)

**Success Response (200):**
```json
{
  "success": true,
  "message": "Nearby drivers retrieved successfully.",
  "data": {
    "nearby_drivers": [
      {
        "id": 1,
        "name": "Driver Name",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "last_location_updated_at": "2025-12-17T05:28:49+00:00"
      }
    ]
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error message here",
  "data": {
    "nearby_drivers": []
  }
}
```

---

## File Structure

### Models
- `lib/core/models/location_update_response.dart` - Response model for location update API
- `lib/core/models/nearby_drivers_response.dart` - Response model for nearby drivers API

### Repository
- `lib/core/repository/location_repository.dart` - Handles all location-related API calls

### Services
- `lib/core/utils/location_service.dart` - Handles location permissions and GPS operations

### UI
- `lib/presentation/map/nearby_drivers_map_screen.dart` - Main map screen with Google Maps integration

### Configuration
- `lib/core/config/api_config.dart` - API endpoints configuration

---

## Implementation Details

### Location Service (`LocationService`)

**Methods:**
- `requestLocationPermission()` - Requests location permissions from user
- `getCurrentLocation()` - Gets current GPS position
- `getLocationStream()` - Streams location updates (for future use)

**Usage:**
```dart
final locationService = LocationService();

// Request permission
final hasPermission = await locationService.requestLocationPermission();

// Get current location
final position = await locationService.getCurrentLocation();
```

---

### Location Repository (`LocationRepository`)

**Methods:**
- `updateLocation({required double latitude, required double longitude})` - Updates driver location on server
- `getNearbyDrivers({double radius = 10.0})` - Fetches nearby drivers within radius

**Usage:**
```dart
final locationRepository = LocationRepository();

// Update location
final response = await locationRepository.updateLocation(
  latitude: 40.7128,
  longitude: -74.0060,
);

// Get nearby drivers
final nearbyResponse = await locationRepository.getNearbyDrivers(radius: 10.0);
```

---

### Map Screen (`NearbyDriversMapScreen`)

**Features:**
- Automatic location tracking (updates every 15 seconds)
- Automatic nearby drivers refresh (every 30 seconds)
- Manual refresh button
- Start/Stop tracking controls
- "My Location" button to center map
- Error handling and loading states

**State Management:**
- Uses `StatefulWidget` for local state management
- Manages timers for periodic updates
- Handles map controller lifecycle

**Location Updates:**
- Updates location to server every 15 seconds when tracking is active
- Fetches nearby drivers every 30 seconds when tracking is active
- Updates map markers when new data is received

---

## Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to show nearby drivers and update your location</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to your location to track your position and show nearby drivers</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location to track your position and show nearby drivers</string>
```

---

## Dependencies

### Added to `pubspec.yaml`:
```yaml
dependencies:
  geolocator: ^10.1.0  # Location services
  google_maps_flutter: ^2.5.0  # Map display (already existed)
```

---

## Usage Flow

1. **User clicks "See nearby drivers" button** on home screen
2. **App requests location permission** (if not already granted)
3. **App gets current location** using GPS
4. **App displays Google Map** with current location centered
5. **App starts tracking:**
   - Updates location to server every 15 seconds
   - Fetches nearby drivers every 30 seconds
6. **Map displays markers:**
   - Blue marker for current user location
   - Red markers for nearby drivers
7. **User can:**
   - Start/Stop tracking
   - Refresh nearby drivers manually
   - Center map on their location
   - View driver info by tapping markers

---

## API Configuration

The API base URL is configured in `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://onecharge.io';
  static const String locationUpdateEndpoint = '/api/driver/location/update';
  static const String nearbyDriversEndpoint = '/api/driver/location/nearby';
}
```

---

## Authentication

All API calls use Bearer token authentication. The token is retrieved from `TokenStorage`:

```dart
final token = await TokenStorage.getToken();
```

The token is automatically included in all API requests via the `Authorization` header.

---

## Error Handling

The implementation includes comprehensive error handling:

1. **Permission Denied:**
   - Shows error message
   - Provides retry button

2. **Location Unavailable:**
   - Shows error message
   - Provides retry button

3. **API Errors:**
   - Logs errors to console
   - Continues operation (doesn't crash app)
   - Shows user-friendly messages when appropriate

4. **Network Errors:**
   - Handles gracefully
   - Retries on next update cycle

---

## Testing Checklist

- [x] Location permissions requested and granted
- [x] Current location displayed on map
- [x] Location updates sent to API every 15 seconds
- [x] Nearby drivers fetched every 30 seconds
- [x] Nearby drivers displayed on map
- [x] Map updates when drivers move
- [x] Handles network errors gracefully
- [x] Stops tracking when screen is closed
- [x] Start/Stop tracking controls work
- [x] Manual refresh works
- [x] "My Location" button works

---

## Future Enhancements

Potential improvements for future versions:

1. **WebSocket Integration:**
   - Real-time location updates via WebSocket (Reverb/Pusher)
   - Instant updates when drivers move
   - No need for polling

2. **Background Location Tracking:**
   - Continue tracking when app is in background
   - Lower accuracy for battery optimization

3. **Route Display:**
   - Show routes between drivers
   - Navigation features

4. **Driver Details:**
   - Click marker to see driver details
   - Contact driver option

5. **Filters:**
   - Filter by distance
   - Filter by driver status
   - Filter by vehicle type

---

## Troubleshooting

### Location Not Updating
- Check location permissions are granted
- Verify GPS is enabled on device
- Check API response for errors
- Verify auth token is valid

### Map Not Showing
- Verify Google Maps API key is configured
- Check internet connection
- Verify location permissions

### Nearby Drivers Not Showing
- Check API response in logs
- Verify radius parameter
- Check if other drivers have updated their location
- Verify auth token is valid

### Permission Issues
- Android: Check `AndroidManifest.xml` has location permissions
- iOS: Check `Info.plist` has location usage descriptions
- Try uninstalling and reinstalling app

---

## Code Examples

### Basic Usage

```dart
// Navigate to map screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NearbyDriversMapScreen(),
  ),
);
```

### Update Location Manually

```dart
final locationService = LocationService();
final locationRepository = LocationRepository();

// Get current location
final position = await locationService.getCurrentLocation();
if (position != null) {
  // Update to server
  final response = await locationRepository.updateLocation(
    latitude: position.latitude,
    longitude: position.longitude,
  );
  
  if (response.success) {
    print('Location updated successfully');
  }
}
```

### Get Nearby Drivers Manually

```dart
final locationRepository = LocationRepository();

final response = await locationRepository.getNearbyDrivers(radius: 5.0);
if (response.success) {
  for (var driver in response.nearbyDrivers) {
    print('Driver ${driver.id}: ${driver.name}');
    print('Location: ${driver.latitude}, ${driver.longitude}');
  }
}
```

---

## Notes

- Location updates are sent every 15 seconds when tracking is active
- Nearby drivers are fetched every 30 seconds when tracking is active
- Tracking automatically stops when the screen is closed
- All API calls require authentication token
- The implementation follows the existing codebase patterns
- Error handling is comprehensive and user-friendly

---

## Version Information

- **Implementation Date:** December 2024
- **Flutter Version:** Compatible with SDK ^3.9.2
- **geolocator:** ^10.1.0
- **google_maps_flutter:** ^2.5.0

---

## Support

For issues or questions about this implementation, please refer to:
- API documentation
- Flutter geolocator package: https://pub.dev/packages/geolocator
- Google Maps Flutter package: https://pub.dev/packages/google_maps_flutter

