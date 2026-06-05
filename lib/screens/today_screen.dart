import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'profile_screen.dart';
import 'qr_screen.dart'; // ✅ ADDED
import 'attendance_screen.dart';
import 'student_qr_screen.dart';
import 'edit_screen.dart';

class TodayScreen extends StatefulWidget {
  final Map user;

  const TodayScreen({super.key, required this.user});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime selectedDate = DateTime.now();
  List timetable = [];

  final PageController _pageController =
  PageController(viewportFraction: 0.9);

  Map<String, String> qrCache = {}; // ✅ ADDED

  @override
  void initState() {
    super.initState();
    fetchTimetable();
  }

  String getDayName(DateTime date) {
    return [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ][date.weekday - 1];
  }

  String formatDate(DateTime date) {
    return "${getDayName(date)}, ${date.day}/${date.month}/${date.year}";
  }

  Future<void> fetchTimetable() async {
    final dateStr = selectedDate.toIso8601String().split('T')[0];

    final response = await http.get(
      Uri.parse("http://172.20.10.5:5001/timetable?date=$dateStr"),
    );

    setState(() {
      timetable = jsonDecode(response.body);
    });
  }

  String getLocation(String type) {
    if (type == "L") return "MB607";
    if (type == "T") return "AC304";
    return "-";
  }

