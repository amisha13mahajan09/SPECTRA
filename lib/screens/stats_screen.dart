import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'defaulter_screen.dart';

class StatsScreen extends StatefulWidget {
  final Map user;

  const StatsScreen({super.key, required this.user});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map studentData = {};
  List teacherData = [];
  bool loading = true;

  int currentDayIndex = 0;
  List dailyList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future fetchData() async {
    String id = widget.user['id'].toString();
    String role = widget.user['role'];

    String url = role == 'teacher'
        ? "http://172.20.10.5:5001/teacher_analytics/$id"
        : "http://172.20.10.5:5001/student_analytics/$id";

    var res = await http.get(Uri.parse(url));
    var decoded = jsonDecode(res.body);

    setState(() {
      if (role == 'teacher') {
        teacherData = decoded;
      } else {
        studentData = decoded;
        dailyList = decoded['daily_list'] ?? [];

        if (dailyList.isNotEmpty) {
          currentDayIndex = dailyList.length - 1; // 👈 THIS is the fix
        }
      }
      loading = false;
    });
  }

  // ================= CARD =================
  Widget card(Widget child) {
    return Container(
      height: 200, // 👈 SET THIS (adjust as you like)
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10.withOpacity(0.8),
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.2),
            offset: Offset(3, 4),
          )
        ],
      ),
      child: child,
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/statsbg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: loading
            ? Center(child: CircularProgressIndicator())
            : SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              Text(
                "Attendance Statistics",
                style: TextStyle(
                  fontFamily: "Poly",
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Color(0xFF0A0F2C),
                ),
              ),
              SizedBox(
                height: 500,
                child: PageView(
                  controller: PageController(viewportFraction: 0.95), // 👈 ADD THIS
                  children: widget.user['role'] == 'teacher'
                      ? teacherCards()
                      : studentCards(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ================= STUDENT =================
  List<Widget> studentCards() {
    return [
      overallCard(),
      dailyCard(),
      weeklyCard(),
      monthlyCard(),
      subjectTableCard(),
    ];
  }

  // ================= OVERALL =================
  Widget overallCard() {
    var o = studentData['overall'];

    return card(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Overall Attendance",
            style: TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 26),
          ),
          SizedBox(height: 10),
          SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PIE CHART
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: (o['present_pct'] ?? 0).toDouble(),
                        color: Color(0xFF2D531A),
                        title: "",                 // 👈 ADD THIS
                        titleStyle: TextStyle(fontSize: 0), // 👈 ADD THIS
                      ),
                      PieChartSectionData(
                        value: (o['absent_pct'] ?? 0).toDouble(),
                        color: Color(0xFF9A0002),
                        title: "",                 // 👈 ADD THIS
                        titleStyle: TextStyle(fontSize: 0), // 👈 ADD THIS
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 20),

              // TEXT ON SIDE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Color(0xFF2D531A),
                      ),
                      SizedBox(width: 6),
                      Text("Present: ${o['present_pct']}%"),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Color(0xFF9A0002),
                      ),
                      SizedBox(width: 6),
                      Text("Absent: ${o['absent_pct']}%"),
                    ],
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  // ================= DAILY =================
  Widget dailyCard() {
    if (dailyList.isEmpty) {
      return card(Center(child: Text("No Data")));
    }

    int safeIndex = currentDayIndex;

// 👇 If something goes wrong, force latest
    if (safeIndex < 0 || safeIndex >= dailyList.length) {
      safeIndex = dailyList.length - 1;
    }

    var d = dailyList[safeIndex];

    int present =
        d['slots'].where((s) => s == "Present").length;
    int absent = 4 - present;
    double percent = (present / 4) * 100;

    return card(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔥 HEADING → POPPINS BOLD
          Text(
            "Daily Attendance",
            style: TextStyle(
              color: Color(0xFFCF7381),
              fontWeight: FontWeight.bold,
              fontSize: 26,
              fontFamily: "Poppins", // 👈 changed
            ),
          ),

          SizedBox(height: 10),

          // 🔥 DATE + ARROWS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left, size: 30),
                onPressed: safeIndex > 0
                    ? () => setState(() => currentDayIndex = safeIndex - 1)
                    : null,
              ),

              // 🔥 DATE → POPPINS BOLD
              Text(
                d['date'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: "Poppins", // 👈 changed
                ),
              ),

              IconButton(
                icon: Icon(Icons.arrow_right, size: 30),
                onPressed: safeIndex < dailyList.length - 1
                    ? () => setState(() => currentDayIndex = safeIndex + 1)
                    : null,
              ),
            ],
          ),

          SizedBox(height: 12),

          // 🔥 INNER BOX
          Container(
            padding: EdgeInsets.all(14),
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...List.generate(4, (i) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Slot ${i + 1}  ",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: "Poly",
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        d['slots'][i] == "Present" ? "✅" : "❌",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  );
                }),

                Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Present: $present",
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: "Poly",
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          "Absent: $absent",
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: "Poly",
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),

                    // 🔥 % → POPPINS BOLD
                    Text(
                      "${percent.toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: Color(0xFFCF7381),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: "Poppins", // 👈 changed
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ================= WEEKLY =================
  Widget weeklyCard() {
    var w = studentData['weekly'];

    List days = ["Mon", "Tue", "Wed", "Thu", "Fri"];
    List values =
    days.map((d) => (w[d] ?? 0).toDouble()).toList();

    return card(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,   // 👈 vertical center
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Weekly Attendance",
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 26)),
          SizedBox(height: 25),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: 100,
                titlesData: FlTitlesData(
                  // ❌ REMOVE TOP NUMBERS
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  // ❌ REMOVE RIGHT NUMBERS
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  // ✅ LEFT → ONLY % VALUES
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20, // 👈 0,20,40,60,80,100
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}",
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),

                  // ✅ BOTTOM → DAYS
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        return Text(days[value.toInt()]);
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(values.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        width: 18,
                        color: Colors.blue,
                      )
                    ],
                  );
                }),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ================= MONTHLY =================
  Widget monthlyCard() {
    var m = studentData['monthly'];

    List months = ["Jan", "Feb", "Mar", "Apr"];
    List values =
    months.map((mth) => (m[mth] ?? 0).toDouble()).toList();

    return card(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,   // 👈 vertical center
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Monthly Attendance",
              style: TextStyle(
                  color: Color(0xFFE9B957),
                  fontWeight: FontWeight.bold,
                  fontSize: 26)),
          SizedBox(height: 25),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                titlesData: FlTitlesData(
                  // ❌ REMOVE TOP NUMBERS
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  // ❌ REMOVE RIGHT NUMBERS
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  // ✅ LEFT → CLEAN % SCALE
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}",
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),

                  // ✅ BOTTOM → MONTHS ONLY
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        return Text(
                          months[value.toInt()],
                          style: TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      values.length,
                          (i) =>
                          FlSpot(i.toDouble(), values[i]),
                    ),
                    isCurved: true,
                    color: Color(0xFFE9B957),
                    dotData: FlDotData(show: true),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // ================= TABLE =================
  Widget subjectTableCard() {
    List subjects = studentData['subjects'];

    // ✅ CALCULATE TOTALS
    int totalHeld = 0;
    int totalPresent = 0;
    int totalAbsent = 0;

    for (var s in subjects) {
      totalHeld += s['total'] as int;
      totalPresent += s['present'] as int;
      totalAbsent += s['absent'] as int;
    }

    double totalPercent =
    totalHeld == 0 ? 0 : (totalPresent / totalHeld) * 100;

    return card(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Subject Wise Attendance",
            style: TextStyle(
              color: Color(0xFFADACB5),
              fontWeight: FontWeight.bold,
              fontSize: 22, // 🔽 reduced
            ),
          ),
          SizedBox(height: 25),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Table(
                // ✅ CONTROL COLUMN WIDTHS
                columnWidths: const {
                  0: FlexColumnWidth(2), // Subject wider
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1.4),
                },

                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.black),
                  verticalInside: BorderSide(color: Colors.black),
                ),
                children: [
                  // ✅ HEADER
                  TableRow(children: [
                    cell("Subject", bold: true),
                    cell("Held", bold: true),
                    cell("P", bold: true),
                    cell("A", bold: true),
                    cell("%", bold: true),
                  ]),

                  // ✅ DATA ROWS
                  ...subjects.map((s) {
                    return TableRow(children: [
                      cell(s['subject']),
                      cell("${s['total']}"),
                      cell("${s['present']}"),
                      cell("${s['absent']}"),
                      cell("${s['percentage']}%"),
                    ]);
                  }).toList(),

                  // ✅ TOTAL ROW
                  TableRow(children: [
                    cell("TOTAL", bold: true),
                    cell("$totalHeld", bold: true),
                    cell("$totalPresent", bold: true),
                    cell("$totalAbsent", bold: true),
                    cell("${totalPercent.toStringAsFixed(2)}%", bold: true),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// ================= CELL =================
  Widget cell(String text, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), // 🔽 reduced
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1, // ✅ prevents overflow
        overflow: TextOverflow.ellipsis, // ✅ adds ...
        softWrap: false,
        style: TextStyle(
          fontSize: 13, // 🔽 reduced
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // ================= TEACHER =================
  // ================= TEACHER =================
  List<Widget> teacherCards() {
    List<Widget> cards = teacherData.map((t) {
      return card(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // SUBJECT NAME
            Text(
              t['subject_name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: "Poppins",
              ),
            ),

            SizedBox(height: 8),

            // COURSE CODE
            Text(
              "Code: ${t['subject_code']}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontFamily: "Poppins",
              ),
            ),

            SizedBox(height: 20),

            // TOTAL CLASSES
            Text(
              "${t['total']}",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A0F2C),
                fontFamily: "Poppins",
              ),
            ),

            SizedBox(height: 6),

            Text(
              "Classes Held",
              style: TextStyle(
                fontSize: 18,
                fontFamily: "Poppins",
              ),
            ),
          ],
        ),
      );
    }).toList();

    cards.add(
      card(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              "View Students List with Attendance < 75%",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF0A0F2C),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A0F2C),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DefaulterScreen(),
                  ),
                );
              },
              child: Text(
                "Defaulter",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC9C2B2),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return cards;
  }
}