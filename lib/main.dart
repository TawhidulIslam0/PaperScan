import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'services/document_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DocumentStore.instance.init();
  runApp(const PaperScanApp());
}

class PaperScanApp extends StatefulWidget {
  const PaperScanApp({super.key});
  @override State<PaperScanApp> createState() => _PaperScanAppState();
}
class _PaperScanAppState extends State<PaperScanApp> {
  bool dark = false;
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'PaperScan', debugShowCheckedModeBanner: false,
    theme: AppTheme.light, darkTheme: AppTheme.dark,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: HomeScreen(onThemeChanged: (v) => setState(() => dark = v), darkMode: dark),
  );
}
