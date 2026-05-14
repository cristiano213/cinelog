import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../widgets/register_cinema_visit_dialog.dart';

class MovieDetailScreen extends ConsumerWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                movie.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              background: Hero(
                tag: 'movie-hero-${movie.id}',
                child: Image.network(
                  movie.fullPosterUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.red.withValues(alpha: 0.3),
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildInfoBadge(Icons.star, '${movie.voteAverage}', Colors.amber),
                      const SizedBox(width: 10),
                      _buildInfoBadge(Icons.timer, movie.formattedDuration, Colors.blue),
                      const SizedBox(width: 10),
                      _buildInfoBadge(Icons.movie, movie.releaseYear, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Sinossi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    movie.overview,
                    style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  
                  // IL BOTTONE FINANCE (REGISTRA VISIONE)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.confirmation_number),
                      label: const Text('REGISTRA VISIONE', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => RegisterCinemaVisitDialog(
                            movie: movie,
                            onSuccess: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Lo spazio extra che avevi messo per lo scroll
                  const SizedBox(height: 500), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}