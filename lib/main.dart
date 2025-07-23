import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Force landscape orientation
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      MaterialApp(debugShowCheckedModeBanner: false, home: MainApp());
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _selectedPage = 'controller';
  String _targetIp = '172.22.25.169';
  int _targetPort = 4210;
  int _speed = 100;
  String _forwardCommand = 'F';
  String _leftCommand = 'L';
  String _backwardCommand = 'B';
  String _rightCommand = 'R';
  String _stopCommand = 'S';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetIp = prefs.getString('targetIp') ?? _targetIp;
      _targetPort = prefs.getInt('targetPort') ?? _targetPort;
      _speed = prefs.getInt('speed') ?? _speed;
      _forwardCommand = prefs.getString('forwardCommand') ?? _forwardCommand;
      _leftCommand = prefs.getString('leftCommand') ?? _leftCommand;
      _backwardCommand = prefs.getString('backwardCommand') ?? _backwardCommand;
      _rightCommand = prefs.getString('rightCommand') ?? _rightCommand;
      _stopCommand = prefs.getString('stopCommand') ?? _stopCommand;
    });
  }

  Future<void> _updateTarget(
      String ip,
      int port,
      int speed,
      String forward,
      String left,
      String backward,
      String right,
      String stop,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('targetIp', ip);
    await prefs.setInt('targetPort', port);
    await prefs.setInt('speed', speed);
    await prefs.setString('forwardCommand', forward);
    await prefs.setString('leftCommand', left);
    await prefs.setString('backwardCommand', backward);
    await prefs.setString('rightCommand', right);
    await prefs.setString('stopCommand', stop);

    setState(() {
      _targetIp = ip;
      _targetPort = port;
      _speed = speed;
      _forwardCommand = forward;
      _leftCommand = left;
      _backwardCommand = backward;
      _rightCommand = right;
      _stopCommand = stop;
    });
  }

  Widget _buildPage() {
    if (_selectedPage == 'controller') {
      return ControllerPage(
        ip: _targetIp,
        port: _targetPort,
        speed: _speed,
        forwardCommand: _forwardCommand,
        leftCommand: _leftCommand,
        backwardCommand: _backwardCommand,
        rightCommand: _rightCommand,
        stopCommand: _stopCommand,
        onSettingsTap: () => setState(() => _selectedPage = 'settings'),
        onAboutTap: () => setState(() => _selectedPage = 'about'), // Added callback
      );
    } else if (_selectedPage == 'settings') {
      return SettingsPage(
        defaultIp: _targetIp,
        defaultPort: _targetPort,
        defaultSpeed: _speed,
        defaultForward: _forwardCommand,
        defaultLeft: _leftCommand,
        defaultBackward: _backwardCommand,
        defaultRight: _rightCommand,
        defaultStop: _stopCommand,
        onConnect: _updateTarget,
        onBackTap: () => setState(() => _selectedPage = 'controller'),
      );
    } else {
      return AboutUsPage(
        onBackTap: () => setState(() => _selectedPage = 'controller'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildPage());
  }
}

class SettingsPage extends StatefulWidget {
  final String defaultIp;
  final int defaultPort;
  final int defaultSpeed;
  final String defaultForward;
  final String defaultLeft;
  final String defaultBackward;
  final String defaultRight;
  final String defaultStop;
  final Function(String, int, int, String, String, String, String, String)
  onConnect;
  final VoidCallback onBackTap;

  SettingsPage({
    required this.defaultIp,
    required this.defaultPort,
    required this.defaultSpeed,
    required this.defaultForward,
    required this.defaultLeft,
    required this.defaultBackward,
    required this.defaultRight,
    required this.defaultStop,
    required this.onConnect,
    required this.onBackTap,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _speedController;
  late TextEditingController _forwardController;
  late TextEditingController _leftController;
  late TextEditingController _backwardController;
  late TextEditingController _rightController;
  late TextEditingController _stopController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.defaultIp);
    _portController = TextEditingController(text: widget.defaultPort.toString());
    _speedController = TextEditingController(text: widget.defaultSpeed.toString());
    _forwardController = TextEditingController(text: widget.defaultForward);
    _leftController = TextEditingController(text: widget.defaultLeft);
    _backwardController = TextEditingController(text: widget.defaultBackward);
    _rightController = TextEditingController(text: widget.defaultRight);
    _stopController = TextEditingController(text: widget.defaultStop);
  }

  @override
  void dispose() {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? widget.defaultPort;
    final speed = int.tryParse(_speedController.text.trim()) ?? widget.defaultSpeed;
    final forward = _forwardController.text.trim().isNotEmpty
        ? _forwardController.text.trim()
        : widget.defaultForward;
    final left = _leftController.text.trim().isNotEmpty
        ? _leftController.text.trim()
        : widget.defaultLeft;
    final backward = _backwardController.text.trim().isNotEmpty
        ? _backwardController.text.trim()
        : widget.defaultBackward;
    final right = _rightController.text.trim().isNotEmpty
        ? _rightController.text.trim()
        : widget.defaultRight;
    final stop = _stopController.text.trim().isNotEmpty
        ? _stopController.text.trim()
        : widget.defaultStop;

    widget.onConnect(ip, port, speed, forward, left, backward, right, stop);

    _ipController.dispose();
    _portController.dispose();
    _speedController.dispose();
    _forwardController.dispose();
    _leftController.dispose();
    _backwardController.dispose();
    _rightController.dispose();
    _stopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("UDP Controller App"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBackTap,
          tooltip: 'Back to Controller',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Target IP Address"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Target Port"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _speedController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Hold Send Interval (ms)"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _forwardController,
                decoration: InputDecoration(labelText: "Forward Command"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _leftController,
                decoration: InputDecoration(labelText: "Left Command"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _backwardController,
                decoration: InputDecoration(labelText: "Backward Command"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _rightController,
                decoration: InputDecoration(labelText: "Right Command"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _stopController,
                decoration: InputDecoration(labelText: "Stop Command"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutUsPage extends StatelessWidget {
  final VoidCallback onBackTap;

  AboutUsPage({required this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About Us"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: onBackTap,
          tooltip: 'Back to Controller',
        ),
      ),
      body: Center(
        child: Text(
          "About Us Content\n\n"
              "This is the About Us page for the UDP Controller App.\n"
              "Add your app details, team information, or other content here.",
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ControllerPage extends StatefulWidget {
  final String ip;
  final int port;
  final int speed;
  final String forwardCommand;
  final String leftCommand;
  final String backwardCommand;
  final String rightCommand;
  final String stopCommand;
  final VoidCallback onSettingsTap;
  final VoidCallback onAboutTap; // Added callback

  ControllerPage({
    required this.ip,
    required this.port,
    required this.speed,
    required this.forwardCommand,
    required this.leftCommand,
    required this.backwardCommand,
    required this.rightCommand,
    required this.stopCommand,
    required this.onSettingsTap,
    required this.onAboutTap, // Added parameter
  });

  @override
  _ControllerPageState createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  RawDatagramSocket? _socket;
  bool _socketReady = false;
  Timer? _sendTimer;
  String _currentCommand = "";

  @override
  void initState() {
    super.initState();
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
      _socket = socket;
      _socketReady = true;
    });
  }

  void _startSending(String command) {
    if (!_socketReady || _socket == null) return;
    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(Duration(milliseconds: widget.speed), (_) {
      _socket!.send(command.codeUnits, InternetAddress(widget.ip), widget.port);
      setState(() {
        _currentCommand = command;
      });
    });
  }

  void _stopSending() {
    if (_socketReady && _socket != null) {
      _socket!.send(
        widget.stopCommand.codeUnits,
        InternetAddress(widget.ip),
        widget.port,
      );
      setState(() {
        _currentCommand = widget.stopCommand;
      });
    }
    _sendTimer?.cancel();
    _sendTimer = null;
  }

  Widget _controlButton(
      IconData icon,
      String command, {
        double size = 80,
        Color? color,
      }) {
    return Listener(
      onPointerDown: (_) {
        HapticFeedback.lightImpact();
        _startSending(command);
      },
      onPointerUp: (_) {
        HapticFeedback.selectionClick();
        _stopSending();
      },
      onPointerCancel: (_) {
        HapticFeedback.selectionClick();
        _stopSending();
      },
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ??
              (_currentCommand == command
                  ? Colors.blueAccent.withOpacity(0.9)
                  : Colors.blue.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = min(screenSize.width * 0.15, screenSize.height * 0.2);
    final buttonSpacing = buttonSize * 0.5;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            // image: DecorationImage(
            //   image: AssetImage("images/Artboard_1.png"),
            //   fit: BoxFit.cover,
            // ),
          ),
        ),

        // Main control area
        Positioned(
          top: screenSize.height * 0.2,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status labels
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _currentCommand.isEmpty
                          ? "Ready | ${widget.ip}:${widget.port}"
                          : "Sending: $_currentCommand",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "Not Receiving",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: buttonSize * 0.5), // Gap between labels and directional pad
              // Directional pad
              Column(
                children: [
                  _controlButton(
                    Icons.arrow_upward,
                    widget.forwardCommand,
                    size: buttonSize,
                    color: Colors.black38,
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _controlButton(
                        Icons.arrow_back,
                        widget.leftCommand,
                        size: buttonSize,
                        color: Colors.black38,
                      ),
                      SizedBox(width: buttonSize * 1.2),
                      _controlButton(
                        Icons.arrow_forward,
                        widget.rightCommand,
                        size: buttonSize,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  _controlButton(
                    Icons.arrow_downward,
                    widget.backwardCommand,
                    size: buttonSize,
                    color: Colors.black38,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Settings button (top-left)
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            width: buttonSize * 0.7,
            height: buttonSize * 0.7,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings,
                size: buttonSize * 0.35,
                color: Colors.white,
              ),
              onPressed: widget.onSettingsTap,
              tooltip: 'Go to Settings',
            ),
          ),
        ),

        // About Us button (top-right)
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: buttonSize * 0.7,
            height: buttonSize * 0.7,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.info,
                size: buttonSize * 0.35,
                color: Colors.white,
              ),
              onPressed: widget.onAboutTap, // Use callback
              tooltip: 'About Us',
            ),
          ),
        ),
      ],
    );
  }
}