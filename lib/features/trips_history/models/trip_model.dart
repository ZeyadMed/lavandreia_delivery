enum TripStatus { completed, rejected, cancelled }

class TripModel {
  final String orderNumber;
  final String customerName;
  final String laundryName;
  final String destination;
  final double price;
  final DateTime date;
  final TripStatus status;

  const TripModel({
    required this.orderNumber,
    required this.customerName,
    required this.laundryName,
    required this.destination,
    required this.price,
    required this.date,
    required this.status,
  });
}
