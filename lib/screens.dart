import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/api.dart';
import 'core/format.dart';
import 'core/language.dart';
import 'core/theme.dart';
import 'models.dart';
import 'session.dart';

extension DriverText on BuildContext {
  String tr(String es, String en) => lang == 'en' ? en : es;
  String get lang => Localizations.localeOf(this).languageCode;
}

String errorText(Object e, [String lang = 'es']) {
  final en = lang == 'en';
  if (e is! ApiException) {
    return en
        ? 'Something went wrong. Please try again.'
        : 'Ha ocurrido un error. Inténtalo de nuevo.';
  }
  final messages = <String, (String, String)>{
    'NETWORK': (
      'Sin conexión con el servidor.',
      'Unable to connect to the server.',
    ),
    'INVALID_CREDENTIALS': (
      'Correo o contraseña incorrectos.',
      'Incorrect email or password.',
    ),
    'ACCOUNT_LOCKED': (
      'Cuenta bloqueada temporalmente. Inténtalo más tarde.',
      'Account temporarily locked. Try again later.',
    ),
    'RATE_LIMITED': (
      'Demasiados intentos. Espera un minuto.',
      'Too many attempts. Please wait a minute.',
    ),
    'NOT_DRIVER': (
      'Esta cuenta no es de repartidor.',
      'This account is not a driver account.',
    ),
    'WEAK_PASSWORD': (
      'Mínimo 10 caracteres, con letras y números.',
      'Use at least 10 characters with letters and numbers.',
    ),
    'ORDER_NOT_READY': (
      'La cocina todavía no ha marcado el pedido como listo.',
      'The kitchen has not marked this order ready yet.',
    ),
    'INVALID_STATE': (
      'El pedido ha cambiado. Actualiza la lista.',
      'This order has changed. Refresh your deliveries.',
    ),
    'NOT_ASSIGNED_DRIVER': (
      'Este reparto ya no está asignado a ti.',
      'This delivery is no longer assigned to you.',
    ),
    'INVALID_PASSWORD': (
      'La contraseña actual no es correcta.',
      'The current password is incorrect.',
    ),
    'UNAUTHORIZED': (
      'Tu sesión ha caducado. Inicia sesión de nuevo.',
      'Your session expired. Please sign in again.',
    ),
  };
  final pair = messages[e.code];
  return pair == null
      ? (en ? 'Unable to complete this request. Please try again.' : e.message)
      : en
      ? pair.$2
      : pair.$1;
}

void _snack(BuildContext c, String text, {bool error = false}) =>
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Brand.tomatoDark : Brand.green,
      ),
    );
Future<void> _open(BuildContext c, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {}
  if (c.mounted) {
    _snack(
      c,
      c.tr(
        'No se puede abrir esta aplicación.',
        'Unable to open this application.',
      ),
      error: true,
    );
  }
}

Future<void> _logout(BuildContext c) async {
  await c.read<DriverSession>().logout();
  if (c.mounted) Navigator.of(c).popUntil((r) => r.isFirst);
}

