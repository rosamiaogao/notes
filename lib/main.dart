import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/note_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Required because we use async code (Hive) before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive, register the TypeAdapter and open the "notes" box.
  await NoteService.init();

  runApp(const NotesKeeperApp());
}

class NotesKeeperApp extends StatelessWidget {
  const NotesKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes Keeper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
