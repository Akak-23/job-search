import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../providers/favorites_provider.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/job_card_refactored.dart';

/// Screen for displaying favorite job listings
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesProvider _favoritesProvider;

  @override
  void initState() {
    super.initState();
    _favoritesProvider = FavoritesProvider();
    _favoritesProvider.addListener(_onFavoritesChanged);
    _loadFavorites();
  }

  @override
  void dispose() {
    _favoritesProvider.removeListener(_onFavoritesChanged);
    _favoritesProvider.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    await _favoritesProvider.loadFavorites();
  }

  void _onFavoritesChanged() {
    setState(() {});
  }

  Future<void> _removeFavorite(Map<String, String> job) async {
    await _favoritesProvider.removeFavorite(job);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Jobs'),
        elevation: 0,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_favoritesProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_favoritesProvider.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.favorite_border,
        title: 'No Favorites Yet',
        message: 'Save jobs you like by tapping the heart icon.\nThey\'ll appear here for easy access.',
        iconColor: AppColors.primary,
        action: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Browse Jobs'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.padding),
      itemCount: _favoritesProvider.favorites.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final job = _favoritesProvider.favorites[index];
        return JobCardRefactored(
          title: job['title'] ?? '',
          description: job['description'] ?? '',
          job: job,
          refnr: job['refnr'],
          isFavorited: true,
          onFavoriteChanged: (isFav) {
            if (!isFav) _removeFavorite(job);
          },
        );
      },
    );
  }
}
