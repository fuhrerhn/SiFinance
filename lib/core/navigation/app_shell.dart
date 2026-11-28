import 'package:material_ui/material_ui.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/budget/data/supabase_budget_repository.dart';
import '../../features/chat/data/chat_service.dart';
import '../../features/dashboard/data/supabase_dashboard_repository.dart';
import '../../features/histori_transaksi/data/supabase_histori_transaksi_repository.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/manual_logging/data/supabase_manual_logging_repository.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.userId,
    required this.authRepository,
    this.chatService,
  });

  final String userId;
  final AuthRepository authRepository;
  final ChatService? chatService;

  @override
  Widget build(BuildContext context) {
    final client = authRepository.client;
    return HomePage(
      chatService: chatService,
      dashboardRepository: SupabaseDashboardRepository(client, userId),
      budgetRepository: SupabaseBudgetRepository(client, userId),
      historiTransaksiRepository:
          SupabaseHistoriTransaksiRepository(client, userId),
      manualLoggingRepository: SupabaseManualLoggingRepository(client, userId),
      onSignOut: authRepository.signOut,
    );
  }
}
