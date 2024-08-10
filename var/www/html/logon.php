<!-- logon.php -->

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Choose your WiFi</title>

    <style>
        body {
            background-color: #1a1a1a; /* Dark background color */
            color: #ffffff; /* Light text color */
            font-family: Arial, sans-serif; /* Font family */
        }

        h1 {
            color: #ffcc00; /* Header text color */
        }

        select, input, button {
            background-color: #333333; /* Dark input background color */
            color: #ffffff; /* Light input text color */
            border: 1px solid #666666; /* Input border color */
            padding: 5px; /* Input padding */
            margin-bottom: 10px; /* Margin between elements */
        }

        button {
            cursor: pointer; /* Change cursor on hover for button */
        }

        /* Optional: Hover effect for button */
        button:hover {
            background-color: #555555; /* Darker button background color on hover */
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

   <?php
$output = shell_exec("python3 scan_wifi.py");
$wifi_networks = json_decode($output, true);

// Sort and filter the array to keep only the first occurrence of each unique SSID
$uniqueNetworks = [];
usort($wifi_networks, function ($a, $b) {
    return $b['signal'] <=> $a['signal'];
});
foreach ($wifi_networks as $network) {
    $ssid = $network['ssid'];
    if (!isset($uniqueNetworks[$ssid])) {
        $uniqueNetworks[$ssid] = $network;
    }
}

if (!empty($uniqueNetworks)) {
    echo '<form action="create_config.php" method="post">';
    echo 'Select WiFi Network: <select name="ssid" required>';

    foreach ($uniqueNetworks as $network) {
        echo '<option value="' . $network['ssid'] . '">' . $network['ssid'] . ' (Signal: ' . $network['signal'] . ')</option>';
    }

    echo '</select><br>';
    echo 'Password: <input type="password" name="password" id="password" required>';
    echo '<button type="button" onclick="togglePasswordVisibility()">Show Password</button><br>';
    echo '<input type="submit" value="Save and Reboot">';
    echo '</form>';
} else {
    echo "<p>No WiFi networks found.</p>";
}
?>

</body>
</html>
