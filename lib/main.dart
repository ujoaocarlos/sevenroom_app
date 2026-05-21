import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
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
  
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  
  runApp(
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => themeProvider,
      child: const SevenRoomApp(),
    ),
  );
}

class SevenRoomApp extends StatelessWidget {
  const SevenRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SevenRoom',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
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
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}
