# 🔴 Real-Time Ticket Broadcasting — Backend Developer Guide

> **Status**: Flutter app WebSocket is ✅ fully connected and subscribed.  
> **Blocker**: Backend is NOT broadcasting the Reverb event when a ticket is offered.

---

## 🚨 The One Thing Missing Right Now

When the admin assigns a ticket to a driver, the Laravel controller saves the ticket to the database and returns `"Ticket offered to driver"` — but it **never calls `event(...)`** to broadcast it over Reverb.

**Fix: Add this one line to the offer-ticket controller:**

```php
// After saving the assignment to database, add:
event(new \App\Events\TicketOffered($ticket->toArray(), $ticket->driver_id));
```

---

## ✅ Step 1: Check `.env` on Railway

```env
BROADCAST_DRIVER=reverb

REVERB_APP_ID=your-app-id
REVERB_APP_KEY=5csvb4sew88zqnmcxuqg     ← Must match mobile app exactly
REVERB_APP_SECRET=your-secret-key
REVERB_HOST=one-charge-1-charge.up.railway.app
REVERB_PORT=443
REVERB_SCHEME=https
```

After changing `.env`, always run:
```bash
php artisan config:clear
php artisan cache:clear
```

---

## ✅ Step 2: Enable Broadcasting in `config/app.php`

Make sure `BroadcastServiceProvider` is **not** commented out:

```php
// config/app.php → 'providers' array
App\Providers\BroadcastServiceProvider::class,
```

---

## ✅ Step 3: Add Channel Authorization in `routes/channels.php`

```php
use Illuminate\Support\Facades\Broadcast;

// Authorizes: private-driver.{driverId}.tickets
Broadcast::channel('driver.{driverId}.tickets', function ($user, $driverId) {
    return (int) $user->id === (int) $driverId;
});
```

> The mobile app subscribes to `private-driver.12.tickets`.  
> Laravel maps this to `driver.12.tickets` in `channels.php` (it strips the `private-` prefix automatically).

---

## ✅ Step 4: Broadcasting Auth Route in `routes/api.php`

```php
use Illuminate\Support\Facades\Broadcast;

Route::middleware('auth:sanctum')->post('/driver/broadcasting/auth', function () {
    return Broadcast::auth(request());
});
```

---

## ✅ Step 5: Create the Event Classes

### Run artisan to create:
```bash
php artisan make:event TicketOffered
php artisan make:event TicketUpdated
php artisan make:event TicketCancelled
```

### `TicketOffered.php` (complete code):

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class TicketOffered implements ShouldBroadcastNow  // ← ShouldBroadcastNow (not ShouldBroadcast)
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public array $ticket,
        public int $driverId
    ) {}

    // Channel: private-driver.{id}.tickets
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('driver.' . $this->driverId . '.tickets'),
        ];
    }

    // Event name the mobile app listens for: App\Events\TicketOffered
    public function broadcastAs(): string
    {
        return 'TicketOffered';
    }

    // Data sent to the mobile app
    public function broadcastWith(): array
    {
        return ['ticket' => $this->ticket];
    }
}
```

> ⚠️ Use **`ShouldBroadcastNow`** (not `ShouldBroadcast`).  
> `ShouldBroadcast` queues the event — if the queue worker is not running, it will never be sent.  
> `ShouldBroadcastNow` sends it **instantly** without needing a queue.

### `TicketUpdated.php` and `TicketCancelled.php` — same structure, change class name and `broadcastAs()` string.

---

## ✅ Step 6: Fire the Event From the Controller

Find the controller that handles **"Offer Ticket to Driver"** (the endpoint the admin panel calls) and add the event:

```php
use App\Events\TicketOffered;

public function offerTicket(Request $request, Ticket $ticket)
{
    // --- Your existing code here ---
    $ticket->driver_id = $request->driver_id;
    $ticket->status = 'offered';
    $ticket->save();
    // --------------------------------

    // 🔴 ADD THIS LINE — broadcasts to driver's mobile app in real-time
    event(new TicketOffered($ticket->toArray(), $ticket->driver_id));

    return response()->json(['message' => 'Ticket offered to driver.']);
}
```

---

## 🧪 Step 7: Test Without the Admin Panel (Tinker)

While the **driver app is open and subscribed**, run this on the Railway server:

```bash
php artisan tinker
```

```php
// Send a fake ticket to Driver ID 12 (Ajay)
event(new \App\Events\TicketOffered(
    ticket: [
        'id'        => 999,
        'ticket_id' => 'TKT-TEST-001',
        'status'    => 'offered',
        'location'  => 'Downtown Dubai',
        'customer'  => ['name' => 'Test Customer', 'phone' => '+971500000000'],
    ],
    driverId: 12
));
```

✅ **Expected result**: The Flutter app logs show `📨 INCOMING EVENT` and the ticket appears on screen in real time.

---

## 📱 What the Mobile App Listens For

The mobile app (`ReverbService.dart`) listens for these event names:

| Backend Event Class | Mobile Listener Method |
|---|---|
| `App\Events\TicketOffered` | `bindTicketOffered(callback)` |
| `App\Events\TicketUpdated` | `bindTicketUpdated(callback)` |
| `App\Events\TicketCancelled` | `bindTicketCancelled(callback)` |

The **channel** the mobile app is subscribed to: `private-driver.{driverId}.tickets`  
The **channel** to broadcast to in Laravel: `new PrivateChannel('driver.' . $driverId . '.tickets')`

---

## 🔍 Troubleshooting

| Problem | Solution |
|---|---|
| App subscribes but no events arrive | The controller is not calling `event(new TicketOffered(...))` |
| Auth returns 403 | `routes/channels.php` callback is returning `false` |
| Auth returns 500 | `BroadcastServiceProvider` is not registered in `app.php` |
| Event is delayed by minutes | You used `ShouldBroadcast` — change to `ShouldBroadcastNow` |
| Config changes not working | Run `php artisan config:clear && php artisan cache:clear` |
| Tinker works but admin panel doesn't | The controller is not calling `event(...)` after saving |

---

*Onecharge Driver App — WebSocket Integration Guide | February 2026*
