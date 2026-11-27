import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../auth/presentation/sign_in_page.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/presentation/budget_page.dart';
import '../../chat/data/chat_service.dart';
import '../../chat/presentation/chat_page.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import '../../manual_logging/data/manual_logging_repository.dart';
import '../../manual_logging/presentation/manual_logging_page.dart';
import '../demo_finance.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.chatService,
    this.userEmail,
    this.dashboardRepository,
    this.budgetRepository,
    this.manualLoggingRepository,
    this.onSignOut,
  });

  final ChatService? chatService;
  final String? userEmail;
  final DashboardRepository? dashboardRepository;
  final BudgetRepository? budgetRepository;
  final ManualLoggingRepository? manualLoggingRepository;
  final Future<void> Function()? onSignOut;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final _demo = DemoFinance();
  late final _chatService = widget.chatService ?? createChatService();
  final _openedTabs = <int>{0};
  int _selectedNavIndex = 0;
  int _transactionRevision = 0;
  bool _signingOut = false;

  void _onNavTapped(int index) {
    FocusScope.of(context).unfocus();
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ManualLoggingPage(
            repository: widget.manualLoggingRepository ?? _demo,
            onSaved: () {
              if (mounted) setState(() => _transactionRevision++);
            },
          ),
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (index == 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Menu Transaksi belum ditambahkan')),
      );
      return;
    }
    setState(() {
      _selectedNavIndex = index;
      _openedTabs.add(index);
    });
  }

  Future<void> _logout() async {
    if (_signingOut) return;
    final signOut = widget.onSignOut;
    if (signOut != null) {
      setState(() => _signingOut = true);
      try {
        await signOut();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal keluar. Coba lagi.')),
          );
        }
      } finally {
        if (mounted) setState(() => _signingOut = false);
      }
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SignInPage(chatService: widget.chatService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          _buildHome(),
          if (_openedTabs.contains(1))
            DashboardPage(
              repository: widget.dashboardRepository ?? _demo,
              transactionRevision: _transactionRevision,
              onSignOut: _signingOut ? null : _logout,
            )
          else
            const SizedBox.shrink(),
          const SizedBox.shrink(),
          if (_openedTabs.contains(3))
            BudgetPage(
              repository: widget.budgetRepository ?? _demo.budgets,
              transactionRevision: _transactionRevision,
            )
          else
            const SizedBox.shrink(),
          const SizedBox.shrink(),
          if (_openedTabs.contains(5))
            ChatPage(service: _chatService, onBack: () => _onNavTapped(0))
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom == 0
          ? _buildBottomNavigationBar()
          : null,
    );
  }

  Widget _buildHome() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Stack(
          children: [
            // Top Blue Background Header
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(color: Color(0xFF0038BC)),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar (Profile, Greeting, Notifications, Logout)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Profile Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFF0038BC),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Greeting
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Hai Kamu!',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sudah siap kelola keuangan hari ini?',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Notification Bell Button
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tidak ada notifikasi baru'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFF0038BC),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Logout Button
                          InkWell(
                            onTap: _logout,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFF0038BC),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (widget.onSignOut != null)
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.dashboard_outlined),
                              title: const Text('Dashboard Personal'),
                              subtitle: const Text(
                                'Lihat ringkasan pengeluaran',
                              ),
                              onTap: () => _onNavTapped(1),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.account_balance_wallet_outlined,
                              ),
                              title: const Text('Kelola Budget'),
                              subtitle: const Text(
                                'Atur batas pengeluaran per kategori',
                              ),
                              onTap: () => _onNavTapped(3),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._buildDemoSummary(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDemoSummary() => [
    const Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Text(
        'Contoh ringkasan · Mode demo',
        style: TextStyle(color: Colors.white),
      ),
    ),
    // 1. Balance Summary Card (White container wrapper)
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Sisa Keuangan Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0035B3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sisa Keuangan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Rp1.000.000,00',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Row Pemasukan & Pengeluaran
            Row(
              children: [
                // Pemasukan (Green)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A843),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pemasukan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: Color(0xFF00A843),
                                size: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'Rp100.000,00',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Pengeluaran (Red)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1E40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengeluaran',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Color(0xFFFF1E40),
                                size: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'Rp100.000,00',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 16),

    // 2. Budget Saya Card
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Saya',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Pantau pengeluaran budget anda',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF475467),
              ),
            ),
            const SizedBox(height: 18),
            // Item Belanja
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Belanja',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                Text(
                  'Rp750.000',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Flexible(
                  child: Text(
                    'Kebutuhan sehari-hari',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF98A2B3),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'dari Rp1.000.000',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.75,
                minHeight: 8,
                backgroundColor: Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004CFF)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '75% terpakai',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFFF1E40),
                  ),
                ),
                Text(
                  'Sisa Rp250.000',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00A843),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 3-dot indicator matching Figma
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF004CFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 16),

    // 3. Transaksi Terakhir Card
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Minggu 17 Mei 2026',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF98A2B3),
              ),
            ),
            const SizedBox(height: 16),

            // Item 1: Transportasi
            _buildTransactionItem(
              imageAsset: 'assets/icons/Mobil.png',
              iconBgColor: const Color(0xFF1A56DB),
              title: 'Transportasi',
              subtitle: 'isi bensin motor',
              amount: '-Rp 25.000',
            ),
            const Divider(height: 24, color: Color(0xFFF2F4F7), thickness: 1),

            // Item 2: Kesehatan
            _buildTransactionItem(
              imageAsset: 'assets/icons/Hospital.png',
              iconBgColor: const Color(0xFF00C466),
              title: 'Kesehatan',
              subtitle: 'beli vitamin untuk immune',
              amount: '-Rp 45.000',
            ),
            const Divider(height: 24, color: Color(0xFFF2F4F7), thickness: 1),

            // Item 3: Makanan & Minuman
            _buildTransactionItem(
              imageAsset: 'assets/icons/minuman.png',
              iconBgColor: const Color(0xFFB82BFF),
              title: 'Makanan & Minuman',
              subtitle: 'Beli ikan bakar',
              amount: '-Rp 100.000',
            ),
          ],
        ),
      ),
    ),
  ];

  Widget _buildTransactionItem({
    IconData? icon,
    String? imageAsset,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: imageAsset != null
                ? Image.asset(
                    imageAsset,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  )
                : Icon(icon, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101828),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // 1. Beranda
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  imageAsset: 'assets/icons/ic_beranda.png',
                  label: 'Beranda',
                ),
              ),
              // 2. Dashboard
              Expanded(
                child: _buildNavItem(
                  index: 1,
                  imageAsset: 'assets/icons/ic_dashboard.png',
                  label: 'Dashboard',
                ),
              ),
              // 3. Catat (Center FAB Button)
              Expanded(
                child: GestureDetector(
                  onTap: () => _onNavTapped(2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF004CFF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33004CFF),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Catat',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 4. Budget
              Expanded(
                child: _buildNavItem(
                  index: 3,
                  imageAsset: 'assets/icons/ic_budget.png',
                  label: 'Budget',
                ),
              ),
              // 5. Transaksi
              Expanded(
                child: _buildNavItem(
                  index: 4,
                  icon: Icons.receipt_long_outlined,
                  label: 'Transaksi',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  index: 5,
                  icon: Icons.chat_bubble_outline,
                  label: 'AI Chat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    IconData? icon,
    String? imageAsset,
    required String label,
  }) {
    final isSelected = _selectedNavIndex == index;
    final color = isSelected
        ? const Color(0xFF004CFF)
        : const Color(0xFF98A2B3);

    return InkWell(
      onTap: () => _onNavTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageAsset != null)
              Image.asset(
                imageAsset,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                color: color,
              )
            else
              Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
