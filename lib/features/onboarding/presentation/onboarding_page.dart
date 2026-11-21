import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_page.dart';
import '../../auth/presentation/sign_in_page.dart';
import '../../chat/data/chat_service.dart';

class OnboardingPage extends StatelessWidget {
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

  void _onKembali(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _onLanjut(BuildContext context) {
    if (onFinished != null) {
      onFinished!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            if (client != null) {
              return AuthPage(
                repository: AuthRepository(client!),
                chatService: chatService,
              );
            }
            return SignInPage(
              chatService: chatService,
            );
          },
        ),
      );
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
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 52),
                      // Illustration
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Image.asset(
                          'assets/images/onboarding_manage_money.png',
                          width: 318,
                          height: 214,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 56),
                      // Title
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Kelola Uang Lebih Cerdas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Pantau pemasukan, pengeluaran, dan target keuanganmu dalam satu aplikasi yang simpel dan mudah digunakan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF101828),
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 38),
                      // Page Indicators (4 dots with 4th blue dot at the end)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (dotIndex) {
                          final isActive = dotIndex == 3;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
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
                          onPressed: () => _onKembali(context),
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
                          onPressed: () => _onLanjut(context),
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
