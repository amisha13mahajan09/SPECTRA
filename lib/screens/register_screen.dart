import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class Register1Page extends StatefulWidget {
  const Register1Page({super.key});

  @override
  State<Register1Page> createState() => _Register1PageState();
}

class _Register1PageState extends State<Register1Page> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController prnController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = "";

  Future<void> handleRegister() async {
    String name = nameController.text.trim();
    String prn = prnController.text.trim();
    String password = passwordController.text.trim();

    setState(() {
      errorMessage = "";
    });

    // ✅ validations
    if (name.isEmpty || prn.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "All fields are required";
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://172.20.10.5:5001/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": prn,
          "password": password,
          "name": name,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {

        // ✅ POPUP DIALOG
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Registration Successful"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  // 👉 Redirect to login
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text("OK"),
              )
            ],
          ),
        );

      } else {
        setState(() {
          errorMessage = data["message"];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Server error / connection failed";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              "assets/images/loginpagebg.png",
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.white.withOpacity(0.1)),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Register to",
                      style: TextStyle(
                          fontFamily: "Poly",
                          color: Color(0xFF1E3A5F),
                          fontStyle: FontStyle.italic,
                          fontSize: 18)),
                  const SizedBox(height: 5),
                  const Text("SPECTRA.",
                      style: TextStyle(
                          fontFamily: "Poppins",
                          color: Color(0xFF1E3A5F),
                          fontWeight: FontWeight.bold,
                          fontSize: 44)),
                  const SizedBox(height: 25),

                  // BOX
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Color(0xFF1E3A5F)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: "Enter Name",
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                        const SizedBox(height: 18),

                        TextField(
                          controller: prnController,
                          decoration: InputDecoration(
                            hintText: "Enter PRN (Username)",
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                        const SizedBox(height: 18),

                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Create Password",
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (errorMessage.isNotEmpty)
                          Text(errorMessage,
                              style: const TextStyle(color: Colors.red)),

                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: handleRegister,
                          child: Container(
                            height: 55,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xFF1E3A5F),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Center(
                              child: Text("Continue >>",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: "Poly",
                                    fontStyle: FontStyle.italic,
                                  )),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LOGIN REDIRECT
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF1E3A5F),
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                      children: [
                        const TextSpan(
                            text: "Already have an Account? "),
                        TextSpan(
                          text: "Login",
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}