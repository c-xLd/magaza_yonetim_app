import 'package:flutter/material.dart';
import 'package:magaza_yonetimi/common/slidable_notifications.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollController = ScrollController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Yerel bildirim verileri yükleme
  Future<void> _loadNotifications() async {
    // Biraz yükleme hissi vermek için gecikmeli yapay veri yükleme
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    // A101 mağaza yönetimi için örnek bildirim verileri
    final mockNotifications = [
      {
        'id': '1',
        'title': 'Personel Toplantısı',
        'body':
            'Önümüzdeki Pazartesi günü saat 09:00\'da bölge yönetici toplantısı düzenlenecektir. Katılımınızı rica ederiz.',
        'type': 'meeting',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': false,
      },
      {
        'id': '2',
        'title': 'Stok Durumu Kritik',
        'body':
            'Süt ürünleri reyonunda bazı ürünlerin stok seviyesi kritik duruma düşmüştür. Lütfen sipariş listesine ekleyiniz.',
        'type': 'inventory',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'isRead': false,
      },
      {
        'id': '3',
        'title': 'Bakım Çalışması Duyurusu',
        'body':
            'Yarın 22:00-06:00 saatleri arasında planlanan bakım çalışmaları nedeniyle depoda çalışma yapılmayacaktır.',
        'type': 'warning',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'isRead': true,
      },
      {
        'id': '4',
        'title': 'Yeni Personel',
        'body':
            'Ekibimize yeni katılan Mehmet Yılmaz kasiyer pozisyonunda göreve başlamıştır. Hoşgeldin mesajınızı iletebilirsiniz.',
        'type': 'resident',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'isRead': true,
      },
      {
        'id': '5',
        'title': 'Güvenlik Hatırlatması',
        'body':
            'Lütfen mesai bitiminde soğutucu dolapların kontrolünü yapmadan mağazayı terk etmeyiniz. Elektrik tasarrufu sağlayalım.',
        'type': 'security',
        'createdAt': DateTime.now().subtract(const Duration(days: 7)),
        'isRead': false,
      },
      {
        'id': '6',
        'title': 'Kampanya Duyurusu',
        'body':
            'Önümüzdeki hafta başlayacak yeni kampanyalar için reyon düzeni talimatları eposta ile gönderilmiştir.',
        'type': 'announcement',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'isRead': true,
      },
      {
        'id': '4',
        'title': 'Personel Toplantısı',
        'body':
            'Önümüzdeki Pazartesi saat 14:00\'te mağaza personeli aylık değerlendirme toplantısı yapılacaktır.',
        'type': 'meeting',
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
        'isRead': true,
      },
      {
        'id': '5',
        'title': 'Son Kullanma Tarihi Yaklaşan Ürünler',
        'body':
            '10 üründe son kullanma tarihi yaklaşıyor. SKT takip ekranından kontrol edebilirsiniz.',
        'type': 'skt',
        'createdAt': DateTime.now().subtract(const Duration(days: 4)),
        'isRead': true,
      },
    ];

    if (mounted) {
      setState(() {
        _notifications = mockNotifications;
        _isLoading = false;
      });
    }
  }

  // Bildirim okundu olarak işaretleme
  void _markAsRead(String notificationId) {
    setState(() {
      _notifications = _notifications.map((notification) {
        if (notification['id'] == notificationId) {
          return {...notification, 'isRead': true};
        }
        return notification;
      }).toList();
    });
  }

  // Sonsuz kaydırma için kaydırma dinleyicisi
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreNotifications();
    }
  }

  // Daha fazla bildirim yükleme (örnek için boş bırakıldı)
  Future<void> _loadMoreNotifications() async {
    // Bu örnekte ek bildirim yüklemeye gerek yok
  }

  // Tarih görüntüleme biçimini düzenleyen yardımcı metod
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Bildirim tipi için ikon belirleyen yardımcı metod
  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'inventory':
        return Icons.inventory_2;
      case 'warning':
        return Icons.warning_amber;
      case 'payment':
        return Icons.payment;
      case 'meeting':
        return Icons.event;
      case 'resident':
        return Icons.people;
      case 'security':
        return Icons.security;
      case 'maintenance':
        return Icons.build;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  // Bildirim tipi için renk belirleyen yardımcı metod
  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'inventory':
        return Colors.blue;
      case 'warning':
        return Colors.amber;
      case 'payment':
        return Colors.green;
      case 'meeting':
        return Colors.purple;
      case 'resident':
        return Colors.teal;
      case 'security':
        return Colors.red;
      case 'maintenance':
        return Colors.blue;
      case 'announcement':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    // Bildirimleri okunmuş ve okunmamış olarak ayır
    final unread = _notifications.where((n) => n['isRead'] == false).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Bildirimler', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check_circle_outline,
              size: isSmallScreen ? 22 : 24,
              color: _notifications.any((n) => n['isRead'] == false)
                  ? colorScheme.primary
                  : colorScheme.outline,
            ),
            onPressed: () {
              final hasUnread = _notifications.any((n) => n['isRead'] == false);
              if (!hasUnread) return;
              setState(() {
                _notifications = _notifications
                    .map((notification) => {
                          ...notification,
                          'isRead': true,
                        })
                    .toList();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tüm bildirimler okundu olarak işaretlendi', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary)),
                  backgroundColor: colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
            tooltip: 'Tümünü Okundu İşaretle',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary))
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off,
                            size: 80, color: colorScheme.outlineVariant),
                        const SizedBox(height: 20),
                        Text(
                          'Bildiriminiz bulunmamaktadır',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadNotifications,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Yenile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    children: [
                      if (unread.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                          child: Row(
                            children: [
                              Text(
                                'Okunmamış',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unread.length.toString(),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...unread.map((notification) => SlidableNotification(
                              title: notification['title'],
                              message: notification['body'],
                              time: _formatDate(notification['createdAt']),
                              icon: _getNotificationTypeIcon(notification['type']),
                              iconColor: _getNotificationTypeColor(notification['type']),
                              isRead: notification['isRead'],
                              onTap: () {},
                              onDelete: () {
                                setState(() {
                                  _notifications.removeWhere((n) => n['id'] == notification['id']);
                                });
                              },
                              onMarkAsRead: () => _markAsRead(notification['id']),
                            )),
                      ],
                    ],
                  ),
      ),
    );
  }
}