void _push(BuildContext c, Widget screen) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => screen));

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext c) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/images/logo.png',
        width: size * 1.5,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: 'La Toscana Pizzeria',
      ),
      const SizedBox(height: 8),
      Text(
        c.tr('REPARTO', 'DELIVERY'),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 3,
          fontWeight: FontWeight.w800,
          color: Brand.tomato,
        ),
      ),
    ],
  );
}

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});
  @override
  Widget build(BuildContext c) {
    final l = c.watch<AppLanguage>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final code in ['es', 'en'])
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(42, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: l.code == code
                    ? Brand.tomato
                    : Colors.transparent,
                foregroundColor: l.code == code ? Colors.white : Brand.muted,
              ),
              onPressed: () => l.setLanguage(code),
              child: Text(
                code.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final VoidCallback? onSubmitted;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;
  @override
  Widget build(BuildContext c) => TextField(
    controller: widget.controller,
    obscureText: _hidden,
    autocorrect: false,
    enableSuggestions: false,
    onSubmitted: (_) => widget.onSubmitted?.call(),
    decoration: InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Icons.lock_outline, size: 20),
      suffixIcon: IconButton(
        tooltip: c.tr(
          _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
          _hidden ? 'Show password' : 'Hide password',
        ),
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(), _password = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _snack(
        context,
        context.tr(
          'Introduce tu correo y contraseña.',
          'Enter your email and password.',
        ),
        error: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.read<DriverSession>().login(
        _email.text.trim(),
        _password.text,
      );
    } catch (e) {
      if (mounted) _snack(context, errorText(e, context.lang), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/banner.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .48),
                  Brand.green.withValues(alpha: .94),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (c, bounds) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (bounds.maxHeight - 48).clamp(0, double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: LanguageSwitch(),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const BrandLogo(size: 82),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      c.tr(
                        'Tu ruta, nuestra cocina.',
                        'Your route. Our kitchen.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Playfair',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.tr(
                        'Cada reparto, una buena experiencia.',
                        'A great experience with every delivery.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            c.tr('Bienvenido de nuevo', 'Welcome back'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.tr(
                              'Inicia sesión para ver tus repartos.',
                              'Sign in to see your deliveries.',
                            ),
                            style: const TextStyle(
                              color: Brand.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                            decoration: InputDecoration(
                              labelText: c.tr(
                                'Correo electrónico',
                                'Email address',
                              ),
                              prefixIcon: const Icon(
                                Icons.mail_outline,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          PasswordField(
                            controller: _password,
                            label: c.tr('Contraseña', 'Password'),
                            onSubmitted: _submit,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_busy)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Text(c.tr('Entrar', 'Sign in')),
                                const SizedBox(width: 12),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      c.tr(
                        'Tu cuenta la crea el restaurante.',
                        'Your account is created by the restaurant.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.requiredChange = true});
  final bool requiredChange;
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController(),
      _next = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_next.text != _confirm.text) {
      _snack(
        context,
        context.tr('Las contraseñas no coinciden.', 'Passwords do not match.'),
        error: true,
      );
      return;
    }
    if (_current.text.isEmpty ||
        _next.text.length < 10 ||
        !RegExp(r'[a-zA-Z]').hasMatch(_next.text) ||
        !RegExp(r'[0-9]').hasMatch(_next.text)) {
      _snack(
        context,
        context.tr(
          'Introduce tu contraseña actual y una nueva con 10 caracteres, letras y números.',
          'Enter your current password and a new password with 10 characters, letters and numbers.',
        ),
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<DriverSession>().changePassword(
        _current.text,
        _next.text,
      );
      if (mounted && !widget.requiredChange) {
        _snack(
          context,
          context.tr('Contraseña actualizada.', 'Password updated.'),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _snack(context, errorText(e, context.lang), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(c.tr('Nueva contraseña', 'New password')),
      actions: [
        if (widget.requiredChange)
          IconButton(
            tooltip: c.tr('Cerrar sesión', 'Sign out'),
            onPressed: () => _logout(c),
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: BrandLogo(size: 54)),
        const SizedBox(height: 24),
        const Center(
          child: CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFFFFE8EC),
            child: Icon(Icons.lock_outline, color: Brand.tomato, size: 30),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          c.tr(
            widget.requiredChange
                ? 'Cambia tu contraseña temporal para empezar.'
                : 'Elige una contraseña segura para tu cuenta.',
            widget.requiredChange
                ? 'Change your temporary password to get started.'
                : 'Choose a secure password for your account.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Brand.muted),
        ),
        const SizedBox(height: 24),
        PasswordField(
          controller: _current,
          label: c.tr('Contraseña actual', 'Current password'),
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _next,
          label: c.tr('Nueva contraseña', 'New password'),
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _confirm,
          label: c.tr('Confirmar contraseña', 'Confirm password'),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _Requirement(
                c.tr('Mínimo 10 caracteres', 'At least 10 characters'),
              ),
              _Requirement(
                c.tr(
                  'Debe incluir letras y números',
                  'Must include letters and numbers',
                ),
              ),
              _Requirement(
                c.tr('Usa una contraseña única', 'Use a unique password'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(
            c.tr(
              _busy ? 'Guardando…' : 'Guardar cambios',
              _busy ? 'Saving…' : 'Save changes',
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: LanguageSwitch()),
      ],
    ),
  );
}

class _Requirement extends StatelessWidget {
  const _Requirement(this.text);
  final String text;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Brand.basil, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});
  @override
  Widget build(BuildContext c) {
    final live = c.watch<DriverSession>().live;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: live ? const Color(0xFFE1F8E7) : Brand.border,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: live ? Brand.basil : Brand.muted),
          const SizedBox(width: 5),
          Text(
            c.tr(
              live ? 'En línea' : 'Sin conexión',
              live ? 'Online' : 'Offline',
            ),
            style: TextStyle(
              color: live ? Brand.basil : Brand.muted,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});
  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  int _tab = 0;
  void _select(int tab) {
    Navigator.of(context).pop();
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        c.tr(
          ['Mis repartos', 'Mis rutas', 'Historial'][_tab],
          ['My deliveries', 'My routes', 'History'][_tab],
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Center(child: LiveBadge()),
        ),
      ],
    ),
    drawer: Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFFFE8EC),
                        child: Text(
                          (c.watch<DriverSession>().name ?? 'D')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Brand.tomato,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const LiveBadge(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    c.watch<DriverSession>().name ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    c.watch<DriverSession>().email ?? '',
                    style: const TextStyle(fontSize: 12, color: Brand.muted),
                  ),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.delivery_dining,
              title: c.tr('Mis repartos', 'My deliveries'),
              selected: _tab == 0,
              onTap: () => _select(0),
            ),
            _DrawerItem(
              icon: Icons.route_outlined,
              title: c.tr('Mis rutas', 'My routes'),
              selected: _tab == 1,
              onTap: () => _select(1),
            ),
            _DrawerItem(
              icon: Icons.history,
              title: c.tr('Historial', 'History'),
              selected: _tab == 2,
              onTap: () => _select(2),
            ),
            const Divider(indent: 24, endIndent: 24),
            _DrawerItem(
              icon: Icons.lock_outline,
              title: c.tr('Cambiar contraseña', 'Change password'),
              onTap: () {
                Navigator.pop(c);
                _push(c, const ChangePasswordScreen(requiredChange: false));
              },
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              title: c.tr('Ajustes', 'Settings'),
              onTap: () {
                Navigator.pop(c);
                _push(c, const SettingsScreen());
              },
            ),
            _DrawerItem(
              icon: Icons.logout,
              title: c.tr('Cerrar sesión', 'Sign out'),
              onTap: () => _logout(c),
            ),
            const SizedBox(height: 28),
            const BrandLogo(size: 62),
            const SizedBox(height: 12),
            const Center(child: LanguageSwitch()),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    body: switch (_tab) {
      0 => const _Active(),
      1 => const RoutesScreen(),
      _ => const HistoryScreen(),
    },
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.delivery_dining_outlined),
          selectedIcon: const Icon(Icons.delivery_dining, color: Brand.tomato),
          label: c.tr('Repartos', 'Deliveries'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.route_outlined),
          selectedIcon: const Icon(Icons.route, color: Brand.tomato),
          label: c.tr('Rutas', 'Routes'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.history),
          selectedIcon: const Icon(Icons.history, color: Brand.tomato),
          label: c.tr('Historial', 'History'),
        ),
      ],
    ),
  );
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedTileColor: const Color(0xFFFFE8EC),
      selectedColor: Brand.tomato,
      leading: Icon(icon, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      onTap: onTap,
    ),
  );
}

class _Active extends StatefulWidget {
  const _Active();
  @override
  State<_Active> createState() => _ActiveState();
}

class _ActiveState extends State<_Active> {
  int _filter = 0;
  bool _matches(Assignment a, int f) => switch (f) {
    1 => a.canRespond,
    2 => a.onTheWay,
    3 => a.canPickUp,
    4 => a.waitingKitchen,
    _ => true,
  };
  @override
  Widget build(BuildContext c) {
    final s = c.watch<DriverSession>();
    final all = s.assignments,
        list = s.assignments?.where((a) => _matches(a, _filter)).toList();
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: _filter == i,
                      showCheckmark: false,
                      selectedColor: Brand.tomato,
                      backgroundColor: const Color(0xFFF1F3F5),
                      side: BorderSide.none,
                      label: Text(
                        '${c.tr(['Todos', 'Nuevos', 'En camino', 'Listos', 'Cocina'][i], ['All', 'New', 'On the way', 'Ready', 'Kitchen'][i])}  ${all?.where((a) => _matches(a, i)).length ?? 0}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _filter == i ? Colors.white : Brand.charcoal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onSelected: (_) => setState(() => _filter = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: s.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (s.error != null)
                  _ErrorPanel(error: s.error!, onRetry: s.refresh),
                if (list == null)
                  const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (list.isEmpty)
                  _Empty(
                    icon: Icons.delivery_dining,
                    title: c.tr('Todo al día', 'You’re all caught up'),
                    message: c.tr(
                      'No hay repartos en esta categoría.',
                      'There are no deliveries in this category.',
                    ),
                  )
                else
                  for (final a in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DeliveryCard(a: a),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _stateLabel(BuildContext c, Assignment a) =>
    a.status == 'delivered' || a.status == 'refunded'
    ? c.tr('ENTREGADO', 'DELIVERED')
    : a.onTheWay
    ? c.tr('EN CAMINO', 'ON THE WAY')
    : a.canRespond
    ? c.tr('NUEVO', 'NEW')
    : a.canPickUp
    ? c.tr('LISTO', 'READY')
    : c.tr('EN COCINA', 'IN THE KITCHEN');
Color _stateColor(Assignment a) => a.canRespond
    ? Brand.tomato
    : a.waitingKitchen
    ? const Color(0xFF976200)
    : Brand.basil;

class _Status extends StatelessWidget {
  const _Status(this.a);
  final Assignment a;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: _stateColor(a).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _stateLabel(c, a),
      style: TextStyle(
        color: _stateColor(a),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.a});
  final Assignment a;
  @override
  Widget build(BuildContext c) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _push(c, DeliveryDetailScreen(assignment: a)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Brand.tomato,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Status(a),
                      const SizedBox(height: 4),
                      Text(
                        a.number,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (a.estimatedReadyAt != null && !a.onTheWay)
                  Text(
                    '~ ${hhmm(a.estimatedReadyAt!)}',
                    style: const TextStyle(color: Brand.muted, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              a.customerName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Brand.tomato, size: 15),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    a.address,
                    style: const TextStyle(color: Brand.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              a.items.join('\n'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Brand.muted,
                fontSize: 11,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 12),
            _Payment(a),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _push(c, DeliveryDetailScreen(assignment: a)),
                    child: Text(
                      c.tr('Ver detalles', 'View details'),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _OrderAction(a: a, compact: true)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Payment extends StatelessWidget {
  const _Payment(this.a);
  final Assignment a;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: a.collectCents > 0
          ? const Color(0xFFFFF3D9)
          : const Color(0xFFE9F7EF),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(
          a.collectCents > 0 ? Icons.payments_outlined : Icons.credit_card,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            c.tr(
              a.collectCents > 0 ? 'Efectivo' : 'Pagado con tarjeta',
              a.collectCents > 0 ? 'Cash' : 'Paid by card',
            ),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        if (a.collectCents > 0)
          Text(
            eur(a.collectCents, c.lang),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          )
        else if (a.simulated)
          Text(
            c.tr('Prueba', 'Test'),
            style: const TextStyle(color: Brand.basil, fontSize: 10),
          ),
      ],
    ),
  );
}

class _OrderAction extends StatefulWidget {
  const _OrderAction({required this.a, this.compact = false});
  final Assignment a;
  final bool compact;
  @override
  State<_OrderAction> createState() => _OrderActionState();
}

class _OrderActionState extends State<_OrderAction> {
  bool _busy = false;
  Future<void> _act() async {
    if (_busy) return;
    final a = widget.a;
    if (a.canDeliver) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(c.tr('¿Pedido entregado?', 'Delivery completed?')),
          content: Text(
            c.tr(
              a.collectCents > 0
                  ? 'Confirma que has entregado el pedido y cobrado el efectivo.'
                  : 'Confirma que has entregado el pedido. Ya está pagado con tarjeta.',
              a.collectCents > 0
                  ? 'Confirm you handed over the order and collected the cash.'
                  : 'Confirm you handed over the order. It is already paid by card.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(c.tr('Cancelar', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(c.tr('Confirmar', 'Confirm')),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await context.read<DriverSession>().act(
        a,
        a.canRespond
            ? 'accept'
            : a.canPickUp
            ? 'picked-up'
            : 'delivered',
      );
      if (!mounted) return;
      if (a.canDeliver) {
        _push(context, DeliveryCompleteScreen(assignment: a));
      } else {
        _snack(
          context,
          context.tr(
            a.canRespond ? 'Reparto aceptado' : 'En camino al cliente',
            a.canRespond ? 'Delivery accepted' : 'On the way to the customer',
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack(context, errorText(e, context.lang), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final a = widget.a,
        enabled =
            widget.a.canRespond || widget.a.canPickUp || widget.a.canDeliver;
    final es = a.canRespond
        ? 'Aceptar'
        : a.canPickUp
        ? 'Recogido, salgo'
        : a.canDeliver
        ? 'Marcar entregado'
        : a.waitingKitchen
        ? 'Esperando a cocina'
        : 'Entregado';
    final en = a.canRespond
        ? 'Accept'
        : a.canPickUp
        ? 'Picked up'
        : a.canDeliver
        ? 'Mark delivered'
        : a.waitingKitchen
        ? 'Waiting for kitchen'
        : 'Delivered';
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 18),
        textStyle: TextStyle(
          fontSize: widget.compact ? 11 : 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      onPressed: enabled && !_busy ? _act : null,
      child: Text(
        _busy ? c.tr('Guardando…', 'Saving…') : c.tr(es, en),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class DeliveryDetailScreen extends StatelessWidget {
  const DeliveryDetailScreen({super.key, required this.assignment});
  final Assignment assignment;
  @override
  Widget build(BuildContext c) {
    final a =
        c.watch<DriverSession>().latestAssignment(assignment.id) ?? assignment;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          c.tr(
            a.onTheWay ? 'En camino al cliente' : 'Detalle del reparto',
            a.onTheWay ? 'On the way' : 'Delivery details',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              _Status(a),
              const Spacer(),
              if (a.estimatedReadyAt != null)
                Text(
                  '~ ${hhmm(a.estimatedReadyAt!)}',
                  style: const TextStyle(color: Brand.muted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            a.number,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            a.customerName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          _AddressPanel(a),
          if (a.addressNotes != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                a.addressNotes!,
                style: const TextStyle(color: Brand.muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  onPressed: () => _push(c, NavigationScreen(assignment: a)),
                  label: Text(c.tr('Navegar', 'Navigate')),
                ),
              ),
              const SizedBox(width: 8),
              if (a.customerPhone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.call_outlined, size: 18),
                    onPressed: () => _open(
                      c,
                      Uri(
                        scheme: 'tel',
                        path: a.customerPhone!.replaceAll(' ', ''),
                      ),
                    ),
                    label: Text(c.tr('Llamar', 'Call')),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            c.tr('Pedido', 'Order'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (final item in a.items)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Brand.cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restaurant_outlined,
                        color: Brand.tomato,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            c.tr('Pago', 'Payment'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _Payment(a),
          const SizedBox(height: 8),
          Text(
            c.tr(
              a.collectCents > 0
                  ? 'Cobra este importe al entregar el pedido.'
                  : 'No cobres nada al cliente.',
              a.collectCents > 0
                  ? 'Collect this amount when handing over the order.'
                  : 'Do not collect payment from the customer.',
            ),
            style: const TextStyle(color: Brand.muted, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _DeliveryProgress(a),
          const SizedBox(height: 18),
          if (a.canRespond)
            TextButton(
              onPressed: () => _decline(c, a),
              child: Text(
                c.tr('Rechazar este reparto', 'Decline this delivery'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: _OrderAction(a: a),
        ),
      ),
    );
  }

  Future<void> _decline(BuildContext c, Assignment a) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: Text(d.tr('¿Rechazar reparto?', 'Decline delivery?')),
        content: Text(
          d.tr(
            'El restaurante asignará otro repartidor.',
            'The restaurant will assign another driver.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(d.tr('Cancelar', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(d.tr('Rechazar', 'Decline')),
          ),
        ],
      ),
    );
    if (ok != true || !c.mounted) return;
    try {
      await c.read<DriverSession>().act(a, 'decline');
      if (c.mounted) Navigator.pop(c);
    } catch (e) {
      if (c.mounted) _snack(c, errorText(e, c.lang), error: true);
    }
  }
}

class _AddressPanel extends StatelessWidget {
  const _AddressPanel(this.a);
  final Assignment a;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Brand.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on, color: Brand.tomato),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.tr('Dirección de entrega', 'Delivery address'),
                style: const TextStyle(color: Brand.muted, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                a.address,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress(this.a);
  final Assignment a;
  @override
  Widget build(BuildContext c) {
    final step = a.status == 'delivered' || a.status == 'refunded'
        ? 3
        : a.onTheWay
        ? 2
        : a.canRespond
        ? 0
        : 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.tr('Pasos de entrega', 'Delivery progress'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Icon(
                      i < step
                          ? Icons.check_circle
                          : i == step
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: i < step
                          ? Brand.basil
                          : i == step
                          ? Brand.tomato
                          : Brand.border,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.tr(
                          [
                            'Asignado',
                            'Aceptado · esperando recogida',
                            'En camino al cliente',
                            'Entregado',
                          ][i],
                          [
                            'Assigned',
                            'Accepted · awaiting pickup',
                            'On the way to the customer',
                            'Delivered',
                          ][i],
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: i <= step ? Brand.charcoal : Brand.muted,
                          fontWeight: i == step
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DeliveryCompleteScreen extends StatelessWidget {
  const DeliveryCompleteScreen({super.key, required this.assignment});
  final Assignment assignment;
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        const Center(
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Brand.basil,
            child: Icon(Icons.check_rounded, size: 64, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          c.tr('Pedido entregado', 'Delivery complete'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          c.tr('¡Buen trabajo!', 'Great work!'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Brand.muted),
        ),
        const SizedBox(height: 30),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.number,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(assignment.customerName),
                Text(
                  assignment.address,
                  style: const TextStyle(color: Brand.muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                _Payment(assignment),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(c).popUntil((r) => r.isFirst),
          icon: const Icon(Icons.home_outlined),
          label: Text(c.tr('Volver a mis repartos', 'Back to my deliveries')),
        ),
        const SizedBox(height: 30),
        const Center(child: BrandLogo(size: 54)),
      ],
    ),
  );
}

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final s = c.watch<DriverSession>(),
        list = c.watch<DriverSession>().assignments;
    return RefreshIndicator(
      onRefresh: s.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            c.tr('Tu próxima parada', 'Your next stop'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            c.tr(
              'Abre la ruta real en Google Maps para iniciar la navegación.',
              'Open the live route in Google Maps to start navigation.',
            ),
            style: const TextStyle(color: Brand.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (s.error != null) _ErrorPanel(error: s.error!, onRetry: s.refresh),
          if (list == null)
            const Center(child: CircularProgressIndicator())
          else if (list.isEmpty)
            _Empty(
              icon: Icons.route,
              title: c.tr('Sin rutas pendientes', 'No pending routes'),
              message: c.tr(
                'Tus direcciones aparecerán aquí.',
                'Your delivery addresses will appear here.',
              ),
            )
          else
            for (final a in [
              ...list.where((a) => a.onTheWay),
              ...list.where((a) => !a.onTheWay),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFE8EC),
                      child: Icon(Icons.location_on, color: Brand.tomato),
                    ),
                    title: Text(
                      a.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.address, style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 8),
                        _Status(a),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: Brand.tomato,
                    ),
                    onTap: () => _push(c, NavigationScreen(assignment: a)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key, required this.assignment});
  final Assignment assignment;
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(c.tr('Navegación', 'Navigation'))),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        const Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFFFFE8EC),
            child: Icon(Icons.route, size: 48, color: Brand.tomato),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          c.tr(
            'De nuestra cocina\na su puerta.',
            'From our kitchen\nto their door.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Playfair',
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.storefront_outlined,
                    color: Brand.basil,
                  ),
                  title: Text(
                    c.tr('Restaurante', 'Restaurant'),
                    style: const TextStyle(color: Brand.muted, fontSize: 11),
                  ),
                  subtitle: Text(
                    assignment.branchName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on, color: Brand.tomato),
                  title: Text(
                    assignment.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(assignment.address),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          c.tr(
            'Google Maps mostrará la ruta, distancia y tiempo estimado desde tu ubicación.',
            'Google Maps will show the route, distance and estimated travel time from your location.',
          ),
          style: const TextStyle(color: Brand.muted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _open(
            c,
            Uri.https('www.google.com', '/maps/dir/', {
              'api': '1',
              'destination': assignment.address,
              'travelmode': 'driving',
            }),
          ),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(c.tr('Abrir en Google Maps', 'Open in Google Maps')),
        ),
        const SizedBox(height: 18),
        _AddressPanel(assignment),
      ],
    ),
  );
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Assignment>> _future;
  bool _today = false;
  @override
  void initState() {
    super.initState();
    _future = context.read<DriverSession>().history();
  }

  Future<void> _refresh() async {
    final next = context.read<DriverSession>().history();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext c) => FutureBuilder<List<Assignment>>(
    future: _future,
    builder: (c, snap) {
      if (snap.hasError) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [_ErrorPanel(error: snap.error!, onRetry: _refresh)],
        );
      }
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final all = snap.data!;
      bool today(Assignment a) =>
          a.deliveredAt != null &&
          DateUtils.isSameDay(a.deliveredAt!.toLocal(), DateTime.now());
      final list = _today ? all.where(today).toList() : all,
          cash = all.where(today).fold<int>(0, (n, a) => n + a.collectCents);
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.tr('Tus entregas', 'Your deliveries'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _today,
                  label: Text(c.tr('Hoy', 'Today')),
                  avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                  onSelected: (v) => setState(() => _today = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Brand.tomato, Brand.tomatoDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.tr('Efectivo cobrado hoy', 'Cash collected today'),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Text(
                    eur(cash, c.lang),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (list.isEmpty)
              _Empty(
                icon: Icons.task_alt,
                title: c.tr(
                  'Aún no hay entregas',
                  'No completed deliveries yet',
                ),
                message: c.tr(
                  'Tus pedidos entregados aparecerán aquí.',
                  'Your completed deliveries will appear here.',
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final a in list)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        onTap: () =>
                            _push(c, DeliveryDetailScreen(assignment: a)),
                        title: Text(
                          a.number,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.customerName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              a.address,
                              style: const TextStyle(fontSize: 11),
                            ),
                            if (a.deliveredAt != null)
                              Text(
                                dateTime(a.deliveredAt!, c.lang),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Brand.muted,
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              c.tr(
                                a.collectCents > 0 ? 'Efectivo' : 'Tarjeta',
                                a.collectCents > 0 ? 'Cash' : 'Card',
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Brand.basil,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (a.collectCents > 0)
                              Text(
                                eur(a.collectCents, c.lang),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              )
                            else
                              const Icon(
                                Icons.credit_card,
                                size: 20,
                                color: Brand.muted,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final s = c.watch<DriverSession>();
    return Scaffold(
      appBar: AppBar(title: Text(c.tr('Ajustes', 'Settings'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: BrandLogo(size: 64)),
          const SizedBox(height: 28),
          Text(
            c.tr('Idioma', 'Language'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            c.tr(
              'Elige el idioma de la aplicación.',
              'Choose the app language.',
            ),
            style: const TextStyle(color: Brand.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft, child: LanguageSwitch()),
          const SizedBox(height: 28),
          Text(
            c.tr('Durante el reparto', 'While delivering'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                c.tr('Compartir mi ubicación', 'Share my location'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                c.tr(
                  'Solo durante un pedido en reparto y con la app abierta. El cliente puede ver dónde estás. Puedes desactivarlo cuando quieras.',
                  'Only while an order is out for delivery and the app is open. The customer can see your location. You can turn it off at any time.',
                ),
                style: const TextStyle(fontSize: 11, height: 1.6),
              ),
              value: s.shareLocation,
              onChanged: s.setShareLocation,
            ),
          ),
          if (s.locationProblem != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                c.tr(
                  s.locationProblem == 'LOCATION_DISABLED'
                      ? 'Activa la ubicación del teléfono.'
                      : 'Permite el acceso a la ubicación en los ajustes del teléfono.',
                  s.locationProblem == 'LOCATION_DISABLED'
                      ? 'Turn on your phone’s location services.'
                      : 'Allow location access in your phone settings.',
                ),
                style: const TextStyle(color: Brand.tomato, fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(
                c.tr('Cambiar contraseña', 'Change password'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  _push(c, const ChangePasswordScreen(requiredChange: false)),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            c.tr(
              'La Toscana · Reparto\nVersión 1.0.0',
              'La Toscana · Delivery\nVersion 1.0.0',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Brand.muted,
              fontSize: 11,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error, required this.onRetry});
  final Object error;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              errorText(error, c.lang),
              style: const TextStyle(color: Brand.tomatoDark),
            ),
            TextButton.icon(
              onPressed: () async {
                try {
                  await onRetry();
                } catch (_) {}
              },
              icon: const Icon(Icons.refresh),
              label: Text(c.tr('Reintentar', 'Try again')),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 16),
    child: Column(
      children: [
        Icon(icon, size: 54, color: Brand.tomato.withValues(alpha: .5)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Brand.muted, fontSize: 12),
        ),
      ],
    ),
  );
}
