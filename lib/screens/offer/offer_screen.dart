import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:doss_core/doss_core.dart' hide LatLng;
import 'package:doss_core/theme/app_theme.dart';
import 'package:doss_core/constants/constants.dart';
import 'package:doss_core/widgets/chat_screen.dart';
import '../../blocs/offer/offer_bloc.dart';
import '../../blocs/driver/driver_bloc.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});
  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  GoogleMapController? _mapCtrl;
  bool _updatingStatus = false;
  bool _sosSent = false;
  bool _sosVisible = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  /// Update ride status — backend accepts: driver_arrived | in_ride | completed
  Future<void> _updateStatus(String rideId, String status) async {
    if (_updatingStatus) return;
    setState(() => _updatingStatus = true);
    try {
      await ApiClient.instance.mutate(
        'rides.updateStatus',
        input: {'rideId': rideId, 'status': status},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _sendSOS(RideOffer offer) async {
    if (_sosSent) return;
    SocketService.instance.emitSOS(
      rideId: offer.rideId,
      userId: AuthService.instance.currentUser?.id ?? '',
      userRole: 'driver',
      lat: offer.pickupLat,
      lng: offer.pickupLng,
    );
    try {
      await ApiClient.instance.mutate('sos.trigger', input: {
        'rideId': offer.rideId,
        'userRole': 'driver',
        'lat': offer.pickupLat,
        'lng': offer.pickupLng,
      });
    } catch (_) {}
    if (mounted) {
      setState(() {
        _sosSent = true;
        _sosVisible = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('SOS sent! Help is on the way.'),
        backgroundColor: AppTheme.error,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;

    return BlocConsumer<OfferBloc, OfferState>(
      listener: (ctx, state) {
        if (state is OfferDeclined || state is OfferTimedOut) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) ctx.go('/dashboard');
          });
        }
        if (state is OfferIdle) ctx.go('/dashboard');
        if (state is OfferRideFinished) {
          ctx.read<DriverBloc>().add(DriverStatsRequested());
          ctx.go('/dashboard');
        }
        if (state is OfferError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (ctx, state) {
        if (state is OfferPending) return _buildPending(ctx, state, t);
        if (state is OfferAccepting)
          return _loading(t('Accepting ride...', 'جاري القبول...'));
        if (state is OfferActive) return _buildActive(ctx, state, t);
        if (state is OfferDeclined)
          return _loading(t('Ride declined', 'تم رفض الرحلة'));
        if (state is OfferTimedOut)
          return _loading(t('Offer timed out', 'انتهى وقت العرض'));
        if (state is OfferRideFinished) return _buildFinished(state);
        return _loading(t('Loading...', 'جاري التحميل...'));
      },
    );
  }

  // ── Pending view ──────────────────────────────────────────────────────────
  Widget _buildPending(
      BuildContext ctx, OfferPending state, String Function(String, String) t) {
    final offer = state.offer;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Map
        Positioned.fill(
            child: GoogleMap(
          initialCameraPosition: CameraPosition(
              target: LatLng(offer.pickupLat, offer.pickupLng), zoom: 13),
          onMapCreated: (c) {
            _mapCtrl = c;
            c.setMapStyle(AppTheme.mapStyle);
          },
          markers: {
            Marker(
                markerId: const MarkerId('p'),
                position: LatLng(offer.pickupLat, offer.pickupLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(
                    title: t('Pickup', 'الانطلاق'),
                    snippet: offer.pickupAddress)),
            Marker(
                markerId: const MarkerId('d'),
                position: LatLng(offer.dropoffLat, offer.dropoffLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(
                    title: t('Dropoff', 'الوجهة'),
                    snippet: offer.dropoffAddress)),
          },
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          padding: const EdgeInsets.only(bottom: 320),
        )),

        // Timer
        SafeArea(
            child: Center(child: _TimerRing(seconds: state.secondsRemaining))),

        // Offer card
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _OfferCard(
            offer: offer,
            t: t,
            onAccept: () =>
                ctx.read<OfferBloc>().add(OfferAccepted(offer.offerId)),
            onReject: () =>
                ctx.read<OfferBloc>().add(OfferRejected(offer.offerId)),
          ),
        ),
      ]),
    );
  }

  // ── Active view ───────────────────────────────────────────────────────────
  Widget _buildActive(
      BuildContext ctx, OfferActive state, String Function(String, String) t) {
    final offer = state.offer;
    final status = state.status;

    String? nextStatus;
    String? btnLabel;
    Color btnColor = AppTheme.primary;

    if (status == RideStatus.accepted) {
      nextStatus = 'driver_arrived';
      btnLabel = t('I Have Arrived', 'وصلت');
      btnColor = AppTheme.warning;
    } else if (status == RideStatus.arrived) {
      nextStatus = 'in_ride';
      btnLabel = t('Start Ride', 'ابدأ الرحلة');
      btnColor = AppTheme.success;
    } else if (status == RideStatus.inProgress) {
      nextStatus = 'completed';
      btnLabel = t('Complete Ride', 'إنهاء الرحلة');
      btnColor = AppTheme.primary;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(
            child: GoogleMap(
          initialCameraPosition: CameraPosition(
              target: LatLng(offer.pickupLat, offer.pickupLng), zoom: 14),
          onMapCreated: (c) {
            _mapCtrl = c;
            c.setMapStyle(AppTheme.mapStyle);
          },
          markers: {
            Marker(
                markerId: const MarkerId('p'),
                position: LatLng(offer.pickupLat, offer.pickupLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen)),
            Marker(
                markerId: const MarkerId('d'),
                position: LatLng(offer.dropoffLat, offer.dropoffLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed)),
          },
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          padding: const EdgeInsets.only(top: 80, bottom: 320),
        )),

        // Status banner
        SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: _statusBanner(status, t),
        )),

        // SOS confirm
        if (_sosVisible)
          _SOSOverlay(
            onConfirm: () => _sendSOS(offer),
            onCancel: () => setState(() => _sosVisible = false),
            t: t,
          ),

        // Bottom active card
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _ActiveCard(
            offer: offer,
            status: status,
            t: t,
            nextStatus: nextStatus,
            btnLabel: btnLabel,
            btnColor: btnColor,
            isUpdating: _updatingStatus,
            sosSent: _sosSent,
            onUpdate: (s) => _updateStatus(offer.rideId, s),
            onChat: () {
              final user = AuthService.instance.currentUser;
              if (user == null) return;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RideChatScreen(
                            rideId: offer.rideId,
                            currentUserId: user.id,
                            currentUserRole: 'driver',
                            otherUserName: 'Rider',
                          )));
            },
            onSOS: () => setState(() => _sosVisible = true),
            onCall: () async {
              final phone = offer.riderPhone;
              if (phone == null || phone.isEmpty) return;
              final uri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
        ),
      ]),
    );
  }

  Widget _statusBanner(RideStatus status, String Function(String, String) t) {
    Color c;
    IconData ic;
    String label;
    if (status == RideStatus.accepted) {
      c = AppTheme.primary;
      ic = Icons.navigation_rounded;
      label = t('Navigate to pickup', 'توجّه نحو نقطة الانطلاق');
    } else if (status == RideStatus.arrived) {
      c = AppTheme.warning;
      ic = Icons.location_on_rounded;
      label = t('Waiting for rider', 'في انتظار الراكب');
    } else {
      c = AppTheme.success;
      ic = Icons.local_taxi_rounded;
      label = t('On the way to destination', 'في الطريق إلى الوجهة');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: c.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ]),
    );
  }

  Widget _buildFinished(OfferRideFinished state) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 48)),
          const SizedBox(height: 20),
          const Text('Ride Completed!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('EGP ${state.fareEgp.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 42,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Collect cash from rider',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ])),
      );

  Widget _loading(String msg) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: AppTheme.textSecondary)),
        ])),
      );
}

