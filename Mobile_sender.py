import socket
import sys
from pynput import keyboard

def start_client():
    print("--- Remote Keyboard: Termux Client ---")
    print("Step 1: Run the PowerShell script on your PC.")
    print("Step 2: Choose Option 1 (Android/Termux).")
    
    # Ask the user for the IP displayed on the PC
    pc_ip = input("\nTarget PC IP Address: ").strip()
    port = 5005

    if not pc_ip:
        print("Error: IP address is required.")
        sys.exit(1)

    # Initialize UDP Socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    def on_press(key):
        try:
            # Handle alphanumeric keys
            data = key.char
        except AttributeError:
            # Handle special keys
            special_keys = {
                keyboard.Key.enter: "ENTER",
                keyboard.Key.backspace: "BACKSPACE",
                keyboard.Key.space: "SPACE"
            }
            data = special_keys.get(key, None)

        if data:
            try:
                sock.sendto(data.encode('utf-8'), (pc_ip, port))
            except Exception as e:
                print(f"Transmission error: {e}")

    print(f"\n[CONNECTED] Sending input to {pc_ip}:{port}")
    print("Type into this terminal to send keys to your PC.")
    print("Press Ctrl+C in this terminal to stop.")

    try:
        with keyboard.Listener(on_press=on_press) as listener:
            listener.join()
    except KeyboardInterrupt:
        print("\nTerminating client...")
    finally:
        sock.close()

if __name__ == "__main__":
    start_client()
