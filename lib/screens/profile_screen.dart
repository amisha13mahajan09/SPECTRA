import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String displayedText = "";
  final String fullText = "SPECTRA";

  @override
  void initState() {
    super.initState();
    startTyping();
  }

  void startTyping() async {
    while (true) {
      for (int i = 0; i < fullText.length; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          displayedText = fullText.substring(0, i + 1);
        });
      }

      await Future.delayed(const Duration(milliseconds: 600));

      for (int i = fullText.length; i > 0; i--) {
        await Future.delayed(const Duration(milliseconds: 60));
        setState(() {
          displayedText = fullText.substring(0, i - 1);
        });
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse("http://YOUR_MAC_IP:5001/logout"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.user['id'],
        }),
      );

      print("Logout response: ${response.body}");

    } catch (e) {
      print("Logout error: $e");
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
    );
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Confirm Logout",
            style: TextStyle(
              fontFamily: 'Poly',
              fontStyle: FontStyle.italic,
            ),
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              fontFamily: 'Poly',
              fontStyle: FontStyle.italic,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3A5F),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "NO",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poly',
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3A5F),
              ),
              onPressed: () {
                Navigator.pop(context);
                logout();
              },
              child: const Text(
                "YES",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poly',
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showAboutDialogBox() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "About the Creators",
            style: TextStyle(
              fontFamily: 'Poly',
              fontStyle: FontStyle.italic,
            ),
          ),
          content: const Text(
            "SPECTRA (Smart Presence Evaluation and Classroom Tracking Recognition Architecture) is an innovative attendance management application that integrates QR code scanning, geofencing, and facial recognition to ensure accurate and efficient tracking of student presence. Designed to streamline classroom attendance processes, SPECTRA enhances reliability while minimizing manual effort. This project was developed by Amisha Mahajan, Aryan Bhosale, Maithily Tembhurne, and Pranav Borse from AD2, AIDS Department, MMCOE.",
            style: TextStyle(
              fontFamily: 'Poly',
              fontStyle: FontStyle.italic,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(
                  fontFamily: 'Poly',
                  color: Color(0xFF1E3A5F),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    List<String> subjects = [
      "Data Structures and Algorithms (T)",
      "Data Structures and Algorithms (L)",
      "Database Management System (T)",
      "Database Management System (L)",
      "Applied Statistics Theory (T)",
      "Engineering Design and Innovation (L)",
      "Media Literacy and Critical Thinking (L)",
      "Campus To Corporate (L)",
    ];

    if (widget.user['role'] == 'teacher') {
      String teacherName = widget.user['name'];

      Map<String, List<String>> teacherSubjectsMap = {
        "Prof. Jyoti Kulkarni": [
          "Data Structures and Algorithms (T)",
          "Data Structures and Algorithms (L)",
        ],
        "Prof. Supriya Kapase": [
          "Database Management System (T)",
          "Database Management System (L)",
        ],
        "Prof. Kalpna Saharan": [
          "Applied Statistics Theory (T)",
          "Engineering Design and Innovation (L)",
        ],
        "Prof. Dhanshri Gore": [
          "Media Literacy and Critical Thinking (L)",
        ],
        "Prof. Rishikesh Yeolekar": [
          "Campus To Corporate (L)",
        ],
      };

      subjects = teacherSubjectsMap[teacherName] ?? [];
    }

    Map<String, String> subjectCodes = {
      "Data Structures and Algorithms (T)": "CS201",
      "Data Structures and Algorithms (L)": "CS202",
      "Database Management System (T)": "CS203",
      "Database Management System (L)": "CS204",
      "Applied Statistics Theory (T)": "MA201",
      "Engineering Design and Innovation (L)": "ED202",
      "Media Literacy and Critical Thinking (L)": "HS201",
      "Campus To Corporate (L)": "HS202",
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/profilebg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.only(left: 10, right: 30, top: 10, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),

                    Row(
                      children: [
                        Text(
                          displayedText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Opacity(
                          opacity: 0.7,
                          child: const CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage('assets/images/profile.png'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// ✅ ABOUT BUTTON FIXED
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Opacity(
                        opacity: 0.7,
                        child: SizedBox(
                          width: 220,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            onPressed: showAboutDialogBox,
                            child: const Text(
                              "ABOUT THE CREATORS",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              /// ✅ PROFILE TEXT FIXED (NO BOX, WHITE TEXT)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        widget.user['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Poly',
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Department of Artificial Intelligence and Data Science",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poly',
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        widget.user['username'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 45),

              /// SUBJECT GRID (UNCHANGED)
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subjects.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    String subject = subjects[index];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            subject,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subjectCodes[subject] ?? "N/A",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                child: Opacity(
                  opacity: 0.7,
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: showLogoutDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "LOGOUT",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}