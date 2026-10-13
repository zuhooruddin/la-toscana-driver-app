import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api.dart';
import 'core/theme.dart';
import 'screens.dart';
import 'session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStore();
  final session = DriverSession(Api(tokens), tokens);
  session.init();
  runApp(ChangeNotifierProvider.value(value: session, child: const DriverApp()));
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'La Toscana Reparto',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: const _Gate(),
      );
}

class _Gate extends StatelessWidget {
  const _Gate();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<DriverSession>();
    if (!s.ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!s.signedIn) return const LoginScreen();
    if (s.mustChangePassword) return const ChangePasswordScreen();
    return const DeliveriesScreen();
  }
}
