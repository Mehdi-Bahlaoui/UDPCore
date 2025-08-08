# 🎮 Remote Control App

## 📱 Overview

A powerful and intuitive remote control application that allows you to send UDP commands to control devices over your local network. Perfect for IoT devices, robotics projects, and home automation systems.

## ✨ Features

- **Real-time Control**: Instant command transmission with visual feedback
- **Customizable Settings**: Configure target IP, port, and transmission speed
- **Network Status**: Live connection monitoring and socket status
- **Responsive UI**: Immediate label updates when buttons are pressed
- **Optimized Performance**: Efficient UDP communication with minimal latency

<div align="center">
  <img src="feature_image.png" alt="App Features" width="600">
</div>

## 🚀 How It Works

1. **Configure Connection**: Set your target device's IP address and port
2. **Establish Socket**: Connect to your network and initialize UDP socket
3. **Send Commands**: Press control buttons to send specific commands
4. **Real-time Feedback**: Watch the current command label update instantly
5. **Monitor Status**: Keep track of connection status and network health

## 🛠️ Technical Features

- **UDP Socket Communication**: Fast and lightweight data transmission
- **Timer-based Sending**: Configurable command repetition intervals
- **State Management**: Efficient UI updates and command tracking
- **Error Handling**: Robust network error detection and recovery
- **Cross-device Compatibility**: Works on various Android devices and network conditions

## 📋 Requirements

- Android 5.0 (API level 21) or higher
- Network connectivity (Wi-Fi or mobile data)
- Target device on the same network or accessible IP

## 🔧 Configuration

The app allows you to configure:
- **Target IP Address**: The device you want to control
- **Target Port**: Communication port for your device
- **Transmission Speed**: Command sending frequency (milliseconds)

## 🎯 Use Cases

- **Home Automation**: Control smart lights, fans, and appliances
- **Robotics**: Remote control for robots and automated systems
- **IoT Projects**: Interface with ESP32, Arduino, and Raspberry Pi devices
- **Media Control**: Manage media players and streaming devices
- **Custom Hardware**: Control any UDP-enabled device

## 🔒 Network Security

- Uses UDP protocol for fast, connectionless communication
- Commands are sent only to specified IP addresses
- No persistent connections or data storage
- Local network communication prioritized for security

## 📞 Support

If you encounter any issues or have questions about the app, please check the connection settings and ensure your target device is accessible on the network.

---

<div align="center">
  Made with ❤️ 
</div>