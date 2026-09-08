import 'package:flutter/material.dart';
import 'screens/tarif_selection_screen.dart';

void main() {
  runApp(const AquajexApp());
}

class AquajexApp extends StatelessWidget {
  const AquajexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catalogue Commercial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3B5F)),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const TarifSelectionScreen(),
    );
  }
}
