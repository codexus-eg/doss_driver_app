import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverTermsScreen extends StatefulWidget {
  const DriverTermsScreen({super.key});

  @override
  State<DriverTermsScreen> createState() => _DriverTermsScreenState();
}

class _DriverTermsScreenState extends State<DriverTermsScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/register'),
        ),
        title: const Text(
          'اتفاقية الشراكة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.description_outlined,
                    color: Color(0xFF00D4FF), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يرجى قراءة الاتفاقية كاملة قبل الموافقة',
                    style: TextStyle(color: Color(0xFF00D4FF), fontSize: 13),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title('اتفاقية شراكة السائق — DOSS'),
                      _sub('الإصدار 1.0 | يناير 2026'),
                      const SizedBox(height: 16),
                      _title('مقدمة'),
                      _body(
                        'هذه الاتفاقية مبرمة بين شركة DOSS للنقل الذكي ("الشركة") وبين السائق الشريك ("الشريك"). '
                        'بقبول هذه الاتفاقية، يوافق الشريك على الالتزام بجميع الشروط والأحكام الواردة فيها.',
                      ),
                      const SizedBox(height: 14),
                      _title('1. طبيعة العلاقة'),
                      _body(
                        'يُعدّ الشريك مقاولاً مستقلاً وليس موظفاً لدى الشركة. لا تنشأ عن هذه الاتفاقية أي علاقة عمل '
                        'أو شراكة أو وكالة بين الطرفين. يتحمل الشريك المسؤولية الكاملة عن التزاماته الضريبية والتأمينية.',
                      ),
                      const SizedBox(height: 14),
                      _title('2. متطلبات التسجيل'),
                      _bullet('• يجب أن يكون عمر الشريك 21 سنة فأكثر'),
                      _bullet(
                          '• رخصة قيادة سارية المفعول (درجة ثالثة أو أعلى)'),
                      _bullet('• بطاقة رقم قومي سارية'),
                      _bullet(
                          '• استمارة تسجيل السيارة باسم الشريك أو بتوكيل رسمي'),
                      _bullet('• شهادة تأمين سارية على السيارة'),
                      _bullet('• صورة شخصية حديثة'),
                      _bullet('• السيارة لا يزيد عمرها عن 10 سنوات'),
                      const SizedBox(height: 14),
                      _title('3. التزامات الشريك'),
                      _bullet('• الحفاظ على نظافة المركبة وصلاحيتها للتشغيل'),
                      _bullet('• الالتزام بقواعد المرور والقوانين المصرية'),
                      _bullet('• التعامل مع الركاب باحترام ومهنية عالية'),
                      _bullet(
                          '• عدم قبول الركاب خارج التطبيق أو التفاوض على الأسعار'),
                      _bullet(
                          '• الإبلاغ الفوري عن أي حوادث أو مشكلات عبر التطبيق'),
                      _bullet('• عدم استخدام الهاتف أثناء القيادة'),
                      _bullet('• ارتداء الزي اللائق وتقديم نفسه بمظهر مهني'),
                      const SizedBox(height: 14),
                      _title('4. الأسعار والعمولات'),
                      _body(
                        'تحتفظ الشركة بحق تحديد أسعار الرحلات وتعديلها. تُخصم عمولة الشركة تلقائياً من كل رحلة '
                        'وفق النسبة المتفق عليها عند التسجيل.',
                      ),
                      const SizedBox(height: 14),
                      _title('5. المدفوعات'),
                      _bullet(
                          '• تُحوَّل المستحقات أسبوعياً إلى الحساب البنكي المسجل'),
                      _bullet(
                          '• يمكن الاطلاع على تفاصيل الأرباح في قسم "الأرباح" بالتطبيق'),
                      _bullet('• تُخصم أي غرامات أو مبالغ مستردة من المستحقات'),
                      _bullet('• الحد الأدنى للسحب هو 100 جنيه مصري'),
                      const SizedBox(height: 14),
                      _title('6. معايير الأداء'),
                      _body(
                        'يلتزم الشريك بالحفاظ على معدل قبول لا يقل عن 80% ومعدل إكمال الرحلات لا يقل عن 90%. '
                        'قد يؤدي الانخفاض المستمر في هذه المعدلات إلى تعليق الحساب.',
                      ),
                      const SizedBox(height: 14),
                      _title('7. التقييمات'),
                      _body(
                        'يُقيِّم الركاب الشريك بعد كل رحلة. يجب الحفاظ على تقييم لا يقل عن 4.0 من 5.0.',
                      ),
                      const SizedBox(height: 14),
                      _title('8. السلوك المحظور'),
                      _bullet('• رفض الركاب بسبب الجنس أو الدين أو الجنسية'),
                      _bullet('• التحرش اللفظي أو الجسدي بالركاب'),
                      _bullet('• القيادة تحت تأثير الكحول أو المخدرات'),
                      _bullet('• تزوير بيانات الرحلات أو التلاعب بالتطبيق'),
                      _bullet('• مشاركة بيانات الركاب مع أطراف ثالثة'),
                      _bullet('• استخدام الحساب من قِبل شخص آخر'),
                      const SizedBox(height: 14),
                      _title('9. التأمين والمسؤولية'),
                      _body(
                        'يلتزم الشريك بالحصول على تأمين شامل ساري المفعول على مركبته. '
                        'الشركة غير مسؤولة عن أي حوادث أو أضرار تنشأ أثناء تقديم الخدمة.',
                      ),
                      const SizedBox(height: 14),
                      _title('10. إنهاء الاتفاقية'),
                      _body(
                        'يحق لأي من الطرفين إنهاء هذه الاتفاقية بإشعار مسبق مدته 7 أيام. '
                        'تحتفظ الشركة بحق إنهاء الاتفاقية فوراً في حالات الانتهاك الجسيم.',
                      ),
                      const SizedBox(height: 14),
                      _title('11. حماية البيانات'),
                      _body(
                        'تلتزم الشركة بحماية بيانات الشريك. يوافق الشريك على استخدام بياناته '
                        'لأغراض تشغيلية وتحسين الخدمة فقط.',
                      ),
                      const SizedBox(height: 14),
                      _title('12. تعديل الاتفاقية'),
                      _body(
                        'تحتفظ الشركة بحق تعديل هذه الاتفاقية مع إشعار مسبق للشركاء. '
                        'استمرار الشريك في استخدام التطبيق يُعدّ قبولاً للتعديلات.',
                      ),
                      const SizedBox(height: 14),
                      _title('13. القانون الحاكم'),
                      _body(
                        'تخضع هذه الاتفاقية لأحكام القانون المصري. أي نزاع يُحال إلى '
                        'المحاكم المختصة في جمهورية مصر العربية.',
                      ),
                      const SizedBox(height: 24),
                      _sub('للتواصل: support@doss.app'),
                      _sub('© 2026 DOSS — جميع الحقوق محفوظة'),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _accepted = !_accepted),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Checkbox(
                        value: _accepted,
                        onChanged: (v) =>
                            setState(() => _accepted = v ?? false),
                        activeColor: const Color(0xFF00D4FF),
                        checkColor: Colors.black,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'أوافق على جميع شروط وأحكام اتفاقية الشراكة مع DOSS',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _accepted ? () => context.go('/documents') : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4FF),
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _accepted
                          ? 'أوافق وأكمل التسجيل'
                          : 'يجب الموافقة على الشروط أولاً',
                      style: TextStyle(
                        color: _accepted ? Colors.black : Colors.white38,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF00D4FF),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
      );

  Widget _sub(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
          textDirection: TextDirection.rtl,
        ),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.7,
          ),
          textDirection: TextDirection.rtl,
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4, right: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.6,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
}
