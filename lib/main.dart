import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/offer_repository.dart';
import 'services/settings_service.dart';
import 'state/offers_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<SettingsService>(create: (_) => SettingsService()),
        ChangeNotifierProvider<OffersProvider>(
          create: (_) => OffersProvider(OfferRepository())..load(),
        ),
      ],
      child: const OfferteAiApp(),
    ),
  );
}

class OfferteAiApp extends StatelessWidget {
  const OfferteAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2E7D32);
    return MaterialApp(
      title: 'Offerte AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
