import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/rooms_list_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/my_reservations_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  runApp(SevenRoomApp(isDarkMode: isDarkMode));
}

class SevenRoomApp extends StatefulWidget {
  final bool isDarkMode;
  const SevenRoomApp({super.key, required this.isDarkMode});

  @override
  State<SevenRoomApp> createState() => _SevenRoomAppState();
}

class _SevenRoomAppState extends State<SevenRoomApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void toggleTheme(bool value) async {
    setState(() => _isDarkMode = value);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SevenRoom',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return HomeScreen(userName: args);
        },
        '/rooms': (context) => const RoomsListScreen(),
        '/schedule': (context) => ScheduleScreen(
          roomId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/my_reservations': (context) => const MyReservationsScreen(),
        '/admin': (context) => const AdminPanelScreen(),
        '/profile': (context) => ProfileScreen(
          onThemeToggle: toggleTheme,
          currentDarkMode: _isDarkMode,
        ),
      },
    );
  }
}