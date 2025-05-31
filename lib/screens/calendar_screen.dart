import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:magaza_yonetimi/providers/auth_provider.dart';

// Envanter Özeti Modeli
class InventorySummary {
  final int totalProducts;
  final int stockIssueCount;
  final int potentialTheft;
  final Duration countDuration;

  InventorySummary({
    required this.totalProducts,
    required this.stockIssueCount,
    required this.potentialTheft,
    required this.countDuration,
  });

  Map<String, dynamic> toJson() => {
        'totalProducts': totalProducts,
        'stockIssueCount': stockIssueCount,
        'potentialTheft': potentialTheft,
        'countDuration': countDuration.inMinutes,
      };

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      totalProducts: json['totalProducts'] as int,
      stockIssueCount: json['stockIssueCount'] as int,
      potentialTheft: json['potentialTheft'] as int,
      countDuration: Duration(minutes: json['countDuration'] as int),
    );
  }
}

// Envanter Kaydı Modeli
class InventoryRecord {
  final String id;
  final DateTime countDate;
  final int productCount;
  final int stockIssueCount;
  final int potentialTheft;
  final String countDuration;
  final String category;
  final String? countedBy;

  InventoryRecord({
    required this.id,
    required this.countDate,
    required this.productCount,
    required this.stockIssueCount,
    required this.potentialTheft,
    required this.countDuration,
    required this.category,
    this.countedBy,
  });

  String get formattedDate => DateFormat('dd.MM.yyyy HH:mm').format(countDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'countDate': countDate.toIso8601String(),
        'productCount': productCount,
        'stockIssueCount': stockIssueCount,
        'potentialTheft': potentialTheft,
        'countDuration': countDuration,
        'category': category,
        'countedBy': countedBy,
      };

  factory InventoryRecord.fromJson(Map<String, dynamic> json) {
    return InventoryRecord(
      id: json['id'] as String,
      countDate: DateTime.parse(json['countDate'] as String),
      productCount: json['productCount'] as int,
      stockIssueCount: json['stockIssueCount'] as int,
      potentialTheft: json['potentialTheft'] as int,
      countDuration: json['countDuration'] as String,
      category: json['category'] as String,
      countedBy: json['countedBy'] as String?,
    );
  }
}

// Tamamlanmış Ürün Modeli
class CompletedProduct {
  final String name;
  final int count;
  final String category;
  final String status;
  final DateTime completedAt;

  CompletedProduct({
    required this.name,
    required this.count,
    required this.category,
    required this.status,
    required this.completedAt,
  });
}

// Ürün detayı için model (örnek/mock)
class CountedProduct {
  final String name;
  final String code;
  final String category;
  final int countedAmount;
  final int salesAmount;
  final int stockStatus; // -1, 0, +1

  CountedProduct({
    required this.name,
    required this.code,
    required this.category,
    required this.countedAmount,
    required this.salesAmount,
    required this.stockStatus,
  });
}

// Takvim Günü Modeli
class InventoryDay {
  final int day;
  final int totalCounts;
  final List<InventoryRecord> records;
  final InventorySummary summary;
  final DateTime date;

