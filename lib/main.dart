import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'providers/project_provider.dart';
import 'screens/login_screen.dart'; // <-- Imported your ACTUAL login screen!
import 'screens/projects_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: const StudyWellApp(),
    ),
  );
}

class StudyWellApp extends StatelessWidget {
  const StudyWellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Well',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF334195)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      // --- THE SECURITY GUARD ---
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If Firebase says we have a valid user session, go to the app
          if (snapshot.hasData) {
            return const MainLayout();
          }
          // Otherwise, show YOUR actual custom Login Screen
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ProjectsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF334195).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined, color: Colors.grey), selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF334195)), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.book_outlined, color: Colors.grey), selectedIcon: Icon(Icons.menu_book_rounded, color: Color(0xFF334195)), label: 'Study Plans'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined, color: Colors.grey), selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF334195)), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.folder_outlined, color: Colors.grey), selectedIcon: Icon(Icons.folder_rounded, color: Color(0xFF334195)), label: 'Projects'),
        ],
      ),
    );
  }
}