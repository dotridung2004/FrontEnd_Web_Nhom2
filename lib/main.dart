import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // <-- Dòng quan trọng: Nhập tệp màn hình

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TLU Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Bạn có thể thêm font chữ ở đây nếu muốn
        // fontFamily: 'YourCustomFont',
      ),
      // Sử dụng LoginScreen được nhập từ tệp 'screens/login_screen.dart'
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

