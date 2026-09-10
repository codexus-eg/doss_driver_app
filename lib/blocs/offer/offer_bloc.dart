// ════════════════════════════════════════════════════════════════════
// FILE: doss_driver/lib/blocs/offer/offer_bloc.dart
// FIX: rides.acceptOffer with {offerId} → {rideId}
//      rides.rejectOffer with {offerId} → {rideId}
// ════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:doss_core/doss_core.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class OfferEvent extends Equatable {
  const OfferEvent();
  @override
  List<Object?> get props => [];
}

class OfferReceived extends OfferEvent {
  final RideOffer offer;
  const OfferReceived(this.offer);
  @override
  List<Object?> get props => [offer];
}

class OfferAccepted extends OfferEvent {
  final String offerId;
  const OfferAccepted(this.offerId);
  @override
  List<Object?> get props => [offerId];
}

class OfferRejected extends OfferEvent {
  final String offerId;
  const OfferRejected(this.offerId);
  @override
  List<Object?> get props => [offerId];
}

class OfferTimerTick extends OfferEvent {
  final int secondsRemaining;
  const OfferTimerTick(this.secondsRemaining);
  @override
  List<Object?> get props => [secondsRemaining];
}

class OfferExpired extends OfferEvent {}
class OfferRideCompleted extends OfferEvent {}
class OfferReset extends OfferEvent {}

class OfferRideStatusUpdated extends OfferEvent {
  final Map<String, dynamic> payload;
  const OfferRideStatusUpdated(this.payload);
  @override
  List<Object?> get props => [payload];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class OfferState extends Equatable {
  const OfferState();
  @override
  List<Object?> get props => [];
}

class OfferIdle extends OfferState {}
class OfferAccepting extends OfferState {}
class OfferDeclined extends OfferState {}
class OfferTimedOut extends OfferState {}

class OfferPending extends OfferState {
  final RideOffer offer;
  final int secondsRemaining;
  const OfferPending(this.offer, this.secondsRemaining);
  @override
  List<Object?> get props => [offer, secondsRemaining];
}

class OfferActive extends OfferState {
  final RideOffer offer;
  final RideStatus status;
  const OfferActive(this.offer, this.status);
  @override
  List<Object?> get props => [offer, status];
}

class OfferRideFinished extends OfferState {
  final double fareEgp;
  const OfferRideFinished(this.fareEgp);
  @override
  List<Object?> get props => [fareEgp];
}

class OfferError extends OfferState {
  final String message;
  const OfferError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

const int _kOfferTimeoutSeconds = 30;

class OfferBloc extends Bloc<OfferEvent, OfferState> {
  Timer? _countdownTimer;
  StreamSubscription? _offerSub;
  StreamSubscription? _statusSub;

  // Keep track of current offer for rideId lookup
  RideOffer? _currentOffer;

  OfferBloc() : super(OfferIdle()) {
    on<OfferReceived>(_onReceived);
    on<OfferAccepted>(_onAccepted);
    on<OfferRejected>(_onRejected);
    on<OfferTimerTick>(_onTick);
    on<OfferExpired>(_onExpired);
    on<OfferRideStatusUpdated>(_onStatusUpdate);
    on<OfferRideCompleted>(_onRideCompleted);
    on<OfferReset>(_onReset);

    _offerSub = SocketService.instance.onRideOffer.listen((offer) {
      add(OfferReceived(offer));
    });
    _statusSub = SocketService.instance.onRideStatus.listen((payload) {
      add(OfferRideStatusUpdated(payload));
    });
  }

  void _onReceived(OfferReceived event, Emitter<OfferState> emit) {
    _countdownTimer?.cancel();
    _currentOffer = event.offer;
    emit(OfferPending(event.offer, _kOfferTimeoutSeconds));

    int remaining = _kOfferTimeoutSeconds;
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        add(OfferExpired());
      } else {
        add(OfferTimerTick(remaining));
      }
    });
  }

  Future<void> _onAccepted(
      OfferAccepted event, Emitter<OfferState> emit) async {
    _countdownTimer?.cancel();

    // Get the current offer to find rideId
    final offer = _currentOffer ??
        (state is OfferPending ? (state as OfferPending).offer : null);

    emit(OfferAccepting());
    try {
      // FIX: Backend expects {rideId} not {offerId}
      // offer.rideId is the correct field to send
      final rideId = offer?.rideId ?? event.offerId;
      await ApiClient.instance.mutate(
        'rides.acceptOffer',
        input: {'rideId': rideId},
      );

      if (offer != null) {
        emit(OfferActive(offer, RideStatus.accepted));
      } else {
        emit(OfferIdle());
      }
    } catch (e) {
      emit(OfferError('Failed to accept ride: ${e.toString()}'));
    }
  }

  Future<void> _onRejected(
      OfferRejected event, Emitter<OfferState> emit) async {
    _countdownTimer?.cancel();

    final offer = _currentOffer ??
        (state is OfferPending ? (state as OfferPending).offer : null);

    try {
      // FIX: Backend expects {rideId} not {offerId}
      final rideId = offer?.rideId ?? event.offerId;
      await ApiClient.instance.mutate(
        'rides.rejectOffer',
        input: {'rideId': rideId},
      );
    } catch (_) {}

    _currentOffer = null;
    emit(OfferDeclined());
    await Future.delayed(const Duration(seconds: 2));
    if (!isClosed) emit(OfferIdle());
  }

  void _onTick(OfferTimerTick event, Emitter<OfferState> emit) {
    if (state is OfferPending) {
      emit(OfferPending(
          (state as OfferPending).offer, event.secondsRemaining));
    }
  }

  void _onExpired(OfferExpired event, Emitter<OfferState> emit) {
    _currentOffer = null;
    emit(OfferTimedOut());
    Future.delayed(const Duration(seconds: 2), () {
      if (!isClosed) add(OfferReset());
    });
  }

  void _onStatusUpdate(
      OfferRideStatusUpdated event, Emitter<OfferState> emit) {
    if (state is! OfferActive) return;
    final current = state as OfferActive;
    final statusStr = event.payload['status'] as String? ?? '';
    final status = rideStatusFromString(statusStr);

    if (status == RideStatus.completed ||
        status == RideStatus.cancelled) {
      final fare = (event.payload['fareEgp'] as num?)?.toDouble() ??
          current.offer.fareEgp;
      if (status == RideStatus.completed) {
        emit(OfferRideFinished(fare));
      } else {
        _currentOffer = null;
        emit(OfferIdle());
      }
    } else {
      emit(OfferActive(current.offer, status));
    }
  }

  void _onRideCompleted(
      OfferRideCompleted event, Emitter<OfferState> emit) {
    if (state is OfferActive) {
      emit(OfferRideFinished((state as OfferActive).offer.fareEgp));
    }
  }

  void _onReset(OfferReset event, Emitter<OfferState> emit) {
    _countdownTimer?.cancel();
    _currentOffer = null;
    emit(OfferIdle());
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _offerSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
