#/bin/bash
adb devices
echo "Waiting for device"
adb wait-for-device
ip=$(adb shell ifconfig wlan0 | awk '{if (sub(/inet addr:/,"")) print $1 }');
echo "Device ip: $ip"
echo "Setting Up tcpip port"
adb tcpip 5555
echo "Connecting to $ip"
adb connect $ip
