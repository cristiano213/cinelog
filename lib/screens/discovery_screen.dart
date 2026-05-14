import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/movie_provider.dart';
import '../models/movie.dart';
import 'movie_detail_screen.dart';
import 'search_screen.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('CineLog'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategorySection(
                  title: 'Ora al Cinema',
                  category: MovieCategory.nowPlaying,
                ),
                _CategorySection(
                  title: 'Prossime Uscite',
                  category: MovieCategory.upcoming,
                ),
                _CategorySection(
                  title: 'I Grandi Cult',
                  category: MovieCategory.topRated,
                ),
                _GenreSection(title: 'Azione', genreId: 28),
                _GenreSection(title: 'Animazione', genreId: 16),
                _GenreSection(title: 'Commedia', genreId: 35),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category section ─────────────────────────────────────────────────────────

class _CategorySection extends ConsumerWidget {
  final String title;
  final MovieCategory category;

  const _CategorySection({required this.title, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(movieListProvider((category, 1)));
    return _CarouselSection(
      title: title,
      moviesAsync: moviesAsync,
      onSeeAll: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchScreen(
            initialCategory: category,
            sectionTitle: title,
          ),
        ),
      ),
    );
  }
}

// ─── Genre section ────────────────────────────────────────────────────────────

class _GenreSection extends ConsumerWidget {
  final String title;
  final int genreId;

  const _GenreSection({required this.title, required this.genreId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(genreMoviesProvider(genreId));
    return _CarouselSection(
      title: title,
      moviesAsync: moviesAsync,
      onSeeAll: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchScreen(
            initialGenreIds: [genreId],
            sectionTitle: title,
          ),
        ),
      ),
    );
  }
}

// ─── Shared carousel layout ───────────────────────────────────────────────────

class _CarouselSection extends StatelessWidget {
  final String title;
  final AsyncValue<List<Movie>> moviesAsync;
  final VoidCallback onSeeAll;

  const _CarouselSection({
    required this.title,
    required this.moviesAsync,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 8, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Text(
                  'Vedi tutti',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: moviesAsync.when(
            data: (movies) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: movies.length,
              itemBuilder: (context, index) =>
                  _MoviePosterCard(movie: movies[index]),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            ),
            error: (_, _) => const Center(
              child: Icon(Icons.cloud_off, color: Colors.grey, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Poster card ──────────────────────────────────────────────────────────────

class _MoviePosterCard extends StatelessWidget {
  final Movie movie;

  const _MoviePosterCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: movie.smallPosterUrl,
                  width: 120,
                  height: 170,
                  fit: BoxFit.cover,
                  memCacheWidth: 240,
                  placeholder: (_, _) => Container(
                    width: 120,
                    height: 170,
                    color: Colors.grey[900],
                  ),
                  errorWidget: (_, _, _) => Container(
                    width: 120,
                    height: 170,
                    color: Colors.grey[850],
                    child: const Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
            ),
            const SizedBox(height: 5),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
