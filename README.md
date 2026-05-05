# Hotspot Keyboard (by Fortnix)

Hotspot Keyboard is a high-productivity, cross-platform bridge designed to turn your mobile device into a remote keyboard for your Windows PC. Whether you are using Android (Termux) for a low-latency CLI feel or iOS for a zero-install web experience, this tool allows you to control your PC wirelessly over a local hotspot connection.

---

## Features

* Dual-Platform Architecture:
  * Android (Termux): Utilizes a Python-based UDP client for ultra-low latency, perfect for developers.
  * iOS / Universal Web: A minimalist local web server is hosted directly from your PC. No app installation is required on the mobile device.
* Security & Automation:
  * Self-Elevating Privileges: The PowerShell script automatically requests Administrator rights to manage the network listener.
  * Self-Cleaning Firewall: The script creates a temporary Windows Firewall rule on startup and removes it immediately upon exit (via Ctrl+C) to keep your system secure.
* Robust Input Handling:
  * Automatically escapes special characters and PowerShell reserved symbols (+, ^, %, etc.) to ensure the script never crashes during fast typing.
* Intelligent Network Detection:
  * Automatically detects your Hotspot Gateway IP and provides clear instructions for the mobile client.

---

## Installation & Setup

### 1. Windows (Server Side)
1. Save RemoteKeyboardServer.ps1 to your PC.
2. Connect your PC to your phone's mobile hotspot.
3. Right-click the script and select Run with PowerShell.
4. Choose Option 1 for Android or Option 2 for iOS.

### 2. Android (Termux Client)
1. Open Termux and install dependencies:
   pkg install python
   pip install pynput
2. Run the client:
   python mobile_sender.py
3. Enter the PC IP Address displayed in the PowerShell window when prompted.

### 3. iOS (Web Client)
1. Select Option 2 in the PowerShell script.
2. Open Safari on your iPhone and navigate to the URL provided (e.g., http://10.249.113.233:5005/).
3. Tap the text box and begin typing.

---

## Project Structure

* RemoteKeyboardServer.ps1: The core PowerShell engine handling the network listener, firewall rules, and key injection.
* mobile_sender.py: The Python client for Termux that captures keystrokes and sends them via UDP.

---

## Troubleshooting

* Network Profile: Ensure your hotspot connection is set to Private in Windows Network Settings.
* Connection Issues: If the web page won't load on iOS, verify the IP and port (5005) match the information shown in the PowerShell terminal.

---

## License & Credits
Developed as a utility for the Fortnix ecosystem.

Peace. ✌️
