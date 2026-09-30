import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  const HomeState({
    this.isAvailable = false,
    this.isUpdatingAvailability = false,
    this.todayTrips = 0,
    this.todayEarnings = 0,
    this.activeTrip,
    this.resolution = TripResolution.none,
    this.resolutionTick = 0,
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
  }) => HomeState(
    isAvailable: isAvailable ?? this.isAvailable,
    isUpdatingAvailability:
        isUpdatingAvailability ?? this.isUpdatingAvailability,
    todayTrips: todayTrips ?? this.todayTrips,
    todayEarnings: todayEarnings ?? this.todayEarnings,
    activeTrip: clearActiveTrip ? null : activeTrip ?? this.activeTrip,
    resolution: resolution ?? this.resolution,
    resolutionTick: resolutionTick ?? this.resolutionTick,
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
  ];
}

/// حالة التوفر وإحصائيات اليوم والرحلة الحالية، وبتسمع على رد المغسلة
/// على طلبات الرحلات عشان تعرضه وتفتح الرحلة لو اتقبلت
class HomeCubit extends Cubit<HomeState> {
  final TripsDataSource _tripsDataSource;
  final ProfileDataSource _profileDataSource;
  StreamSubscription<RealtimeEvent>? _subscription;

  HomeCubit(
    this._tripsDataSource,
    this._profileDataSource,
    RealtimeService realtime,
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
    result.fold(
      (_) {},
      (profile) => emit(state.copyWith(isAvailable: profile.isAvailable)),
    );
  }

  /// الرحلة الحالية وإحصائيات النهارده من رحلاتنا، لحد ما يبقى فيه endpoint للإحصائيات
  Future<void> loadMyTrips() async {
    final result = await _tripsDataSource.getMyTrips(
      pageIndex: 1,
      pageSize: 30,
    );
    if (isClosed) return;
    result.fold((_) {}, (page) {
      final active = page.items.where((trip) => trip.isActive).firstOrNull;
      final today = page.items.where(
        (trip) =>
            trip.stage == TripStage.completed &&
            _isToday(trip.completedAt ?? trip.createdAt),
      );
      emit(
        state.copyWith(
          activeTrip: active,
          clearActiveTrip: active == null,
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
        emit(state.copyWith(isUpdatingAvailability: false));
        return null;
      },
    );
  }

  Future<void> _onRealtimeEvent(RealtimeEvent event) async {
    final previousActiveId = state.activeTrip?.id;
    await loadMyTrips();
    if (isClosed || !event.isTripRequestResolved) return;

    // لو الـ payload مش بيقول اتقبلنا ولا لأ، بنعرف من إن رحلة جديدة اتعيّنت علينا
    final active = state.activeTrip;
    final approved =
        event.isApproved ??
        (active != null &&
            active.id != previousActiveId &&
            (event.tripId == null || active.id == event.tripId));
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
