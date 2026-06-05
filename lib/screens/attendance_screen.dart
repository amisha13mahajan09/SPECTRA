import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceScreen extends StatefulWidget {
  final int subjectId;
  final String date;
  final String subjectName;

  const AttendanceScreen({
    super.key,
    required this.subjectId,
    required this.date,
    required this.subjectName,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List students = [];
  bool isLoading = true;
  bool isGenerated = true;

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    final res = await http.get(Uri.parse(
        "http://172.20.10.5:5001/slot_attendance?subject_id=${widget.subjectId}&date=${widget.date.split('T')[0]}"
    ));

    var data = jsonDecode(res.body);

    if (data is! List) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    bool generated = data.isNotEmpty;
    setState(() {
      students = data;
      isGenerated = generated;
      isLoading = false;
    });
  }

  Future<void> updateAttendance(int studentId, String newStatus) async {
    try {
      setState(() {
        isLoading = true;
      });

      final res = await http.post(
        Uri.parse("http://172.20.10.5:5001/update_attendance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "student_id": studentId,
          "subject_id": widget.subjectId,
          "date": widget.date.split('T')[0],
          "status": newStatus
        }),
      );

      if (res.statusCode == 200) {
        fetchAttendance();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showConfirmDialog(int studentId, String name, String current) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),

        title: const Text(
          "Change Attendance",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),

        content: Text(
          "Change attendance of $name?",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 16,
          ),
        ),

        actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

        actions: [
          TextButton(
            onPressed: () {
              updateAttendance(studentId, "Present");
              Navigator.pop(context);
            },
            child: const Text(
              "Present",
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.green,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              updateAttendance(studentId, "Absent");
              Navigator.pop(context);
            },
            child: const Text(
              "Absent",
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "Attendance List",
            style: TextStyle(
              fontSize: 30,
              fontFamily: 'Poly',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/attbg.png",
              fit: BoxFit.cover,
            ),
          ),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!isGenerated || students.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Attendance List\nNot Generated Yet",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            buildTableUI(),
        ],
      ),
    );
  }

  Widget buildTableUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // 🔹 HEADER ROW
              Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "PRN",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      "Name",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Att.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(color: Colors.black26),

              // 🔹 DATA LIST
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // PRN
                            Expanded(
                              flex: 3,
                              child: Text(
                                s['prn']?.toString() ?? "",
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),

                            // NAME
                            Expanded(
                              flex: 4,
                              child: Text(
                                s['name'] ?? "",
                                style: const TextStyle(color: Colors.black),
                                softWrap: true,
                              ),
                            ),

                            // ATTENDANCE
                            Expanded(
                              flex: 1,
                              child: GestureDetector(
                                onTap: () => showConfirmDialog(
                                    s['id'], s['name'], s['status']),
                                child: Text(
                                  s['status'] == "Present" ? "P" : "A",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: s['status'] == "Present"
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(color: Colors.black12),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
