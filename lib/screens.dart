import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/api.dart';
import 'core/format.dart';
import 'core/theme.dart';
import 'models.dart';
import 'session.dart';

String errorText(Object e) {
  if (e is! ApiException) return 'Ha ocurrido un error.';
  return const {
        'NETWORK': 'Sin conexión con el servidor.',
        'INVALID_CREDENTIALS': 'Correo o contraseña incorrectos.',
        'ACCOUNT_LOCKED': 'Cuenta bloqueada temporalmente. Inténtalo más tarde.',
        'RATE_LIMITED': 'Demasiados intentos. Espera un minuto.',
        'NOT_DRIVER': 'Esta cuenta no es de repartidor.',
        'WEAK_PASSWORD': 'Mínimo 10 caracteres, con letras y números.',
        'ORDER_NOT_READY': 'La cocina todavía no ha marcado el pedido como listo.',
        'INVALID_STATE': 'El pedido ha cambiado. Actualiza la lista.',
        'NOT_ASSIGNED_DRIVER': 'Este reparto ya no está asignado a ti.',
      }[e.code] ??
      e.message;
}

void _snack(BuildContext context, String text, {bool error = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Brand.tomatoDark : null));

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await context.read<DriverSession>().login(_email.text.trim(), _password.text);
    } catch (e) {
      if (mounted) _snack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 40),
            const Icon(Icons.delivery_dining, size: 64, color: Brand.tomato),
            const SizedBox(height: 10),
            const Text('La Toscana · Reparto', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 28),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico')),
            const SizedBox(height: 12),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña'), onSubmitted: (_) => _submit()),
            const SizedBox(height: 20),
            FilledButton(onPressed: _busy ? null : _submit, child: const Text('Entrar')),
            const SizedBox(height: 12),
            const Text('Tu cuenta la crea el restaurante.', textAlign: TextAlign.center, style: TextStyle(color: Brand.muted)),
          ]),
        ),
      );
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nueva contraseña'), actions: [TextButton(onPressed: () => context.read<DriverSession>().logout(), child: const Text('Salir'))]),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('Cambia tu contraseña temporal para empezar.', style: TextStyle(color: Brand.muted)),
          const SizedBox(height: 16),
          TextField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña actual')),
          const SizedBox(height: 12),
          TextField(controller: _next, obscureText: true, decoration: const InputDecoration(labelText: 'Nueva contraseña', helperText: 'Mínimo 10 caracteres, con letras y números.')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      await context.read<DriverSession>().changePassword(_current.text, _next.text);
                    } catch (e) {
                      if (context.mounted) _snack(context, errorText(e), error: true);
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            child: const Text('Guardar'),
          ),
        ]),
      );
}

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});
  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<DriverSession>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Mis repartos' : 'Historial'),
        actions: [
          Tooltip(message: s.live ? 'Conectado' : 'Sin conexión en directo', child: Icon(Icons.circle, size: 12, color: s.live ? Colors.green : Brand.muted)),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'logout' ? s.logout() : null,
            itemBuilder: (_) => [PopupMenuItem(enabled: false, child: Text(s.name ?? '')), const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión'))],
          ),
        ],
      ),
      body: _tab == 0 ? const _Active() : const _History(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.delivery_dining_outlined), label: 'Repartos'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}

class _Active extends StatelessWidget {
  const _Active();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<DriverSession>();
    final list = s.assignments;
    return RefreshIndicator(
      onRefresh: s.refresh,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: SwitchListTile(
            title: const Text('Compartir mi ubicación durante el reparto', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(s.locationProblem ??
                'Solo mientras un pedido está en reparto y la app está abierta. El cliente de ese pedido ve dónde estás. Puedes desactivarlo cuando quieras.'),
            value: s.shareLocation,
            onChanged: s.setShareLocation,
          ),
        ),
        const SizedBox(height: 12),
        if (s.error != null) Text(errorText(s.error!), style: const TextStyle(color: Brand.tomatoDark)),
        if (list == null)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else if (list.isEmpty)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No tienes repartos asignados.', style: TextStyle(color: Brand.muted))))
        else
          for (final a in list) _AssignmentCard(a: a),
      ]),
    );
  }
}

