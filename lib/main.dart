import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'feature/login/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
