import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'selfie_screen.dart';

class StudentQRScreen extends StatefulWidget {
  final int studentId;
  final String? expectedTimeSlot;

  const StudentQRScreen({
    super.key,
    required this.studentId,
    this.expectedTimeSlot,
  });

  @override
  State<StudentQRScreen> createState() => _StudentQRScreenState();
}

class _StudentQRScreenState extends State<StudentQRScreen> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        controller: _controller,
        onDetect: (barcodeCapture) {
          if (_isNavigating) return;

          final barcodes = barcodeCapture.barcodes;

          if (barcodes.isNotEmpty) {
            final qrData = barcodes.first.rawValue;

            if (qrData != null) {

              if (widget.expectedTimeSlot != null) {
                String? scannedTimeSlot;
                try {
                  for (var part in qrData.split("|")) {
                    final kv = part.split(":");
                    if (kv[0] == "TIME") {
                      scannedTimeSlot = kv.sublist(1).join(":");
                      break;
                    }
                  }
                } catch (_) {}

                print("🔍 Expected slot: ${widget.expectedTimeSlot}");
                print("🔍 Scanned slot:  $scannedTimeSlot");
                print("🔍 Full QR data:  $qrData");

                if (scannedTimeSlot == null ||
                    scannedTimeSlot != widget.expectedTimeSlot) {

                  _isNavigating = true; // ✅ block re-triggers immediately

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Wrong QR! Please scan the QR for your current slot."),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );

                  // ✅ re-enable scanning after snackbar disappears
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _isNavigating = false;
                      });
                    }
                  });

                  return;
                }
              } else {
                print("⚠️ expectedTimeSlot is NULL — slot check skipped entirely");
              }

              _isNavigating = true;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SelfieScreen(
                    qrData: qrData,
                    studentId: widget.studentId,
                    expectedTimeSlot: widget.expectedTimeSlot,
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}