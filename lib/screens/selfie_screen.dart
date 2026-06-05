import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class SelfieScreen extends StatefulWidget {
  final String qrData;
  final int studentId;
  final String? expectedTimeSlot; // ✅ ADDED

  const SelfieScreen({
    super.key,
    required this.qrData,
    required this.studentId,
    this.expectedTimeSlot, // ✅ ADDED
  });

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  File? image;
  final picker = ImagePicker();
  String result = "";

  Future<Position> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

// ✅ Reject if GPS accuracy is too poor (over 50m margin of error)
    if (position.accuracy > 50) {
      throw Exception("GPS signal too weak (accuracy: ${position.accuracy.toStringAsFixed(1)}m). Please move near a window and try again.");
    }

    return position;
  }

  Future<void> captureAndSend() async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (picked == null) return;

    image = File(picked.path);

    final position = await getLocation();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://172.20.10.5:5001/recognize"),
    );

    request.fields['qr_data'] = widget.qrData;
    request.fields['student_id'] = widget.studentId.toString();
    request.fields['lat'] = position.latitude.toString();
    request.fields['lng'] = position.longitude.toString();

    // ✅ ADDED — send expected slot to backend for cross-verification
    if (widget.expectedTimeSlot != null) {
      request.fields['expected_time_slot'] = widget.expectedTimeSlot!;
    }

    request.files.add(
      await http.MultipartFile.fromPath('image', image!.path),
    );

    try {
      var response = await request.send().timeout(
        const Duration(seconds: 60),
      );

      var res = await http.Response.fromStream(response);
      var data = jsonDecode(res.body);
      print("🟢 Backend response: ${res.body}");

      setState(() {
        if (data.containsKey('message')) {
          result = data['message'];
        } else {
          result = "❌ Invalid response from server";
        }
      });
    } catch (e) {
      print("❌ ERROR: $e");
      setState(() {
        // ✅ show the actual GPS error message if that's what failed
        result = e.toString().contains("GPS")
            ? "❌ ${e.toString().replaceAll('Exception: ', '')}"
            : "❌ Request failed (timeout or network issue)";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    captureAndSend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              result.isEmpty ? "Processing..." : result,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}