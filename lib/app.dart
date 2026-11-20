import 'package:flutter/material.dart';

import 'features/auth/presentation/sign_in_page.dart';
import 'features/chat/data/chat_service.dart';
import 'features/chat/presentation/chat_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/splash/presentation/splash_page.dart';

enum AppStartScreen { splash, onboarding, signIn, home, chat }

class SiFinanceApp extends StatelessWidget {
  const SiFinanceApp({
    super.key,
    this.chatService,
    this.startScreen = AppStartScreen.chat,
    this.home,
  });

  final ChatService? chatService;
  final AppStartScreen startScreen;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final effectiveChatService = chatService ?? createChatService();

    Widget defaultHome;
    if (home != null) {
      defaultHome = home!;
    } else {
      switch (startScreen) {
        case AppStartScreen.splash:
          defaultHome = SplashPage(
            chatService: effectiveChatService,
          );
          break;
        case AppStartScreen.onboarding:
          defaultHome = OnboardingPage(
            chatService: effectiveChatService,
          );
          break;
        case AppStartScreen.signIn:
          defaultHome = SignInPage(
            chatService: effectiveChatService,
          );
          break;
        case AppStartScreen.home:
          defaultHome = HomePage(
            chatService: effectiveChatService,
          );
          break;
        case AppStartScreen.chat:
          defaultHome = ChatPage(
            service: effectiveChatService,
          );
          break;
      }
    }

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
      home: defaultHome,
      routes: {
        '/splash': (context) => SplashPage(
              chatService: effectiveChatService,
            ),
        '/onboarding': (context) => OnboardingPage(
              chatService: effectiveChatService,
            ),
        '/sign-in': (context) => SignInPage(
              chatService: effectiveChatService,
            ),
        '/home': (context) => HomePage(
              chatService: effectiveChatService,
            ),
        '/chat': (context) => ChatPage(
              service: effectiveChatService,
            ),
      },
    );
  }
}