  @override
  Widget build(BuildContext context) {
    String day = getDayName(selectedDate);

    var allSlots = timetable;

    List todaySlots = List.generate(4, (index) {
      if (index < allSlots.length) {
        var slot = allSlots[index];

        if (widget.user['role'] == "student") {
          return slot;
        }

        if (widget.user['role'] == "teacher") {
          if (slot['teacher_code'] == widget.user['username']) {
            return slot;
          } else {
            return null;
          }
        }
      }
      return null;
    });

    bool isStudent = widget.user['role'] == "student";
    int totalSlots = 4;
    bool isHoliday = allSlots.isEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/images/todaybg.png",
            fit: BoxFit.cover,
          ),
        ),

        SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(
                                    user: widget.user),
                          ),
                        );
                      },
                      child: const CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: Opacity(
                            opacity: 0.6,
                            child: Image(
                              image: AssetImage("assets/images/profile.png"),
                              fit: BoxFit.cover,
                              width: 68,
                              height: 68,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      "Welcome Back,",
                      style: TextStyle(
                        fontFamily: "Poly",
                        fontStyle: FontStyle.italic,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.user['name'],
                      style: const TextStyle(
                        fontFamily: "Poly",
                        fontStyle: FontStyle.italic,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_left,
                          size: 30,
                          color: Color(0xFF0A1A3A)),
                      onPressed: () {
                        setState(() {
                          selectedDate = selectedDate.subtract(const Duration(days: 1));
                        });

                        fetchTimetable(); // ✅ ADD THIS LINE
                      },
                    ),
                    Text(
                      formatDate(selectedDate),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1A3A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_right,
                          size: 30,
                          color: Color(0xFF0A1A3A)),
                      onPressed: () {
                        setState(() {
                          selectedDate = selectedDate.add(const Duration(days: 1));
                        });

                        fetchTimetable(); // ✅ ADD THIS LINE
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                SizedBox(
                  height: 420,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: isHoliday ? 1 : totalSlots,
                    itemBuilder: (context, index) {
                      var slot =
                      index < todaySlots.length
                          ? todaySlots[index]
                          : null;

                      String startTime = "";
                      String endTime = "";

                      if (slot != null) {
                        var times =
                        slot['time_slot'].split("-");
                        startTime = times[0];
                        endTime = times[1];
                      }

                      if (isHoliday) {
                        return buildHolidayCard();
                      }

                      return buildSlotCard(
                          index, slot, startTime, endTime);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSlotCard(
      int index, var slot, String start, String end) {
    bool isTeacher = widget.user['role'] == "teacher";

    if (slot == null && isTeacher) {
      return Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black),
          ),
          child: const Center(
            child: Text(
              "No Subjects Allotted for this Slot",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6), // ✅ CHANGED HERE
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                "Slot ${index + 1}",
                style: const TextStyle(
                  fontFamily: "Poly",
                  fontStyle: FontStyle.italic,
                  fontSize: 26,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: timeBox(start)),
                Container(
                  width: 35,
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_right_alt,
                      size: 28),
                ),
                Expanded(child: timeBox(end)),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      slot != null
                          ? "${slot['subject_name']} (${slot['type']})"
                          : "No Subjects Allotted for this Slot",
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 15,
                      ),
                    ),
                  ),

                  // ✅ EDIT BUTTON (ONLY FOR TEACHER)
                  if (widget.user['role'] == "teacher" && slot != null)
                    GestureDetector(
                      onTap: () async {
                        final updatedSlot = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditScreen(
                              slot: slot,
                              selectedDate: selectedDate,
                            ),
                          ),
                        );

                        if (updatedSlot == true) {
                          fetchTimetable();
                        }
                      },
                      child: Container(
                        height: 38,
                        width: 45, // ✅ increased width only
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7), // smoother corners
                          border: Border.all(
                            color: Colors.black.withOpacity(0.7), // cleaner border look
                            width: 1.2,
                          ),
                          color: Colors.white, // helps remove “dirty” border look
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            "assets/images/edit.png",
                            fit: BoxFit.cover, // better than cover for icons
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: expandedBox(
                        "assets/images/cc.png",
                        slot?['subject_code'] ?? "-",
                        20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: expandedBox(
                        "assets/images/location.png",
                        slot != null
                            ? getLocation(slot['type'])
                            : "-",
                        28),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            isTeacher
                ? Row(
              children: [
                buildButton("assets/images/qr.png", true,
                    slot: slot, index: index),
                const Spacer(),
                buildButton("assets/images/att.png", false,
                    slot: slot, index: index),
              ],
            )
            // AFTER
                : Row(
              children: [
                Expanded(
                  child: Text(
                    slot != null ? "~ ${slot['teacher_name']}" : "",
                    style: const TextStyle(
                      fontFamily: "Poly",
                      fontStyle: FontStyle.italic,
                      fontSize: 20,
                    ),
                  ),
                ),
                buildButton("assets/images/qr.png", true, slot: slot, index: index),  // ← pass slot!
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String imagePath, bool isQR,
      {var slot, int? index}) {
    return GestureDetector(
      onTap: () async {
        // ✅ TEACHER QR
        if (isQR &&
            widget.user['role'] == "teacher" &&
            slot != null) {

          String qrData =
              "SUB:${slot['subject_id']}|TIME:${slot['time_slot']}|DATE:${selectedDate.toIso8601String()}";

          // 🔴 START QR SESSION
          await http.post(
            Uri.parse("http://172.20.10.5:5001/qr/start"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "subject_id": slot['subject_id'],
              "date": selectedDate.toIso8601String().split('T')[0],
              "time_slot": slot['time_slot']
            }),
          );

          // ✅ NEW CODE — add subjectId: slot['subject_id']
          // ✅ REPLACE the QRScreen navigator block with this
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QRScreen(
                qrData: qrData,
                slotNumber: index! + 1,
                subjectId: slot['subject_id'],
                sessionDate: selectedDate.toIso8601String().split('T')[0],  // ✅ ADDED
                subjectName: slot['subject_name'],
                subjectCode: slot['subject_code'],
                type: slot['type'],
                timeSlot: slot['time_slot'],
              ),
            ),
          );
        }

        // ✅ STUDENT QR
        else if (isQR && widget.user['role'] == "student") {
          // slot here is the slot card the student tapped on
          final String? expectedTimeSlot = slot?['time_slot'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentQRScreen(
                studentId: widget.user['id'],
                expectedTimeSlot: expectedTimeSlot, // ✅ pass the slot
              ),
            ),
          );
        }

        // ✅ ATTENDANCE
        else if (!isQR &&
            widget.user['role'] == "teacher" &&
            slot != null) {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceScreen(
                subjectId: slot['subject_id'],
                subjectName: slot['subject_name'],
                date: selectedDate.toIso8601String(),
              ),
            ),
          );
        }
      },
      child: Container(
        width: 125,
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Image.asset(
          imagePath,
          height: isQR ? 65 : 55,
        ),
      ),
    );
  }

  Widget buildHolidayCard() {
    return Container(
      margin:
      const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius:
        BorderRadius.circular(30),
        border: Border.all(color: Colors.black),
      ),
      child: const Center(
        child: Text(
          "Holiday.\nNo Subjects Allotted for Today.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget timeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius:
        BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time, size: 16),
          const SizedBox(width: 6),
          Text(time),
        ],
      ),
    );
  }

  Widget expandedBox(
      String icon, String text, double iconSize) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Image.asset(icon, height: iconSize),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}