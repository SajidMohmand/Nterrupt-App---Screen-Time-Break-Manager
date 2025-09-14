
# nterrupt

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Nterrupt - Screen Time Break Manager

**Nterrupt** is a personal-use Android app to help manage your screen time.  
It monitors selected apps and forces you to take a **10-minute break** after using them for a set duration.

---

## ✨ Features

- Requests all necessary permissions upon first launch:
  - `PACKAGE_USAGE_STATS`
  - `SYSTEM_ALERT_WINDOW`
  - `FOREGROUND_SERVICE`
- Re-checks permissions each time the app is opened, and requests again if missing.
- Lists all installed apps on the device.
- Allows selecting/deselecting apps to interrupt.
- Per-app time limits: **5, 10, or 15 minutes** of usage.
- Locks selected apps when the time limit is reached.
- Shows a countdown screen during the 10-minute enforced break.
- After the break, the app can be used again.

---

## 🚀 How It Works

1. Open Nterrupt and grant the required permissions.  
2. Select which apps you want to monitor.  
3. Set a maximum usage duration for each app.  
4. Once you reach the limit, the app is locked.  
5. A **10-minute countdown screen** is shown.  
6. After the break, access to the app is restored.

---

## 🛠️ Tech Stack

- Android (Java/Kotlin)
- UsageStatsManager API
- Foreground services
- Overlay (system alert window) for countdown lock screen

---

## ⚠️ Note

This app is built for **personal use** and not intended for publishing on Google Play.  
Some features (like app-locking) may depend on device-specific behavior and Android version limitations.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
 
