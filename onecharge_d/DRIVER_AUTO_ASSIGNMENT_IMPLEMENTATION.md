# Driver Auto-Assignment & Live Location Implementation

This document describes the implementation of driver auto-assignment and live location tracking features in the Onecharge Driver app.

## Overview

The implementation ensures that:
1. **Driver location is continuously tracked** and updated to the server every 30 seconds
2. **Tickets are automatically assigned** to drivers based on proximity and experience
3. **New tickets are detected in real-time** through periodic polling
4. **Location updates continue in background** when the app is minimized

## Implementation Details

### 1. Background Location Service

**File:** `lib/core/services/background_location_service.dart`

This service runs continuously when the driver is logged in and has selected a vehicle. It:
- Updates driver location every 30 seconds (as per API documentation)
- Uses location stream for real-time updates when driver is moving (10m threshold)
- Automatically stops when driver logs out
- Handles permission requests and errors gracefully

**Key Features:**
- Singleton pattern for single instance across the app
- Automatic permission handling
- Periodic updates (30 seconds) + stream updates (on movement)
- Automatic cleanup on logout

### 2. Ticket Polling Service

**File:** `lib/core/services/ticket_polling_service.dart`

This service periodically fetches tickets to detect auto-assigned tickets:
- Polls every 15 seconds to catch new assignments quickly
- Detects new tickets by comparing ticket counts
- Automatically updates the UI when new tickets are found
- Stops when driver logs out

**Key Features:**
- Detects new auto-assigned tickets
- Updates TicketBloc to refresh UI
- Automatic cleanup on logout

### 3. Integration Points

#### Main Navigation Screen
**File:** `lib/presentation/main_navigation_screen.dart`

- Starts both services when the screen is initialized (after login)
- Handles app lifecycle (resumed/paused) to ensure services continue running
- Services are started automatically when driver navigates to main screen

#### Home Screen (Vehicle Selection)
**File:** `lib/presentation/home/home_screen.dart`

- Starts location service after successful vehicle selection
- This ensures location tracking begins as soon as driver is ready to receive tickets

#### Profile Screen (Logout)
**File:** `lib/presentation/profile/bloc/profile_bloc.dart`

- Stops both services when driver logs out
- Ensures no location updates are sent after logout

## Flow Diagram

```
Driver Login
    ↓
MainNavigationScreen loads
    ↓
BackgroundLocationService.start()
TicketPollingService.start()
    ↓
Driver selects vehicle
    ↓
LocationService.start() (if not already running)
    ↓
Location updates every 30 seconds
Ticket polling every 15 seconds
    ↓
Customer creates ticket → Auto-assigned to driver
    ↓
TicketPollingService detects new ticket
    ↓
UI updates with new ticket
    ↓
Driver logs out
    ↓
Both services stop
```

## API Integration

### Location Update Endpoint
- **Endpoint:** `POST /api/driver/location/update`
- **Frequency:** Every 30 seconds
- **Payload:** `{ "latitude": double, "longitude": double }`
- **Response:** Confirms location update

### Ticket Fetching Endpoint
- **Endpoint:** `GET /api/driver/tickets`
- **Frequency:** Every 15 seconds
- **Response:** List of assigned tickets

## Auto-Assignment Logic (Backend)

The backend automatically assigns tickets to drivers based on:
1. **Distance** - Nearest driver within 50km radius
2. **Experience** - Driver with more completed tickets
3. **Availability** - Driver must have:
   - Location updated in last 10 minutes
   - Vehicle selected (`is_active = false`)
   - **NO active tickets** (0 active tickets) - **One task per driver policy**

### One Task Per Driver Policy

**Important:** Each driver can only have **ONE active task** at a time. This ensures:
- Better focus and service quality
- Fair distribution of work among drivers
- Faster response times for customers

**Active Task Statuses:**
- `assigned` - Ticket assigned but work not started
- `in_progress` - Driver has started work on the ticket

**When a driver has one active task:**
- They will **NOT** receive new ticket assignments
- The next ticket will be automatically assigned to the next available driver
- Assignment is based on location proximity and driver experience
- Once the current task is completed, the driver becomes available for new assignments

## Testing Checklist

### Location Tracking
- [ ] Location service starts after login
- [ ] Location updates every 30 seconds
- [ ] Location updates continue in background
- [ ] Location service stops on logout
- [ ] Location permission is requested properly

### Ticket Auto-Assignment
- [ ] Ticket polling starts after login
- [ ] New tickets are detected within 15 seconds
- [ ] UI updates when new ticket is assigned
- [ ] Ticket polling stops on logout

### Integration
- [ ] Services start automatically after login
- [ ] Services start after vehicle selection
- [ ] Services stop on logout
- [ ] App lifecycle (background/foreground) handled correctly

## Configuration

### Update Intervals
- **Location Update:** 30 seconds (configurable in `BackgroundLocationService`)
- **Ticket Polling:** 15 seconds (configurable in `TicketPollingService`)
- **Location Stream:** Updates on 10m movement (configurable in `LocationService`)

### Permissions Required

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

#### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to assign nearby tickets</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to assign nearby tickets</string>
```

## Troubleshooting

### Location Not Updating
1. Check location permissions are granted
2. Verify GPS is enabled on device
3. Check network connectivity
4. Review logs for error messages

### Tickets Not Appearing
1. Verify ticket polling service is running
2. Check driver has selected a vehicle
3. Verify driver location is being updated
4. Check backend logs for assignment logic

### Services Not Starting
1. Verify driver is logged in
2. Check token is valid
3. Review initialization logs
4. Ensure app has necessary permissions

## Best Practices

1. **Battery Optimization:** Location updates are throttled to 30 seconds to balance accuracy and battery life
2. **Network Efficiency:** Failed location updates are logged but don't stop the service
3. **Error Handling:** Services gracefully handle errors and continue running
4. **Resource Cleanup:** Services are properly stopped on logout to prevent resource leaks

## Future Enhancements

1. **Push Notifications:** Replace polling with push notifications for instant ticket assignment
2. **WebSocket Integration:** Real-time ticket updates via WebSocket
3. **Geofencing:** Automatic location updates when entering/leaving specific areas
4. **Adaptive Polling:** Adjust polling frequency based on network conditions

## Support

For issues or questions:
- Check console logs for detailed error messages
- Review API documentation for endpoint details
- Verify backend auto-assignment logic is working correctly

