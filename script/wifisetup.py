#!/usr/bin/env python3

import cgi
import subprocess
import json
import html

# Function to replace the specific escape sequences with their respective characters
def clean_ssid(ssid):
    ssid = ssid.replace("\\xE2\\x80\\x99", " WILL NOT WORK WITH APOSTROPHE ")  # Replace specific hex code for apostrophe
    return ssid

def scan_wifi_networks():
    try:
        result = subprocess.run(["iwlist", "scan"], capture_output=True, text=True, check=True)
        output_lines = result.stdout.splitlines()

        networks = []
        ssid = None
        quality = None
        signal = None

        for line in output_lines:
            line = line.strip()
            if line.startswith("ESSID:"):
                ssid = line.split(":")[1].strip().strip('"')
                ssid = clean_ssid(ssid)  # Clean the SSID to replace escape sequences
            elif "Quality=" in line and "Signal level=" in line:
                quality_parts = line.split(" ")[0].split("=")[1].split("/")
                quality = int(quality_parts[0])
                signal = int(line.split("Signal level=")[1].split(" ")[0])
            elif line.startswith("Cell ") and ssid is not None:
                network = {"ssid": ssid, "quality": quality, "signal": signal}
                networks.append(network)
                ssid = None
                quality = None
                signal = None

        return networks
    except subprocess.CalledProcessError as e:
        return {"error": f"Command failed: {str(e)}"}
    except Exception as e:
        return {"error": str(e)}


def generate_html_form(wifi_networks):
    unique_networks = {}
    wifi_networks.sort(key=lambda x: x['signal'], reverse=True)
    for network in wifi_networks:
        ssid = network['ssid']
        if ssid not in unique_networks:
            unique_networks[ssid] = network

    html_form = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Choose your WiFi</title>
       <style>
    body {
        background-color: #121212;
        color: #e0e0e0;
        font-family: Arial, sans-serif;
        margin: 20px;
    }
    form {
        max-width: 400px;
        margin: auto;
        background-color: #1e1e1e;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
    }
    label {
        display: block;
        margin-bottom: 8px;
        color: #e0e0e0;
    }
    select, input {
        display: block;
        margin-bottom: 10px;
        width: 100%;
        padding: 8px;
        border: 1px solid #333;
        border-radius: 4px;
        background-color: #333;
        color: #e0e0e0;
    }
    button {
        margin-top: 10px;
        padding: 10px;
        border: none;
        border-radius: 4px;
        background-color: #185C91;
        color: #ffffff;
        cursor: pointer;
    }
    button:hover {
        background-color: #185C91;
    }
</style>

        <script>
            function togglePasswordVisibility() {
                var passwordInput = document.getElementById("password");
                if (passwordInput.type === "password") {
                    passwordInput.type = "text";
                } else {
                    passwordInput.type = "password";
                }
            }
        </script>
    </head>
    <body>
        <h1>Choose your WiFi</h1>
    """

    if unique_networks:
        html_form += '<form action="" method="post">'
        html_form += '<label for="ssid">Select WiFi Network:</label>'
        html_form += '<select name="ssid" id="ssid" required>'

        for ssid, network in unique_networks.items():
            html_form += f'<option value="{html.escape(ssid)}">{html.escape(ssid)} (Signal: {network["signal"]})</option>'

        html_form += '</select>'
        html_form += '<label for="password">Password:</label>'
        html_form += '<input type="password" name="password" id="password" required>'
        html_form += '<button type="button" onclick="togglePasswordVisibility()">Show Password</button>'
        html_form += '<button type="submit">Save and Reboot</button>'
        html_form += '</form>'
    else:
        html_form += "<p>No WiFi networks found.</p>"

    html_form += "</body></html>"
    return html_form

def create_wifi_config(ssid, password):
    try:
        command = ["sudo", "nmcli", "device", "wifi", "connect", ssid, "password", password]
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        return f"Error: {e.stderr}"

def main():
    print("Content-Type: text/html")
    print("Cache-Control: no-cache, no-store, must-revalidate")  # HTTP 1.1.
    print("Pragma: no-cache")  # HTTP 1.0.
    print("Expires: 0")  # Proxies.
    print()

    form = cgi.FieldStorage()
    ssid = form.getfirst("ssid", "").strip()
    password = form.getfirst("password", "").strip()

    if ssid and password:
        output = create_wifi_config(ssid, password)
        if "success" in output.lower():
            print(f"<p>Config file created successfully for SSID: {html.escape(ssid)}</p>")
            print("<p>Hotspot rebooting!</p>")
            subprocess.run(["sudo", "reboot"], check=True)
        else:
            print(f"<p>Error creating config for SSID: {html.escape(ssid)}</p><p>{html.escape(output)}</p>")
    else:
        wifi_networks = scan_wifi_networks()
        html_output = generate_html_form(wifi_networks)
        print(html_output)

if __name__ == "__main__":
    main()
