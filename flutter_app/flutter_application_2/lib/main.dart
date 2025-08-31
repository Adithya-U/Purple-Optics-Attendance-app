import 'package:flutter/material.dart';
import 'screens/attendance_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: Colors.grey[100],
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: AppConstants.primaryColor,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Roboto',
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
      ),
      home: const AttendanceScreen(),
    );
  }
}
