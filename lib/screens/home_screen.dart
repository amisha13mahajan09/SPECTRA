import 'package:flutter/material.dart';
import 'dart:ui';
import 'today_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  late List<Widget> screens;

  @override
  void initState() {
    super.initState();

    screens = [
      TodayScreen(user: widget.user),
      StatsScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      /// ✅ SCREEN HANDLES ITS OWN BACKGROUND
      body: screens[currentIndex],

      bottomNavigationBar: ClipRRect(
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                selectedItemColor: Colors.black,
                unselectedItemColor: Colors.grey,
                iconSize: 32,
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Opacity(
                        opacity: 0.75,
                        child: Image.asset(
                          "assets/images/today.png",
                          height: 32,
                        ),
                      ),
                    ),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Opacity(
                        opacity: 0.75,
                        child: Image.asset(
                          "assets/images/stats.png",
                          height: 32,
                        ),
                      ),
                    ),
                    label: "",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}