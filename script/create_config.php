<!-- create_config.php -->

<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $ssid = isset($_POST["ssid"]) ? htmlspecialchars($_POST["ssid"]) : null;
    $password = isset($_POST["password"]) ? htmlspecialchars($_POST["password"]) : null;

    // Validate input
    if ($ssid !== null && $password !== null) {
        // Sanitize input for command execution
        $ssid = escapeshellarg($ssid);
        $password = escapeshellarg($password);

        // Call Python script to create config
        $result = shell_exec("sudo nmcli device wifi connect $ssid password $password name $ssid 2>&1");

        if ($result === null) {
            echo "<p>Error creating config for SSID: $ssid</p>";
        } else {

            echo "<p>Config file created successfully for SSID: $ssid</p><p>Hotspot rebooting!</p>";

            // Reboot the machine
            shell_exec("sudo reboot");
        }
    } else {
        echo "<p>Invalid or missing input data.</p>";
    }
}
?>
