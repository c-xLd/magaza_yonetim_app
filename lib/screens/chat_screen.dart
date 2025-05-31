import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

// Mesaj modeli
class ChatMessage {
  final String id;
  final String sender;
  final String senderName;
  final String senderAvatar;
  final String message;
  final DateTime timestamp;
  final String time;
  final bool isMe;
  final bool isAdmin;
  final String? imageUrl;
  bool isPinned;
  DateTime? pinnedUntil;
  bool isDeleted;
  bool isEdited;
  bool get isPinActive =>
      isPinned && (pinnedUntil == null || pinnedUntil!.isAfter(DateTime.now()));
  bool get shouldBeDeleted =>
      isDeleted &&
      timestamp.add(const Duration(days: 1)).isBefore(DateTime.now());

  ChatMessage({
    required this.senderName,
    required this.senderAvatar,
    String? id,
    String? sender,
    required this.message,
    required this.timestamp,
    String? time,
    required this.isMe,
    bool? isAdmin,
    this.imageUrl,
    bool? isPinned,
    this.pinnedUntil,
    bool? isDeleted,
    bool? isEdited,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        sender = sender ?? '',
        time = time ??
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
        isAdmin = isAdmin ?? false,
        isPinned = isPinned ?? false,
        isDeleted = isDeleted ?? false,
        isEdited = isEdited ?? false;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// Site sakinlerinin yönetimle iletişim kurduğu yardım masası ekranı

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Kullanıcı ayarları
  final String _currentUserName = "Ahmet Şahin";
  // ignore: unused_field
  final String _currentUserSurname = "";
  final String _currentUserAvatar =
      "https://randomuser.me/api/portraits/men/1.jpg";
  final bool _isAdmin = true;

  // Animasyon için hızlı reaksiyonlar listesi
  // ignore: unused_field
  final List<Map<String, String>> _quickReactions = [
    {
      'name': 'Beğen',
      'animUrl': 'https://assets10.lottiefiles.com/packages/lf20_BLz0kC.json',
      'textEmoji': '👍',
    },
    {
      'name': 'Kalp',
      'animUrl': 'https://assets4.lottiefiles.com/packages/lf20_bvzj3oha.json',
      'textEmoji': '❤️',
    },
    {
      'name': 'Alkış',
      'animUrl': 'https://assets1.lottiefiles.com/packages/lf20_kp5gmkts.json',
      'textEmoji': '👏',
    },
    {
      'name': 'Gülme',
      'animUrl':
          'https://assets7.lottiefiles.com/private_files/lf30_cGi6Ox.json',
      'textEmoji': '😂',
    },
    {
      'name': 'Üzgün',
      'animUrl': 'https://assets3.lottiefiles.com/packages/lf20_vky6k8zg.json',
      'textEmoji': '😢',
    },
  ];

  // Yazıyor animasyonu için
  bool _isTyping = false;
  Timer? _typingTimer;
  // ignore: unused_field
  final bool _showTypingIndicator = false;

  // Animasyon kontrolörleri
  late List<AnimationController> _dotControllers;
  // ignore: unused_field
  late List<Animation<double>> _dotAnimations;

  // Düzenleme modu
  bool _isEditMode = false;
  ChatMessage? _messageBeingEdited;

  // Fotoğraf ekleme
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  // Fotoğraf seçme fonksiyonu
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        // Seçilen görseli geçici olarak sakla ve mesaj kutusuna ekle
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel seçilemedi: $e')),
        );
      }
    }
  }

  // Mesajlar listesi
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: "1",
      sender: "Sistem",
      senderName: "Sistem",
      senderAvatar: "https://cdn-icons-png.flaticon.com/512/1053/1053210.png",
      message: "Mağaza yönetimi sohbet kanalına hoş geldiniz!",
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      time: "10:00",
      isMe: false,
      isAdmin: true,
    ),
    ChatMessage(
      id: "2",
      sender: "Mehmet Demir",
      senderName: "Mehmet Demir",
      senderAvatar: "https://randomuser.me/api/portraits/men/32.jpg",
      message:
          "Merhaba, yeni bir ürün siparişimiz var. Detayları görebilir miyiz?",
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isMe: false,
    ),
    ChatMessage(
      id: "3",
      sender: "Ahmet Şahin",
      senderName: "Ahmet Şahin",
      senderAvatar: "https://randomuser.me/api/portraits/men/1.jpg",
      message: "Tabii ki, sipariş detaylarını şimdi gönderiyorum.",
      timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
      isMe: true,
    ),
    ChatMessage(
      id: "4",
      sender: "Ayşe Kaya",
      senderName: "Ayşe Kaya",
      senderAvatar: "https://randomuser.me/api/portraits/women/44.jpg",
      message: "Merhaba, kasada bir sorun var. Yardım edebilir misiniz?",
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isMe: false,
    ),
    ChatMessage(
      id: "5",
      sender: "Ahmet Şahin",
      senderName: "Ahmet Şahin",
      senderAvatar: "https://randomuser.me/api/portraits/men/1.jpg",
      message: "Hemen geliyorum, lütfen bekleyin.",
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      isMe: true,
    ),
    ChatMessage(
      id: "6",
      sender: "Sistem",
      senderName: "Sistem",
      senderAvatar: "https://cdn-icons-png.flaticon.com/512/1053/1053210.png",
      message: "Günlük rapor hazırlandı. İndirmek için tıklayın.",
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isMe: false,
      isAdmin: true,
      isPinned: true,
      pinnedUntil: DateTime.now().add(const Duration(days: 1)),
    ),
  ];

  // Kullanıcıya özel renkler için sabit bir renk paleti
  final List<Color> _avatarColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.brown,
    Colors.cyan,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lime,
    Colors.amber,
    Colors.lightGreen,
    Colors.yellow,
    Colors.grey,
  ];

  // Kullanıcı ismine göre renk seç
  Color _colorForName(String name) {
    if (name.isEmpty) return Colors.black;
    final code = name.codeUnits.fold(0, (prev, el) => prev + el);
    return _avatarColors[code % _avatarColors.length];
  }

  // WhatsApp tarzı reaksiyon paneli için kullanılacak emojiler
  final List<String> _reactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  // Mesajlara atanmış reaksiyonlar (örnek, gerçek uygulamada modele eklenmeli)
  final Map<String, String> _messageReactions = {};

  RenderBox? _lastTappedBox;

  void _showReactionPanel(BuildContext context, ChatMessage message) async {
    if (_lastTappedBox == null || !_lastTappedBox!.attached) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final position =
        _lastTappedBox!.localToGlobal(Offset.zero, ancestor: overlay);

    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = _reactionEmojis.length * 38 + 24; // 38*emoji + padding

    // Ortalamak ve ekran dışına taşmayı engellemek için left değerini hesapla
    double left = position.dx +
        ((_lastTappedBox!.size.width - (_reactionEmojis.length * 38)) / 2);
    if (left < 8) left = 8;
    if (left + panelWidth > screenWidth - 8) left = screenWidth - panelWidth - 8;

    final emoji = await showGeneralDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: "Reaksiyon Paneli",
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = Tween<double>(begin: 0.7, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
        );
        final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeIn),
        );
        return AnimatedBuilder(
          animation: opacity,
          builder: (context, child) {
            final safeOpacity = opacity.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: safeOpacity,
              child: Stack(
                children: [
                  Positioned(
                    left: left,
                    top: position.dy - 54.0,
                    child: Material(
                      color: Colors.transparent,
                      child: ScaleTransition(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                List.generate(_reactionEmojis.length, (i) {
                              final emoji = _reactionEmojis[i];
                              final delay = i * 60;
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(milliseconds: 220 + delay),
                                curve: Curves.easeOutBack,
                                builder: (context, value, child) {
                                  final safeValue = value.clamp(0.0, 1.0);
                                  return Transform.translate(
                                    offset: Offset(0, (1 - safeValue) * 30),
                                    child: Opacity(
                                      opacity: safeValue,
                                      child: child,
                                    ),
                                  );
                                },
                                child: InkWell(
                                  onTap: () => Navigator.of(context).pop(emoji),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (emoji != null) {
      setState(() {
        _messageReactions[message.id] = emoji;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();

    // Animasyon kontrolörlerini kapat
    for (var controller in _dotControllers) {
      controller.dispose();
    }

    // Yazıyor timer'ı kapat
    _typingTimer?.cancel();

    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty && _selectedImage == null) return;

    setState(() {
      if (_isEditMode && _messageBeingEdited != null) {
        // Mesaj düzenleme
        final index =
            _messages.indexWhere((m) => m.id == _messageBeingEdited!.id);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: _messageBeingEdited!.id,
            sender: _messageBeingEdited!.sender,
            senderName: _messageBeingEdited!.senderName,
            senderAvatar: _messageBeingEdited!.senderAvatar,
            message: text,
            timestamp: _messageBeingEdited!.timestamp,
            isMe: _messageBeingEdited!.isMe,
            isAdmin: _messageBeingEdited!.isAdmin,
            imageUrl: _messageBeingEdited!.imageUrl,
            isPinned: _messageBeingEdited!.isPinned,
            pinnedUntil: _messageBeingEdited!.pinnedUntil,
            isDeleted: false,
            isEdited: true,
          );
        }
        _isEditMode = false;
        _messageBeingEdited = null;
      } else {
        // Yeni mesaj gönderme (görsel varsa ekle)
        _messages.add(ChatMessage(
          sender: _currentUserName,
          senderName: _currentUserName,
          senderAvatar: _currentUserAvatar,
          message: text,
          timestamp: DateTime.now(),
          isMe: true,
          isAdmin: _isAdmin,
          imageUrl: _selectedImage?.path,
        ));
      }
      _messageController.clear();
      _selectedImage = null;
      _isTyping = false;

      // Mesaj listesini en aşağıya kaydır
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  // Yazıyor durumu için timer

  // Yazıyor durumu için timer
  void _handleTypingStatusChange() {
    final text = _messageController.text;

    if (text.isEmpty) {
      setState(() {
        _isTyping = false;
      });
      return;
    }

    if (!_isTyping) {
      setState(() {
        _isTyping = true;
      });
    }

    // Timer'ı yenile
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  // Silinen mesajları temizle
  void _cleanupOldMessages() {
    setState(() {
      _messages.removeWhere((message) => message.shouldBeDeleted);
    });
  }

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolörleri
    _dotControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + (index * 100)),
      );
    });

    // Animasyonları tanımla
    for (var i = 0; i < _dotControllers.length; i++) {
      _dotControllers[i].repeat(reverse: true);
    }

    // Mesaj yazılırken kontrolü için listener ekle
    _messageController.addListener(_handleTypingStatusChange);

    // 6 saatte bir silinen mesajları temizle
    Timer.periodic(const Duration(hours: 6), (timer) {
      _cleanupOldMessages();
    });

    // Mesaj listesini başlangıçta en aşağıya kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Sohbet', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        backgroundColor: colorScheme.secondaryContainer,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sabitlenen mesajlar
          if (_messages.any((m) => m.isPinActive))
            _PinnedMessagesCarousel(
              pinnedMessages: _messages.where((m) => m.isPinActive).toList(),
              onTapMessage: (pinnedMsg) {
                final idx = _messages.indexWhere((m) => m.id == pinnedMsg.id);
                                if (idx != -1 && _scrollController.hasClients) {
                                  _scrollController.animateTo(
                    idx * 80.0,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
            ),
          // Mesaj listesi
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(_messages[index], colorScheme, textTheme);
              },
            ),
          ),
          // Mesaj yazma bölümü
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
              border: Border(top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.13))),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedImage!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                          showModalBottomSheet(
                            context: context,
                              backgroundColor: Colors.transparent,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                              ),
                              builder: (context) {
                                final colorScheme = Theme.of(context).colorScheme;
                                final textTheme = Theme.of(context).textTheme;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHigh,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow.withOpacity(0.13),
                                        blurRadius: 28,
                                        offset: const Offset(0, -6),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                                  child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAttachmentOption(
                                  icon: Icons.camera_alt,
                                  title: 'Kamera',
                                  onTap: () async {
                                    await _pickImage(ImageSource.camera);
                                  },
                                        iconColor: colorScheme.primary,
                                        textColor: colorScheme.onSurface,
                                ),
                                _buildAttachmentOption(
                                  icon: Icons.photo_library,
                                  title: 'Galeri',
                                  onTap: () async {
                                    await _pickImage(ImageSource.gallery);
                                  },
                                        iconColor: colorScheme.primary,
                                        textColor: colorScheme.onSurface,
                                ),
                              ],
                            ),
                          );
                        },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.attach_file, color: colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.10)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  minLines: 1,
                                  maxLines: 5,
                                  style: textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: _isEditMode ? 'Mesajı düzenle...' : 'Mesaj yaz...',
                                    hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              if (_isTyping)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Icon(Icons.edit_note, color: colorScheme.primary, size: 22),
                                ),
                              if (_isEditMode)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Icon(Icons.edit, color: colorScheme.tertiary, size: 20),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            if (_messageController.text.trim().isNotEmpty || _selectedImage != null) {
                              _sendMessage(_messageController.text);
                            }
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Icon(_isEditMode ? Icons.check : Icons.send, color: colorScheme.onPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
    required Future<void> Function() onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.black),
      ),
      onTap: () async {
        Navigator.pop(context); // BottomSheet'i kapat
        await Future.delayed(
            const Duration(milliseconds: 150)); // Animasyon için kısa bekleme
        try {
          await onTap(); // onTap artık Future<void> döner
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bir hata oluştu: $e')),
            );
          }
        }
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message, ColorScheme colorScheme, TextTheme textTheme) {
    final bool isMe = message.isMe;
    final Color userColor = _colorForName(message.senderName);
    final GlobalKey bubbleKey = GlobalKey();

    String pinnedTimeLeft() {
      if (message.pinnedUntil == null) return '';
      final now = DateTime.now();
      final diff = message.pinnedUntil!.difference(now);
      if (diff.inMinutes < 1) return 'Sona erdi';
      if (diff.inHours < 1) return '${diff.inMinutes} dk kaldı';
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (minutes == 0) {
        return '$hours saat kaldı';
      } else {
        return '$hours sa $minutes dk kaldı';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
          ],
          GestureDetector(
            onTap: () {
              final context = bubbleKey.currentContext;
              if (context != null) {
                _lastTappedBox = context.findRenderObject() as RenderBox?;
                _showReactionPanel(this.context, message);
              }
            },
            onLongPress: () {
              final bool canEdit = message.isMe && !message.isDeleted;
              final bool canDelete = message.isMe && !message.isDeleted;
              final bool canPin = !message.isDeleted;
              if (!canEdit && !canDelete && !canPin) {
                return;
              }
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                builder: (ctx) {
                  final colorScheme = Theme.of(context).colorScheme;
                  final textTheme = Theme.of(context).textTheme;
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.10),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canEdit)
                        ListTile(
                              leading: Icon(Icons.edit, color: colorScheme.primary),
                              title: Text('Düzenle', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
                          onTap: () {
                            setState(() {
                              _messageController.text = message.message;
                              _isEditMode = true;
                              _messageBeingEdited = message;
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                      if (canDelete)
                        ListTile(
                              leading: Icon(Icons.delete, color: colorScheme.error),
                              title: Text('Sil', style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
                          onTap: () {
                            setState(() {
                                  final index = _messages.indexWhere((m) => m.id == message.id);
                              if (index != -1) {
                                _messages[index] = ChatMessage(
                                  id: message.id,
                                  sender: message.sender,
                                  senderName: message.senderName,
                                  senderAvatar: message.senderAvatar,
                                  message: message.message,
                                  timestamp: message.timestamp,
                                  isMe: message.isMe,
                                  isAdmin: message.isAdmin,
                                  imageUrl: message.imageUrl,
                                  isPinned: false,
                                  pinnedUntil: null,
                                  isDeleted: true,
                                  isEdited: message.isEdited,
                                );
                              }
                              _cleanupOldMessages();
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                      if (canPin)
                        ListTile(
                          leading: Icon(
                                message.isPinActive ? Icons.push_pin : Icons.push_pin_outlined,
                                color: message.isPinActive ? colorScheme.tertiary : colorScheme.onSurface,
                          ),
                          title: Text(
                                message.isPinActive ? 'Sabitlemeden Kaldır' : 'Mesajı Sabitle',
                                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                              ),
                              onTap: () async {
                                if (message.isPinActive) {
                            setState(() {
                                    final index = _messages.indexWhere((m) => m.id == message.id);
                              if (index != -1) {
                                _messages[index] = ChatMessage(
                                  id: message.id,
                                  sender: message.sender,
                                  senderName: message.senderName,
                                  senderAvatar: message.senderAvatar,
                                  message: message.message,
                                  timestamp: message.timestamp,
                                  isMe: message.isMe,
                                  isAdmin: message.isAdmin,
                                  imageUrl: message.imageUrl,
                                        isPinned: false,
                                        pinnedUntil: null,
                                  isDeleted: message.isDeleted,
                                  isEdited: message.isEdited,
                                );
                              }
                            });
                            Navigator.pop(ctx);
                                } else {
                                  final now = DateTime.now();
                                  final Duration? selected = await showModalBottomSheet<Duration>(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                                    ),
                                    builder: (context) {
                                      final colorScheme = Theme.of(context).colorScheme;
                                      final textTheme = Theme.of(context).textTheme;
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHigh,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.shadow.withOpacity(0.13),
                                              blurRadius: 28,
                                              offset: const Offset(0, -6),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Sabitleme Süresi Seç', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 12),
                                            ListTile(
                                              leading: const Icon(Icons.timer, color: Colors.blue),
                                              title: const Text('1 Saat'),
                                              onTap: () => Navigator.pop(context, const Duration(hours: 1)),
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.today, color: Colors.green),
                                              title: const Text('1 Gün'),
                                              onTap: () => Navigator.pop(context, const Duration(days: 1)),
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.date_range, color: Colors.orange),
                                              title: const Text('1 Hafta'),
                                              onTap: () => Navigator.pop(context, const Duration(days: 7)),
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.calendar_month, color: Colors.purple),
                                              title: const Text('1 Ay'),
                                              onTap: () => Navigator.pop(context, const Duration(days: 30)),
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, null),
                                              child: const Text('Vazgeç'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                  if (selected != null) {
                                    setState(() {
                                      final index = _messages.indexWhere((m) => m.id == message.id);
                                      if (index != -1) {
                                        _messages[index] = ChatMessage(
                                          id: message.id,
                                          sender: message.sender,
                                          senderName: message.senderName,
                                          senderAvatar: message.senderAvatar,
                                          message: message.message,
                                          timestamp: message.timestamp,
                                          isMe: message.isMe,
                                          isAdmin: message.isAdmin,
                                          imageUrl: message.imageUrl,
                                          isPinned: true,
                                          pinnedUntil: now.add(selected),
                                          isDeleted: message.isDeleted,
                                          isEdited: message.isEdited,
                                        );
                                      }
                                    });
                                  }
                                  Navigator.pop(ctx);
                                }
                          },
                        ),
                    ],
                  ),
                ),
                  );
                },
              );
            },
            child: ChatBubble(
              key: bubbleKey,
              message: message,
              isMe: isMe,
              userColor: userColor,
              reaction: _messageReactions[message.id],
              onEdit: () => setState(() {
                _messageController.text = message.message;
                _isEditMode = true;
                _messageBeingEdited = message;
              }),
              onDelete: () => setState(() {
                final index = _messages.indexWhere((m) => m.id == message.id);
                if (index != -1) {
                  _messages[index] = ChatMessage(
                    id: message.id,
                    sender: message.sender,
                    senderName: message.senderName,
                    senderAvatar: message.senderAvatar,
                    message: message.message,
                    timestamp: message.timestamp,
                    isMe: message.isMe,
                    isAdmin: message.isAdmin,
                    imageUrl: message.imageUrl,
                    isPinned: false,
                    pinnedUntil: null,
                    isDeleted: message.isDeleted,
                    isEdited: message.isEdited,
                  );
                }
                _cleanupOldMessages();
              }),
              onPin: () => setState(() {
                final index = _messages.indexWhere((m) => m.id == message.id);
                if (index != -1) {
                  _messages[index] = ChatMessage(
                    id: message.id,
                    sender: message.sender,
                    senderName: message.senderName,
                    senderAvatar: message.senderAvatar,
                    message: message.message,
                    timestamp: message.timestamp,
                    isMe: message.isMe,
                    isAdmin: message.isAdmin,
                    imageUrl: message.imageUrl,
                    isPinned: true,
                    pinnedUntil: DateTime.now().add(const Duration(hours: 1)),
                    isDeleted: message.isDeleted,
                    isEdited: message.isEdited,
                  );
                }
              }),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8.0),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Color userColor;
  final String? reaction;
  final Function()? onEdit;
  final Function()? onDelete;
  final Function()? onPin;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.userColor,
    this.reaction,
    this.onEdit,
    this.onDelete,
    this.onPin,
  });

  BoxDecoration _bubbleDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (message.isDeleted) {
      return BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.13)),
      );
    }
    if (message.isPinActive) {
      return BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.tertiary.withOpacity(0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    if (!isMe) {
      return BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    // isMe
    return BoxDecoration(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
              BoxShadow(
          color: colorScheme.shadow.withOpacity(0.09),
          blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bool isActivePinned = message.isPinActive;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isActivePinned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin, size: 14, color: colorScheme.onTertiaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Sabitlenmiş Mesaj',
                    style: textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (message.pinnedUntil != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      _pinnedTimeLeft(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onTertiaryContainer.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: mediaQuery.size.width * 0.74),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: _bubbleDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!message.isMe && !message.isDeleted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              message.senderName,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isActivePinned
                                    ? Colors.white
                                    : message.isAdmin
                                        ? Colors.amber
                                        : colorScheme.primary,
                              ),
                            ),
                            if (message.isAdmin) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Yönetici',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (message.isDeleted)
                      Text(
                        "Bu mesaj silindi",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else ...[
                      if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: message.imageUrl!.startsWith('http')
                                ? Image.network(
                                    message.imageUrl!,
                                    width: 180,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(message.imageUrl!),
                                    width: 180,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: textTheme.bodyLarge?.copyWith(
                            color: isActivePinned
                                ? colorScheme.onTertiaryContainer
                                : isMe
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                            fontStyle: message.isEdited ? FontStyle.italic : null,
                          ),
                        ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          message.time,
                          style: textTheme.bodySmall?.copyWith(
                            color: isActivePinned
                                ? colorScheme.onTertiaryContainer.withOpacity(0.8)
                                : isMe
                                    ? colorScheme.onPrimary.withOpacity(0.7)
                                    : colorScheme.outline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (message.isEdited && !message.isDeleted) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(Düzenlendi)',
                            style: textTheme.bodySmall?.copyWith(
                              color: isActivePinned
                                  ? colorScheme.onTertiaryContainer.withAlpha(178)
                                    : isMe
                                      ? colorScheme.onPrimary.withAlpha(178)
                                      : colorScheme.outline,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (reaction != null)
                Positioned(
                  bottom: -18,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActivePinned
                            ? colorScheme.tertiaryContainer
                            : isMe
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 4,
                          ),
                        ],
                        border: Border.all(
                          color: isActivePinned
                              ? colorScheme.tertiary.withOpacity(0.18)
                              : isMe
                                  ? colorScheme.primary.withOpacity(0.18)
                                  : colorScheme.outlineVariant.withOpacity(0.18),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        reaction!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isActivePinned
                              ? colorScheme.onTertiaryContainer
                              : isMe
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _pinnedTimeLeft() {
    if (message.pinnedUntil == null) return '';
    final now = DateTime.now();
    final diff = message.pinnedUntil!.difference(now);
    if (diff.inMinutes < 1) return 'Sona erdi';
    if (diff.inHours < 1) return '${diff.inMinutes} dk kaldı';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (minutes == 0) {
      return '$hours saat kaldı';
    } else {
      return '$hours sa $minutes dk kaldı';
    }
  }
}

class _PinnedMessagesCarousel extends StatefulWidget {
  final List<ChatMessage> pinnedMessages;
  final void Function(ChatMessage) onTapMessage;
  const _PinnedMessagesCarousel({required this.pinnedMessages, required this.onTapMessage});

  @override
  State<_PinnedMessagesCarousel> createState() => _PinnedMessagesCarouselState();
}

class _PinnedMessagesCarouselState extends State<_PinnedMessagesCarousel> {
  int _currentPage = 0;
  late final PageController _pageController;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    if (widget.pinnedMessages.length <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % widget.pinnedMessages.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _PinnedMessagesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pinnedMessages.length != widget.pinnedMessages.length) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pinned = widget.pinnedMessages;
    return Container(
      margin: const EdgeInsets.only(top: 6, left: 8, right: 8, bottom: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colorScheme.primary.withOpacity(0.10), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin, size: 22, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Sabitlenmiş Mesajlar',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  pinned.length.toString(),
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (pinned.length > 1)
                Row(
        mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    pinned.length,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentPage ? colorScheme.primary : colorScheme.primary.withOpacity(0.25),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 48, // Yüksekliği artırdık (eski: 48)
            child: PageView.builder(
              controller: _pageController,
              itemCount: pinned.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, i) {
                final msg = pinned[i];
                return GestureDetector(
                  onTap: () => widget.onTapMessage(msg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.primary.withOpacity(0.13),
                    child: Text(
                          msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              msg.message,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                                fontSize: 11.5,
                              ),
                              maxLines: 1, // Tek satırda tut
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  msg.time,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                  ),
                                ),
                                if (msg.pinnedUntil != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    _pinnedTimeLeft(msg),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _pinnedTimeLeft(ChatMessage msg) {
    if (msg.pinnedUntil == null) return '';
    final now = DateTime.now();
    final diff = msg.pinnedUntil!.difference(now);
    if (diff.inMinutes < 1) return 'Sona erdi';
    if (diff.inHours < 1) return '${diff.inMinutes} dk kaldı';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (minutes == 0) {
      return '$hours saat kaldı';
    } else {
      return '$hours sa $minutes dk kaldı';
    }
  }
}
