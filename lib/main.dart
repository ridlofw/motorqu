import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

import 'models/motorcycle.dart';
import 'ui/login_screen.dart';
import 'ui/home_screen.dart';
import 'ui/motor_detail_screen.dart';
import 'ui/add_motor_screen.dart';
import 'ui/add_oil_screen.dart';
import 'ui/group_screen.dart';
import 'ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotorQu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(notificationService: notificationService);
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) =>
            HomeScreen(notificationService: notificationService),
        '/motor': (context) {
          final moto = ModalRoute.of(context)!.settings.arguments as Motorcycle?;
          return MotorDetailScreen(motorcycle: moto!);
        },
        '/addMotor': (context) {
          final moto = ModalRoute.of(context)!.settings.arguments as Motorcycle?;
          return AddMotorScreen(moto: moto);
        },
        '/addOil': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String?;
          return AddOilScreen(preselectMotorId: id);
        },
        '/group': (context) => const GroupScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}