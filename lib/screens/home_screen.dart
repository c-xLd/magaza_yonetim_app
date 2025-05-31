import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../common/sliding_panels.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showUpcomingTasksBottomSheet(BuildContext context) {
    final List<Map<String, String>> tasks = [
      {
        'date': '18.08.2025',
        'desc': 'Sayım işlemlerinin satışı bekliyor.'
      },
      {
        'date': '20.08.2025',
        'desc': 'SKT kontrolü yapılacak.'
      },
      {
        'date': '22.08.2025',
        'desc': 'Aylık envanter raporu hazırlanacak.'
      },
      {
        'date': '25.08.2025',
        'desc': 'Yönetici toplantısı.'
      },
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
            mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_note, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text('Yaklaşan Görevler', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 18),
              ...tasks.take(3).map((task) => Card(
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withOpacity(0.13),
                    child: Icon(Icons.calendar_today, color: colorScheme.primary),
                  ),
                  title: Text(task['desc'] ?? '', style: textTheme.bodyLarge),
                  subtitle: Text(task['date'] ?? '', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                ),
              )),
              if (tasks.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Tümünü Gör'),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = (authProvider.displayName?.split(' ').first) ?? 'Kullanıcı';
    final userRole = AuthProvider.getDisplayRole(authProvider.role ?? 'staff');
    debugPrint('Kullanıcı role: [32m${authProvider.role ?? 'staff'}[0m');
    print('Kullanıcı role: ${authProvider.role ?? 'staff'}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Mağaza Yönetimi', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: colorScheme.secondaryContainer,
        elevation: 0,
        actions: [
          Badge(
            label: const Text('3'),
            offset: const Offset(-4, -1),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              tooltip: 'Bildirimler',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          Badge(
            label: const Text('2'), 
            offset: const Offset(-4, -1),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: IconButton(
              icon: const Icon(Icons.mail_outline),
              onPressed: () => Navigator.pushNamed(context, '/chat'),
              tooltip: 'Mesajlar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.10),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: UserSettingsPanel(
                      isDarkMode: true, // Tema değişimi için gerçek state eklenebilir
                      onThemeChanged: (val) {}, // Tema değişimi fonksiyonu eklenebilir
                      onProfileEdit: () {
                        Navigator.pop(context);
                        // Profil düzenleme ekranına yönlendirme eklenebilir
                      },
                      onAdminSettings: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin-panel');
                      },
                      onLogout: () async {
                        Navigator.pop(context); // paneli kapat
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      userName: (authProvider.displayName ?? 'Kullanıcı'),
                      userRole: AuthProvider.getDisplayRole(authProvider.role),
                      isAdmin: authProvider.role == 'admin',
                    ),
                  );
                },
              );
            },
            tooltip: 'Profil',
          ),
        ],
      ),
      body: Container(
        color: colorScheme.surface,
        child: Stack(
          children: [
            // Üstte dalga deseni
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TopWavePainter(color: colorScheme.secondaryContainer),
                ),
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hoşgeldin kartı
                  Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                      final userName = (authProvider.displayName?.split(' ').first) ?? 'Kullanıcı';
                      final userRole = AuthProvider.getDisplayRole(authProvider.role ?? 'staff');
                      return Card(
                        color: colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary,
                              child: Text(
                              (userName.isNotEmpty) ? userName[0].toUpperCase() : '?',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'Hoş Geldin, $userName',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          subtitle: Row(
                            children: [
                              Text(
                                userRole,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          trailing: Icon(Icons.waving_hand, color: colorScheme.primary),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Hızlı aksiyonlar
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.event_note),
                              label: const Text('Yaklaşan Görevler'),
                              onPressed: () => _showUpcomingTasksBottomSheet(context),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                      ),
                    ],
                  );
                },
              ),
                  const SizedBox(height: 28),
                  // Ana menü kartları
                  Expanded(
                    child: GridView(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 0.95,
                      ),
                      children: [
                        _HomeMenuCard(
                          icon: Icons.fact_check,
                          title: 'Günlük Sayım',
                          color: colorScheme.primaryContainer,
                          iconColor: colorScheme.primary,
                          onTap: () => Navigator.pushNamed(context, '/inventory-count'),
                        ),
                        _HomeMenuCard(
                          icon: Icons.assignment_turned_in,
                          title: 'SKT Takibi',
                          color: colorScheme.primaryFixedDim,
                          iconColor: colorScheme.onPrimaryFixedVariant,
                          onTap: () => Navigator.pushNamed(context, '/skt-tracking'),
                        ),
                         _HomeMenuCard(
                          icon: Icons.point_of_sale,
                          title: 'Satış Girişi',
                          color: colorScheme.secondaryContainer,
                          iconColor: colorScheme.secondary,
                          onTap: () => Navigator.pushNamed(context, '/inventory-sales'),
                        ),
                        _HomeMenuCard(
                          icon: Icons.calendar_month,
                          title: 'Envanter Takvimi',
                          color: colorScheme.tertiaryContainer,
                          iconColor: colorScheme.tertiary,
                          onTap: () => Navigator.pushNamed(context, '/calendar'),
                        ),
                        
                      ],
                    ),
                  ),
                  // Bilgilendirme kartı
                  Card(
                    color: colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                    children: [
                          Icon(Icons.info_outline, color: colorScheme.primary, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Mağaza işlemlerini kolayca yönetebileceğiniz bir uygulama.',
                              style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Material 3 uyumlu ana menü kartı
class _HomeMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _HomeMenuCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: color,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.13),
                radius: 24,
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 10),
                  Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: iconColor,
                      fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dalga şekli için CustomPainter
class _TopWavePainter extends CustomPainter {
  final Color color;
  _TopWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.35,
      size.width * 0.5, size.height * 0.55,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.75,
      size.width, size.height * 0.55,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
