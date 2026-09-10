import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:doss_core/doss_core.dart';

/// Max accepted image size — mirrors the 5MB limit enforced by
/// `drivers.uploadDocument` on the server.
const int _maxUploadBytes = 5 * 1024 * 1024;

class _DocItem {
  /// Matches the `documentType` enum accepted by `drivers.uploadDocument`.
  final String docType;
  final String titleEn;
  final String titleAr;
  final IconData icon;
  final bool isRequired;
  File? file;
  String? url;
  bool uploaded = false;
  bool uploading = false;
  String? error;
  _DocItem({
    required this.docType,
    required this.titleEn,
    required this.titleAr,
    required this.icon,
    this.isRequired = true,
  });
}

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});
  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _picker = ImagePicker();
  bool _submitting = false;

  final List<_DocItem> _docs = [
    _DocItem(
        docType: 'nationalIdFront',
        titleEn: 'National ID (Front)',
        titleAr: 'بطاقة الرقم القومي (الوجه)',
        icon: Icons.badge_outlined),
    _DocItem(
        docType: 'drivingLicense',
        titleEn: "Driver's License",
        titleAr: 'رخصة القيادة',
        icon: Icons.drive_eta_outlined),
    _DocItem(
        docType: 'vehicleLicense',
        titleEn: 'Vehicle License',
        titleAr: 'رخصة السيارة',
        icon: Icons.article_outlined),
    _DocItem(
        docType: 'selfie',
        titleEn: 'Driver Selfie',
        titleAr: 'صورة شخصية',
        icon: Icons.person_outline),
    _DocItem(
        docType: 'vehiclePhoto',
        titleEn: 'Vehicle Photo',
        titleAr: 'صورة السيارة',
        icon: Icons.directions_car_outlined),
    _DocItem(
        docType: 'criminalRecord',
        titleEn: 'Criminal Record',
        titleAr: 'فيش الجنائي',
        icon: Icons.gavel_outlined,
        isRequired: false),
  ];

  /// The server rejects `submitForReview` unless every required document
  /// already has a stored URL.
  bool get _allRequiredUploaded =>
      _docs.where((d) => d.isRequired).every((d) => d.uploaded);

  Future<void> _pick(_DocItem doc) async {
    if (doc.uploading)
      return; // guard against double-tap / picker-already-active
    final t = context.read<LanguageProvider>().t;
    try {
      final result = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: AppTheme.primaryMid,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SafeArea(
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
            title: Text(t('Take Photo', 'التقاط صورة'),
                style: const TextStyle(color: AppTheme.textPrimary)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppTheme.primary),
            title: Text(t('Choose from Gallery', 'اختيار من المعرض'),
                style: const TextStyle(color: AppTheme.textPrimary)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ])),
      );
      if (result == null) return;

      final picked = await _picker.pickImage(
        source: result,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() {
        doc.file = File(picked.path);
        doc.error = null;
      });
      await _upload(doc);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        doc.uploading = false;
        doc.error = t(
            'Could not open camera/gallery. Allow permission and try again.',
            'تعذر فتح الكاميرا/المعرض. اسمح بالإذن وحاول مرة أخرى.');
      });
    }
  }

  Future<void> _upload(_DocItem doc) async {
    final file = doc.file;
    if (file == null) return;
    final t = context.read<LanguageProvider>().t;

    setState(() {
      doc.uploading = true;
      doc.error = null;
    });
    try {
      final bytes = await file.readAsBytes();

      if (bytes.length > _maxUploadBytes) {
        if (!mounted) return;
        setState(() {
          doc.uploading = false;
          doc.error = t('Image is larger than 5MB. Please retake it.',
              'حجم الصورة أكبر من 5 ميجابايت. من فضلك أعد التقاطها.');
        });
        return;
      }

      final isPng = file.path.toLowerCase().endsWith('.png');

      final result = await ApiClient.instance.mutate(
        'drivers.uploadDocument',
        input: {
          'documentType': doc.docType,
          'imageBase64': base64Encode(bytes),
          'mimeType': isPng ? 'image/png' : 'image/jpeg',
        },
      );

      if (!mounted) return;
      final url = result['url'] as String?;
      if (url != null && url.isNotEmpty) {
        setState(() {
          doc.url = url;
          doc.uploaded = true;
          doc.uploading = false;
          doc.error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${t(doc.titleEn, doc.titleAr)} — ${t('uploaded', 'تم الرفع')} ✓'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      } else {
        setState(() {
          doc.uploading = false;
          doc.error = t('Upload failed. Please try again.',
              'فشل الرفع. من فضلك حاول مرة أخرى.');
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        doc.uploading = false;
        doc.error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        doc.uploading = false;
        doc.error = t('Network error. Check your connection.',
            'خطأ في الشبكة. تحقق من اتصالك.');
      });
    }
  }

  Future<void> _submitAll() async {
    if (_submitting) return;
    final t = context.read<LanguageProvider>().t;
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.mutate('drivers.submitForReview');
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            t('Documents submitted for review!', 'تم إرسال الوثائق للمراجعة!')),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.go('/pending');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('Submission failed. Please try again.',
            'فشل الإرسال. من فضلك حاول مرة أخرى.')),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
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
          title: Text(t('Upload Documents', 'رفع الوثائق'),
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(
                        t('Upload clear photos of your documents. All documents are encrypted and secure.',
                            'ارفع صوراً واضحة للوثائق. جميع الوثائق مشفرة وآمنة.'),
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Document cards
                  ..._docs.map((doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _DocCard(
                          doc: doc,
                          t: t,
                          onTap: () => _pick(doc),
                        ),
                      )),
                ],
              ),
            ),

            // Submit button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_allRequiredUploaded && !_submitting)
                      ? _submitAll
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onBrand,
                    disabledBackgroundColor: AppTheme.surface,
                    disabledForegroundColor: AppTheme.textMuted,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.textMuted))
                      : Text(
                          _allRequiredUploaded
                              ? t('Submit for Review', 'إرسال للمراجعة')
                              : t('Upload all required documents to continue',
                                  'ارفع جميع الوثائق المطلوبة للمتابعة'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final _DocItem doc;
  final String Function(String, String) t;
  final VoidCallback onTap;
  const _DocCard({required this.doc, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: doc.uploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: doc.uploaded
                ? AppTheme.success.withValues(alpha: 0.5)
                : doc.error != null
                    ? AppTheme.error.withValues(alpha: 0.5)
                    : AppTheme.divider,
            width: doc.uploaded || doc.error != null ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: doc.uploaded
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              doc.uploaded ? Icons.check_circle_rounded : doc.icon,
              color: doc.uploaded ? AppTheme.success : AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Flexible(
                    child: Text(t(doc.titleEn, doc.titleAr),
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                  if (!doc.isRequired) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(t('Optional', 'اختياري'),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(
                  doc.uploaded
                      ? t('Uploaded ✓', 'تم الرفع ✓')
                      : doc.error != null
                          ? doc.error!
                          : doc.uploading
                              ? t('Uploading...', 'جاري الرفع...')
                              : t('Tap to upload', 'اضغط للرفع'),
                  style: TextStyle(
                    color: doc.uploaded
                        ? AppTheme.success
                        : doc.error != null
                            ? AppTheme.error
                            : AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ])),

          // Status indicator
          if (doc.uploading)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primary))
          else if (doc.error != null)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t('Retry', 'إعادة'),
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            )
          else
            Icon(
              doc.uploaded
                  ? Icons.check_circle_rounded
                  : Icons.upload_file_rounded,
              color: doc.uploaded ? AppTheme.success : AppTheme.textMuted,
              size: 22,
            ),
        ]),
      ),
    );
  }
}
