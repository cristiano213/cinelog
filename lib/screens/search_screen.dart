import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';
import '../repositories/movie_repository.dart';
import 'movie_detail_screen.dart';

// ─── Genre catalogue ──────────────────────────────────────────────────────────

const _allGenres = [
  (label: 'Azione', id: 28),
  (label: 'Avventura', id: 12),
  (label: 'Animazione', id: 16),
  (label: 'Commedia', id: 35),
  (label: 'Crime', id: 80),
  (label: 'Documentario', id: 99),
  (label: 'Dramma', id: 18),
  (label: 'Fantasy', id: 14),
  (label: 'Horror', id: 27),
  (label: 'Famiglia', id: 10751),
  (label: 'Mistero', id: 9648),
  (label: 'Musica', id: 10402),
  (label: 'Romance', id: 10749),
  (label: 'Fantascienza', id: 878),
  (label: 'Thriller', id: 53),
  (label: 'Guerra', id: 10752),
  (label: 'Western', id: 37),
];

String _genreLabel(int id) =>
    _allGenres.firstWhere((g) => g.id == id, orElse: () => (label: '#$id', id: id)).label;

String _categoryLabel(MovieCategory c) => switch (c) {
      MovieCategory.nowPlaying => 'Ora al Cinema',
      MovieCategory.upcoming => 'Prossime Uscite',
      MovieCategory.topRated => 'I Grandi Cult',
      MovieCategory.trending => 'Trending',
    };

// ─── Paginated state ──────────────────────────────────────────────────────────

class SearchPageState {
  final List<Movie> movies;
  final int currentPage;
  final bool isLoading;
  final bool hasReachedMax;
  final String? error;
  final String query;
  final Set<int> genreIds;
  final MovieCategory? category;

  const SearchPageState({
    this.movies = const [],
    this.currentPage = 0,
    this.isLoading = false,
    this.hasReachedMax = false,
    this.error,
    this.query = '',
    this.genreIds = const {},
    this.category,
  });

  bool get hasActiveFilters =>
      query.isNotEmpty || genreIds.isNotEmpty || category != null;

  SearchPageState copyWith({
    List<Movie>? movies,
    int? currentPage,
    bool? isLoading,
    bool? hasReachedMax,
    String? error,
    bool clearError = false,
  }) =>
      SearchPageState(
        movies: movies ?? this.movies,
        currentPage: currentPage ?? this.currentPage,
        isLoading: isLoading ?? this.isLoading,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        error: clearError ? null : error ?? this.error,
        query: query,
        genreIds: genreIds,
        category: category,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SearchNotifier extends StateNotifier<SearchPageState> {
  SearchNotifier(this._repo) : super(const SearchPageState());

  final MovieRepository _repo;
  bool _initialized = false;
  int _generation = 0;

  void initialize({MovieCategory? category, List<int> genreIds = const []}) {
    if (_initialized) return;
    _initialized = true;
    state = SearchPageState(
      category: category,
      genreIds: genreIds.toSet(),
    );
    _loadNext();
  }

  void updateQuery(String q) {
    if (q == state.query) return;
    // text search: clear genre + category filters
    state = SearchPageState(query: q);
    _loadNext();
  }

  void toggleGenre(int id) {
    final next = Set<int>.from(state.genreIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    // genre pick: clear text, preserve category
    state = SearchPageState(genreIds: next, category: state.category);
    _loadNext();
  }

  void removeCategory() {
    state = SearchPageState(query: state.query, genreIds: state.genreIds);
    _loadNext();
  }

  Future<void> loadMore() => _loadNext();

  Future<void> _loadNext() async {
    if (state.isLoading || state.hasReachedMax) return;

    final gen = ++_generation;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final nextPage = state.currentPage + 1;
      final newMovies = await _fetch(nextPage);

      if (gen != _generation) return; // stale — filter changed mid-flight
      state = state.copyWith(
        movies: [...state.movies, ...newMovies],
        currentPage: nextPage,
        isLoading: false,
        hasReachedMax: newMovies.isEmpty,
      );
    } catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<Movie>> _fetch(int page) {
    final q = state.query;
    final genres = state.genreIds;
    final cat = state.category;

    if (q.isNotEmpty) return _repo.searchMovies(q, page: page);
    if (genres.isNotEmpty) return _repo.getMoviesByGenres(genres.toList(), page: page);
    if (cat != null) return _repo.getMoviesByCategory(cat, page: page);
    return _repo.getMoviesByCategory(MovieCategory.trending, page: page);
  }
}

final searchNotifierProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchPageState>(
  (ref) => SearchNotifier(ref.read(movieRepositoryProvider)),
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  final MovieCategory? initialCategory;
  final List<int> initialGenreIds;
  final String? sectionTitle;

  const SearchScreen({
    this.initialCategory,
    this.initialGenreIds = const [],
    this.sectionTitle,
    super.key,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _textCtrl;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
    _scrollCtrl.addListener(_onScroll);
    // Must defer: Riverpod forbids state mutation during the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchNotifierProvider.notifier).initialize(
        category: widget.initialCategory,
        genreIds: widget.initialGenreIds,
      );
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(searchNotifierProvider.notifier).loadMore();
    }
  }

  void _showGenrePicker() {
    final current = ref.read(searchNotifierProvider).genreIds;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GenrePickerSheet(
        selectedIds: current,
        onToggle: (id) =>
            ref.read(searchNotifierProvider.notifier).toggleGenre(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: _SearchField(
          controller: _textCtrl,
          onChanged: (q) {
            if (q.isNotEmpty) _textCtrl.text = q;
            ref.read(searchNotifierProvider.notifier).updateQuery(q);
          },
          onClear: () {
            _textCtrl.clear();
            ref.read(searchNotifierProvider.notifier).updateQuery('');
          },
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: state.genreIds.isNotEmpty,
              child: const Icon(Icons.tune),
            ),
            tooltip: 'Filtri genere',
            onPressed: _showGenrePicker,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.hasActiveFilters)
            _ActiveFiltersBar(
              state: state,
              onRemoveCategory: () =>
                  ref.read(searchNotifierProvider.notifier).removeCategory(),
              onRemoveGenre: (id) =>
                  ref.read(searchNotifierProvider.notifier).toggleGenre(id),
              onClearQuery: () {
                _textCtrl.clear();
                ref.read(searchNotifierProvider.notifier).updateQuery('');
              },
            ),
          Expanded(
            child: _ResultsList(state: state, scrollCtrl: _scrollCtrl),
          ),
        ],
      ),
    );
  }
}

