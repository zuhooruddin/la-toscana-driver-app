import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:la_toscana_driver/core/api.dart';
import 'package:la_toscana_driver/core/language.dart';
import 'package:la_toscana_driver/main.dart';
import 'package:la_toscana_driver/models.dart';
import 'package:la_toscana_driver/screens.dart';
import 'package:la_toscana_driver/session.dart';

Assignment fixture(
  String id,
  String status,
  String state,
) => Assignment.fromJson({
  'id': id,
  'number': 'FRA-TEST-$id',
  'branch': {'name': 'La Toscana Fraga'},
  'status': status,
  'driverState': state,
  'customer': {'name': 'Ana Garcia', 'phone': '+34600000000'},
  'address': {'line1': 'Calle Mayor 12', 'postcode': '22520', 'city': 'Fraga'},
  'items': [
    {'quantity': 2, 'name': 'Pizza Toscana'},
  ],
  'payment': {'method': 'cash', 'collectCents': 3280},
  if (status == 'delivered') 'deliveredAt': DateTime.now().toIso8601String(),
});

class TestSession extends DriverSession {
  TestSession() : super(Api(TokenStore()), TokenStore()) {
    ready = true;
    name = 'Test Driver';
    email = 'driver@latoscana.test';
    live = true;
    assignments = [
      fixture('1', 'confirmed', 'assigned'),
      fixture('2', 'preparing', 'accepted'),
      fixture('3', 'out_for_delivery', 'picked_up'),
    ];
  }
  final actions = <String>[];
  int historyCalls = 0;
  @override
  Future<List<Assignment>> history() async {
    historyCalls++;
    return [fixture('4', 'delivered', 'delivered')];
  }

  @override
  Future<void> refresh() async {}
  @override
  Future<void> act(Assignment a, String action) async {
    actions.add(action);
    if (action == 'delivered') {
      assignments = assignments!.where((x) => x.id != a.id).toList();
      notifyListeners();
    }
  }
}

Future<void> mount(
  WidgetTester tester,
  TestSession s,
  AppLanguage language,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DriverSession>.value(value: s),
        ChangeNotifierProvider.value(value: language),
      ],
      child: const DriverApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'language preference survives a new controller and rejects unsupported locales',
    () async {
      final l = AppLanguage();
      await l.setLanguage('en');
      final restored = AppLanguage();
      await restored.load();
      expect(restored.code, 'en');
      await restored.setLanguage('fr');
      expect(restored.code, 'en');
    },
  );
  testWidgets('switching language updates the open screen and navigation', (
    tester,
  ) async {
    final s = TestSession(), l = AppLanguage();
    await mount(tester, s, l);
    expect(find.text('Mis repartos'), findsOneWidget);
    await l.setLanguage('en');
    await tester.pumpAndSettle();
    expect(find.text('My deliveries'), findsOneWidget);
    expect(find.text('Deliveries'), findsOneWidget);
    expect(find.text('Cash'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('new filter hides kitchen and on-the-way orders', (tester) async {
    await mount(tester, TestSession(), AppLanguage('en'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'New  1'));
    await tester.pumpAndSettle();
    expect(find.text('FRA-TEST-1'), findsOneWidget);
    expect(find.text('FRA-TEST-2'), findsNothing);
    expect(find.text('FRA-TEST-3'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('history does not refetch when the language changes', (
    tester,
  ) async {
    final s = TestSession(), l = AppLanguage();
    await mount(tester, s, l);
    await tester.tap(find.text('Historial').last);
    await tester.pumpAndSettle();
    expect(s.historyCalls, 1);
    expect(find.text('Efectivo cobrado hoy'), findsOneWidget);
    await l.setLanguage('en');
    await tester.pumpAndSettle();
    expect(find.text('Cash collected today'), findsOneWidget);
    expect(s.historyCalls, 1);
    expect(find.text('€32.80'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets('delivery requires confirmation before updating the server', (
    tester,
  ) async {
    final s = TestSession();
    await mount(tester, s, AppLanguage('en'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'On the way  1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark delivered'));
    await tester.pumpAndSettle();
    expect(s.actions, isEmpty);
    expect(find.text('Delivery completed?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(s.actions, isEmpty);
    await tester.tap(find.text('Mark delivered'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(s.actions, ['delivered']);
    expect(find.text('Delivery complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'login and password validation use English at a small screen size',
    (tester) async {
      final s = TestSession()..name = null;
      await mount(tester, s, AppLanguage('en'));
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byType(BrandLogo), findsOneWidget);
      await tester.ensureVisible(find.text('Sign in'));
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(find.text('Enter your email and password.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    },
  );
}
