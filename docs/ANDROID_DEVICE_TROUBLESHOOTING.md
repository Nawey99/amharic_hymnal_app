# Android Device Connection Troubleshooting

## Issue: Device Not Detected

If you're getting errors when trying to run the app on your Android device, follow these steps:

---

## ✅ Step 1: Check USB Connection

1. **Unplug and replug** your USB cable
2. Try a **different USB cable** (some cables are charge-only)
3. Try a **different USB port** on your computer
4. Make sure the cable is **fully connected** on both ends

---

## ✅ Step 2: Enable USB Debugging

On your Android device:

1. Go to **Settings** → **About phone**
2. Tap **Build number** 7 times to enable Developer options
3. Go back to **Settings** → **Developer options**
4. Enable **USB debugging**
5. Enable **Install via USB** (if available)
6. Enable **USB debugging (Security settings)** (if available)

---

## ✅ Step 3: Authorize Computer

When you connect your device:

1. A popup will appear on your phone: **"Allow USB debugging?"**
2. Check **"Always allow from this computer"**
3. Tap **"Allow"** or **"OK"**

---

## ✅ Step 4: Check ADB Connection

Open PowerShell/Command Prompt and run:

```bash
adb devices
```

**Expected output:**
```
List of devices attached
R5CT62VNMVK    device
```

**If you see "unauthorized":**
- Unplug and replug the USB cable
- Check the popup on your phone again
- Run `adb kill-server` then `adb start-server`

**If you see "offline":**
- Unplug and replug the USB cable
- Restart ADB: `adb kill-server` then `adb start-server`

**If device doesn't appear:**
- Check USB debugging is enabled
- Try a different USB cable/port
- Restart your phone

---

## ✅ Step 5: Check Flutter Device Detection

Run:

```bash
flutter devices
```

**Expected output:**
```
Found 1 connected device:
  SM S9080 (mobile) • R5CT62VNMVK • android-arm64 • Android 16 (API 36)
```

**If device doesn't appear:**
- Make sure ADB can see it (`adb devices`)
- Run `flutter doctor` to check for issues
- Restart Flutter: `flutter doctor -v`

---

## ✅ Step 6: Install APK Manually (Alternative)

If Flutter can't detect the device but ADB can:

1. **Build the APK:**
   ```bash
   flutter build apk --debug
   ```

2. **Install via ADB:**
   ```bash
   adb install android\app\build\outputs\apk\debug\app-debug.apk
   ```

   Or if you need to replace an existing installation:
   ```bash
   adb install -r android\app\build\outputs\apk\debug\app-debug.apk
   ```

---

## ✅ Step 7: Common Issues & Solutions

### Issue: "device not found"
**Solution:**
- Enable USB debugging
- Authorize computer on phone
- Check USB cable/port

### Issue: "unauthorized"
**Solution:**
- Revoke USB debugging authorizations on phone (Settings → Developer options → Revoke USB debugging authorizations)
- Unplug and replug
- Re-authorize when prompted

### Issue: "offline"
**Solution:**
- Restart ADB: `adb kill-server` then `adb start-server`
- Unplug and replug USB cable
- Restart phone

### Issue: "Gradle build failed to produce an .apk file"
**Solution:**
- The APK is actually built successfully at: `android\app\build\outputs\apk\debug\app-debug.apk`
- This is a Flutter path detection issue
- Install manually using Step 6 above
- Or use Android Studio to run the app

### Issue: Device appears in `adb devices` but not in `flutter devices`
**Solution:**
- Restart Flutter: Close and reopen terminal
- Run `flutter doctor` to check for issues
- Make sure device is in "File Transfer" or "MTP" mode (not "Charge only")

---

## ✅ Step 8: Use Android Studio (Alternative)

If command line doesn't work:

1. Open **Android Studio**
2. Open the project: `File` → `Open` → Select your project folder
3. Wait for Gradle sync to complete
4. Click the **device dropdown** at the top
5. Select your device
6. Click the **Run** button (green play icon)

---

## ✅ Step 9: Wireless Debugging (Android 11+)

If USB is problematic, you can use wireless debugging:

1. Connect device via USB first (one time setup)
2. On phone: **Settings** → **Developer options** → **Wireless debugging**
3. Enable **Wireless debugging**
4. Tap **Pair device with pairing code**
5. Note the **IP address and port** (e.g., `192.168.1.100:12345`)
6. On computer, run:
   ```bash
   adb pair 192.168.1.100:12345
   ```
   (Enter the pairing code when prompted)
7. After pairing, tap **Wireless debugging** again
8. Note the **IP address and port** under "IP address & Port"
9. Run:
   ```bash
   adb connect 192.168.1.100:XXXXX
   ```
10. Verify: `adb devices` should show your device
11. Now you can unplug USB and use wireless debugging

---

## Quick Checklist

- [ ] USB cable is connected and working
- [ ] USB debugging is enabled on phone
- [ ] Computer is authorized on phone
- [ ] `adb devices` shows the device
- [ ] `flutter devices` shows the device
- [ ] Device is in "File Transfer" mode (not "Charge only")

---

## Still Not Working?

1. **Restart everything:**
   - Restart your phone
   - Restart your computer
   - Restart ADB: `adb kill-server` then `adb start-server`

2. **Check USB drivers:**
   - Install/update USB drivers for your phone manufacturer
   - Samsung: Install Samsung USB drivers
   - Google: Install Google USB drivers

3. **Try different connection method:**
   - Use wireless debugging (Android 11+)
   - Use Android Studio instead of command line

4. **Check for conflicts:**
   - Close other apps that might use ADB (Android Studio, other IDEs)
   - Make sure only one ADB server is running

---

## Success Indicators

✅ `adb devices` shows your device as "device" (not "unauthorized" or "offline")
✅ `flutter devices` shows your Android device
✅ `flutter run` successfully launches the app

---

## Need More Help?

- Flutter documentation: https://flutter.dev/docs/get-started/install/windows
- Android developer guide: https://developer.android.com/studio/run/device
- Check Flutter issues: https://github.com/flutter/flutter/issues


