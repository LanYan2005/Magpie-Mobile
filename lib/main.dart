import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? preferences;
  try {
    preferences = await SharedPreferences.getInstance();
  } on Exception {
    // The demo remains usable if the platform preference store is unavailable.
  }
  runApp(MagpieApp(preferences: preferences));
}
