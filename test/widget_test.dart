import 'package:flutter_test/flutter_test.dart';
import 'package:la_toscana_driver/models.dart';

Assignment _a(String status, String driverState, {String method = 'cash', int collect = 2780}) => Assignment.fromJson({
      'id': 'o1',
      'number': 'BAR-261013-004',
      'branch': {'name': 'La Toscana Barbastro'},
      'status': status,
      'driverState': driverState,
      'customer': {'name': 'Laura', 'phone': '+34 600 000 000'},
      'address': {'line1': 'Calle Mayor 1', 'postcode': '22300', 'city': 'Barbastro', 'notes': '2º B'},
      'items': [
        {'name': 'Barbacoa', 'quantity': 2},
      ],
      'payment': {'method': method, 'collectCents': collect},
    });

void main() {
  test('actions follow the API rules', () {
    expect(_a('preparing', 'assigned').canRespond, isTrue);
    expect(_a('preparing', 'accepted').canPickUp, isFalse);
    expect(_a('preparing', 'accepted').waitingKitchen, isTrue);
    expect(_a('ready', 'accepted').canPickUp, isTrue);
    expect(_a('out_for_delivery', 'picked_up').canDeliver, isTrue);
    expect(_a('out_for_delivery', 'picked_up').onTheWay, isTrue);
  });

  test('address and cash to collect', () {
    final a = _a('ready', 'accepted');
    expect(a.address, 'Calle Mayor 1, 22300 Barbastro');
    expect(a.addressNotes, '2º B');
    expect(a.items, ['2× Barbacoa']);
    expect(a.collectCents, 2780);
    expect(_a('ready', 'accepted', method: 'card', collect: 0).collectCents, 0);
  });
}
