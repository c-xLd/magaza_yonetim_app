import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// AuthProvider için import
import '../providers/auth_provider.dart' as app;
//import '../common/ui_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Test kullanıcı listesi ve bilgileri (Firebase entegrasyonu öncesi)
final List<String> testKayitliTelefonlar = [
  '05347836503',
  '05559876543',
];

// Test kullanıcı ad-soyad bilgileri
final Map<String, String> testKullaniciIsimleri = {
  '05347836503': 'Ahmet Şahin',
  '05559876543': 'Mehmet Demir',
};

// --- WAVE PAINTER ---
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
      size.width * 0.15, size.height * 0.85, // daha yüksek tepe
      size.width * 0.35, size.height * 0.45, // daha derin çukur
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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _telefonController = TextEditingController();
  final _smsController = TextEditingController();
  final _smsFocusNode = FocusNode();
  bool _smsTalepEdildi = false;
  bool _yukleniyor = false;
  String? _verificationId;
  String? _smsKodHatasi;
  int? _resendToken;
  bool _kodGonderildi = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _telefonController.dispose();
    _smsController.dispose();
    _smsFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _smsKoduTalepEt({bool resend = false}) async {
    final telefon = _telefonController.text.trim();
    if (telefon.isEmpty || !RegExp(r'^\d{10}$').hasMatch(telefon)) {
      _showError('Geçerli bir telefon numarası girin (5012345678)');
      return;
    }
    setState(() {
      _yukleniyor = true;
      _smsKodHatasi = null;
    });
    final formattedPhone = '+90$telefon';
    // ADMIN NUMARASI İÇİN KAYIT KONTROLÜ YAPMA, DİREKT SMS BAŞLAT
    if (formattedPhone == '+905555555555') {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            await _firestoreLogin(formattedPhone);
          } catch (e) {
            setState(() => _yukleniyor = false);
            _showError('Otomatik doğrulama başarısız: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _yukleniyor = false;
            _smsKodHatasi = e.message;
          });
          _showError('SMS gönderilemedi: \\${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _yukleniyor = false;
            _smsTalepEdildi = true;
            _verificationId = verificationId;
            _resendToken = resendToken;
            _kodGonderildi = true;
          });
          _showInfo('Doğrulama kodu gönderildi.');
          _animController.forward();
          FocusScope.of(context).requestFocus(_smsFocusNode);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      return;
    }
    // Önce Firestore'da kayıtlı mı kontrol et
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('phoneNumber', isEqualTo: formattedPhone)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      setState(() => _yukleniyor = false);
      Navigator.pushReplacementNamed(context, '/register', arguments: telefon);
      return;
    }
    // Kayıtlıysa SMS doğrulama başlat
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resend ? _resendToken : null,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _firestoreLogin(formattedPhone);
        } catch (e) {
          setState(() => _yukleniyor = false);
          _showError('Otomatik doğrulama başarısız: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _yukleniyor = false;
          _smsKodHatasi = e.message;
        });
        _showError('SMS gönderilemedi: \\${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _yukleniyor = false;
          _smsTalepEdildi = true;
          _verificationId = verificationId;
          _resendToken = resendToken;
          _kodGonderildi = true;
        });
        _showInfo('Doğrulama kodu gönderildi.');
        _animController.forward();
        FocusScope.of(context).requestFocus(_smsFocusNode);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _firestoreLogin(String formattedPhone) async {
    // Eğer admin numarası ise Firestore'dan isim ve rol çek, role her durumda 'admin' olarak ata
    if (formattedPhone == '+905555555555') {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();
      String kullaniciAdi = 'Admin';
      String role = 'admin';
      if (query.docs.isNotEmpty) {
        final userData = query.docs.first.data();
        kullaniciAdi = userData['name'] ?? 'Admin';
        // role = userData['role'] ?? 'admin'; // YORUMDA KALSIN, HER ZAMAN 'admin' OLACAK
      }
      final authProvider = Provider.of<app.AuthProvider>(context, listen: false);
      await authProvider.login(kullaniciAdi, role: 'admin');
      setState(() => _yukleniyor = false);
      Navigator.pushReplacementNamed(context, '/');
      return;
    }
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('phoneNumber', isEqualTo: formattedPhone)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final userData = query.docs.first.data();
      if (userData['isActive'] == true) {
        String kullaniciAdi = userData['name'] ?? 'A101 Kullanıcı';
        String? role = userData['role'];
        String? phone = userData['phoneNumber'];
        final authProvider = Provider.of<app.AuthProvider>(context, listen: false);
        await authProvider.login(kullaniciAdi, role: role);
        if (phone != null) {
          await authProvider.checkPhone(phone);
        }
        // Admin olsa bile ana sayfaya yönlendir
          Navigator.pushReplacementNamed(context, '/');
        setState(() => _yukleniyor = false);
      } else {
        setState(() => _yukleniyor = false);
        _showError('Yönetici onayı bekleniyor. Giriş yapamazsınız.');
      }
    } else {
      setState(() => _yukleniyor = false);
      Navigator.pushReplacementNamed(context, '/register', arguments: formattedPhone.substring(3));
    }
  }

  void _girisYap() async {
    final telefon = _telefonController.text.trim();
    final kod = _smsController.text.trim();
    if (telefon.isEmpty || kod.isEmpty) {
      _showError('Telefon ve doğrulama kodu girin');
      return;
    }
    if (_verificationId == null) {
      _showError('Önce kod isteyin ve SMS kodu geldikten sonra tekrar deneyin.');
      return;
    }
    setState(() {
      _yukleniyor = true;
      _smsKodHatasi = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: kod,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await _firestoreLogin('+90$telefon');
    } catch (e) {
      setState(() {
        _yukleniyor = false;
        _smsKodHatasi = e.toString();
      });
      _showError('Kod doğrulama hatası: $e');
    }
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
      resizeToAvoidBottomInset: true,
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: !_smsTalepEdildi
                      ? Column(
                          key: const ValueKey('phone'),
                            crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              Icon(Icons.phone_iphone_rounded, size: 80, color: Colors.white.withOpacity(0.95)),
                              const SizedBox(height: 12),
                            Text(
                                'Giriş Yap',
                              textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                            Text(
                                'Telefon numaran ile devam et',
                              textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 36),
                              // --- MODERN INPUT ---
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
                                controller: _telefonController,
                                enabled: !_yukleniyor,
                                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, letterSpacing: 1.1),
                                decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.phone, color: colorScheme.primary),
                                  labelText: 'Telefon Numarası',
                                    labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  hintText: '5012345678',
                                    hintStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.1),
                                  prefixText: '+90 ',
                                    prefixStyle: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
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
                                    counterText: '',
                                ),
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                              ),
                            ),
                              const SizedBox(height: 36),
                              // --- MODERN BUTTON ---
                              GestureDetector(
                                onTap: _yukleniyor ? null : () => _smsKoduTalepEt(resend: false),
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
                                          'İleri',
                                          style: textTheme.titleLarge?.copyWith(
                                            color: colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                ),
                            ),
                          ],
                        )
                        : Column(
                            key: const ValueKey('code'),
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 80, color: Colors.white.withOpacity(0.95)),
                              const SizedBox(height: 12),
                              Text(
                                'Kodu Gir',
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'SMS ile gelen doğrulama kodunu gir',
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 28),
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
                                  controller: _smsController,
                                  focusNode: _smsFocusNode,
                                  enabled: !_yukleniyor,
                                  style: textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface, letterSpacing: 10, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                                    labelText: 'SMS Kodu',
                                    labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                    hintText: '123456',
                                    hintStyle: textTheme.headlineMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.3), letterSpacing: 10, fontWeight: FontWeight.bold),
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
                                    counterText: '',
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: (_yukleniyor || _verificationId == null) ? null : _girisYap,
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
                                          'Giriş Yap',
                                          style: textTheme.titleLarge?.copyWith(
                                            color: colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextButton(
                                onPressed: _yukleniyor
                                    ? null
                                    : () {
                                        setState(() {
                                          _smsTalepEdildi = false;
                                          _smsController.clear();
                                          _animController.reverse();
                                        });
                                      },
                                child: Text('Telefonu Değiştir', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                              ),
                              if (_kodGonderildi)
                                TextButton.icon(
                                  icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.85)),
                                  label: Text('Kodu Tekrar Gönder', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                                  onPressed: _yukleniyor ? null : () => _smsKoduTalepEt(resend: true),
                                ),
                            ],
                          ),
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
