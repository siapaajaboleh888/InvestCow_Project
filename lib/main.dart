import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:investcow_app/screens/home_page.dart';
import 'package:investcow_app/screens/pasar_modal_page.dart';
import 'package:investcow_app/screens/kunjungan_page.dart';
import 'package:investcow_app/screens/akun_page.dart';
import 'package:investcow_app/screens/login_page.dart';
import 'package:investcow_app/services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientasi portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InvestCow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
      ),
      home: const CustomSplashScreen(),
    );
  }
}

// ✅ CUSTOM SPLASH SCREEN dengan Login Check
class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Setup animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate setelah 3 detik dengan check login
    _initialize();
  }

  Future<void> _initialize() async {
    // Delay splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check login status
    final isLoggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    // Navigate berdasarkan status login
    if (isLoggedIn) {
      // Jika sudah login, langsung ke MainScreen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      // Jika belum login, ke LoginPage
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[700],
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.trending_up,
                  size: 60,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(height: 30),
              // App Name
              const Text(
                'InvestCow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              // Tagline
              Text(
                'Investasi Cerdas, Masa Depan Cerah',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ MAIN SCREEN dengan Lazy Loading
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  // ✅ Lazy load pages - hanya create saat pertama diakses
  final Map<int, Widget> _cachedPages = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    // Pre-load home page aja
    _cachedPages[0] = const HomePage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Get page dengan lazy loading
  Widget _getPage(int index) {
    if (!_cachedPages.containsKey(index)) {
      switch (index) {
        case 0:
          _cachedPages[0] = const HomePage();
          break;
        case 1:
          _cachedPages[1] = const PasarModalPage();
          break;
        case 2:
          _cachedPages[2] = const KunjunganPage();
          break;
        case 3:
          _cachedPages[3] = const AkunPage();
          break;
      }
    }
    return _cachedPages[index]!;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) => _getPage(index),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.cyan[700],
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: 'Pasar Modal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grass_outlined),
            activeIcon: Icon(Icons.grass),
            label: 'Kunjungan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
