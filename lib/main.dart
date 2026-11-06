import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ticket_loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFBFBF9),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const CoterieApp());
}

class CoterieApp extends StatelessWidget {
  const CoterieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coterie — Institute for Rare & Exact Diction',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBFBF9),
        fontFamily: 'PlusJakartaSans',
      ),
      home: const TicketLoadingScreen(),
    );
  }
}
