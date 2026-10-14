import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:la_toscana_driver/core/language.dart';
import 'package:la_toscana_driver/core/theme.dart';
import 'package:la_toscana_driver/screens.dart';
import 'package:la_toscana_driver/session.dart';
import '../test/redesign_test.dart' show TestSession, fixture;

// Review artifacts use labelled fixture data; no backend calls or order changes.
void main() {
  testWidgets('capture reference design review previews in both languages', (
    tester,
  ) async {
    // This entry point runs exclusively through flutter test to render fixtures.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final family in ['Manrope', 'Playfair']) {
        final loader = FontLoader(family);
        for (final weight
            in family == 'Manrope' ? [400, 500, 600, 700, 800] : [700]) {
          loader.addFont(
            rootBundle.load(
              'assets/fonts/${family == 'Manrope' ? 'manrope' : 'playfair-display'}-$weight.ttf',
            ),
          );
        }
        await loader.load();
      }
      final directory = Directory(
        '../screenshots/driver-reference-2026-10-14/previews',
      );
      await directory.create(recursive: true);
    });
    final directory = Directory(
      '../screenshots/driver-reference-2026-10-14/previews',
    );
    for (final language in ['es', 'en']) {
      final session = TestSession();
      final assigned = fixture('001', 'confirmed', 'assigned');
      final delivered = fixture('004', 'delivered', 'delivered');
      final pages = <String, Widget>{
        'login': const LoginScreen(),
        'deliveries': const DeliveriesScreen(),
        'drawer': const DeliveriesScreen(),
        'details': DeliveryDetailScreen(assignment: assigned),
        'on-the-way': DeliveryDetailScreen(
          assignment: fixture('003', 'out_for_delivery', 'picked_up'),
        ),
        'delivered': DeliveryCompleteScreen(assignment: delivered),
        'history': Scaffold(
          appBar: AppBar(
            title: Text(language == 'en' ? 'History' : 'Historial'),
          ),
          body: const HistoryScreen(),
        ),
        'password': const ChangePasswordScreen(requiredChange: false),
        'navigation': NavigationScreen(assignment: assigned),
        'settings': const SettingsScreen(),
      };
      for (final entry in pages.entries) {
        final key = GlobalKey();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<DriverSession>.value(value: session),
              ChangeNotifierProvider.value(value: AppLanguage(language)),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme().copyWith(
                filledButtonTheme: FilledButtonThemeData(
                  style: buildTheme().filledButtonTheme.style!.copyWith(
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              locale: Locale(language),
              supportedLocales: const [Locale('es'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: RepaintBoundary(key: key, child: entry.value),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (entry.key == 'drawer') {
          tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${directory.path}/${entry.key}-$language.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} $language',
        );
      }
    }
    await tester.binding.setSurfaceSize(null);
  });
}
