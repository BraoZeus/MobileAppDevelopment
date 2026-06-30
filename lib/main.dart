import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

import 'providers/study_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/project_provider.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProxyProvider<ProfileProvider, StudyProvider>(
          create: (_) => StudyProvider(),
          update: (_, profileProvider, studyProvider) {
            studyProvider!.setProfileProvider(profileProvider);
            return studyProvider;
          },
        ),
      ],
      child: const StudyWellApp(),
    ),
  );
}

// COLOUR PALETTE (shared between light & dark themes)
const _brandBlue = Color(0xFF334195);
const _brandNavy = Color(0xFF2D3142);

// LIGHT THEME
final ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _brandBlue,
    brightness: Brightness.light,
  ),
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: _brandBlue,
    ),
    iconTheme: IconThemeData(color: _brandNavy),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    indicatorColor: Color(0x26334195),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _brandBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: _brandBlue, width: 2),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFEEEEEE)),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

// DARK THEME
final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _brandBlue,
    brightness: Brightness.dark,
  ),
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: const Color(0xFF111318),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: Color(0xFF8FA8F8),
    ),
    iconTheme: IconThemeData(color: Color(0xFFE0E4FF)),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF1C1F2A),
    surfaceTintColor: Colors.transparent,
    indicatorColor: const Color(0xFF334195).withValues(alpha: 0.35),
    labelTextStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E2130),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4D5FD4),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF252840),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF3A3F5C)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF8FA8F8), width: 2),
    ),
    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF2C3050)),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    backgroundColor: const Color(0xFF252840),
    contentTextStyle: const TextStyle(color: Colors.white),
  ),
);

// APP ROOT
class StudyWellApp extends StatelessWidget {
  const StudyWellApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Study Well',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeProvider.themeMode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          if (!authSnapshot.hasData) {
            return const LoginScreen();
          }
          return Consumer<ProfileProvider>(
            builder: (context, profileProvider, _) {
              if (profileProvider.isLoading) return const _SplashScreen();
              if (!profileProvider.isOnboardingComplete) {
                return const OnboardingScreen();
              }
              return const MainLayout();
            },
          );
        },
      ),
    );
  }
}

/// Branded splash shown while Firebase / Firestore resolves.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111318)
          : const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_rounded,
              size: 64,
              color: isDark ? const Color(0xFF8FA8F8) : _brandBlue,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              color: isDark ? const Color(0xFF8FA8F8) : _brandBlue,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
