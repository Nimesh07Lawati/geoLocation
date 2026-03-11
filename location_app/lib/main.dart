import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location_app/screens/map_screens.dart';
import 'package:provider/provider.dart';
import 'providers/location_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationProvider(),
      child: MaterialApp(
        title: 'Location Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0D1117),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D4FF),
            surface: Color(0xFF161B22),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF161B22),
            contentTextStyle: TextStyle(color: Colors.white),
          ),
        ),
        home: const MapScreen(),
      ),
    );
  }
}
