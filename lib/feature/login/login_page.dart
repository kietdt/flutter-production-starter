/// Feature View Module
/// Responsibility: The main screen/page for the feature.
///
/// Glues together the state management and widgets.

import 'package:flutter/material.dart';
import 'widget/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(
        child: LoginForm(),
      ),
    );
  }
}
