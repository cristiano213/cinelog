import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(appStatsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Dashboard Finanziario'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatCard("Totale Speso", stats.formattedTotalSpent, Colors.green, isLarge: true),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildStatCard("Film Visti", stats.totalMoviesSeen.toString(), Colors.blue)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("Media Biglietto", stats.formattedAvgTicket, Colors.amber)),
              ],
            ),
            const SizedBox(height: 20),
            if (stats.favoriteCinema != null)
              _buildStatCard("Cinema Preferito", stats.favoriteCinema!, Colors.deepPurpleAccent),
            const SizedBox(height: 20),
            _buildStatCard("Voto Medio", '${stats.avgUserRating.toStringAsFixed(1)}/10', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, {bool isLarge = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLarge ? 30 : 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        gradient: isLarge ? LinearGradient(colors: [Colors.grey[900]!, color.withValues(alpha: 0.1)]) : null,
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontSize: isLarge ? 32 : 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}