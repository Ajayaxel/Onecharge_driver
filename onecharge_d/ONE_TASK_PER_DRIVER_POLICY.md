# One Task Per Driver Policy - Implementation Guide

## Overview

This document describes the **One Task Per Driver** policy implementation for the 1Charge Driver application. This policy ensures that each driver can only have **ONE active task** at a time, promoting better service quality and fair work distribution.

## Policy Rules

### Active Task Definition

An **active task** is a ticket with one of the following statuses:
- `assigned` - Ticket has been assigned to driver but work has not started
- `in_progress` - Driver has started work on the ticket

### Policy Enforcement

1. **Driver Availability Check:**
   - A driver is considered **available** for new assignments only when they have **0 active tasks**
   - If a driver has 1 active task (assigned or in_progress), they are **NOT available** for new assignments

2. **Auto-Assignment Logic:**
   - When a customer creates a ticket, the system finds available drivers (0 active tasks)
   - Among available drivers, the system selects based on:
     - **Distance** - Nearest driver within 50km radius
     - **Experience** - Driver with more completed tickets
   - If the nearest driver has 1 active task, the system automatically assigns to the next available driver

3. **Task Completion:**
   - Once a driver completes their active task (status changes to `completed`), they immediately become available for new assignments
   - The system will automatically assign the next pending ticket to this driver if they are the nearest available driver

## Backend Implementation Requirements

### Database Query for Available Drivers

When assigning a new ticket, the backend should query drivers with:

```sql
SELECT * FROM drivers 
WHERE 
  -- Location updated in last 10 minutes
  last_location_updated_at >= NOW() - INTERVAL 10 MINUTE
  -- Vehicle selected (is_active = false means vehicle is selected)
  AND EXISTS (
    SELECT 1 FROM driver_vehicles 
    WHERE driver_id = drivers.id 
    AND is_active = false
  )
  -- NO active tickets (0 active tickets)
  AND (
    SELECT COUNT(*) FROM tickets 
    WHERE driver_id = drivers.id 
    AND status IN ('assigned', 'in_progress')
  ) = 0
  -- Within 50km radius of ticket location
  AND (
    6371 * acos(
      cos(radians(ticket_latitude)) * 
      cos(radians(drivers.latitude)) * 
      cos(radians(drivers.longitude) - radians(ticket_longitude)) + 
      sin(radians(ticket_latitude)) * 
      sin(radians(drivers.latitude))
    )
  ) <= 50
ORDER BY 
  -- Order by distance (nearest first)
  (
    6371 * acos(
      cos(radians(ticket_latitude)) * 
      cos(radians(drivers.latitude)) * 
      cos(radians(drivers.longitude) - radians(ticket_longitude)) + 
      sin(radians(ticket_latitude)) * 
      sin(radians(drivers.latitude))
    )
  ) ASC,
  -- Then by experience (more completed tickets first)
  (
    SELECT COUNT(*) FROM tickets 
    WHERE driver_id = drivers.id 
    AND status = 'completed'
  ) DESC
LIMIT 1;
```

### Key Changes from Previous Implementation

**Previous Logic:**
- Drivers with **less than 5 active tickets** were considered available

**New Logic:**
- Drivers with **0 active tickets** are considered available
- This ensures **one task per driver** policy

### API Endpoint Behavior

#### POST /api/customer/tickets

When a customer creates a ticket:

1. **Check for available drivers:**
   - Query drivers with 0 active tasks
   - Filter by location (50km radius)
   - Sort by distance and experience

2. **Assign ticket:**
   - If available driver found → Assign ticket (status: `assigned`)
   - If no available driver → Leave ticket unassigned (status: `pending`)

3. **Response:**
   ```json
   {
     "success": true,
     "message": "Ticket created successfully.",
     "data": {
       "ticket": {
         "id": 1,
         "ticket_id": "TKT-2025-001",
         "status": "assigned",  // or "pending" if no driver available
         "driver": {
           "id": 5,
           "name": "Driver Name",
           "latitude": 40.7580,
           "longitude": -73.9855
         }
       }
     }
   }
   ```

## Mobile App Implementation

### UI Indicators

The mobile app displays a status indicator when a driver has reached their task limit:

**Location:** `lib/presentation/home/home_screen.dart`

**Visual Indicator:**
- Orange/yellow banner appears when driver has 1 active task
- Message: "You have 1 active task. Complete it to receive new assignments."
- Banner disappears when active task is completed

### Helper Methods

The app includes helper methods to check driver availability:

```dart
/// Check if driver has an active task (assigned or in_progress)
bool _hasActiveTask(List<Ticket> tickets) {
  return tickets.any((ticket) => 
    ticket.status == 'assigned' || ticket.status == 'in_progress'
  );
}

/// Get count of active tasks
int _getActiveTaskCount(List<Ticket> tickets) {
  return tickets.where((ticket) => 
    ticket.status == 'assigned' || ticket.status == 'in_progress'
  ).length;
}
```

## Benefits of One Task Per Driver Policy

1. **Better Service Quality:**
   - Drivers can focus on one task at a time
   - Reduces errors and improves customer satisfaction

2. **Fair Work Distribution:**
   - Prevents drivers from hoarding multiple tasks
   - Ensures all drivers get equal opportunities

3. **Faster Response Times:**
   - Tasks are distributed among more drivers
   - Customers receive faster service

4. **Better Resource Management:**
   - Clear visibility of driver availability
   - Easier to track and manage workload

## Testing Checklist

### Backend Testing

- [ ] Driver with 0 active tasks receives new assignment
- [ ] Driver with 1 active task (assigned) does NOT receive new assignment
- [ ] Driver with 1 active task (in_progress) does NOT receive new assignment
- [ ] Driver becomes available after completing active task
- [ ] Next available driver receives assignment when nearest driver is busy
- [ ] Assignment prioritizes nearest available driver
- [ ] Assignment considers driver experience when distance is similar

### Mobile App Testing

- [ ] Status indicator appears when driver has 1 active task
- [ ] Status indicator shows correct active task count
- [ ] Status indicator disappears when task is completed
- [ ] Driver does not receive new assignments when they have 1 active task
- [ ] Driver receives new assignments after completing active task

## Migration Notes

If migrating from the previous "5 active tickets" policy:

1. **Update Backend Query:**
   - Change `COUNT(*) < 5` to `COUNT(*) = 0`
   - Update all assignment logic

2. **Update Documentation:**
   - Update API documentation
   - Update driver onboarding materials

3. **Notify Drivers:**
   - Inform drivers about the new policy
   - Explain benefits and expectations

4. **Monitor Performance:**
   - Track assignment distribution
   - Monitor customer satisfaction
   - Adjust if needed

## Support

For questions or issues:
- Review backend assignment logic
- Check driver availability queries
- Verify ticket status transitions
- Review mobile app status indicators

---

**Last Updated:** December 17, 2025  
**Policy Version:** 1.0  
**Status:** Active

