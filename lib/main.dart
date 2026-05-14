import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_initialization_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CineLogApp(),
    ),
  );
}

class CineLogApp extends StatelessWidget {
  const CineLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
      ),
      home: const _InitializedApp(),
    );
  }
}

class _InitializedApp extends ConsumerWidget {
  const _InitializedApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(initializeAppProvider);

    return initAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Errore nell\'inizializzazione',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (_) => const MainNavigationScreen(),
    );
  }
}