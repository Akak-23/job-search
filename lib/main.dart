import 'package:flutter/material.dart';
import 'constants/app_theme.dart';
import 'services/notification_service.dart';
import 'services/saved_search_notifications_service.dart';
import 'services/onboarding_service.dart';
import 'screens/jobs_screen_refactored.dart';
import 'screens/resume_screen_refactored.dart';
import 'screens/application_manager_screen_refactored.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Search',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _navigationDuration = Duration(milliseconds: 300);
  static const _jobsTabIndex = 0;

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _showOnboarding = false;

  late final List<Widget> _screens;
  late final PageController _pageController;
  final GlobalKey<JobsScreenRefactoredState> _jobsScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _screens = _buildScreens();
    _initNotifications();
    _checkOnboarding();
  }

  /// Check if user needs to see onboarding
  Future<void> _checkOnboarding() async {
    final hasCompleted = await OnboardingService.hasCompletedOnboarding();
    setState(() {
      _showOnboarding = !hasCompleted;
      _isLoading = false;
    });
  }

  /// Complete onboarding and show main app
  void _completeOnboarding() {
    setState(() {
      _showOnboarding = false;
    });
  }

  /// Builds the list of screens for navigation
  List<Widget> _buildScreens() => <Widget>[
    JobsScreenRefactored(key: _jobsScreenKey),
    ApplicationManagerScreenRefactored(onNavigateToJobs: navigateToJobs),
    const ResumeScreenRefactored(),
  ];

  /// Initializes notifications in the background
  void _initNotifications() {
    NotificationService.init().then((_) {
      SavedSearchNotificationsService.checkAndNotifyAll();
    });
  }

  /// Public method to navigate to the jobs tab
  void navigateToJobs() {
    _selectTab(_jobsTabIndex);
  }

  /// Selects a tab by index and updates the page view
  void _selectTab(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: _navigationDuration,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while checking onboarding status
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    // Show onboarding flow if not completed
    if (_showOnboarding) {
      return OnboardingFlowScreen(onComplete: _completeOnboarding);
    }

    // Show main app
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
            // Refresh favorites when navigating to jobs screen
            if (index == _jobsTabIndex) {
              _jobsScreenKey.currentState?.refreshFavorites();
            }
          },
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  /// Builds the bottom navigation bar
  Widget _buildNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Resume',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: _selectTab,
      ),
    );
  }
}