// ─── Search field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: false,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.deepPurpleAccent,
      decoration: InputDecoration(
        hintText: 'Cerca un film...',
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[850],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

// ─── Active filter chips bar ──────────────────────────────────────────────────

class _ActiveFiltersBar extends StatelessWidget {
  final SearchPageState state;
  final VoidCallback onRemoveCategory;
  final ValueChanged<int> onRemoveGenre;
  final VoidCallback onClearQuery;

  const _ActiveFiltersBar({
    required this.state,
    required this.onRemoveCategory,
    required this.onRemoveGenre,
    required this.onClearQuery,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          if (state.query.isNotEmpty)
            _FilterTag(
              label: '"${state.query}"',
              onRemove: onClearQuery,
              color: Colors.blue[800]!,
            ),
          if (state.category != null)
            _FilterTag(
              label: _categoryLabel(state.category!),
              onRemove: onRemoveCategory,
              color: Colors.deepPurple[700]!,
            ),
          for (final id in state.genreIds)
            _FilterTag(
              label: _genreLabel(id),
              onRemove: () => onRemoveGenre(id),
              color: Colors.deepPurple[700]!,
            ),
        ],
      ),
    );
  }
}

class _FilterTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final Color color;

  const _FilterTag({
    required this.label,
    required this.onRemove,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
        onDeleted: onRemove,
        backgroundColor: color,
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

// ─── Genre picker bottom sheet ────────────────────────────────────────────────

class _GenrePickerSheet extends ConsumerWidget {
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  const _GenrePickerSheet({required this.selectedIds, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read live state so chips update without reopening sheet
    final liveIds = ref.watch(searchNotifierProvider).genreIds;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Filtra per genere',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final genre in _allGenres)
                    FilterChip(
                      label: Text(genre.label),
                      selected: liveIds.contains(genre.id),
                      onSelected: (_) => onToggle(genre.id),
                      backgroundColor: Colors.grey[800],
                      selectedColor: Colors.deepPurpleAccent,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: liveIds.contains(genre.id)
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 13,
                      ),
                      side: BorderSide.none,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Results list ─────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final SearchPageState state;
  final ScrollController scrollCtrl;

  const _ResultsList({required this.state, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    if (state.error != null && state.movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (!state.isLoading && state.movies.isEmpty) {
      return const Center(
        child: Text('Nessun risultato', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      itemCount: state.movies.length + (state.hasReachedMax ? 0 : 1),
      itemBuilder: (context, index) {
        if (index >= state.movies.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            ),
          );
        }
        return _SearchResultTile(movie: state.movies[index]);
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Movie movie;

  const _SearchResultTile({required this.movie});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: movie.smallPosterUrl,
          width: 48,
          height: 70,
          fit: BoxFit.cover,
          memCacheWidth: 144,
          placeholder: (_, _) =>
              Container(width: 48, height: 70, color: Colors.grey[900]),
          errorWidget: (_, _, _) => Container(
            width: 48,
            height: 70,
            color: Colors.grey[850],
            child: const Icon(Icons.broken_image, color: Colors.white54, size: 20),
          ),
        ),
      ),
      title: Text(
        movie.title,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${movie.voteAverage} ⭐',
        style: TextStyle(color: Colors.amber[700], fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
