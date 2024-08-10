#!/usr/bin/python3

import re
import serial
import time

def read_sa818_config(filename):
    with open(filename, 'r') as file:
        content = file.read()

        # Use regular expressions to extract values
        tx_frequency_match = re.search(r'Tx Frequency: (\d+\.\d+)', content)
        tx_ctcss_match = re.search(r'Tx CTCSS code: (\d+)', content)
        rx_frequency_match = re.search(r'Rx Frequency: (\d+\.\d+)', content)
        rx_ctcss_match = re.search(r'Rx CTCSS code: (\d+)', content)

        if tx_frequency_match and tx_ctcss_match and rx_frequency_match and rx_ctcss_match:
            tx_frequency = "{:.4f}".format(float(tx_frequency_match.group(1)))  # Format frequency to four decimal places
            rx_frequency = "{:.4f}".format(float(rx_frequency_match.group(1)))  # Format frequency to four decimal places
            tx_ctcss = "{:04d}".format(int(tx_ctcss_match.group(1)))  # Format tone code to four digits
            rx_ctcss = "{:04d}".format(int(rx_ctcss_match.group(1)))  # Format tone code to four digits
            return tx_frequency, tx_ctcss, rx_frequency, rx_ctcss
        else:
            print("Unable to find RF Frequency and CTCSS frequency in the file.")
            return None, None, None, None

# Provide the path to your text file
filename = '/root/SA818.log'

# Call the function to read values
tx_frequency, tx_ctcss, rx_frequency, rx_ctcss = read_sa818_config(filename)

# Print the values using format method
if tx_frequency is not None and tx_ctcss is not None:
    print("Tx Frequency: {}".format(tx_frequency))
    print("Rx Frequency: {}".format(rx_frequency))
    print("Tx CTCSS Frequency: {}".format(tx_ctcss))
    print("Rx CTCSS Frequency: {}".format(rx_ctcss))
    command = "AT+DMOSETGROUP=1,{},{},{},1,{}\r\n".format(tx_frequency, rx_frequency, tx_ctcss, rx_ctcss)
    ser = serial.Serial('/dev/ttyAMA0', baudrate=9600, timeout=1)
    ser.write(command.encode())
    time.sleep(1)
    ser.write("AT+DMOSETVOLUME=6\r\n".encode())
    time.sleep(1)
    ser.write("AT+SETTAIL=0\r\n".encode())
    time.sleep(1)
    ser.write("AT+SETFILTER=0,1,1\r\n".encode())
    ser.close()
