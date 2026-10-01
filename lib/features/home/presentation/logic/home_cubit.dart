import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/realtime/driver_location_reporter.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_event.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_service.dart';
import 'package:lavanderia_delivery/features/profile/data/profile_data_source.dart';
import 'package:lavanderia_delivery/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';

/// رد المغسلة على طلب رحلة، بيتعرض مرة واحدة لما resolutionTick يتغير
enum TripResolution { none, approved, rejected }

class HomeState extends Equatable {
  final bool isAvailable;
  final bool isUpdatingAvailability;
  final int todayTrips;
  final num todayEarnings;

  /// الرحلة اللي متعيّنة علينا ولسه ماخلصتش، بتظهر كـ banner فوق
  final DeliveryTripModel? activeTrip;
  final TripResolution resolution;
  final int resolutionTick;

  /// رحلة جديدة وصلت من NewTripAvailable، بتتعرض popup لما newTripTick يتغير
  final DeliveryTripModel? newTrip;
  final int newTripTick;

  const HomeState({
    this.isAvailable = false,
    this.isUpdatingAvailability = false,
    this.todayTrips = 0,
    this.todayEarnings = 0,
    this.activeTrip,
    this.resolution = TripResolution.none,
    this.resolutionTick = 0,
    this.newTrip,
    this.newTripTick = 0,
  });

  HomeState copyWith({
    bool? isAvailable,
    bool? isUpdatingAvailability,
    int? todayTrips,
    num? todayEarnings,
    DeliveryTripModel? activeTrip,
    bool clearActiveTrip = false,
    TripResolution? resolution,
    int? resolutionTick,
    DeliveryTripModel? newTrip,
    int? newTripTick,
  }) => HomeState(
    isAvailable: isAvailable ?? this.isAvailable,
    isUpdatingAvailability:
        isUpdatingAvailability ?? this.isUpdatingAvailability,
    todayTrips: todayTrips ?? this.todayTrips,
    todayEarnings: todayEarnings ?? this.todayEarnings,
    activeTrip: clearActiveTrip ? null : activeTrip ?? this.activeTrip,
    resolution: resolution ?? this.resolution,
    resolutionTick: resolutionTick ?? this.resolutionTick,
    newTrip: newTrip ?? this.newTrip,
    newTripTick: newTripTick ?? this.newTripTick,
  );

  @override
  List<Object?> get props => [
    isAvailable,
    isUpdatingAvailability,
    todayTrips,
    todayEarnings,
    activeTrip,
    resolution,
    resolutionTick,
    newTrip,
    newTripTick,
  ];
}

/// حالة التوفر وإحصائيات اليوم والرحلة الحالية. بتعرض الرحلات الجديدة
/// اللي بتنزل في النطاق، ورد المغسلة على طلباتنا وتفتح الرحلة لو اتقبلت.
/// وطول ما المندوب متاح بتشغّل إرسال الموقع عشان الرحلات الجديدة توصله
class HomeCubit extends Cubit<HomeState> {
  final TripsDataSource _tripsDataSource;
  final ProfileDataSource _profileDataSource;
  final DriverLocationReporter _locationReporter;
  StreamSubscription<RealtimeEvent>? _subscription;

  HomeCubit(
    this._tripsDataSource,
    this._profileDataSource,
    RealtimeService realtime,
    this._locationReporter,
  ) : super(const HomeState()) {
    _subscription = realtime.events.listen(_onRealtimeEvent);
  }

  Future<void> load() async {
    await Future.wait([_loadAvailability(), loadMyTrips()]);
  }

  /// القيمة المبدئية للتوفر محفوظة في البروفايل عند الباك
  Future<void> _loadAvailability() async {
    final result = await _profileDataSource.getProfile();
    if (isClosed) return;
    result.fold((_) {}, (profile) {
      _syncLocationReporter(profile.isAvailable);
      emit(state.copyWith(isAvailable: profile.isAvailable));
    });
  }

  void _syncLocationReporter(bool isAvailable) =>
      isAvailable ? _locationReporter.start() : _locationReporter.stop();

  /// الرحلة الحالية وإحصائيات النهارده
  Future<void> loadMyTrips() async {
    await Future.wait([_loadCurrentTrip(), _loadTodayStats()]);
  }

  Future<void> _loadCurrentTrip() async {
    final result = await _tripsDataSource.getCurrentTrip();
    if (isClosed) return;
    result.fold(
      (_) {},
      (trip) =>
          emit(state.copyWith(activeTrip: trip, clearActiveTrip: trip == null)),
    );
  }

  /// من رحلاتنا، لحد ما يبقى فيه endpoint للإحصائيات
  Future<void> _loadTodayStats() async {
    final result = await _tripsDataSource.getMyTrips(
      pageIndex: 1,
      pageSize: 30,
    );
    if (isClosed) return;
    result.fold((_) {}, (page) {
      final today = page.items.where(
        (trip) =>
            trip.stage == TripStage.completed &&
            _isToday(trip.completedAt ?? trip.createdAt),
      );
      emit(
        state.copyWith(
          todayTrips: today.length,
          todayEarnings: today.fold<num>(0, (sum, trip) => sum + trip.fee),
        ),
      );
    });
  }

  /// بيتغير في الـ UI على طول، ولو الريكوست فشل بيرجع زي ما كان
  /// وبترجع رسالة الخطأ عشان الشاشة تعرضها
  Future<String?> toggleAvailability(bool value) async {
    if (state.isUpdatingAvailability) return null;
    final previous = state.isAvailable;
    emit(state.copyWith(isAvailable: value, isUpdatingAvailability: true));

    final result = await _tripsDataSource.setAvailability(value);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        emit(
          state.copyWith(isAvailable: previous, isUpdatingAvailability: false),
        );
        return failure.message;
      },
      (_) {
        _syncLocationReporter(value);
        emit(state.copyWith(isUpdatingAvailability: false));
        return null;
      },
    );
  }

  Future<void> _onRealtimeEvent(RealtimeEvent event) async {
    if (event.isNewTrip) return _onNewTrip(event);
    if (event.isTripRequestResolved) return _onRequestResolved(event);
    final active = state.activeTrip;
    // تأكيد استلام أو تسليم بيغيّر الرحلة الحالية وأرباح النهارده
    if (event.isResync ||
        (event.isOrderUpdated &&
            (active == null || event.orderId == active.orderId))) {
      await loadMyTrips();
    }
  }

  void _onNewTrip(RealtimeEvent event) {
    final trip = event.trip;
    if (trip == null || !state.isAvailable) return;
    emit(state.copyWith(newTrip: trip, newTripTick: state.newTripTick + 1));
  }

  Future<void> _onRequestResolved(RealtimeEvent event) async {
    final approved = event.isApproved ?? false;
    final tripId = event.tripId;
    if (approved && tripId != null) {
      final result = await _tripsDataSource.getTripDetails(tripId);
      if (isClosed) return;
      result.fold((_) {}, (trip) => emit(state.copyWith(activeTrip: trip)));
      if (state.activeTrip?.id != tripId) await _loadCurrentTrip();
      if (isClosed) return;
    }
    emit(
      state.copyWith(
        resolution: approved
            ? TripResolution.approved
            : TripResolution.rejected,
        resolutionTick: state.resolutionTick + 1,
      ),
    );
  }

  static bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
