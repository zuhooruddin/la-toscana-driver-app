// Driver API shapes (contract 1.3.0): only what a driver needs for the delivery.

typedef Json = Map<String, dynamic>;

int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String _s(Object? v) => v == null ? '' : '$v';
Json _m(Object? v) => v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

class Assignment {
  Assignment({
    required this.id,
    required this.number,
    required this.branchName,
    required this.status,
    required this.driverState,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.addressNotes,
    required this.estimatedReadyAt,
    required this.items,
    required this.paymentMethod,
    required this.collectCents,
    required this.simulated,
    required this.deliveredAt,
  });
  factory Assignment.fromJson(Json j) {
    final a = _m(j['address']);
    final c = _m(j['customer']);
    final p = _m(j['payment']);
    return Assignment(
      id: _s(j['id']),
      number: _s(j['number']),
      branchName: _s(_m(j['branch'])['name']),
      status: _s(j['status']),
      driverState: _s(j['driverState']),
      customerName: _s(c['name']),
      customerPhone: c['phone'] == null ? null : '${c['phone']}',
      address: [a['line1'], a['line2'], [a['postcode'], a['city']].where((x) => x != null).join(' ')].where((x) => x != null && '$x'.trim().isNotEmpty).join(', '),
      addressNotes: a['notes'] == null ? null : '${a['notes']}',
      estimatedReadyAt: j['estimatedReadyAt'] == null ? null : DateTime.tryParse('${j['estimatedReadyAt']}'),
      items: (j['items'] as List? ?? const []).whereType<Map>().map((x) => '${_i(x['quantity'])}× ${x['name']}').toList(),
      paymentMethod: _s(p['method']),
      collectCents: _i(p['collectCents']),
      simulated: p['simulated'] == true,
      deliveredAt: j['deliveredAt'] == null ? null : DateTime.tryParse('${j['deliveredAt']}'),
    );
  }
  final String id;
  final String number;
  final String branchName;
  final String status; // order status
  final String driverState; // assigned | accepted | picked_up | delivered
  final String customerName;
  final String? customerPhone;
  final String address;
  final String? addressNotes;
  final DateTime? estimatedReadyAt;
  final List<String> items;
  final String paymentMethod;
  final int collectCents;
  final bool simulated;
  final DateTime? deliveredAt;

  /// Mirrors the API rules: accept/decline while assigned; pick up once accepted AND the kitchen marked it ready;
  /// delivered while out for delivery.
  bool get canRespond => driverState == 'assigned';
  bool get canPickUp => driverState == 'accepted' && status == 'ready';
  bool get waitingKitchen => driverState == 'accepted' && status != 'ready';
  bool get canDeliver => status == 'out_for_delivery';
  bool get onTheWay => status == 'out_for_delivery';
}
