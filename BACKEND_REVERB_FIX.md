# 🛠️ Backend Fix Guide: WebSocket Authorization Hang

## ❓ What is the Issue? (The "Why")
The Mobile App is working correctly, but it is stuck in a "Waiting" state (Orange dot). Here is exactly what is happening:

1.  **WebSocket Connection (SUCCESS)**: The app successfully connects to the Reverb server at `one-charge-1-charge.up.railway.app`. 
2.  **Auth Request (SENT)**: The app sends an authorization request to your Laravel API: `/api/driver/broadcasting/auth`.
3.  **The "Hidden" Step (FAILING/HANGING)**: When your Laravel API receives that request, it tries to talk to the Reverb server **internally** to verify the `socket_id`.
4.  **The Result**: Because your Laravel server cannot reach the Reverb host internally (likely due to a firewall or wrong `.env` settings), the request **hangs forever**. It doesn't throw an error; it just stays silent until the mobile app gives up after 20-30 seconds.

**Conclusion**: This is a **Server-to-Server communication error**. The PHP server cannot "see" the Reverb server.

---

## 🔴 The Problem Summary
The mobile application successfully connects to the Reverb WebSocket server, but it **hangs (timeouts)** when calling the authorization endpoint:
`POST: https://app.onecharge.io/api/driver/broadcasting/auth`

Because the server never responds to this request, the driver cannot subscribe to the `private-driver.{id}.tickets` channel, and real-time updates fail.

---

## 🔍 Root Cause Analysis
In a Laravel Reverb setup, when a client requests authorization, the **Laravel PHP server** must communicate with the **Reverb Server** via an internal API call to verify the `socket_id`.

If the PHP server cannot reach the Reverb server (due to firewall, wrong host, or SSL loop), the request will **hang indefinitely** until the client times out.

---

## ✅ Step-by-Step Fix (For Backend Developer)

### 1. Update Internal `.env` Configuration
Ensure the PHP server is talking to Reverb using an **internal/local** address rather than the public URL.

```env
# SERVER-SIDE .env
BROADCAST_DRIVER=reverb

# Configuration for INTERNAL communication
REVERB_HOST="127.0.0.1"  # Or the internal service name if using Docker/Railway
REVERB_PORT=8080        # The internal port Reverb is listening on
REVERB_SCHEME="http"    # Use http internally to avoid SSL verification loops
REVERB_APP_KEY="5csvb4sew88zqnmcxuqg"
```

### 2. Verify `routes/channels.php`
Check the authorization logic for the driver channel. Ensure there are no infinite loops or slow database blocks.

```php
// routes/channels.php
Broadcast::channel('driver.{id}.tickets', function ($user, $id) {
    // 💡 TEST: Change to 'return true;' temporarily to see if the hang persists.
    return (int) $user->id === (int) $id;
});
```

### 3. Test Connectivity via Termnial
Run this command from the **same machine/platform** where the PHP code is running:

```bash
# Verify the PHP server can reach the Reverb API internally
curl -v http://127.0.0.1:8080/app/5csvb4sew88zqnmcxuqg
```
*   **Success**: Returns a JSON object with app details.
*   **Failure**: The request times out or says "Connection Refused". This means your firewall or `REVERB_HOST` is wrong.

### 4. Apply Changes
After updating the `.env`, you **MUST** run these commands:

```bash
php artisan config:clear
php artisan cache:clear
php artisan reverb:restart
```

---

## 📱 Mobile App Details for Verification
*   **Reverb Server**: `one-charge-1-charge.up.railway.app`
*   **App Key**: `5csvb4sew88zqnmcxuqg`
*   **Channel Pattern**: `private-driver.{driver_id}.tickets`
*   **Events to Broadcast**: `ticket.offered`, `ticket.updated`, `ticket.cancelled`
