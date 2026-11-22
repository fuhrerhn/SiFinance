import 'package:flutter/material.dart' as flutter_material;
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/auth/presentation/sign_in_page.dart';
import 'features/auth/presentation/sign_up_page.dart';
import 'features/chat/data/chat_service.dart';
import 'features/chat/presentation/chat_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/splash/presentation/splash_page.dart';

enum AppStartScreen { splash, onboarding, signIn, signUp, home, chat }

class SiFinanceApp extends StatelessWidget {
  const SiFinanceApp({
    super.key,
    this.client,
    this.chatService,
    this.chatOnly = false,
    this.startupError,
    this.startScreen = AppStartScreen.splash,
    this.home,
  });

  final SupabaseClient? client;
  final ChatService? chatService;
  final bool chatOnly;
  final String? startupError;
  final AppStartScreen startScreen;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final effectiveChatService = chatService ?? createChatService();
    final client = this.client;

    Widget defaultHome;
    if (home != null) {
      defaultHome = home!;
    } else if (chatOnly) {
      defaultHome = ChatPage(service: effectiveChatService);
    } else {
      switch (startScreen) {
        case AppStartScreen.splash:
          defaultHome = SplashPage(
            chatService: effectiveChatService,
            client: client,
          );
          break;
        case AppStartScreen.onboarding:
          defaultHome = OnboardingPage(
            chatService: effectiveChatService,
            client: client,
          );
          break;
        case AppStartScreen.signIn:
          defaultHome = client != null
              ? AuthPage(
                  repository: AuthRepository(client),
                  chatService: effectiveChatService,
                )
              : SignInPage(chatService: effectiveChatService);
          break;
        case AppStartScreen.signUp:
          defaultHome = client != null
              ? SignUpPage(
                  repository: AuthRepository(client),
                  chatService: effectiveChatService,
                )
              : SignUpPage(chatService: effectiveChatService);
          break;
        case AppStartScreen.home:
          defaultHome = HomePage(chatService: effectiveChatService);
          break;
        case AppStartScreen.chat:
          defaultHome = ChatPage(service: effectiveChatService);
          break;
      }
    }

    return MaterialApp(
      title: 'SiFinance',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        flutter_material.DefaultMaterialLocalizations.delegate,
        flutter_material.DefaultWidgetsLocalizations.delegate,
      ],
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
      home: defaultHome,
      routes: {
        '/splash': (context) =>
            SplashPage(chatService: effectiveChatService, client: client),
        '/onboarding': (context) =>
            OnboardingPage(chatService: effectiveChatService, client: client),
        '/sign-in': (context) => client != null
            ? AuthPage(
                repository: AuthRepository(client),
                chatService: effectiveChatService,
              )
            : SignInPage(chatService: effectiveChatService),
        '/sign-up': (context) => client != null
            ? SignUpPage(
                repository: AuthRepository(client),
                chatService: effectiveChatService,
              )
            : SignUpPage(chatService: effectiveChatService),
        '/home': (context) => HomePage(chatService: effectiveChatService),
        '/chat': (context) => ChatPage(service: effectiveChatService),
      },
    );
  }
}
