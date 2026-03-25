import 'package:flutter/material.dart';
import 'package:kgarage/servicesscreen.dart';
import 'MonthlyReportScre.dart';
import 'coustomer screen.dart';
import 'homescreen.dart';
import 'jobcard.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int index = 0;

  final screens = [
    const HomeScreen(),
    const CustomersScreen(),
    const ServicesScreen(),
    const MonthlyReportPage(),
    const JobCardScreen(),// 4th tab for monthly sales report
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        type: BottomNavigationBarType.fixed, // important for 4 tabs
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Bills'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: "Job Card"),
        ],
      ),
    );
  }
}
