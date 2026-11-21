import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

Future<SupabaseClient> initializeSupabase() async {
  final supabase = await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  return supabase.client;
}
