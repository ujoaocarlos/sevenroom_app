import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/theme_provider.dart';
import 'services/auth_services.dart';
import 'services/room_repository.dart';
import 'services/reservation_repository.dart';
import 'services/email_service.dart';
import 'services/user_repository.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/my_reservations_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SevenRoomApp());
}

class SevenRoomApp extends StatelessWidget {
  const SevenRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => RoomRepository()),
        Provider(create: (_) => ReservationRepository()),
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => EmailService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
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
                final args =
                    ModalRoute.of(context)!.settings.arguments as String?;
                return HomeScreen(userName: args ?? 'Usuário');
              },
              '/profile': (context) => const ProfileScreen(),
              '/my_reservations': (context) => const MyReservationsScreen(),
              '/rooms': (context) => const RoomsScreen(),
              '/schedule': (context) {
                final args = ModalRoute.of(context)!.settings.arguments;
                if (args is String) {
                  return ScheduleScreen(roomDocId: args);
                } else if (args is Map) {
                  final map = Map<String, dynamic>.from(args);
                  return ScheduleScreen(
                      roomDocId: map['roomDocId'] as String,
                      roomName: map['roomName'] as String?);
                } else {
                  return const Scaffold(
                      body: Center(child: Text('Sala não especificada')));
                }
              },
              '/admin': (context) => const AdminPanelScreen(),
            },
          );
        },
      ),
    );
  }
}
