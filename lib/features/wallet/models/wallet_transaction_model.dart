import 'package:equatable/equatable.dart';
import 'package:lavanderia_delivery/features/trips/models/json_reader.dart';

/// حركة في المحفظة: رسوم استلام أو تسليم نزلت، أو سحب
class WalletTransactionModel extends Equatable {
  final int id;

  /// موجب للي دخل المحفظة وسالب للي خرج منها
  final num amount;
  final String description;
  final String type;
  final int? tripId;
  final int? orderId;
  final DateTime? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.amount,
    this.description = '',
    this.type = '',
    this.tripId,
    this.orderId,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final type = json.pickString(['type', 'transactionType']);
    final rawAmount = json.pickDouble(['amount', 'value']) ?? 0;
    // لو الباك بيرجع المبلغ موجب دايماً ومعاه النوع، السحب بيتقلب سالب
    final isDebit =
        type.toLowerCase().contains('debit') ||
        type.toLowerCase().contains('withdraw');
    return WalletTransactionModel(
      id: json.pickInt(['id', 'transactionId']) ?? 0,
      amount: isDebit && rawAmount > 0 ? -rawAmount : rawAmount,
      description: json.pickString(['description', 'note', 'title']),
      type: type,
      tripId: json.pickInt(['tripId', 'deliveryTripId']),
      orderId: json.pickInt(['orderId']),
      createdAt: json.pickDate(['createdAt', 'createdAtUtc', 'date']),
    );
  }

  bool get isCredit => amount >= 0;

  @override
  List<Object?> get props => [
    id,
    amount,
    description,
    type,
    tripId,
    orderId,
    createdAt,
  ];
}
