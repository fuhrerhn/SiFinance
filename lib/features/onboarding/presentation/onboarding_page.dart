import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_page.dart';
import '../../auth/presentation/sign_in_page.dart';
import '../../chat/data/chat_service.dart';

class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  final String title;
  final String description;
  final String imageAsset;
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    this.initialPage = 3,
    this.onFinished,
    this.chatService,
    this.client,
  });

  final int initialPage;
  final VoidCallback? onFinished;
  final ChatService? chatService;
  final SupabaseClient? client;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  late int _currentPage;

  static const List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Pencatatan Keuangan Mudah',
      description:
          'Catat setiap transaksi masuk dan keluar secara instan untuk memantau arus kas harianmu secara rapi.',
      imageAsset: 'assets/images/onboarding_manage_money.png',
    ),
    OnboardingItem(
      title: 'Smart Budgeting & Alert',
      description:
          'Atur batas anggaran per kategori dan dapatkan peringatan sebelum pengeluaran melebihi rencana keuangan.',
      imageAsset: 'assets/images/onboarding_manage_money.png',
    ),
    OnboardingItem(
      title: 'Transparansi Finansial',
      description:
          'Bagikan dan pantau anggaran bersama keluarga dengan kontrol privasi penuh melalui selective sharing.',
      imageAsset: 'assets/images/onboarding_manage_money.png',
    ),
    OnboardingItem(
      title: 'Kelola Uang Lebih Cerdas',
      description:
          'Pantau pemasukan, pengeluaran, dan target keuanganmu dalam satu aplikasi yang simpel dan mudah digunakan.',
      imageAsset: 'assets/images/onboarding_manage_money.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(0, _items.length - 1);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onKembali() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _onLanjut() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (widget.onFinished != null) {
        widget.onFinished!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) {
              if (widget.client != null) {
                return AuthPage(
                  repository: AuthRepository(widget.client!),
                  chatService: widget.chatService,
                );
              }
              return SignInPage(
                chatService: widget.chatService,
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 52),
                          // Illustration
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Image.asset(
                              item.imageAsset,
                              width: 318,
                              height: 214,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 56),
                          // Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF101828),
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Description
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF101828),
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 38),
                          // Page Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_items.length, (dotIndex) {
                              final isActive = _currentPage == dotIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2.5),
                                width: isActive ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF004CFF)
                                      : const Color(0xFFE2E4E8),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.only(
                  left: 28,
                  right: 28,
                  bottom: 40,
                  top: 12,
                ),
                child: Row(
                  children: [
                    // Tombol Kembali
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _onKembali,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF004CFF),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF004CFF),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Kembali',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF004CFF),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Tombol Lanjut
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _onLanjut,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF004CFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Lanjut',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
