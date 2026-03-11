import 'package:flutter/material.dart';
import 'package:location_app/screens/map_screens.dart';
import 'package:provider/provider.dart';
import 'providers/location_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const MapScreen(),
      ),
    );
  }
}
