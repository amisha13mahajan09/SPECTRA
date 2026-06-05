import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = "";

  Future<void> handleLogin() async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    setState(() {
      errorMessage = "";
    });

    if (username.isEmpty && password.isEmpty) {
      setState(() {
        errorMessage = "Please enter username and password";
      });
      return;
    } else if (username.isEmpty) {
      setState(() {
        errorMessage = "Username cannot be empty";
      });
      return;
    } else if (password.isEmpty) {
      setState(() {
        errorMessage = "Password cannot be empty";
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://172.20.10.5:5001/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "success") {
          var user = data["user"];

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login Successful"),
              duration: Duration(milliseconds: 600),
            ),
          );

          Future.delayed(const Duration(milliseconds: 600), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomeScreen(user: user),
              ),
            );
          });
        } else {
          setState(() {
            errorMessage = "Invalid username or password";
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Check server connection";
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
                  const Text("Login to",
                      style: TextStyle(
                          fontFamily: "Poly",
                          color: Color(0xFF1E3A5F),
                          fontStyle: FontStyle.italic,
                          fontSize: 18)),
                  const SizedBox(height: 5),
                  const Text("SPECTRA.",
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
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
                          controller: usernameController,
                          decoration: InputDecoration(
                            hintText: "Enter Username",
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
                            hintText: "Enter Password",
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
                          onTap: handleLogin,
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
                                    fontFamily: "Poly", // 🔧 added
                                    fontStyle: FontStyle.italic, // 🔧 added
                                  )),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF1E3A5F),
                        fontStyle: FontStyle.italic, // 🔧 added
                        fontSize: 16, // 🔧 increased
                      ),
                      children: [
                        const TextSpan(
                            text: "Don’t have an account yet? "),
                        TextSpan(
                          text: "Register",
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontStyle: FontStyle.italic, // 🔧 added
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Register1Page(),
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