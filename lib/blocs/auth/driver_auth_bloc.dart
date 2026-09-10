import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:doss_core/doss_core.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class DriverAuthEvent extends Equatable {
  const DriverAuthEvent();
  @override
  List<Object?> get props => [];
}

class DriverAuthCheckRequested extends DriverAuthEvent {}
class DriverAuthCheckStatus extends DriverAuthEvent {}

class DriverAuthLoginRequested extends DriverAuthEvent {
  final String phone;
  final String password;
  const DriverAuthLoginRequested({required this.phone, required this.password});
  @override
  List<Object?> get props => [phone, password];
}

class DriverAuthRegisterRequested extends DriverAuthEvent {
  final String name;
  final String phone;
  final String password;
  final String vehiclePlate;
  final String vehicleModel;
  final String governorate;
  const DriverAuthRegisterRequested({
    required this.name,
    required this.phone,
    required this.password,
    required this.vehiclePlate,
    required this.vehicleModel,
    required this.governorate,
  });
  @override
  List<Object?> get props =>
      [name, phone, password, vehiclePlate, vehicleModel, governorate];
}

class DriverAuthLogoutRequested extends DriverAuthEvent {}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class DriverAuthState extends Equatable {
  const DriverAuthState();
  @override
  List<Object?> get props => [];
}

class DriverAuthInitial extends DriverAuthState {}
class DriverAuthLoading extends DriverAuthState {}

class DriverAuthAuthenticated extends DriverAuthState {
  final AuthUser user;
  const DriverAuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class DriverAuthUnauthenticated extends DriverAuthState {}

class DriverAuthPending extends DriverAuthState {
  final String message;
  const DriverAuthPending(this.message);
  @override
  List<Object?> get props => [message];
}

class DriverAuthFailure extends DriverAuthState {
  final String message;
  const DriverAuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class DriverAuthBloc extends Bloc<DriverAuthEvent, DriverAuthState> {
  DriverAuthBloc() : super(DriverAuthInitial()) {
    on<DriverAuthCheckRequested>(_onCheck);
    on<DriverAuthCheckStatus>(_onCheck);
    on<DriverAuthLoginRequested>(_onLogin);
    on<DriverAuthRegisterRequested>(_onRegister);
    on<DriverAuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheck(
      DriverAuthEvent event, Emitter<DriverAuthState> emit) async {
    emit(DriverAuthLoading());
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        emit(DriverAuthAuthenticated(user));
        _connectSocket(user.token);
        return;
      }
      final restored = await AuthService.instance.restoreSession()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (restored != null) {
        emit(DriverAuthAuthenticated(restored));
        _connectSocket(restored.token);
      } else {
        emit(DriverAuthUnauthenticated());
      }
    } catch (_) {
      emit(DriverAuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
      DriverAuthLoginRequested event, Emitter<DriverAuthState> emit) async {
    emit(DriverAuthLoading());
    try {
      final user = await AuthService.instance.login(
        phone: event.phone,
        password: event.password,
        entity: 'driver',
      ).timeout(const Duration(seconds: 20));
      emit(DriverAuthAuthenticated(user));
      _connectSocket(user.token);
    } catch (e) {
      emit(DriverAuthFailure(_parseError(e)));
    }
  }

  Future<void> _onRegister(
      DriverAuthRegisterRequested event, Emitter<DriverAuthState> emit) async {
    emit(DriverAuthLoading());
    try {
      await AuthService.instance.registerDriver(
        name: event.name,
        phone: event.phone,
        password: event.password,
        vehiclePlate: event.vehiclePlate,
        vehicleModel: event.vehicleModel,
      );
      emit(const DriverAuthPending(
        'Your application has been submitted. You will be notified once approved.',
      ));
    } catch (e) {
      emit(DriverAuthFailure(_parseError(e)));
    }
  }

  Future<void> _onLogout(
      DriverAuthLogoutRequested event, Emitter<DriverAuthState> emit) async {
    SocketService.instance.disconnect();
    await AuthService.instance.logout();
    emit(DriverAuthUnauthenticated());
  }

  void _connectSocket(String token) {
    try {
      SocketService.instance.connect(
        serverUrl: ApiClient.instance.baseUrl,
        namespace: AppConstants.driverNamespace,
        token: token,
      );
    } catch (_) {}
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('Unauthorized') ||
        msg.contains('Invalid')) {
      return 'Invalid phone number or password.';
    }
    if (msg.contains('409') || msg.contains('already exists')) {
      return 'An account with this phone number already exists.';
    }
    if (msg.contains('SocketException') || msg.contains('connection') ||
        msg.contains('TimeoutException')) {
      return 'Cannot connect to server. Check your internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
