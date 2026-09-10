import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:doss_core/doss_core.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

enum _OcrState { idle, picking, uploading, verifying, success, failed }

class SubscriptionUploadScreen extends StatefulWidget {
  const SubscriptionUploadScreen({super.key});
  @override
  State<SubscriptionUploadScreen> createState() =>
      _SubscriptionUploadScreenState();
}

class _SubscriptionUploadScreenState extends State<SubscriptionUploadScreen> {
  final _picker = ImagePicker();
  _OcrState _state = _OcrState.idle;
  File? _image;
  String? _errorMsg;
  Map<String, dynamic>? _ocrResult;

  // ── InstaPay constants ─────────────────────────────────────────────────────
  static const String _instapayNumber = '01100500022';
  static const int _carFee = 200;
  static const int _bikeFee = 100;

  Future<void> _pickAndUpload() async {
    // guard against double-tap / picker-already-active
    if (_state == _OcrState.picking ||
        _state == _OcrState.uploading ||
        _state == _OcrState.verifying) {
      return;
    }
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: AppTheme.primaryMid,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          ListTile(
            leading:
                const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
            title: const Text('Take Photo of Receipt',
                style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppTheme.primary),
            title: const Text('Choose from Gallery',
                style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ])),
      );
      if (source == null) return;

      setState(() => _state = _OcrState.picking);
      final picked = await _picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 2000);
      if (picked == null) {
        if (mounted) setState(() => _state = _OcrState.idle);
        return;
      }
      if (!mounted) return;

      setState(() {
        _image = File(picked.path);
        _state = _OcrState.uploading;
      });
      await _uploadAndVerify();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _OcrState.failed;
        _errorMsg =
            'Could not open camera/gallery. Allow permission and try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Picker error: $e'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _uploadAndVerify() async {
    setState(() => _state = _OcrState.verifying);
    try {
      final token = await ApiClient.instance.getToken();
      final baseUrl = ApiClient.instance.baseUrl;
      final uri = Uri.parse('$baseUrl/api/trpc/subscriptions.verifyOcrReceipt');

      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['driverId'] = AuthService.instance.currentUser?.id ?? ''
        ..files.add(await http.MultipartFile.fromPath(
          'receipt',
          _image!.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      final streamed = await req.send().timeout(const Duration(seconds: 45));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final raw = jsonDecode(body) as Map<String, dynamic>;
        // tRPC unwrap
        final result =
            (raw['result']?['data']?['json'] ?? raw) as Map<String, dynamic>;

        if (result['success'] == true) {
          setState(() {
            _ocrResult = result;
            _state = _OcrState.success;
          });
          // Navigate back to subscription screen after 2s
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) context.go('/subscription');
        } else {
          setState(() {
            _state = _OcrState.failed;
            _errorMsg = result['message'] as String? ??
                'Receipt could not be verified. Ensure it shows the correct amount and InstaPay number.';
          });
        }
      } else {
        setState(() {
          _state = _OcrState.failed;
          _errorMsg = 'Server error. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _state = _OcrState.failed;
        _errorMsg = 'Network error: ${e.toString().split(':').first}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppTheme.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(t('Upload Payment Receipt', 'رفع إيصال الدفع'),
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── InstaPay Instructions ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMid,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payment_rounded,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                          t('How to Pay via InstaPay',
                              'كيفية الدفع عبر InstaPay'),
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ]),
                    const SizedBox(height: 16),
                    _Step(
                        n: 1,
                        t: t,
                        en: 'Open your bank app and go to InstaPay transfer',
                        ar: 'افتح تطبيق البنك واختر تحويل InstaPay'),
                    _Step(
                        n: 2,
                        t: t,
                        en: 'Send to mobile number: $_instapayNumber',
                        ar: 'أرسل إلى رقم الهاتف: $_instapayNumber'),
                    _Step(
                        n: 3,
                        t: t,
                        en: 'Amount: EGP $_carFee (Car) or EGP $_bikeFee (Bike)',
                        ar: 'المبلغ: $_carFee جنيه (سيارة) أو $_bikeFee جنيه (دراجة)'),
                    _Step(
                        n: 4,
                        t: t,
                        en: 'Screenshot the confirmation page',
                        ar: 'صوّر شاشة تأكيد التحويل'),
                    _Step(
                        n: 5,
                        t: t,
                        en: 'Upload below — AI verifies instantly!',
                        ar: 'ارفع الصورة — الذكاء الاصطناعي يتحقق فوراً!'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── InstaPay Number Copy Box ──────────────────────────────────
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: _instapayNumber));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t('Number copied!', 'تم النسخ!')),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.phone_iphone_rounded,
                        color: AppTheme.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(t('InstaPay Number', 'رقم InstaPay'),
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                          const Text(_instapayNumber,
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: 1)),
                        ])),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.copy_rounded,
                            color: AppTheme.success, size: 14),
                        SizedBox(width: 4),
                        Text('Copy',
                            style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),

              // ── Upload Area ───────────────────────────────────────────────
              _buildUploadArea(t),
              const SizedBox(height: 24),

              // ── Upload button ─────────────────────────────────────────────
              if (_state != _OcrState.success)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: (_state == _OcrState.uploading ||
                            _state == _OcrState.verifying)
                        ? null
                        : _pickAndUpload,
                    icon: const Icon(Icons.upload_file_rounded, size: 20),
                    label: Text(
                      _state == _OcrState.verifying
                          ? t('AI is verifying...', 'الذكاء الاصطناعي يتحقق...')
                          : _state == _OcrState.uploading
                              ? t('Uploading...', 'جاري الرفع...')
                              : _image != null
                                  ? t('Upload Again', 'رفع مرة أخرى')
                                  : t('Upload Receipt', 'رفع الإيصال'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea(String Function(String, String) t) {
    if (_state == _OcrState.verifying || _state == _OcrState.uploading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            _state == _OcrState.verifying
                ? t('AI is reading your receipt...',
                    'الذكاء الاصطناعي يقرأ الإيصال...')
                : t('Uploading image...', 'جاري رفع الصورة...'),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ]),
      );
    }

    if (_state == _OcrState.success && _ocrResult != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.success, size: 52),
          const SizedBox(height: 12),
          Text(t('Payment Verified!', 'تم التحقق من الدفع!'),
              style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(
              t('Your subscription is now active for 24 hours.',
                  'اشتراكك نشط الآن لمدة 24 ساعة.'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          if (_ocrResult?['amount'] != null) ...[
            const SizedBox(height: 12),
            Text('EGP ${_ocrResult!['amount']}',
                style: const TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
          ],
        ]),
      );
    }

    if (_state == _OcrState.failed) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 40),
          const SizedBox(height: 10),
          Text(t('Verification Failed', 'فشل التحقق'),
              style: const TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 8),
          Text(
              _errorMsg ??
                  t('Please upload a clear photo.', 'الرجاء رفع صورة واضحة.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
        ]),
      );
    }

    if (_image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_image!,
            height: 200, width: double.infinity, fit: BoxFit.cover),
      );
    }

    // Default upload box
    return GestureDetector(
      onTap: _pickAndUpload,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1.5,
              style: BorderStyle.solid),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.upload_file_rounded,
                color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
              t('Tap to upload InstaPay screenshot',
                  'اضغط لرفع صورة إيصال InstaPay'),
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(t('JPG, PNG — max 10MB', 'JPG, PNG — الحد الأقصى 10 ميجا'),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String en;
  final String ar;
  final String Function(String, String) t;
  const _Step(
      {required this.n, required this.en, required this.ar, required this.t});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Center(
                child: Text('$n',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(t(en, ar),
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4))),
        ]),
      );
}
