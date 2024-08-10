# scan_wifi.py

import subprocess
import json

def scan_wifi():
    try:
        result = subprocess.run(["iwlist", "scan"], capture_output=True, text=True)
        output_lines = result.stdout.splitlines()

        networks = []

        ssid = None
        quality = None
        signal = None

        for line in output_lines:
            line = line.strip()

            if line.startswith("ESSID:"):
                ssid = line.split(":")[1].strip().strip('"')

            elif "Quality=" in line and "Signal level=" in line:
                quality_parts = line.split(" ")[0].split("=")[1].split("/")
                quality = int(quality_parts[0])
                signal = int(line.split("Signal level=")[1].split(" ")[0])

            elif line.startswith("Cell ") and ssid is not None:
                network = {"ssid": ssid, "quality": quality, "signal": signal}
                networks.append(network)

                # Reset values for the next network
                ssid = None
                quality = None
                signal = None

        return networks

    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    wifi_networks = scan_wifi()
    print(json.dumps(wifi_networks))