class _AssignmentCard extends StatefulWidget {
  const _AssignmentCard({required this.a});
  final Assignment a;
  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  bool _busy = false;

  Future<void> _do(String action, String done) async {
    setState(() => _busy = true);
    try {
      await context.read<DriverSession>().act(widget.a, action);
      if (mounted) _snack(context, done);
    } catch (e) {
      if (mounted) _snack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final state = a.onTheWay
        ? ('En camino al cliente', Brand.basil)
        : a.canRespond
            ? ('Nuevo reparto: ¿lo aceptas?', Brand.tomato)
            : a.canPickUp
                ? ('Listo para recoger en ${a.branchName}', Brand.basil)
                : ('Esperando a cocina', const Color(0xFFA15C00));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(a.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (a.estimatedReadyAt != null && !a.onTheWay) Text('Listo ~${hhmm(a.estimatedReadyAt!)}', style: const TextStyle(color: Brand.muted)),
          ]),
          Text(state.$1, style: TextStyle(color: state.$2, fontWeight: FontWeight.w700)),
          const Divider(height: 20),
          Text(a.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text(a.address),
          if (a.addressNotes != null) Text(a.addressNotes!, style: const TextStyle(color: Color(0xFF7A4500))),
          const SizedBox(height: 6),
          Text(a.items.join(' · '), style: const TextStyle(color: Brand.muted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: a.collectCents > 0 ? const Color(0xFFFFF4DC) : const Color(0xFFE5F4EA), borderRadius: BorderRadius.circular(10)),
            child: Text(
              a.collectCents > 0 ? 'Cobrar en efectivo: ${eur(a.collectCents)}' : 'Pagado con tarjeta${a.simulated ? ' (simulado, pruebas)' : ''}: no cobres nada',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Navegar'),
              onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(a.address)}'), mode: LaunchMode.externalApplication),
            ),
            if (a.customerPhone != null)
              OutlinedButton.icon(icon: const Icon(Icons.call), label: const Text('Llamar'), onPressed: () => launchUrl(Uri.parse('tel:${a.customerPhone!.replaceAll(' ', '')}'))),
            if (a.canRespond) ...[
              FilledButton(onPressed: _busy ? null : () => _do('accept', 'Reparto aceptado'), child: const Text('Aceptar')),
              TextButton(onPressed: _busy ? null : () => _do('decline', 'Reparto rechazado: el restaurante asignará otro'), child: const Text('Rechazar')),
            ],
            if (a.canPickUp) FilledButton(onPressed: _busy ? null : () => _do('picked-up', 'En camino'), child: const Text('Recogido, salgo')),
            if (a.waitingKitchen) const FilledButton(onPressed: null, child: Text('Esperando a cocina')),
            if (a.canDeliver)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Brand.basil),
                onPressed: _busy ? null : () => _do('delivered', 'Pedido entregado'),
                child: Text(a.collectCents > 0 ? 'Entregado y cobrado' : 'Entregado'),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History();
  @override
  Widget build(BuildContext context) {
    final s = context.read<DriverSession>();
    return FutureBuilder<List<Assignment>>(
      future: s.history(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(errorText(snap.error!)));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        if (list.isEmpty) return const Center(child: Text('Todavía no has completado repartos.', style: TextStyle(color: Brand.muted)));
        final cash = list.where((a) => a.deliveredAt != null && DateUtils.isSameDay(a.deliveredAt!.toLocal(), DateTime.now())).fold(0, (n, a) => n + a.collectCents);
        return ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: ListTile(title: const Text('Efectivo cobrado hoy'), trailing: Text(eur(cash), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)))),
          const SizedBox(height: 8),
          for (final a in list)
            ListTile(
              title: Text('${a.number} · ${a.customerName}'),
              subtitle: Text('${a.address}\n${a.deliveredAt != null ? dateTime(a.deliveredAt!, 'es') : ''}'),
              isThreeLine: true,
              trailing: Text(a.collectCents > 0 ? eur(a.collectCents) : 'Tarjeta'),
            ),
        ]);
      },
    );
  }
}
