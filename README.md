# 🚀 Xiaomi HyperOS Debloat Commander

![Platform](https://img.shields.io/badge/Platform-Windows-blue?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)
![Target](https://img.shields.io/badge/Target-HyperOS%20%7C%20MIUI-orange)

A powerful, interactive, and user-friendly Windows Batch script designed to safely remove telemetry, ads, and bloatware from Xiaomi, Redmi, and POCO devices running **HyperOS** or **MIUI** (Android 13/14+). **No Root Required.**

## ✨ Key Features

* **🖥️ Interactive App Explorer:** A fully scrollable, alphabetically sorted terminal UI to browse all database apps currently installed on your phone. Manually freeze, uninstall, or restore apps one by one.
* **📡 Live App State Checking:** Queries your device in real-time to show if an app is currently `Installed`, `Uninstalled (User 0)`, or `Frozen`.
* **🧠 Smart Filtering:** Automatically skips over apps that are already removed from your device, saving you time during manual review.
* **🛡️ 4-Phase Safety System:** Apps are categorized from completely safe (Ads/Analytics) to highly risky (Core System apps), giving you full control over what you remove.
* **📝 Automatic Logging:** Every action is meticulously logged to a dynamically generated `.txt` file with your Device Model, ID, and timestamp.
* **🔄 100% Reversible:** Built-in Recovery Mode allows you to instantly reinstall or unfreeze any app you previously removed.

## ⚠️ Important HyperOS Notice
On newer versions of HyperOS (Android 14+), Xiaomi has blocked the standard `pm disable-user` (Freeze) command for system apps, which throws a `SecurityException`. 
**Solution:** This script fully supports the **Uninstall for User 0** method. It acts exactly like a freeze, hides the app, stops it from running, frees up system resources, and is completely reversible.

## 🛠️ Prerequisites

1. **Windows PC** (Tested on Windows 10/11).
2. **ADB Installed:** Ensure ADB is installed and added to your system's Environment Variables, or place `adb.exe` in the same folder as the script.
3. **Enable Developer Options & USB Debugging:**
   * Go to `Settings` > `About phone` > Tap `OS version` 7 times.
   * Go to `Additional settings` > `Developer options`.
   * Enable **USB debugging**.
   * Enable **USB debugging (Security settings)** *(Requires a Mi Account).*

## 🚀 How to Use

1. **Download** the latest `HyperOS_Ultimate_v15.bat` from the Releases section.
2. **Connect your phone** to your PC via USB. (Accept the RSA fingerprint prompt on your phone's screen).
3. **Run** the `.bat` file as Administrator.
4. The script will automatically detect your device and prompt you with the Main Menu.

### Main Menu Options

* **[1] Standard Debloat (Phases 1-4):** Guides you through the 4 categorized phases of bloatware. You can choose to auto-process, manually review, or skip each phase.
* **[2] Interactive App Explorer:** Opens a paginated, scrollable UI using `[W]` (Up) and `[S]` (Down) keys to individually manage apps found on your phone.

### The 4 Debloat Phases

* **PHASE 1 (Safe):** Ads, Analytics, Background Stubs, and Junk Services (MSA, MIUI Daemon, Joyose).
* **PHASE 2 (Caution):** User-facing apps (Gallery, Weather, App Vault). Only remove if you use alternatives.
* **PHASE 3 (Risky):** Core system apps (Security Center, Find Device, GetApps). *Warning: Removing some of these can cause bootloops on specific firmware.*
* **PHASE 4 (Hidden):** Background APIs, Android core bloat, and deep Xiaomi telemetry.

## 🕹️ App Explorer Controls

If you launch the Interactive App Explorer, use the following keys to navigate:
* `[W]` - Move Cursor Up
* `[S]` - Move Cursor Down
* `[A]` - Page Up (Skip 10 apps)
* `[D]` - Page Down (Skip 10 apps)
* `[E]` - Execute (Select highlighted app)
* `[T]` - Toggle Filter (Switch between 'All DB Apps' and 'Active Apps Only')
* `[B]` - Go Back

## 🛑 Disclaimer

**Use at your own risk.** While this script categorizes apps by risk level, removing the wrong core system app (especially in Phase 3) can result in a bootloop, requiring a factory reset. Always research an app package before removing it if you do not know what it does. 

I am not responsible for bricked devices, lost data, or voided warranties.

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.