import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/driver_auth_bloc.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/pending_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/offer/offer_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/subscription/subscription_upload_screen.dart';
import '../screens/profile/driver_profile_screen.dart';
import '../screens/onboarding/document_upload_screen.dart';
import '../screens/onboarding/terms_screen.dart';
import '../screens/trips/trips_screen.dart';

class DriverAppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();

  static DriverAuthBloc? _authBloc;
  static final _notifier = _BlocNotifier();

  static void setAuthBloc(DriverAuthBloc bloc) {
    _authBloc = bloc;
    bloc.stream.listen((_) => _notifier.notify());
  }

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: _notifier,
    redirect: (context, state) {
      final auth     = _authBloc?.state ?? context.read<DriverAuthBloc>().state;
      final loggedIn = auth is DriverAuthAuthenticated;
      final pending  = auth is DriverAuthPending;
      final loading  = auth is DriverAuthLoading || auth is DriverAuthInitial;
      final loc      = state.matchedLocation;
      if (loading) return loc == '/splash' ? null : '/splash';
      if (pending) return loc == '/pending' ? null : '/pending';
      if (!loggedIn) return (loc == '/login' || loc == '/register') ? null : '/login';
      if (loc == '/splash' || loc == '/login' || loc == '/register') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',              builder: (_, __) => const DriverSplashScreen()),
      GoRoute(path: '/login',               builder: (_, __) => const DriverLoginScreen()),
      GoRoute(path: '/register',            builder: (_, __) => const DriverRegisterScreen()),
      GoRoute(path: '/pending',             builder: (_, __) => const PendingApprovalScreen()),
      GoRoute(path: '/dashboard',           builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/offer',               builder: (_, __) => const OfferScreen()),
      GoRoute(path: '/earnings',            builder: (_, __) => const EarningsScreen()),
      GoRoute(path: '/subscription',        builder: (_, __) => const DriverSubscriptionScreen()),
      GoRoute(path: '/subscription/upload', builder: (_, __) => const SubscriptionUploadScreen()),
      GoRoute(path: '/trips',               builder: (_, __) => const TripsScreen()),
      GoRoute(path: '/profile',             builder: (_, __) => const DriverProfileScreen()),
      GoRoute(path: '/terms',              builder: (_, __) => const DriverTermsScreen()),
      GoRoute(path: '/documents',           builder: (_, __) => const DocumentUploadScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(child: Text('Page not found: ${state.error}',
          style: const TextStyle(color: Colors.white))),
    ),
  );
}

class _BlocNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
