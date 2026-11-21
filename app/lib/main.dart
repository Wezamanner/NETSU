import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/app.dart';
import 'package:netsu_app/core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.isConfigured) {
    runApp(const ConfigMissingApp());
    return;
  }
  await Supabase.initialize(url: Env.url, publishableKey: Env.publishableKey);
  runApp(const ProviderScope(child: NetsuApp()));
}
