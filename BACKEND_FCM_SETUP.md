# 🔔 FCM Push Notification — PHP Backend Setup

> When a ticket is **offered** to a driver, send a **push notification** via Firebase Cloud Messaging (FCM).  
> The driver will see the notification even if the app is **closed or killed**.

---

## Step 1: Database — Add FCM Token Column

Run this migration on your `drivers` table:

```sql
ALTER TABLE drivers ADD COLUMN fcm_token VARCHAR(500) NULL;
ALTER TABLE drivers ADD COLUMN device_type VARCHAR(10) DEFAULT 'android';
```

Or create a Laravel migration:

```bash
php artisan make:migration add_fcm_token_to_drivers_table
```

```php
public function up()
{
    Schema::table('drivers', function (Blueprint $table) {
        $table->string('fcm_token', 500)->nullable();
        $table->string('device_type', 10)->default('android');
    });
}
```

---

## Step 2: API Route — Save FCM Token

In `routes/api.php`:

```php
Route::middleware('auth:driver')->group(function () {
    // ... your existing routes ...
    Route::post('/driver/fcm-token', [DriverController::class, 'saveFcmToken']);
});
```

---

## Step 3: Controller — Save FCM Token

In `DriverController.php`:

```php
public function saveFcmToken(Request $request)
{
    $request->validate([
        'fcm_token'   => 'required|string',
        'device_type' => 'nullable|string|in:android,ios',
    ]);

    $driver = $request->user();
    $driver->fcm_token   = $request->fcm_token;
    $driver->device_type = $request->device_type ?? 'android';
    $driver->save();

    return response()->json([
        'success' => true,
        'message' => 'FCM token saved successfully',
    ]);
}
```

---

## Step 4: Firebase Service Account Key

1. Go to **Firebase Console** → **Project Settings** → **Service accounts**
2. Click **"Generate new private key"**
3. Download the JSON file
4. Save it in your Laravel project:

```
storage/app/firebase/service-account.json
```

5. Add to `.env`:

```env
FIREBASE_CREDENTIALS=storage/app/firebase/service-account.json
```

---

## Step 5: Install Google Auth Library

```bash
composer require google/auth
```

---

## Step 6: Create FCM Service

Create file: `app/Services/FcmService.php`

```php
<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    private string $projectId;
    private string $credentialsPath;

    public function __construct()
    {
        $this->credentialsPath = base_path(env('FIREBASE_CREDENTIALS'));
        $credentials = json_decode(file_get_contents($this->credentialsPath), true);
        $this->projectId = $credentials['project_id'];
    }

    /**
     * Get OAuth2 access token for FCM HTTP v1 API
     */
    private function getAccessToken(): string
    {
        $credentials = new ServiceAccountCredentials(
            'https://www.googleapis.com/auth/firebase.messaging',
            json_decode(file_get_contents($this->credentialsPath), true)
        );

        $token = $credentials->fetchAuthToken();
        return $token['access_token'];
    }

    /**
     * Send push notification to a specific driver device
     */
    public function sendNotification(
        string $fcmToken,
        string $title,
        string $body,
        array $data = []
    ): bool {
        try {
            $accessToken = $this->getAccessToken();

            $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

            $message = [
                'message' => [
                    'token' => $fcmToken,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'data' => array_map('strval', $data),
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'channel_id'              => 'ticket_alerts',
                            'sound'                   => 'default',
                            'default_vibrate_timings'  => true,
                        ],
                    ],
                    'apns' => [
                        'payload' => [
                            'aps' => [
                                'alert' => [
                                    'title' => $title,
                                    'body'  => $body,
                                ],
                                'sound'            => 'default',
                                'badge'            => 1,
                                'content-available' => 1,
                            ],
                        ],
                    ],
                ],
            ];

            $response = Http::withToken($accessToken)->post($url, $message);

            if ($response->successful()) {
                Log::info('FCM sent', ['title' => $title]);
                return true;
            } else {
                Log::error('FCM failed', [
                    'status' => $response->status(),
                    'body'   => $response->body(),
                ]);
                return false;
            }
        } catch (\Exception $e) {
            Log::error('FCM error: ' . $e->getMessage());
            return false;
        }
    }
}
```

---

## Step 7: Send Notification When Ticket Is Offered

In the place where you **assign/offer a ticket to a driver** (Controller, Job, or Event), add this **after** the Reverb socket broadcast:

```php
use App\Services\FcmService;
use App\Models\Driver;

// ---- Your existing Reverb broadcast code ----
// broadcast(new TicketOffered($ticket, $driver))->toOthers();

// ---- NEW: Send FCM Push Notification ----
$driver = Driver::find($driverId);

if ($driver && $driver->fcm_token) {
    $fcm = new FcmService();
    $fcm->sendNotification(
        $driver->fcm_token,
        '🎫 New Ticket Offered!',
        'A new service ticket has been assigned to you. Tap to view details.',
        [
            'type'              => 'ticket_offered',
            'ticket_id'         => (string) $ticket->id,
            'ticket_reference'  => $ticket->ticket_reference ?? '',
            'status'            => 'offered',
            'customer_name'     => $ticket->customer->name ?? 'Customer',
            'location'          => $ticket->location ?? '',
        ]
    );
}
```

---

## Complete Flow

```
Admin assigns ticket to driver
         │
         ├──► Reverb Socket (existing)
         │      → Works when app is OPEN (foreground)
         │
         └──► FCM Push (NEW - Step 7 above)
                → Works when app is in BACKGROUND
                → Works when app is KILLED / NOT RUNNING
                → Shows system notification with sound + vibration
                → Driver taps notification → App opens → Tickets load
```

---

## Optional: Send FCM for Other Events

### Ticket Cancelled

```php
if ($driver && $driver->fcm_token) {
    $fcm = new FcmService();
    $fcm->sendNotification(
        $driver->fcm_token,
        'Ticket Cancelled',
        "Ticket #{$ticket->ticket_reference} has been cancelled.",
        [
            'type'      => 'ticket_cancelled',
            'ticket_id' => (string) $ticket->id,
        ]
    );
}
```

### Ticket Status Changed

```php
if ($driver && $driver->fcm_token) {
    $fcm = new FcmService();
    $fcm->sendNotification(
        $driver->fcm_token,
        'Ticket Updated',
        "Ticket #{$ticket->ticket_reference} status: {$ticket->status}",
        [
            'type'      => 'ticket_status_changed',
            'ticket_id' => (string) $ticket->id,
            'status'    => $ticket->status,
        ]
    );
}
```

---

## Checklist

- [ ] Database migration ran (`fcm_token` column added)
- [ ] API route `POST /api/driver/fcm-token` added
- [ ] Controller method `saveFcmToken()` added
- [ ] Firebase service account JSON downloaded and saved
- [ ] `.env` updated with `FIREBASE_CREDENTIALS` path
- [ ] `composer require google/auth` installed
- [ ] `app/Services/FcmService.php` created
- [ ] FCM send code added where ticket is offered to driver
