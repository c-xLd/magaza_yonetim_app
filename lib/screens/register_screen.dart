import 'package:flutter/material.dart';
// AuthProvider için import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

// Test kayıtlı telefonlar listesi (Login ekranı ile paylaşılan - Gerçek uygulamada veritabanında olacak)
final List<String> testKayitliTelefonlar = [
  '05551234567',
  '05559876543',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  bool _yukleniyor = false;
  String? _telefonArguman;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is String) {
        setState(() {
          _telefonArguman = arguments;
        });
      }
    });
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    super.dispose();
  }

  void _kayitOl() async {
    if (_adController.text.trim().isEmpty || _soyadController.text.trim().isEmpty) {
      _showError('Ad ve soyad girin');
      return;
    }
    setState(() => _yukleniyor = true);
    final isim = _adController.text.trim();
    final soyisim = _soyadController.text.trim();
    final telefon = '+90${_telefonArguman ?? ''}';
    final isAdmin = (telefon == '+905555555555');
    final role = isAdmin ? 'admin' : 'staff';
    final isActive = isAdmin ? true : false;

    // Önce bu numara ile kayıt var mı kontrol et
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('phoneNumber', isEqualTo: telefon)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      // Varsa güncelle
      final docId = query.docs.first.id;
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'name': '$isim $soyisim',
        'role': role,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Yoksa yeni kayıt ekle
    await FirebaseFirestore.instance.collection('users').add({
      'name': '$isim $soyisim',
      'phoneNumber': telefon,
        'role': role,
        'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    });
    }
    setState(() => _yukleniyor = false);
    _showInfo('Kaydınız alınmıştır, yönetici onayı bekleniyor.');
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final bodyPadding = isSmallScreen ? 12.0 : 24.0;
    
   return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // WAVE
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _TopWavePainter(color: colorScheme.primaryContainer),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: bodyPadding, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_rounded, size: 80, color: Colors.white.withOpacity(0.95)),
                      const SizedBox(height: 12),
                      Text(
                        'Kayıt Ol',
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ad ve soyad bilgilerinizi girin',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Ad
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
            child: TextField(
                          controller: _adController,
              enabled: !_yukleniyor,
                          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, letterSpacing: 1.1),
                          textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                            labelText: 'Ad',
                            labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            hintText: 'Adınız',
                            hintStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.13), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.13), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Soyad
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _soyadController,
                          enabled: !_yukleniyor,
                          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, letterSpacing: 1.1),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                            labelText: 'Soyad',
                            labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            hintText: 'Soyadınız',
                            hintStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.13), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.13), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Buton
                      GestureDetector(
                        onTap: _yukleniyor ? null : _kayitOl,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.13),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _yukleniyor
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  'Kaydı Tamamla',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

// Login ekranındaki wave painter'ı kullanabilmek için ekle
class _TopWavePainter extends CustomPainter {
  final Color color;
  _TopWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.65);
    path.cubicTo(
      size.width * 0.15, size.height * 0.85,
      size.width * 0.35, size.height * 0.45,
      size.width * 0.5, size.height * 0.65,
    );
    path.cubicTo(
      size.width * 0.65, size.height * 0.85,
      size.width * 0.85, size.height * 0.45,
      size.width, size.height * 0.65,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String capitalized = newValue.text.replaceAllMapped(
      RegExp(r'\b\w'),
      (match) => match.group(0)!.toUpperCase(),
    );
    return newValue.copyWith(
      text: capitalized,
      selection: newValue.selection,
    );
  }
}
