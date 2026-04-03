import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:near_run/providers/run_provider.dart';
import 'package:near_run/screens/main_nav_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()),
      ],
      child: MaterialApp(
        title: 'NearRun',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: GoogleFonts.poppins().fontFamily,
          useMaterial3: true,
        ),
        home: const MainNavScreen(),
      ),
    );
  }
}