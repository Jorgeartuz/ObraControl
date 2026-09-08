import 'package:flutter/material.dart';
import '../features/home/presentation/pages/home_page.dart';

class ObraControlApp extends StatelessWidget {
  const ObraControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ObraControl',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
      home: const HomePage(),
    );
  }
}