// Modern Material 3 Expressive bildirim kartı
class _ModernNotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _ModernNotificationCard({
    required this.notification,
    required this.colorScheme,
    required this.textTheme,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['isRead'] as bool;
    final String type = notification['type'] as String;
    final IconData typeIcon = _getNotificationTypeIcon(type);
    final Color typeColor = _getNotificationTypeColor(type);
    final DateTime createdAt = notification['createdAt'] as DateTime;
    final String timeAgo = _formatDate(createdAt);

    // Tema ile uyumlu reaction arka planı
    final Color reactionBg = Color.alphaBlend(
      typeColor.withOpacity(0.13),
      colorScheme.primaryContainer,
    );

    // Emoji algılama (mesaj başında emoji varsa)
    final String body = notification['body'] as String;
    final RegExp emojiRegex = RegExp(
      r'^(?:[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}])',
      unicode: true,
    );
    String? leadingEmoji;
    String messageBody = body;
    if (body.isNotEmpty && emojiRegex.hasMatch(body[0])) {
      leadingEmoji = body[0];
      messageBody = body.substring(1).trimLeft();
    }

    // Emoji kutusu arka planı kart ile aynı renk
    final Color emojiBg = colorScheme.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: typeColor.withOpacity(0.35), width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İkon ve renkli arka plan
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: reactionBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    // İçerik
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: typeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  notification['title'] as String,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: typeColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (leadingEmoji != null)
                                CircleAvatar(
                                  backgroundColor: emojiBg,
                                  radius: 18,
                                  child: Text(
                                    leadingEmoji,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              if (leadingEmoji != null)
                                const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  messageBody,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timeAgo,
                            style: textTheme.bodySmall?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sil butonu
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      tooltip: 'Sil',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bildirim tipi için ikon
  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'inventory':
        return Icons.inventory_2;
      case 'warning':
        return Icons.warning_amber;
      case 'payment':
        return Icons.payment;
      case 'meeting':
        return Icons.event;
      case 'resident':
        return Icons.people;
      case 'security':
        return Icons.security;
      case 'maintenance':
        return Icons.build;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  // Tarih biçimi
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Bildirim tipi için renk
  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'inventory':
        return Colors.blue;
      case 'warning':
        return Colors.amber;
      case 'payment':
        return Colors.green;
      case 'meeting':
        return Colors.purple;
      case 'resident':
        return Colors.teal;
      case 'security':
        return Colors.red;
      case 'maintenance':
        return Colors.blue;
      case 'announcement':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}

// Emoji Reaction Bar widget
class EmojiReactionBar extends StatelessWidget {
  final List<String> emojis;
  final Color? backgroundColor;

  const EmojiReactionBar({
    super.key,
    required this.emojis,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHigh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: emojis
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(e, style: const TextStyle(fontSize: 24)),
                ))
            .toList(),
      ),
    );
  }
}
