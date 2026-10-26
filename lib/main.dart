import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for security UX consistency
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Stealth system UI — dark navigation bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF090A0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const CanaryApp());
}
