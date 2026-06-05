import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DefaulterScreen extends StatefulWidget {
  const DefaulterScreen({super.key});

  @override
  State<DefaulterScreen> createState() => _DefaulterScreenState();
}

class _DefaulterScreenState extends State<DefaulterScreen> {
  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDefaulters();
  }

  Future fetchDefaulters() async {
    var res = await http.get(
      Uri.parse("http://172.20.10.5:5001/defaulters"),
    );

    setState(() {
      data = jsonDecode(res.body);
      loading = false;
    });
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
            "Defaulter List",
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
              "assets/images/defaulterbg.png",
              fit: BoxFit.cover,
            ),
          ),

          loading
              ? const Center(child: CircularProgressIndicator())
              : buildTableUI(),
        ],
      ),
    );
  }

  Widget buildTableUI() {
    return SafeArea(
        child: Align(
          alignment: Alignment.topCenter, // 👈 KEY LINE
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 HEADER
              Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "PRN",
                      textAlign: TextAlign.center,
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
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Att.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(color: Colors.black26),

              // 🔹 DATA LIST (FIXED)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final d = data[index];

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              d['prn'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              d['name'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "${d['attendance']}%",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.black12),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
          ),
      ),
    );
  }
}