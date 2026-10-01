import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_event.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/models/order_status.dart';
import 'package:lavanderia_delivery/features/trips/models/paged_model.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_otp_model.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_request_model.dart';
import 'package:lavanderia_delivery/features/wallet/models/wallet_transaction_model.dart';

void main() {
  group('DeliveryTripModel', () {
    test('reads flat fields and maps pickup from customer to laundry', () {
      final trip = DeliveryTripModel.fromJson({
        'id': 7,
        'orderId': 42,
        'type': 'Pickup',
        'fee': 15.5,
        'distanceKm': 3.2,
        'pickupContactName': 'Ali',
        'pickupContactPhoneNumber': '0911',
        'deliveryAddress': 'Home',
        'latitude': 32.1,
        'longitude': 13.2,
        'laundryName': 'Clean',
        'laundryLatitude': 32.5,
        'laundryLongitude': 13.5,
      });

      expect(trip.id, 7);
      expect(trip.orderId, 42);
      expect(trip.type, TripType.pickup);
      expect(trip.fee, 15.5);
      expect(trip.from.name, 'Ali');
      expect(trip.from.phone, '0911');
      expect(trip.from.hasLocation, isTrue);
      expect(trip.to.name, 'Clean');
      expect(trip.to.latitude, 32.5);
    });

    test('reads nested laundry and order objects', () {
      final trip = DeliveryTripModel.fromJson({
        'tripId': 3,
        'tripType': 1,
        'laundry': {'name': 'Nested', 'phoneNumber': '0922', 'latitude': 1.0},
        'order': {'id': 9, 'status': 'Ready', 'deliveryAddress': 'Flat 2'},
      });

      expect(trip.id, 3);
      expect(trip.type, TripType.dropoff);
      expect(trip.orderId, 9);
      expect(trip.orderStatus, OrderStatus.ready);
      expect(trip.laundry.name, 'Nested');
      expect(trip.laundry.phone, '0922');
      expect(trip.customer.address, 'Flat 2');
      // Dropoff: من المغسلة للعميل
      expect(trip.from.name, 'Nested');
    });

    test('infers stage from trip status', () {
      DeliveryTripModel withStatus(String status, [String type = 'Pickup']) =>
          DeliveryTripModel.fromJson({'id': 1, 'type': type, 'status': status});

      expect(withStatus('Pending').stage, TripStage.awaitingDriver);
      expect(withStatus('Assigned').stage, TripStage.assigned);
      expect(withStatus('Collected').stage, TripStage.collected);
      expect(withStatus('Arrived', 'Dropoff').stage, TripStage.arrived);
      expect(withStatus('Completed').stage, TripStage.completed);
      expect(withStatus('Cancelled').stage, TripStage.cancelled);
      expect(withStatus('Assigned').isActive, isTrue);
      expect(withStatus('Completed').isActive, isFalse);
    });

    test(
      'order status marks the trip completed even if trip status is vague',
      () {
        final pickupDone = DeliveryTripModel.fromJson({
          'id': 1,
          'type': 'Pickup',
          'status': 'InProgress',
          'orderStatus': 'AtLaundryPendingMatch',
        });
        final dropoffNotDone = DeliveryTripModel.fromJson({
          'id': 2,
          'type': 'Dropoff',
          'orderStatus': 'OutForDelivery',
        });

        expect(pickupDone.stage, TripStage.completed);
        expect(dropoffNotDone.stage, TripStage.assigned);
      },
    );

    test('an OTP without a clear status means collected / arrived', () {
      final pickup = DeliveryTripModel.fromJson({
        'id': 1,
        'type': 'Pickup',
        'otpCode': '1234',
      });
      final updated = pickup.copyWith(otpCode: '5678');

      expect(pickup.stage, TripStage.collected);
      expect(
        DeliveryTripModel.fromJson({'id': 2, 'type': 'Dropoff', 'otp': '9999'})
            .stage,
        TripStage.arrived,
      );
      expect(updated.otpCode, '5678');
    });
  });

  group('OrderStatus', () {
    test('parses names case-insensitively, including the new statuses', () {
      expect(OrderStatus.parse('OutForDelivery'), OrderStatus.outForDelivery);
      expect(
        OrderStatus.parse('awaitingdropoffcollection'),
        OrderStatus.awaitingDropoffCollection,
      );
      expect(OrderStatus.parse('PickupFailed'), OrderStatus.pickupFailed);
      expect(OrderStatus.parse('DeliveryFailed'), OrderStatus.deliveryFailed);
      expect(OrderStatus.parse('Cancelled'), OrderStatus.cancelled);
    });

    test('parses numbers in swagger order', () {
      expect(OrderStatus.parse(0), OrderStatus.newOrder);
      expect(OrderStatus.parse(6), OrderStatus.outForDelivery);
      expect(OrderStatus.parse(9), OrderStatus.awaitingDropoffCollection);
      expect(OrderStatus.parse(12), OrderStatus.cancelled);
    });

    test('unknown values are not treated as New', () {
      expect(OrderStatus.parse('SomethingNew'), OrderStatus.unknown);
      expect(OrderStatus.parse(99), OrderStatus.unknown);
      expect(OrderStatus.parse(null), OrderStatus.unknown);
    });
  });

  group('TripStage from the new order statuses', () {
    DeliveryTripModel trip(String type, String orderStatus, {String? status}) =>
        DeliveryTripModel.fromJson({
          'id': 5,
          'type': type,
          'orderStatus': orderStatus,
          'status': ?status,
        });

    test('AwaitingDropoffCollection waits for the laundry handover', () {
      final dropoff = trip('Dropoff', 'AwaitingDropoffCollection');
      expect(dropoff.stage, TripStage.awaitingHandover);
      expect(dropoff.isActive, isTrue);
    });

    test('dropoff collected at the laundry keeps waiting for the handover', () {
      final dropoff = trip(
        'Dropoff',
        'AwaitingDropoffCollection',
      ).copyWith(otpCode: '1234', rawStatus: 'Collected');
      expect(dropoff.stage, TripStage.awaitingHandover);
      expect(dropoff.otpCode, '1234');
    });

    test(
      'AwaitingDropoffCollection in the status field is not "collected"',
      () {
        final dropoff = DeliveryTripModel.fromJson({
          'id': 5,
          'type': 'Dropoff',
          'status': 'AwaitingDropoffCollection',
        });
        expect(dropoff.orderStatus, OrderStatus.awaitingDropoffCollection);
        expect(dropoff.stage, TripStage.awaitingHandover);
      },
    );

    test('OutForDelivery allows arrive, then arrived with an OTP', () {
      expect(trip('Dropoff', 'OutForDelivery').stage, TripStage.assigned);
      expect(
        trip('Dropoff', 'OutForDelivery').copyWith(otpCode: '1234').stage,
        TripStage.arrived,
      );
    });

    test('failed and cancelled trips are no longer active', () {
      final pickupFailed = trip('Pickup', 'PickupFailed');
      final deliveryFailed = trip('Dropoff', 'DeliveryFailed');
      final cancelled = trip('Dropoff', 'Cancelled');

      expect(pickupFailed.stage, TripStage.failed);
      expect(deliveryFailed.stage, TripStage.failed);
      expect(cancelled.stage, TripStage.cancelled);
      expect(
        [pickupFailed, deliveryFailed, cancelled].any((t) => t.isActive),
        isFalse,
      );
    });

    test('a failed delivery does not fail the earlier pickup trip', () {
      expect(trip('Pickup', 'DeliveryFailed').stage, TripStage.completed);
      expect(
        trip('Pickup', 'AwaitingDropoffCollection').stage,
        TripStage.completed,
      );
    });

    test('an order cancelled after a completed pickup keeps it completed', () {
      expect(
        trip('Pickup', 'Cancelled', status: 'Completed').stage,
        TripStage.completed,
      );
      expect(trip('Pickup', 'Cancelled').stage, TripStage.cancelled);
    });
  });

  group('PagedModel', () {
    test('reads items and pagination inside data map', () {
      final page = PagedModel.fromJson(
        {
          'items': [
            {'id': 1, 'type': 'Pickup'},
            {'id': 2, 'type': 'Dropoff'},
          ],
          'pageIndex': 1,
          'totalPages': 3,
          'totalCount': 25,
        },
        itemFromJson: DeliveryTripModel.fromJson,
        pageIndex: 1,
        pageSize: 10,
      );

      expect(page.items.length, 2);
      expect(page.pagination.pagesCount, 3);
      expect(page.pagination.total, 25);
    });

    test('reads a data list at the root of the response', () {
      final page = PagedModel.fromJson(
        {
          'data': [
            {'id': 5},
          ],
        },
        itemFromJson: DeliveryTripModel.fromJson,
        pageIndex: 2,
        pageSize: 10,
      );

      expect(page.items.single.id, 5);
      expect(page.pagination.currentPage, 2);
    });
  });

  group('TripOtpModel', () {
    test('reads otp nested in data', () {
      expect(
        TripOtpModel.fromJson({
          'data': {'otpCode': '4321'},
        }).otpCode,
        '4321',
      );
    });

    test('reads otp when data is the code itself', () {
      expect(TripOtpModel.fromJson({'data': 8765}).otpCode, '8765');
    });

    test('reads otp at the root', () {
      expect(TripOtpModel.fromJson({'otp': '1111'}).otpCode, '1111');
    });
  });

  test('TripRequestModel reads status and nested trip', () {
    final request = TripRequestModel.fromJson({
      'id': 10,
      'status': 'Approved',
      'trip': {'id': 4, 'type': 'Pickup'},
    });

    expect(request.status, TripRequestStatus.approved);
    expect(request.tripId, 4);
    expect(
      TripRequestModel.fromJson({'id': 1, 'tripId': 2}).status,
      TripRequestStatus.pending,
    );
  });

  test('WalletTransactionModel treats withdrawals as negative', () {
    final debit = WalletTransactionModel.fromJson({
      'id': 1,
      'amount': 20,
      'type': 'Withdrawal',
    });
    final credit = WalletTransactionModel.fromJson({
      'id': 2,
      'amount': 12,
      'type': 'Credit',
    });

    expect(debit.amount, -20);
    expect(debit.isCredit, isFalse);
    expect(credit.isCredit, isTrue);
  });

  group('RealtimeEvent', () {
    test('TripRequestResolved reads DeliveryTripRequestDto', () {
      const approved = RealtimeEvent(
        name: 'TripRequestResolved',
        data: {'id': 9, 'deliveryTripId': 3, 'status': 'Approved'},
      );
      const rejected = RealtimeEvent(
        name: 'TripRequestResolved',
        data: {'id': 10, 'deliveryTripId': 4, 'status': 'Rejected'},
      );

      expect(approved.isTripRequestResolved, isTrue);
      expect(approved.tripId, 3);
      expect(approved.isApproved, isTrue);
      expect(rejected.tripId, 4);
      expect(rejected.isApproved, isFalse);
    });

    test('unknown approval stays null', () {
      const event = RealtimeEvent(name: 'TripRequestResolved');
      expect(event.isApproved, isNull);
      expect(event.isNewTrip, isFalse);
    });

    test('NewTripAvailable carries the full trip', () {
      const event = RealtimeEvent(
        name: 'NewTripAvailable',
        data: {
          'id': 5,
          'orderId': 11,
          'type': 'Dropoff',
          'fee': 20,
          'distanceKm': 2.5,
        },
      );

      expect(event.tripId, 5);
      expect(event.orderId, 11);
      expect(event.trip?.type, TripType.dropoff);
      expect(event.trip?.distanceKm, 2.5);
    });

    test('OrderUpdated id is the order id', () {
      const event = RealtimeEvent(
        name: 'OrderUpdated',
        data: {'id': 11, 'status': 'OutForDelivery'},
      );

      expect(event.orderId, 11);
      expect(event.tripId, isNull);
      expect(event.orderStatus, OrderStatus.outForDelivery);
    });
  });

  group('DeliveryTripModel stage from confirmation flags', () {
    DeliveryTripModel trip(Map<String, dynamic> json) =>
        DeliveryTripModel.fromJson({'id': 1, ...json});

    test('pickup waiting for laundry OTP is collected', () {
      final t = trip({
        'type': 'Pickup',
        'orderStatus': 'AwaitingPickup',
        'isAwaitingConfirmation': true,
        'awaitingConfirmationBy': 'Laundry',
      });
      expect(t.stage, TripStage.collected);
    });

    test('pickup confirmed by laundry is completed', () {
      final t = trip({
        'type': 'Pickup',
        'orderStatus': 'AwaitingPickup',
        'isConfirmed': true,
      });
      expect(t.stage, TripStage.completed);
    });

    test('dropoff waiting for laundry handover', () {
      final t = trip({
        'type': 'Dropoff',
        'orderStatus': 'AwaitingDropoffCollection',
        'isAwaitingConfirmation': true,
        'awaitingConfirmationBy': 'Laundry',
      });
      expect(t.stage, TripStage.awaitingHandover);
    });

    test('dropoff handed over goes to the customer', () {
      final t = trip({
        'type': 'Dropoff',
        'orderStatus': 'OutForDelivery',
        'isHandedOver': true,
      });
      expect(t.isHandedOver, isTrue);
      expect(t.stage, TripStage.assigned);
    });

    test('dropoff collected at the laundry shows its OTP', () {
      final t = trip({
        'type': 'Dropoff',
        'orderStatus': 'AwaitingDropoffCollection',
        'isAwaitingConfirmation': true,
        'awaitingConfirmationBy': 'Laundry',
        'otpCode': '4321',
      });
      expect(t.stage, TripStage.awaitingHandover);
      expect(t.otpCode, '4321');
    });

    test('dropoff after the handover goes to the customer without an OTP', () {
      final t = trip({'type': 'Dropoff', 'orderStatus': 'OutForDelivery'});
      expect(t.otpCode, isNull);
      expect(t.stage, TripStage.assigned);
    });

    test('dropoff waiting for customer OTP is arrived', () {
      final t = trip({
        'type': 'Dropoff',
        'orderStatus': 'OutForDelivery',
        'isHandedOver': true,
        'isAwaitingConfirmation': true,
        'awaitingConfirmationBy': 'Customer',
      });
      expect(t.stage, TripStage.arrived);
    });

    test('failed dropoff wins over a pending OTP', () {
      final t = trip({
        'type': 'Dropoff',
        'orderStatus': 'DeliveryFailed',
        'isAwaitingConfirmation': true,
        'awaitingConfirmationBy': 'Customer',
      });
      expect(t.stage, TripStage.failed);
    });
  });
}
