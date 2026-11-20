import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await initializeDateFormatting('id_ID');

  SupabaseClient? client;
  String? startupError;
  if (!SupabaseConfig.chatOnly && SupabaseConfig.isConfigured) {
    try {
      client = await initializeSupabase();
    } catch (_) {
      startupError = 'Supabase gagal dimulai. Tutup dan buka kembali aplikasi.';
    }
  }
  runApp(
    SiFinanceApp(
      client: client,
      chatOnly: SupabaseConfig.chatOnly,
      startupError: startupError,
    ),
  );
}
