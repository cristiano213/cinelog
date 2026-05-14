import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[800]!],
            ),
          ),
          child: Row(
            children: [
             Hero(
                  tag: 'movie-hero-${movie.id}', // Deve essere lo stesso tag usato nel dettaglio
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    child: CachedNetworkImage(
                  imageUrl: movie.smallPosterUrl,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  memCacheWidth: 240,
                  placeholder: (context, url) => Container(
                    width: 80,
                    color: Colors.grey[900],
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    color: Colors.grey[850],
                    child: const Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              ),
             ),
              // PARTE TESTUALE (La tua struttura originale)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rating: ${movie.voteAverage} ⭐',
                        style: TextStyle(color: Colors.amber[700]),
                      ),
                      Text(
                        movie.formattedDuration,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}