  InventoryDay({
    required this.day,
    required this.totalCounts,
    required this.records,
    required this.summary,
    required this.date,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isLoading = true;
  late DateTime _selectedMonth;
  List<InventoryDay> _inventoryDays = [];
  Map<int, List<InventoryRecord>> _daysWithCounts = {};
  int? _selectedDay; // Seçili gün (gün numarası)
  final List<CompletedProduct> _mockProducts = [];
  final ScrollController _daysScrollController = ScrollController();
  Map<String, Map<String, String>> _userInfos = {}; // userId -> {'name': ..., 'role': ...}

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadUserInfos().then((_) => _loadData());
  }

  Future<void> _loadUserInfos() async {
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final infos = <String, Map<String, String>>{};
    for (final doc in usersSnap.docs) {
      final data = doc.data();
      infos[doc.id] = {
        'name': data['name'] ?? doc.id,
        'role': data['role'] ?? '',
      };
    }
    setState(() {
      _userInfos = infos;
    });
  }

  // Son sayım yapılan günü bul (bugüne kadar olan en büyük gün)
  int? _findLastCountDay() {
    if (_daysWithCounts.isEmpty) return null;
    final today = DateTime.now().day;
    // Bugüne kadar olan günler arasında en büyüğünü bul
    final validDays = _daysWithCounts.keys.where((d) => d <= today).toList();
    if (validDays.isNotEmpty) {
      validDays.sort();
      return validDays.last;
    }
    // Eğer bugüne kadar hiç kayıt yoksa, en büyük günü döndür
    final sortedDays = _daysWithCounts.keys.toList()..sort();
    return sortedDays.isNotEmpty ? sortedDays.last : null;
  }

  // Veri yükleme fonksiyonu
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _inventoryDays = [];
    });

    try {
      final month = _selectedMonth;

      // Firestore'dan inventoryCounts koleksiyonunu çek
      final snapshot = await FirebaseFirestore.instance
          .collection('inventoryCounts')
          .get();

      // Günlere göre kayıtları grupla
      final Map<int, List<InventoryRecord>> countsByDay = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Tarih bilgisini al
        final dateParts = doc.id.split('-');
        if (dateParts.length != 3) continue;
        final year = int.tryParse(dateParts[0]);
        final monthNum = int.tryParse(dateParts[1]);
        final day = int.tryParse(dateParts[2]);
        if (year == null || monthNum == null || day == null) continue;

        // Sadece seçili ay ve yıl için
        if (year != month.year || monthNum != month.month) continue;

        // Her kullanıcı için kayıtları işle
        final userCounts = data['userCounts'] as Map<String, dynamic>? ?? {};
        for (final entry in userCounts.entries) {
          final countedBy = entry.key;
          final productsMap = entry.value as Map<String, dynamic>;
          int productCount = 0;
          int stockIssueCount = 0;
          int potentialTheft = 0;
          // Her ürün için sayım ve sorunları topla
          for (final prod in productsMap.values) {
            final prodMap = prod as Map<String, dynamic>;
            productCount++;
            if ((prodMap['problem'] ?? false) == true) {
              stockIssueCount++;
            }
            if ((prodMap['potentialTheft'] ?? false) == true) {
              potentialTheft++;
            }
          }
          // Sayım süresi Firestore'da tutuluyorsa alın, yoksa varsayılan ver
          final countDuration = data['countDuration'] is int
              ? '${data['countDuration']} dakika'
              : (data['countDuration'] ?? '0 dakika').toString();

          final category = data['category'] ?? '-';

          final record = InventoryRecord(
            id: '${doc.id}-$countedBy',
            countDate: DateTime(year, monthNum, day),
            productCount: productCount,
            stockIssueCount: stockIssueCount,
            potentialTheft: potentialTheft,
            countDuration: countDuration,
            category: category,
            countedBy: countedBy,
          );

          countsByDay.putIfAbsent(day, () => []).add(record);
        }
      }

      setState(() {
        _daysWithCounts = countsByDay;
        _isLoading = false;
      });

      _generateInventoryDays();

      // En son sayım yapılan günü seçili yap ve ürünleri güncelle
      final lastCountDay = _findLastCountDay();
      if (lastCountDay != null) {
        setState(() {
          _selectedDay = lastCountDay;
        });
        _updateSelectedDayProducts();
        _scrollToSelectedDay(lastCountDay);
      } else {
        setState(() {
          _selectedDay = DateTime.now().day;
        });
        _updateSelectedDayProducts();
        _scrollToSelectedDay(DateTime.now().day);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Veri yükleme hatası: $e');
    }
  }

  // Envanter günlerini oluştur
  void _generateInventoryDays() {
    final List<InventoryDay> days = [];
    if (_daysWithCounts.isEmpty) {
      setState(() {
        _inventoryDays = [];
      });
      return;
    }

    // Her gün için veri oluştur
    for (final entry in _daysWithCounts.entries) {
      final day = entry.key;
      final records = entry.value;

      int totalProducts = 0;
      int stockIssueCount = 0;
      int potentialTheft = 0;
      Duration totalDuration = Duration.zero;

      // Her sayım kaydı için verileri topla
      for (final record in records) {
        totalProducts += record.productCount;
        stockIssueCount += record.stockIssueCount;
        potentialTheft += record.potentialTheft;

        // Süre verilerini işle
        String durationStr = record.countDuration;
        if (durationStr.contains('dakika')) {
          int minutes = int.parse(durationStr.split(' ')[0]);
          totalDuration += Duration(minutes: minutes);
        }
      }

      // Özet bilgileri oluştur
      final summary = InventorySummary(
        totalProducts: totalProducts,
        stockIssueCount: stockIssueCount,
        potentialTheft: potentialTheft,
        countDuration: totalDuration,
      );

      // Envanter günü oluştur
      final inventoryDay = InventoryDay(
        day: day,
        totalCounts: records.length,
        records: records,
        summary: summary,
        date: DateTime(_selectedMonth.year, _selectedMonth.month, day),
      );

      days.add(inventoryDay);
    }

    // Günlere göre sırala
    days.sort((a, b) => a.day.compareTo(b.day));

    setState(() {
      _inventoryDays = days;
    });
  }

  // Gün seçimi yapıldığında çağrılacak metod
  void _onDaySelected(int day) {
    setState(() {
      _selectedDay = day;
      // Seçili günün kayıtlarını güncelle
      _updateSelectedDayProducts();
    });
    _scrollToSelectedDay(day);
  }

  // Seçili günü yatay listede ortala
  void _scrollToSelectedDay(int day) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Her gün kutusu yaklaşık 76px (width: 72 + margin: 2*2)
      const double itemWidth = 76;
      final double screenWidth = MediaQuery.of(context).size.width;
      final double offset =
          (day - 1) * itemWidth - (screenWidth / 2 - itemWidth / 2);
      _daysScrollController.animateTo(
        offset.clamp(0, _daysScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  // Seçili güne ait ürünleri güncelle
  void _updateSelectedDayProducts() {
    if (_selectedDay == null) return;

    final selectedRecords = _daysWithCounts[_selectedDay] ?? [];
    _mockProducts.clear();

    // Tüm kayıtları CompletedProduct'a dönüştür
    for (var record in selectedRecords) {
      _mockProducts.add(
        CompletedProduct(
          name: 'Sayım #${record.id}',
          count: record.productCount,
          category: record.category,
          status: _getRecordStatus(record),
          completedAt: record.countDate,
        ),
      );
    }
    setState(() {}); // UI'ı güncelle
  }

  String _getRecordStatus(InventoryRecord record) {
    if (record.stockIssueCount > 0) {
      return '${record.stockIssueCount} Sorun';
    }
    if (record.potentialTheft > 0) {
      return 'Kayıp Şüphesi';
    }
    return 'Tamamlandı';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == today.year && _selectedMonth.month == today.month;
    final lastSelectableDay = isCurrentMonth ? today.day : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Geçmiş Sayımlar',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Ay seçici ve özet
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.event_note, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      // İçinde bulunulan ayı Türkçe ve büyük harfle yaz
                      DateFormat('MMMM', 'tr_TR').format(_selectedMonth).toUpperCase(),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.calendar_today,
                    color: colorScheme.primary,
                  ),
                  onPressed: () {
                    // Ay seçici dialog
                  },
                  tooltip: "Ay Seç",
                ),
              ],
            ),
          ),

          // Günler listesi tasarımı
          Container(
            height: 110,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              controller: _daysScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
                final isSelected = _selectedDay == day;
                final hasRecords = _daysWithCounts.containsKey(day);
                final isFuture = day > lastSelectableDay;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isFuture
                          ? null
                          : () => _onDaySelected(day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 72,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected && !isFuture
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.tertiary.withOpacity(0.85),
                                  ],
                                )
                              : null,
                          color: isFuture
                              ? colorScheme.surfaceContainer.withOpacity(0.3)
                              : isSelected
                                  ? null
                                  : (hasRecords
                                      ? colorScheme.surfaceContainer
                                      : Colors.transparent),
                          borderRadius: BorderRadius.circular(16),
                          border: !isSelected
                              ? Border.all(
                                  color: hasRecords && !isFuture
                                      ? colorScheme.primary.withOpacity(0.18)
                                      : Colors.transparent,
                                  width: 1.5,
                                )
                              : null,
                          boxShadow: isSelected && !isFuture
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.13),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Opacity(
                          opacity: isFuture ? 0.45 : 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E', 'tr_TR').format(date).toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: isSelected && !isFuture
                                      ? colorScheme.onPrimary
                                      : isFuture
                                          ? colorScheme.outline.withOpacity(0.5)
                                          : colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                day.toString(),
                                style: textTheme.headlineSmall?.copyWith(
                                  color: isSelected && !isFuture
                                      ? colorScheme.onPrimary
                                      : isFuture
                                          ? colorScheme.outline.withOpacity(0.7)
                                          : colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (hasRecords && !isFuture)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.onPrimary.withOpacity(0.18)
                                        : colorScheme.primary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_daysWithCounts[day]?.length ?? 0}',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Seçili güne ait kayıtlar
          Expanded(
            child: _isLoading
                ? _buildLoadingView()
                : _inventoryDays.isEmpty
                    ? _buildEmptyView()
                    : _buildSelectedDayRecords(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.blue.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bu ay için planlanmış site etkinliği bulunamadı',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yenile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(InventorySummary summary) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              icon: Icons.inventory_2,
              value: summary.totalProducts.toString(),
              label: 'Ürün',
              color: colorScheme.primary,
            ),
            _buildSummaryItem(
              icon: Icons.warning,
              value: summary.stockIssueCount.toString(),
              label: 'Sorun',
              color: Colors.orange,
            ),
            _buildSummaryItem(
              icon: Icons.timer,
              value: '${summary.countDuration.inMinutes}dk',
              label: 'Süre',
              color: colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: (color ?? colorScheme.primary).withOpacity(0.13),
          child: Icon(icon, color: color ?? colorScheme.primary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayRecords() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = _inventoryDays.firstWhere(
      (d) => d.day == _selectedDay,
      orElse: () => _createEmptyInventoryDay(),
    );

    return Column(
      children: [
        // Özet kartı
        _buildSummaryCard(selected.summary),

        // Ürün listesi başlığı
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Günlük Sayımlar',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selected.totalCounts} Kayıt',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sayım listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: selected.records.length,
            itemBuilder: (context, index) {
              final record = selected.records[index];
              final userId = record.countedBy ?? '';
              final userInfo = _userInfos[userId] ?? {};
              final name = userInfo['name'] ?? userId;
              final role = userInfo['role'] ?? '';
              final sorun = record.stockIssueCount;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colorScheme.primary.withOpacity(0.07)),
                ),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AuthProvider.getDisplayRole(role),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  trailing: sorun > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$sorun Sorun',
                            style: textTheme.labelMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Sorun Yok',
                            style: textTheme.labelMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                  onTap: () => _showCountedProductsBottomSheet(record),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Sorun')) return Colors.orange;
    if (status.contains('Kayıp')) return Colors.red;
    return Colors.green;
  }

  void _showCountedProductsBottomSheet(InventoryRecord record) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Örnek/mock ürün listesi (gerçek uygulamada record'dan gelir)
    final List<CountedProduct> products = [
      CountedProduct(
        name: "Süt 1L",
        code: "UR001",
        category: "Gıda",
        countedAmount: 12,
        salesAmount: 10,
        stockStatus: 1,
      ),
      CountedProduct(
        name: "Ekmek",
        code: "UR002",
        category: "Gıda",
        countedAmount: 8,
        salesAmount: 8,
        stockStatus: 0,
      ),
      CountedProduct(
        name: "Deterjan",
        code: "UR003",
        category: "Temizlik",
        countedAmount: 5,
        salesAmount: 6,
        stockStatus: -1,
      ),
    ];

    // Süreyi göster (ör: "34 dakika")
    String sure = record.countDuration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Text(
                record.countedBy ?? '-',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              if ((record.countedBy ?? '').contains('Ahmet Şahin'))
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Mağaza Sorumlusu',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              Text(
                'Sayım Süresi: $sure',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ürünler',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${products.length} adet',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => Divider(
                    color: colorScheme.outline.withOpacity(0.10),
                    height: 1,
                  ),
                  itemBuilder: (context, i) {
                    final p = products[i];
                    Color stockColor;
                    String stockText;
                    if (p.stockStatus == 0) {
                      stockColor = Colors.grey;
                      stockText = "Stok: 0";
                    } else if (p.stockStatus > 0) {
                      stockColor = Colors.green;
                      stockText = "Stok: +${p.stockStatus}";
                    } else {
                      stockColor = Colors.red;
                      stockText = "Stok: ${p.stockStatus}";
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      "Kod: ${p.code}",
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      p.category,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Sayım: ${p.countedAmount} adet",
                                  style: textTheme.bodyMedium,
                                ),
                                Text(
                                  "Satış: ${p.salesAmount} adet",
                                  style: textTheme.bodyMedium,
                                ),
                                Text(
                                  stockText,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: stockColor,
                                    fontWeight: FontWeight.bold,
                                  ),
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
        ),
      ));
  }

  InventoryDay _createEmptyInventoryDay() {
    return InventoryDay(
      day: DateTime.now().day,
      totalCounts: 0,
      records: [],
      summary: InventorySummary(
        totalProducts: 0,
        stockIssueCount: 0,
        potentialTheft: 0,
        countDuration: Duration.zero,
      ),
      date: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _daysScrollController.dispose();
    super.dispose();
  }
}
