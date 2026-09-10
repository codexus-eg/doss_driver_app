// ════════════════════════════════════════════════════════════════════
// FILE: doss_driver/lib/blocs/driver/driver_bloc.dart
// FIX: drivers.goOnline   → drivers.updateStatus {status: "online"}
//      drivers.goOffline  → drivers.updateStatus {status: "offline"}
//      drivers.dailyStats → drivers.getStatus (map totalRides etc.)
// ════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:doss_core/doss_core.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class DriverEvent extends Equatable {
  const DriverEvent();
  @override
  List<Object?> get props => [];
}

class DriverGoOnline extends DriverEvent {}
class DriverGoOffline extends DriverEvent {}

class DriverLocationChanged extends DriverEvent {
  final double lat;
  final double lng;
  const DriverLocationChanged(this.lat, this.lng);
  @override
  List<Object?> get props => [lat, lng];
}

class DriverStatsRequested extends DriverEvent {}

class DriverHotZoneReceived extends DriverEvent {
  final HotZoneAlert alert;
  const DriverHotZoneReceived(this.alert);
  @override
  List<Object?> get props => [alert];
}

class DriverHotZoneDismissed extends DriverEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class DriverState extends Equatable {
  const DriverState();
  @override
  List<Object?> get props => [];
}

class DriverOffline extends DriverState {}

class DriverOnline extends DriverState {
  final double? lat;
  final double? lng;
  final DriverDailyStats? stats;
  final HotZoneAlert? hotZone;

  const DriverOnline({this.lat, this.lng, this.stats, this.hotZone});

  DriverOnline copyWith({
    double? lat,
    double? lng,
    DriverDailyStats? stats,
    HotZoneAlert? hotZone,
    bool clearHotZone = false,
  }) {
    return DriverOnline(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      stats: stats ?? this.stats,
      hotZone: clearHotZone ? null : (hotZone ?? this.hotZone),
    );
  }

  @override
  List<Object?> get props => [lat, lng, stats, hotZone];
}

class DriverError extends DriverState {
  final String message;
  const DriverError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  StreamSubscription<Position>? _locationSub;
  StreamSubscription? _hotZoneSub;

  DriverBloc() : super(DriverOffline()) {
    on<DriverGoOnline>(_onGoOnline);
    on<DriverGoOffline>(_onGoOffline);
    on<DriverLocationChanged>(_onLocationChanged);
    on<DriverStatsRequested>(_onStatsRequested);
    on<DriverHotZoneReceived>(_onHotZone);
    on<DriverHotZoneDismissed>(_onHotZoneDismissed);

    _hotZoneSub = SocketService.instance.onHotZone.listen((zone) {
      add(DriverHotZoneReceived(zone));
    });
  }

  Future<void> _onGoOnline(
      DriverGoOnline event, Emitter<DriverState> emit) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        emit(const DriverError(
            'Location permission is required to go online.'));
        return;
      }

      // FIX: drivers.goOnline → drivers.updateStatus with {status: "online"}
      await ApiClient.instance.mutate(
        'drivers.updateStatus',
        input: {'status': 'online'},
      );

      emit(const DriverOnline());
      add(DriverStatsRequested());

      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((pos) {
        add(DriverLocationChanged(pos.latitude, pos.longitude));
      });
    } catch (e) {
      emit(DriverError('Failed to go online: ${e.toString()}'));
    }
  }

  Future<void> _onGoOffline(
      DriverGoOffline event, Emitter<DriverState> emit) async {
    _locationSub?.cancel();
    _locationSub = null;
    try {
      // FIX: drivers.goOffline → drivers.updateStatus with {status: "offline"}
      await ApiClient.instance.mutate(
        'drivers.updateStatus',
        input: {'status': 'offline'},
      );
    } catch (_) {}
    emit(DriverOffline());
  }

  Future<void> _onLocationChanged(
      DriverLocationChanged event, Emitter<DriverState> emit) async {
    if (state is DriverOnline) {
      final current = state as DriverOnline;
      emit(current.copyWith(lat: event.lat, lng: event.lng));
      SocketService.instance.emitLocation(event.lat, event.lng);
    }
  }

  Future<void> _onStatsRequested(
      DriverStatsRequested event, Emitter<DriverState> emit) async {
    try {
      // FIX: drivers.dailyStats → drivers.getStatus
      // Returns: {driverId, approvalStatus, driverStatus, isActive, totalRides, ...}
      final result = await ApiClient.instance.query('drivers.getStatus');

      // Map getStatus response to DriverDailyStats
      final stats = DriverDailyStats(
        ridesCompleted:
            (result['totalRides'] as num? ?? 0).toInt(),
        ridesAccepted:
            (result['ridesAccepted'] as num? ?? 0).toInt(),
        ridesCancelled:
            (result['ridesCancelled'] as num? ?? 0).toInt(),
        ridesOffered:
            (result['ridesOffered'] as num? ?? 0).toInt(),
        dailyEarningsEgp:
            (result['todayEarnings'] as num? ?? 0).toDouble(),
        idleMinutes: 0,
        onlineMinutes:
            (result['onlineMinutes'] as num? ?? 0).toInt(),
      );

      if (state is DriverOnline) {
        emit((state as DriverOnline).copyWith(stats: stats));
      }
    } catch (_) {
      // Non-fatal — stats are informational
    }
  }

  void _onHotZone(DriverHotZoneReceived event, Emitter<DriverState> emit) {
    if (state is DriverOnline) {
      emit((state as DriverOnline).copyWith(hotZone: event.alert));
    }
  }

  void _onHotZoneDismissed(
      DriverHotZoneDismissed event, Emitter<DriverState> emit) {
    if (state is DriverOnline) {
      emit((state as DriverOnline).copyWith(clearHotZone: true));
    }
  }

  @override
  Future<void> close() {
    _locationSub?.cancel();
    _hotZoneSub?.cancel();
    return super.close();
  }
}
