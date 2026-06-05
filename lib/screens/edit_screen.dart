import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditScreen extends StatefulWidget {
  final Map slot;
  final DateTime selectedDate;

  const EditScreen({
    super.key,
    required this.slot,
    required this.selectedDate,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  String? selectedOption;

  final List<Map<String, dynamic>> subjects = [
    {
      "name": "Data Structures and Algorithms",
      "code": "AD101T",
      "type": "T",
      "teacher": "Prof. Jyoti Kulkarni"
    },
    {
      "name": "Data Structures and Algorithms",
      "code": "AD101L",
      "type": "L",
      "teacher": "Prof. Jyoti Kulkarni"
    },
    {
      "name": "Database Management System",
      "code": "AD102T",
      "type": "T",
      "teacher": "Prof. Supriya Kapase"
    },
    {
      "name": "Database Management System",
      "code": "AD102L",
      "type": "L",
      "teacher": "Prof. Supriya Kapase"
    },
    {
      "name": "Applied Statistics Theory",
      "code": "AD103T",
      "type": "T",
      "teacher": "Prof. Kalpna Saharan"
    },
    {
      "name": "Engineering Design and Innovation",
      "code": "AD103L",
      "type": "L",
      "teacher": "Prof. Kalpna Saharan"
    },
    {
      "name": "Media Literacy and Critical Thinking",
      "code": "AD104L",
      "type": "L",
      "teacher": "Prof. Dhanshri Gore"
    },
    {
      "name": "Campus To Corporate",
      "code": "AD105L",
      "type": "L",
      "teacher": "Prof. Rishikesh Yeolekar"
    },
  ];

  int getSubjectId(String code) {
    switch (code) {
      case "AD101T":
        return 1;
      case "AD101L":
        return 2;
      case "AD102T":
        return 3;
      case "AD102L":
        return 4;
      case "AD103T":
        return 5;
      case "AD103L":
        return 6;
      case "AD104L":
        return 7;
      case "AD105L":
        return 8;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/editbg.png",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                // BACK BUTTON
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),

                // CENTER CONTENT (FIXED OVERFLOW SAFE)
                Center(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Change The Subject Of This Slot...",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // DROPDOWN (IMPROVED UI ONLY)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black26),
                            ),
                            child: DropdownButtonFormField<String>(
                              isExpanded: true, // ✅ ADD THIS LINE
                              value: selectedOption,
                              dropdownColor: Colors.white,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              hint: const Text("Select Subject"),
                              items: subjects.map((sub) {
                                String label =
                                    "${sub['name']} (${sub['type']}) ${sub['code']}";

                                return DropdownMenuItem(
                                  value: label,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width - 120,
                                    child: Text(
                                      label,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedOption = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // DONE BUTTON (BLACK + WHITE TEXT)
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () async {
                                if (selectedOption == null) return;

                                final selected = subjects.firstWhere(
                                      (sub) =>
                                  "${sub['name']} (${sub['type']}) ${sub['code']}" ==
                                      selectedOption,
                                );

                                await http.post(
                                  Uri.parse(
                                    "http://172.20.10.5:5001/update_slot_override",
                                  ),
                                  headers: {
                                    "Content-Type": "application/json"
                                  },
                                  body: jsonEncode({
                                    "date": widget.selectedDate
                                        .toIso8601String()
                                        .split('T')[0],
                                    "time_slot": widget.slot['time_slot'],
                                    "subject_id":
                                    getSubjectId(selected['code']),
                                  }),
                                );

                                Navigator.pop(context, true);
                              },
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Color(0xFF1E3A5F),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Text(
                                  "Done",
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}