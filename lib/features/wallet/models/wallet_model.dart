import 'package:equatable/equatable.dart';
import 'package:lavanderia_delivery/features/trips/models/json_reader.dart';

/// رصيد محفظة المندوب من GET api/driver/wallet.
/// الإجماليات (النهارده والأسبوع والشهر) مش متأكدين إن الباك بيرجعها،
/// فبتفضل null ونحسبها من الحركات لو مش موجودة
class WalletModel extends Equatable {
  final num balance;
  final num? totalEarnings;
  final num? todayEarnings;
  final num? weekEarnings;
  final num? monthEarnings;
  final int? completedTrips;
  final int? todayTrips;

  const WalletModel({
    required this.balance,
    this.totalEarnings,
    this.todayEarnings,
    this.weekEarnings,
    this.monthEarnings,
    this.completedTrips,
    this.todayTrips,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: json.pickDouble(['balance', 'currentBalance', 'amount']) ?? 0,
      totalEarnings: json.pickDouble(['totalEarnings', 'totalCredits']),
      todayEarnings: json.pickDouble(['todayEarnings']),
      weekEarnings: json.pickDouble(['weekEarnings', 'weeklyEarnings']),
      monthEarnings: json.pickDouble(['monthEarnings', 'monthlyEarnings']),
      completedTrips: json.pickInt(['completedTrips', 'tripsCount']),
      todayTrips: json.pickInt(['todayTrips']),
    );
  }

  @override
  List<Object?> get props => [
    balance,
    totalEarnings,
    todayEarnings,
    weekEarnings,
    monthEarnings,
    completedTrips,
    todayTrips,
  ];
}
