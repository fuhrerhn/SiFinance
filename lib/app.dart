import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_page.dart';

import 'features/chat/data/chat_service.dart';
import 'features/chat/presentation/chat_page.dart';

class SiFinanceApp extends StatelessWidget {
  const SiFinanceApp({
    super.key,
    this.client,
    this.chatService,
    this.chatOnly = false,
    this.startupError,
  });

  final SupabaseClient? client;
  final bool chatOnly;
  final String? startupError;

  final ChatService? chatService;

  @override
  Widget build(BuildContext context) {
    final client = this.client;
    return MaterialApp(
      title: 'SiFinance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF004CFF),
          primary: const Color(0xFF004CFF),
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontSize: 12,
            letterSpacing: 0,
            color: Color(0xFF101828),
          ),
        ),
      ),
      home: chatOnly
          ? ChatPage(service: chatService ?? createChatService())
          : client != null
          ? AuthPage(
              repository: AuthRepository(client),
              chatService: chatService,
            )
          : Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    startupError ??
                        'Konfigurasi Supabase belum tersedia. '
                            'Isi SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
    );
  }
}