// ── Timer ring ────────────────────────────────────────────────────────────────
class _TimerRing extends StatelessWidget {
  final int seconds;
  const _TimerRing({required this.seconds});
  Color get _color {
    if (seconds > 15) return AppTheme.success;
    if (seconds > 7) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppTheme.primaryMid,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4), blurRadius: 12)
              ],
            ),
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: seconds / AppConstants.offerTimeoutSeconds,
                  backgroundColor: AppTheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                  strokeWidth: 5,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$seconds',
                    style: TextStyle(
                        color: _color,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const Text('sec',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ]),
            ]),
          ),
        ),
      );
}

// ── Offer card (pending) ──────────────────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  final RideOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final String Function(String, String) t;
  const _OfferCard(
      {required this.offer,
      required this.onAccept,
      required this.onReject,
      required this.t});

  static const _shuttleColor = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
          // Shuttle gets an orange border highlight
          border: offer.isShuttle
              ? Border.all(
                  color: _shuttleColor.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),

          // Title row — Shuttle vs Standard
          Row(children: [
            // Ride type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: offer.isShuttle
                    ? _shuttleColor.withValues(alpha: 0.15)
                    : AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  offer.isShuttle
                      ? Icons.airport_shuttle_rounded
                      : Icons.directions_car_rounded,
                  color: offer.isShuttle ? _shuttleColor : AppTheme.warning,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  offer.isShuttle
                      ? t('New Shuttle Ride', 'رحلة شاتل جديدة')
                      : t('New Ride', 'رحلة جديدة'),
                  style: TextStyle(
                      color: offer.isShuttle ? _shuttleColor : AppTheme.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ]),
            ),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('EGP ${offer.fareEgp.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: offer.isShuttle ? _shuttleColor : AppTheme.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              if (offer.isShuttle)
                Text(t('Fixed fare', 'سعر ثابت'),
                    style: TextStyle(
                        color: _shuttleColor.withValues(alpha: 0.7),
                        fontSize: 10)),
            ]),
          ]),
          const SizedBox(height: 14),

          // Route info — shuttle shows station names
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: offer.isShuttle
                  ? Border.all(color: _shuttleColor.withValues(alpha: 0.2))
                  : null,
            ),
            child: Column(children: [
              // Pickup
              _RouteRow(
                icon: Icons.radio_button_checked,
                color: AppTheme.success,
                text: offer.originStationName ?? offer.pickupAddress,
                subtext:
                    offer.isShuttle ? t('Boarding Point', 'نقطة الصعود') : null,
              ),
              const SizedBox(height: 6),
              // Drop-off
              _RouteRow(
                icon: Icons.location_on,
                color: AppTheme.error,
                text: offer.destinationStationName ?? offer.dropoffAddress,
                subtext: offer.isShuttle
                    ? t('Alighting Point', 'نقطة النزول')
                    : null,
              ),
              const Divider(color: AppTheme.divider, height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _InfoChip(
                    icon: Icons.straighten,
                    label: '${offer.distanceKm.toStringAsFixed(1)} km'),
                if (offer.durationMinutes != null)
                  _InfoChip(
                      icon: Icons.access_time,
                      label:
                          '${offer.durationMinutes!.toStringAsFixed(0)} min'),
                if (offer.isShuttle)
                  _InfoChip(
                      icon: Icons.people_outline_rounded,
                      label: t('14 seats', '14 مقعداً')),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Accept/Reject
          Row(children: [
            Expanded(
                child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(t('Reject', 'رفض'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 12),
            Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        offer.isShuttle ? _shuttleColor : AppTheme.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(t('Accept Ride', 'قبول الرحلة'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                )),
          ]),
        ]),
      );
}

// ── Active card ───────────────────────────────────────────────────────────────
class _ActiveCard extends StatelessWidget {
  final RideOffer offer;
  final RideStatus status;
  final String Function(String, String) t;
  final String? nextStatus;
  final String? btnLabel;
  final Color btnColor;
  final bool isUpdating;
  final bool sosSent;
  final void Function(String) onUpdate;
  final VoidCallback onChat;
  final VoidCallback onSOS;
  final VoidCallback? onCall;
  const _ActiveCard({
    required this.offer,
    required this.status,
    required this.t,
    this.nextStatus,
    this.btnLabel,
    required this.btnColor,
    required this.isUpdating,
    required this.sosSent,
    required this.onUpdate,
    required this.onChat,
    required this.onSOS,
    this.onCall,
  });
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      status == RideStatus.inProgress
                          ? offer.dropoffAddress
                          : offer.pickupAddress,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ])),
            const SizedBox(width: 12),
            Text('EGP ${offer.fareEgp.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20)),
          ]),
          const SizedBox(height: 14),

          // Chat + Call + SOS row
          Row(children: [
            Expanded(
                child: _ActionBtn(
              icon: Icons.chat_bubble_outline_rounded,
              label: t('Chat', 'دردشة'),
              color: AppTheme.primary,
              onTap: onChat,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _ActionBtn(
              icon: Icons.phone_outlined,
              label: t('Call', 'اتصال'),
              color: AppTheme.success,
              onTap: onCall,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _ActionBtn(
              icon: Icons.warning_amber_rounded,
              label: 'SOS',
              color: AppTheme.error,
              onTap: sosSent ? null : onSOS,
              filled: true,
            )),
          ]),
          const SizedBox(height: 10),

          // Status button
          if (nextStatus != null && btnLabel != null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isUpdating ? null : () => onUpdate(nextStatus!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(btnLabel!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
        ]),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap,
      this.filled = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: filled
                ? (onTap == null
                    ? AppTheme.error.withValues(alpha: 0.3)
                    : color)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: filled ? Colors.white : color, size: 20),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: filled ? Colors.white : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String? subtext;
  const _RouteRow(
      {required this.icon,
      required this.color,
      required this.text,
      this.subtext});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (subtext != null)
            Text(subtext!,
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
          Text(text,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ])),
      ]);
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppTheme.textMuted, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]);
}

// ── SOS Confirm Overlay ───────────────────────────────────────────────────────
class _SOSOverlay extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String Function(String, String) t;
  const _SOSOverlay(
      {required this.onConfirm, required this.onCancel, required this.t});
  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.8),
          child: Center(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryMid,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.5)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.error, size: 36)),
                const SizedBox(height: 14),
                Text(t('SOS Emergency', 'طوارئ SOS'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                  t('This will alert DOSS support and share your live location.',
                      'سيتم إخطار دعم DOSS ومشاركة موقعك الحالي.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(t('SEND SOS', 'إرسال SOS'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onCancel,
                  child: Text(t('Cancel', 'إلغاء'),
                      style: const TextStyle(color: AppTheme.textMuted)),
                ),
              ]),
            ),
          )),
        ),
      );
}
