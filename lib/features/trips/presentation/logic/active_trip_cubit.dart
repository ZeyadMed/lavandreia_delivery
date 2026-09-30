import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_event.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_service.dart';
import 'package:lavanderia_delivery/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_otp_model.dart';

class ActiveTripState extends Equatable {
  final Status status;
  final DeliveryTripModel? trip;

  /// صور الهدوم اللي هتتبعت مع collect في رحلة الاستلام
  final List<File> photos;
  final bool isSubmitting;
  final String? errorMessage;

  const ActiveTripState({
    this.status = Status.initial,
    this.trip,
    this.photos = const [],
    this.isSubmitting = false,
    this.errorMessage,
  });

  ActiveTripState copyWith({
    Status? status,
    DeliveryTripModel? trip,
    List<File>? photos,
    bool? isSubmitting,
    String? errorMessage,
  }) => ActiveTripState(
    status: status ?? this.status,
    trip: trip ?? this.trip,
    photos: photos ?? this.photos,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, trip, photos, isSubmitting, errorMessage];
}

/// الرحلة الشغالة وخطواتها: الاستلام من العميل بالصور، أو الوصول لباب العميل،
/// وبعدين استنى تأكيد الـ OTP من المغسلة أو العميل.
///
/// مفيش GET لرحلة واحدة، فبندور عليها في رحلاتنا. والتأكيد بيوصل من الـ
/// realtime، ومعاه polling خفيف وقت الانتظار لحد ما أسامي الأحداث تتأكد
class ActiveTripCubit extends Cubit<ActiveTripState> {
  final TripsDataSource _dataSource;
  StreamSubscription<RealtimeEvent>? _subscription;
  Timer? _pollTimer;

  static const int maxPhotos = 10;
  static const Duration _pollInterval = Duration(seconds: 30);

  ActiveTripCubit(this._dataSource, RealtimeService realtime)
    : super(const ActiveTripState()) {
    _subscription = realtime.events.listen(_onRealtimeEvent);
  }

  int? _tripId;

  /// [tripId] بيتبعت لما نفتح رحلة معينة، ولو null بناخد أول رحلة شغالة
  Future<void> load({int? tripId, bool silent = false}) async {
    _tripId = tripId ?? _tripId;
    if (!silent) emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.getMyTrips(pageIndex: 1, pageSize: 50);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (!silent) {
          emit(
            state.copyWith(
              status: Status.failure,
              errorMessage: failure.message,
            ),
          );
        }
      },
      (page) {
        final trips = page.items;
        final trip = _tripId != null
            ? trips.where((t) => t.id == _tripId).firstOrNull
            : trips.where((t) => t.isActive).firstOrNull;
        if (trip == null) {
          emit(
            state.copyWith(
              status: Status.failure,
              errorMessage: 'no_active_trip'.tr(),
            ),
          );
          return;
        }
        _tripId = trip.id;
        _emitTrip(_withCachedOtp(trip));
      },
    );
  }

  /// الـ OTP مش مضمون يرجع في الليستة، فبنكمله من اللي اتحفظ وقت collect/arrive
  DeliveryTripModel _withCachedOtp(DeliveryTripModel trip) {
    if (trip.otpCode != null) return trip;
    final cached = CacheManager.getTripOtp(trip.id);
    return cached == null ? trip : trip.copyWith(otpCode: cached);
  }

  void _emitTrip(DeliveryTripModel trip) {
    emit(state.copyWith(status: Status.success, trip: trip));
    _updatePolling(trip);
    // الرحلة انتهت بأي شكل، فالـ OTP المحفوظ مالوش لازمة
    if (const {
      TripStage.completed,
      TripStage.failed,
      TripStage.cancelled,
    }.contains(trip.stage)) {
      CacheManager.clearTripData(trip.id);
    }
  }

  /// مستنيين طرف تاني يأكد: المغسلة (استلام أو تسليم للمندوب) أو العميل
  bool _isWaitingConfirmation(DeliveryTripModel trip) => const {
    TripStage.collected,
    TripStage.awaitingHandover,
    TripStage.arrived,
  }.contains(trip.stage);

  void _updatePolling(DeliveryTripModel trip) {
    if (_isWaitingConfirmation(trip)) {
      _pollTimer ??= Timer.periodic(_pollInterval, (_) => load(silent: true));
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    final trip = state.trip;
    if (trip == null) return;
    final isOurs =
        (event.tripId == null && event.orderId == null) ||
        event.tripId == trip.id ||
        (event.orderId != null && event.orderId == trip.orderId);
    if (isOurs) load(silent: true);
  }

  void addPhotos(List<File> files) {
    final photos = [...state.photos, ...files].take(maxPhotos).toList();
    emit(state.copyWith(photos: photos));
  }

  void removePhoto(int index) {
    final photos = [...state.photos]..removeAt(index);
    emit(state.copyWith(photos: photos));
  }

  /// رحلة الاستلام: بيرفع صور الهدوم وبياخد الـ OTP اللي هيتوري للمغسلة
  Future<String?> collect() async {
    final trip = state.trip;
    if (trip == null || state.isSubmitting) return null;
    if (state.photos.isEmpty) return 'add_clothes_photos_first'.tr();

    emit(state.copyWith(isSubmitting: true));
    final result = await _dataSource.collect(
      tripId: trip.id,
      photos: state.photos,
    );
    return _applyOtp(result, trip, nextStatus: 'Collected');
  }

  /// رحلة التسليم: وصلنا باب العميل وبناخد OTP جديد العميل هيأكده من عنده
  Future<String?> arrive() async {
    final trip = state.trip;
    if (trip == null || state.isSubmitting) return null;

    emit(state.copyWith(isSubmitting: true));
    final result = await _dataSource.arrive(trip.id);
    return _applyOtp(result, trip, nextStatus: 'Arrived');
  }

  /// بيحفظ الـ OTP ويحدّث الرحلة، أو بيرجع رسالة الخطأ
  Future<String?> _applyOtp(
    Either<Failure, TripOtpModel> result,
    DeliveryTripModel trip, {
    required String nextStatus,
  }) async {
    if (isClosed) return null;
    return result.fold<Future<String?>>(
      (failure) async {
        emit(state.copyWith(isSubmitting: false));
        return failure.message;
      },
      (otp) async {
        if (otp.otpCode.isNotEmpty) {
          await CacheManager.saveTripOtp(trip.id, otp.otpCode);
        }
        if (isClosed) return null;
        emit(state.copyWith(isSubmitting: false, photos: const []));
        _emitTrip(
          trip.copyWith(
            otpCode: otp.otpCode.isEmpty ? null : otp.otpCode,
            rawStatus: nextStatus,
          ),
        );
        return null;
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _pollTimer?.cancel();
    return super.close();
  }
}
