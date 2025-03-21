import 'package:flutter/material.dart';
import 'package:mobile/screens/admin_profile_page.dart';
import 'package:mobile/screens/issuesRaised_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/screens/auth_screen.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/donation_screen.dart';
import 'package:mobile/screens/raiseIssue_screen.dart';
import 'package:mobile/screens/manuals_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/admin_home_screen.dart';
import 'package:mobile/services/api_service.dart'; // Added for fetching issues

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await EasyLocalization.ensureInitialized();

  final String initialRoute = await _determineInitialRoute();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
        Locale('or'),
        Locale('bn'),
      ],
      path: 'assets/translation',
      fallbackLocale: const Locale('en'),
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

Future<String> _determineInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final bool isAdminLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
  final bool isUserLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (isAdminLoggedIn) {
    return '/admin_home_screen';
  } else if (isUserLoggedIn) {
    return '/home_screen';
  } else {
    return '/auth_screen';
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aapda Mitra | NDRF',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        EasyLocalization.of(context)!.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Inter'),
          bodyMedium: TextStyle(fontFamily: 'Inter'),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/auth_screen': (context) => const AuthScreen(),
        '/home_screen': (context) => const HomeScreen(),
        '/donation_screen': (context) => const DonationPage(),
        '/raiseIssue_screen': (context) => const RaiseIssueScreen(),
        '/manuals_screen': (context) => const ManualsScreen(),
        '/profile_screen': (context) => ProfileScreen(),
        '/admin_home_screen': (context) => AdminHomeScreen(),
        '/admin_profile_screen': (context) => const AdminProfileScreen(),
        // Updated route for IssuesRaisedScreen
        '/issues_raised_screen': (context) => IssuesRaisedScreen(
           // Default empty list, will be fetched in the screen
        ),
      },
    );
  }
}