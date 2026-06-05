import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class QRScreen extends StatefulWidget {
  final String qrData;
  final int slotNumber;
  final int subjectId;
  final String sessionDate;      // ✅ ADDED — the actual timetable date

  final String? subjectName;
  final String? subjectCode;
  final String? type;
  final String? timeSlot;

  const QRScreen({
    super.key,
    required this.qrData,
    required this.slotNumber,
    required this.subjectId,
    required this.sessionDate,   // ✅ ADDED
    this.subjectName,
    this.subjectCode,
    this.type,
    this.timeSlot,
  });

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {

  String getLocation(String? type) {
    if (type == "L") return "MB607";
    if (type == "T") return "AC304";
    return "-";
  }

  @override
  Widget build(BuildContext context) {
    String startTime = "";
    String endTime = "";

    if (widget.timeSlot != null && widget.timeSlot!.contains("-")) {
      var parts = widget.timeSlot!.split("-");
      startTime = parts[0];
      endTime = parts[1];
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/qrbg.png",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),

                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [

                          // TOP CARD
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Slot ${widget.slotNumber}",
                                  style: const TextStyle(
                                    fontFamily: "Poly",
                                    fontStyle: FontStyle.italic,
                                    fontSize: 24,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(child: timeBox(startTime)),
                                    const Icon(Icons.arrow_right_alt),
                                    Expanded(child: timeBox(endTime)),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Text(
                                    widget.subjectName != null
                                        ? "${widget.subjectName} (${widget.type})"
                                        : "No Subject",
                                    style: const TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 15,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: infoBox(
                                        "assets/images/cc.png",
                                        widget.subjectCode ?? "-",
                                        20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: infoBox(
                                        "assets/images/location.png",
                                        getLocation(widget.type),
                                        24,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // QR BOX
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: QrImageView(
                              data: widget.qrData,
                              version: QrVersions.auto,
                              size: 250,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // STOP BUTTON
                          SizedBox(
                            width: 290,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () async {
                                await http.post(
                                  Uri.parse("http://172.20.10.5:5001/qr/stop"),
                                  headers: {
                                    "Content-Type": "application/json"
                                  },
                                  body: jsonEncode({
                                    "subject_id": widget.subjectId,
                                    "date": widget.sessionDate,  // ✅ FIXED — was DateTime.now()
                                    "time_slot": widget.timeSlot,
                                  }),
                                );

                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Stop QR",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget timeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time, size: 16),
          const SizedBox(width: 6),
          Text(time),
        ],
      ),
    );
  }

  Widget infoBox(String imagePath, String text, double size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: size),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
