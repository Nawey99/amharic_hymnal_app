# Device Connection Fix Guide

## Issue: Device Shows as "Unauthorized" or "Offline"

### Quick Fix Steps

1. **On Your Phone:**
   - **Revoke all USB debugging authorizations:**
     - Go to **Settings** → **Developer options**
     - Tap **"Revoke USB debugging authorizations"**
     - Confirm the action
   
   - **Unplug and replug USB cable:**
     - Physically disconnect the USB cable
     - Wait 2-3 seconds
     - Reconnect the USB cable
   
   - **When prompted, authorize the computer:**
     - You'll see a popup: **"Allow USB debugging?"**
     - Check **"Always allow from this computer"**
     - Tap **"Allow"** or **"OK"**

2. **On Your Computer:**
   ```bash
   # Restart ADB
   adb kill-server
   adb start-server
   
   # Check device status
   adb devices
   ```

3. **Verify Connection:**
   ```bash
   flutter devices
   ```

### Expected Result

After authorizing, you should see:
```
List of devices attached
R5CT62VNMVK    device
```

And in `flutter devices`:
```
Found 1 connected device:
  SM S9080 (mobile) • R5CT62VNMVK • android-arm64 • Android 16 (API 36)
```

### If Still Not Working

1. **Check USB Mode:**
   - Ensure phone is in **"File Transfer"** or **"MTP"** mode
   - Not in **"Charge only"** mode

2. **Check USB Cable:**
   - Try a different USB cable (some are charge-only)
   - Try a different USB port

3. **Restart Everything:**
   - Restart your phone
   - Restart your computer
   - Restart ADB: `adb kill-server && adb start-server`

4. **Check USB Drivers:**
   - For Samsung: Install Samsung USB drivers
   - For other brands: Install manufacturer-specific USB drivers

### Alternative: Wireless Debugging (Android 11+)

If USB continues to be problematic:

1. Connect via USB first (one-time setup)
2. On phone: **Settings** → **Developer options** → **Wireless debugging**
3. Enable **Wireless debugging**
4. Tap **"Pair device with pairing code"**
5. On computer, run:
   ```bash
   adb pair <IP_ADDRESS>:<PORT>
   ```
   (Enter the pairing code when prompted)
6. After pairing, tap **"Wireless debugging"** again
7. Run:
   ```bash
   adb connect <IP_ADDRESS>:<PORT>
   ```
8. Now you can unplug USB and use wireless debugging

---

**Current Status**: Device shows as "unauthorized" - needs authorization on phone.


