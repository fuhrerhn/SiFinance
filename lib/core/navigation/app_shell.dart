import 'package:material_ui/material_ui.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/budget/data/budget_repository.dart';
import '../../features/budget/presentation/budget_page.dart';
import '../../features/chat/data/chat_service.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.dashboardRepository,
    required this.budgetRepository,
    required this.authRepository,
    this.chatService,
  });

  final DashboardRepository dashboardRepository;
  final BudgetRepository budgetRepository;
  final AuthRepository authRepository;
  final ChatService? chatService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ChatService _chatService =
      widget.chatService ?? createChatService();
  int _tab = 0;
  bool _chatOpened = false;
  bool _signingOut = false;

  void _selectTab(int tab) {
    FocusScope.of(context).unfocus();
    setState(() {
      _tab = tab;
      if (tab == 1) _chatOpened = true;
    });
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.authRepository.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal keluar. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          DashboardPage(
            repository: widget.dashboardRepository,
            onSignOut: _signingOut ? null : _signOut,
          ),
          if (_chatOpened)
            ChatPage(service: _chatService, onBack: () => _selectTab(0))
          else
            const SizedBox.shrink(),
          BudgetPage(repository: widget.budgetRepository),
        ],
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: _selectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: 'AI Chat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'Budget',
                ),
              ],
            ),
    );
  }
}
