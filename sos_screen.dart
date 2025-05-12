import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  _SosScreenState createState() => _SosScreenState();
}

List<String> emergencyContacts = ["+917013796824"];

class _SosScreenState extends State<SosScreen> {
  bool isSosActive = false;
  bool isSirenOn = false;
  String locationMessage = "Fetching location...";
  FlutterSoundRecorder? _recorder;
  final AudioPlayer _sirenPlayer = AudioPlayer();
  List<String> incidentHistory = [];

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    await Permission.microphone.request();
    await Permission.location.request();
    await Permission.sms.request();
    await _recorder!.openRecorder();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _sirenPlayer.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          locationMessage =
              "${data['city']}, ${data['regionName']}, ${data['country']} (${data['lat']}, ${data['lon']})";
        });
      } else {
        setState(() {
          locationMessage = "Failed to get location from IP.";
        });
      }
    } catch (e) {
      setState(() {
        locationMessage = "Error getting location: $e";
      });
    }
  }

  Future<void> _sendEmergencySms(String location) async {
    String message =
        "🚨 SOS Activated! I need help. My current location: $location";

    try {
      await sendSMS(
        message: message,
        recipients: emergencyContacts,
        sendDirect: true, // Auto-send enabled
      );
      print("✅ SMS sent successfully.");
    } catch (error) {
      print("❌ Failed to send SMS: $error");
    }
  }

  Future<void> _sendWhatsAppAlert(String phone, String message) async {
    final url =
        Uri.parse("https://wa.me/$phone?text=${Uri.encodeFull(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print("❌ Failed to open WhatsApp for $phone.");
    }
  }

  Future<void> _trustedContactCall() async {
    String alertMessage =
        "🚨 Trusted Contact Alert! Please check on me. My location: $locationMessage";

    for (String phone in emergencyContacts) {
      await _sendWhatsAppAlert(phone, alertMessage);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ WhatsApp alert sent to trusted contacts!')),
    );
  }

  Future<void> _startRecording() async {
    await _recorder!.startRecorder(toFile: 'sos_recording.aac');
    print("🎙️ Recording started.");
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    print("⏹️ Recording stopped.");
  }

  Future<void> _playSiren() async {
    if (!isSirenOn) {
      await _sirenPlayer.play(AssetSource('siren.mp3'));
      setState(() => isSirenOn = true);
    } else {
      await _sirenPlayer.stop();
      setState(() => isSirenOn = false);
    }
  }

  Future<void> _showNearbyPoliceStations() async {
    final url =
        Uri.parse("https://www.google.com/maps/search/nearby+police+stations/");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _activateSos() async {
    setState(() {
      isSosActive = !isSosActive;
    });

    if (isSosActive) {
      await _getLocation();
      await _startRecording();
      await _playSiren();

      await _sendEmergencySms(locationMessage);

      for (String phone in emergencyContacts) {
        await _sendWhatsAppAlert(phone,
            "🚨 SOS Activated! I need help. My location: $locationMessage");
      }

      incidentHistory.insert(0, "🚨 SOS Activated at $locationMessage");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚨 SOS Activated! Help is on the way.')),
      );
    } else {
      await _stopRecording();
      await _playSiren(); // Stop siren if playing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🛑 SOS Deactivated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning,
                    size: 100,
                    color: isSosActive ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSosActive ? "SOS Active" : "SOS Inactive",
                    style: TextStyle(
                      fontSize: 24,
                      color: isSosActive ? Colors.red : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _activateSos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSosActive ? Colors.red : Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      isSosActive ? "Deactivate SOS" : "Activate SOS",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showNearbyPoliceStations,
                    child: Text('Show Nearby Police Stations'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _trustedContactCall,
                    child: Text('Trusted Contact Alert'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Current Location:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    locationMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Incident History:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...incidentHistory.map((incident) => Text(incident)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          right: 30,
          child: FloatingActionButton(
            onPressed: _activateSos,
            backgroundColor: Colors.red,
            child: Icon(Icons.warning),
          ),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:flutter_sms/flutter_sms.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:audioplayers/audioplayers.dart';

// class SosScreen extends StatefulWidget {
//   const SosScreen({super.key});

//   @override
//   _SosScreenState createState() => _SosScreenState();
// }

// List<String> emergencyContacts = ["+919876543210", "+911234567890"];

// class _SosScreenState extends State<SosScreen> {
//   bool isSosActive = false;
//   String locationMessage = "Location not fetched";
//   FlutterSoundRecorder? _recorder;
//   final AudioPlayer _sirenPlayer = AudioPlayer();

//   @override
//   void initState() {
//     super.initState();
//     _recorder = FlutterSoundRecorder();
//     _initializeRecorder();
//   }

//   Future<void> _initializeRecorder() async {
//     await _recorder!.openRecorder();
//     await Permission.microphone.request();
//   }

//   @override
//   void dispose() {
//     _recorder!.closeRecorder();
//     _recorder = null;
//     _sirenPlayer.dispose();
//     super.dispose();
//   }

//   Future<void> _playSiren() async {
//     await _sirenPlayer.play(AssetSource('sounds/siren.mp3'));
//   }

//   Future<void> _stopSiren() async {
//     await _sirenPlayer.stop();
//   }

//   Future<void> _getLocation() async {
//     if (!await Geolocator.isLocationServiceEnabled()) {
//       await Geolocator.openLocationSettings();
//       return;
//     }

//     var permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         return;
//       }
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);

//     setState(() {
//       locationMessage =
//           "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
//     });
//   }

//   Future<void> _sendEmergencySms(String location) async {
//     String message =
//         "🚨 SOS Activated! I need help. My current location: $location";

//     try {
//       await sendSMS(
//         message: message,
//         recipients: emergencyContacts,
//         sendDirect: true,
//       );
//     } catch (error) {
//       print("Failed to send SMS: $error");
//     }
//   }

//   Future<void> _sendWhatsAppAlert(String phone, String message) async {
//     final url =
//         Uri.parse("https://wa.me/$phone?text=${Uri.encodeFull(message)}");
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url);
//     }
//   }

//   Future<void> _startRecording() async {
//     await _recorder!.startRecorder(toFile: 'sos_recording.aac');
//   }

//   Future<void> _stopRecording() async {
//     await _recorder!.stopRecorder();
//   }

//   void _activateSos() async {
//     setState(() {
//       isSosActive = !isSosActive;
//     });

//     if (isSosActive) {
//       await _getLocation();
//       await _startRecording();
//       await _sendEmergencySms(locationMessage);

//       for (String phone in emergencyContacts) {
//         await _sendWhatsAppAlert(phone,
//             "🚨 SOS Activated! I need help. My location: $locationMessage");
//       }

//       await _playSiren();

//       // Auto-stop siren after 30 seconds
//       Future.delayed(const Duration(seconds: 30), () {
//         if (isSosActive) _stopSiren();
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('🚨 SOS Activated! Help is on the way.')),
//       );
//     } else {
//       await _stopRecording();
//       await _stopSiren();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('🛑 SOS Deactivated.')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.warning,
//               size: 100,
//               color: isSosActive ? Colors.red : Colors.grey,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               isSosActive ? "SOS Active" : "SOS Inactive",
//               style: TextStyle(
//                 fontSize: 24,
//                 color: isSosActive ? Colors.red : Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _activateSos,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isSosActive ? Colors.red : Colors.blue,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//               ),
//               child: Text(
//                 isSosActive ? "Deactivate SOS" : "Activate SOS",
//                 style: const TextStyle(fontSize: 20),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Current Location:",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               locationMessage,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
