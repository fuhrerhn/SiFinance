import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../core/navigation/app_shell.dart';
import '../../chat/data/chat_service.dart';
import '../../dashboard/data/supabase_dashboard_repository.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import 'sign_in_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.repository, this.chatService});

  final AuthRepository repository;
  final ChatService? chatService;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  StreamSubscription<AppAuthState>? _subscription;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant AuthPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository.client != widget.repository.client) _listen();
  }

  void _listen() {
    _subscription?.cancel();
    _userId = widget.repository.currentState.userId;
    _subscription = widget.repository.changes.listen(
      (state) {
        if (_userId != state.userId) setState(() => _userId = state.userId);
      },
      onError: (Object error) {
        final userId = widget.repository.currentState.userId;
        if (_userId != userId) setState(() => _userId = userId);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    if (userId == null) {
      return SignInPage(
        repository: widget.repository,
        chatService: widget.chatService,
      );
    }

    return AppShell(
      key: ValueKey(userId),
      dashboardRepository: SupabaseDashboardRepository(
        widget.repository.client,
        userId,
      ),
      authRepository: widget.repository,
      chatService: widget.chatService,
    );
  }
}
