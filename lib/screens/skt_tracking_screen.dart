import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart'; // Vibration için
import '../models/expiry_product.dart';
import '../services/expiry_product_service.dart';
import '../widgets/product_detail_bottom_sheet.dart';
import '../widgets/add_product_bottom_sheet.dart';
import '../utils/barcode_scanner_helper.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SktTrackingScreen extends StatefulWidget {
  const SktTrackingScreen({super.key});

  @override
  State<SktTrackingScreen> createState() => _SktTrackingScreenState();
}

class _SktTrackingScreenState extends State<SktTrackingScreen> {
  // Servis
  final ExpiryProductService _productService = ExpiryProductService();

  // Controller ve durum değişkenleri
  final ScrollController _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  // Filtre durumları
  String _selectedFilter = "Tümü";
  String _selectedCategory = "Tümü";
  String _searchQuery = "";
  String _sortBy = "SKT (Yakın)";
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isScanning = false; // Barkod tarama durumu
  final bool _isSelectionMode = false;

  // Seçili ürünler
  final Set<String> _selectedProductIds = <String>{};
  final Map<String, String> _removedFromShelf = {};

  // Filtre seçenekleri
  final List<String> _filterOptions = [
    "Tümü",
    "Kritik (7 gün)",
    "Yaklaşanlar (30 gün)",
    "Geçmiş"
  ];

  // Sıralama seçenekleri
  final List<String> _sortOptions = [
    "SKT (Yakın)",
    "SKT (Uzak)",
    "Ad (A-Z)",
    "Ad (Z-A)",
    "Kategori",
    "Miktar (Az-Çok)",
    "Miktar (Çok-Az)",
    "Eklenme (Yeni-Eski)",
    "Eklenme (Eski-Yeni)",
  ];

  // Ürünler
  final List<ExpiryProduct> _products = [];
  List<ExpiryProduct> _filteredProducts = [];

  // Kategorileri ürünlerden dinamik oluştur
  List<String> get _categories {
    final Set<String> categories = {"Tümü"};

    for (final product in _products) {
      categories.add(product.category);
    }

    return categories.toList();
  }

  // Ürün listesini filtreleme ve sıralama
  void _filterProducts() {
    _filteredProducts = _computeFilteredProducts(_products);
  }

  // _computeFilteredProducts metodunda sıralama işlemini düzeltiyoruz.
  List<ExpiryProduct> _computeFilteredProducts(List<ExpiryProduct> products) {
    List<ExpiryProduct> categoryFiltered = _selectedCategory == "Tümü"
        ? products
        : products.where((p) => p.category == _selectedCategory).toList();

    if (_searchQuery.isNotEmpty) {
      categoryFiltered = categoryFiltered.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.location != null &&
              p.location!.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();
    }

    if (_selectedFilter == "Tümü") {
      categoryFiltered = categoryFiltered;
    } else if (_selectedFilter == "Kritik (7 gün)") {
      categoryFiltered = categoryFiltered.where((p) =>
          p.expiryDate.isBefore(DateTime.now().add(const Duration(days: 7))) &&
          !p.isExpired).toList();
    } else if (_selectedFilter == "Yaklaşanlar (30 gün)") {
      categoryFiltered = categoryFiltered.where((p) =>
          p.expiryDate.isAfter(DateTime.now()) &&
          p.expiryDate.isBefore(DateTime.now().add(const Duration(days: 30))) &&
          !p.isExpired).toList();
    } else if (_selectedFilter == "Geçmiş") {
      categoryFiltered = categoryFiltered.where((p) => p.isExpired).toList();
    }

    // Sıralama işlemi
    switch (_sortBy) {
      case "SKT (Yakın)":
        categoryFiltered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case "SKT (Uzak)":
        categoryFiltered.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
        break;
      case "Ad (A-Z)":
        categoryFiltered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case "Ad (Z-A)":
        categoryFiltered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case "Kategori":
        categoryFiltered.sort((a, b) => a.category.toLowerCase().compareTo(b.category.toLowerCase()));
        break;
      case "Miktar (Az-Çok)":
        categoryFiltered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case "Miktar (Çok-Az)":
        categoryFiltered.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case "Eklenme (Yeni-Eski)":
        categoryFiltered.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case "Eklenme (Eski-Yeni)":
        categoryFiltered.sort((a, b) => a.addedAt.compareTo(b.addedAt));
        break;
      default:
        categoryFiltered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
    }

    return categoryFiltered;
  }

  @override
  void initState() {
    super.initState();
    // Firestore'dan ürünleri dinamik olarak çekmek için stream kullanılacak
    // _loadProducts() ve local _products kaldırıldı
    _isLoading = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Barkod tarama fonksiyonu
  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BarcodeScannerPage(
          onBarcodeScanned: (barcode) async {
            Navigator.pop(context);
            await _processBarcode(barcode);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Barkod tarama özelliklerini içeren metodlar
  // Barkod tarama menüsünü göster
  Future<void> _showBarcodeScanOptions() async {
    await BarcodeScannerHelper.showScanOptions(
      context,
      onCameraScan: _scanBarcodeWithCamera,
      onManualEntry: _showManualBarcodeDialog,
    );
  }

  // Kamera ile barkod tarama
  Future<void> _scanBarcodeWithCamera() async {
    if (!mounted) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final barcode = await BarcodeScannerHelper.scanBarcodeWithCamera(context);

      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });

      if (barcode != null) {
        await _processBarcode(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barkod tarama sırasında hata oluştu: $e')),
      );
    }
  }

  // Manuel barkod giriş dialog'unu göster
  Future<void> _showManualBarcodeDialog() async {
    final barcode = await BarcodeScannerHelper.showManualBarcodeDialog(context);

    if (barcode != null && barcode.isNotEmpty) {
      await _processBarcode(barcode);
    }
  }

  // Barkodu işle
  Future<void> _processBarcode(String barcode) async {
    // Barkod verisini ayıkla
    final processedBarcode = _extractBarcode(barcode);

    // Barkoda göre ürünü ara
    final product = await _productService.findProductByBarcode(processedBarcode);

    if (!mounted) return;

    if (product != null) {
      // Ürün bulundu, detaylarını göster
      await ProductDetailBottomSheet.show(context, product: product,
          onProductUpdated: () {
        // _loadProducts();
      }, onProductDeleted: () {
        // _loadProducts();
        Navigator.pop(context);
      });
    } else {
      // Ürün bulunamadı, manuel kayıt seçeneği sun
      await BarcodeNotFoundDialog.show(
        context,
        barcode: processedBarcode,
        onProductAdded: () {
          // _loadProducts();
        },
      );
    }
  }

  // QR koddan yalnızca barkodu ayıklayan yardımcı metod
  String _extractBarcode(String qrData) {
    // QR kod verisini "-" ile ayır ve barkod kısmını al
    final parts = qrData.split('-');
    if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts[1].trim())) {
      return parts[1].trim(); // Barkod kısmını döndür
    }
    return qrData; // Eğer format uygun değilse tüm veriyi döndür
  }

  Future<void> _onBarcodeDetected(String barcode) async {
    // Barkod okunduğunda kısa titreşim ve animasyon
    HapticFeedback.mediumImpact();

    // Barkod verisini ayıkla
    final processedBarcode = _extractBarcode(barcode);

    await _processBarcode(processedBarcode);
  }

  // Belli bir barkod ile ürün ekleme dialogı
  // Not: Bu method şu anda kullanılmıyor ama gelecekte kullanılabilir
  // ignore: unused_element
  Future<void> _showAddProductBottomSheetWithBarcode(String barcode) async {
    await AddProductBottomSheet.show(
      context,
      initialBarcode: barcode,
      onProductAdded: () => {
        // _loadProducts();
      },
    );
  }

  // Yeni ürün ekleme bottom sheet'ini göster
  void _showAddProductBottomSheet() async {
    await AddProductBottomSheet.show(context, onProductAdded: () {
      // _loadProducts();
    });
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seçili Ürünleri Sil'),
        content: Text('${_selectedProductIds.length} ürünü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              // Silme işlemi
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Durum Değiştir'),
        content: Text('${_selectedProductIds.length} ürünün durumunu değiştirmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              // Durum değiştirme işlemi
              Navigator.pop(ctx);
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedProductIds.length == _filteredProducts.length) {
        _selectedProductIds.clear();
      } else {
        _selectedProductIds.clear();
        for (final product in _filteredProducts) {
          _selectedProductIds.add(product.id);
        }
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = "";
        _filterProducts();
      }
    });
  }

  // Sıralama işlemi için metodu güncelliyoruz.
  void _sortFilteredProducts() {
    _filteredProducts = _computeFilteredProducts(_filteredProducts);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const String currentUser = "Kullanıcı1"; // Giriş yapan kullanıcı adı (örnek)

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Skt Takip',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: colorScheme.secondaryContainer,
      ),
      body: StreamBuilder<List<ExpiryProduct>>(
        stream: _productService.productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final String? role = authProvider.role;
          final String? username = authProvider.username;

          List<ExpiryProduct> filteredByRole;
          if (role == 'admin' || role == 'manager') {
            filteredByRole = products;
          } else if (role == 'staff') {
            filteredByRole = products.where((p) => p.addedBy == username).toList();
          } else {
            filteredByRole = [];
          }

          final filteredProducts = _computeFilteredProducts(filteredByRole);
          return Column(
            children: [
              // Filtre ve arama alanı (Material 3 SearchBar ve IconButton)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBar(
                        controller: _searchController,
                        hintText: 'Ürün adı, barkod veya kategori ara',
                        elevation: WidgetStateProperty.all(0),
                        backgroundColor: WidgetStateProperty.all(colorScheme.surfaceContainerHighest),
                        leading: Icon(Icons.search, color: colorScheme.primary),
                        onChanged: (v) {
                          setState(() {
                            _searchQuery = v;
                            _filterProducts();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonal(
                      onPressed: _scanBarcode,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          const Text("Tara"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Kategori ve filtreler (Material 3 DropdownMenu ve FilterChip)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownMenu<String>(
                        initialSelection: _selectedCategory,
                        dropdownMenuEntries: _categories
                            .map((c) => DropdownMenuEntry(value: c, label: c))
                            .toList(),
                        onSelected: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                              _filterProducts();
                            });
                          }
                        },
                        label: const Text("Kategori"),
                        leadingIcon: Icon(Icons.category_outlined, color: colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownMenu<String>(
                        initialSelection: _selectedFilter,
                        dropdownMenuEntries: _filterOptions
                            .map((f) => DropdownMenuEntry(value: f, label: f))
                            .toList(),
                        onSelected: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFilter = newValue;
                              _filterProducts();
                            });
                          }
                        },
                        label: const Text("Filtre"),
                        leadingIcon: Icon(Icons.filter_list, color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              // Sıralama seçenekleri (Material 3 FilterChip)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sortOptions.map((option) {
                      final selected = _sortBy == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(option),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              _sortBy = option;
                              _sortFilteredProducts();
                            });
                          },
                          selectedColor: colorScheme.primaryContainer,
                          showCheckmark: false,
                          labelStyle: textTheme.labelLarge?.copyWith(
                            color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Ürün listesi
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 90, color: colorScheme.primary.withOpacity(0.18)),
                            const SizedBox(height: 24),
                            Text(
                              'Takipte ürün yok',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Yeni ürün eklemek için + butonunu kullanın',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];

                          // Raf kaldırıldıysa gösterme
                          if (_removedFromShelf.containsKey(product.id)) {
                            return const SizedBox.shrink();
                          }

                          Color cardColor = colorScheme.surface;
                          Color borderColor = colorScheme.outlineVariant;
                          Color? contentTextColor;
                          if (product.isExpired) {
                            cardColor = colorScheme.errorContainer;
                            borderColor = colorScheme.error;
                          } else if (product.isCritical) {
                            cardColor = colorScheme.secondaryContainer;
                            borderColor = colorScheme.secondary;
                          }

                          return Dismissible(
                            key: ValueKey(product.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              color: colorScheme.error,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(Icons.remove_circle, color: Colors.white, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Raftan Kaldır",
                                    style: textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onDismissed: (direction) async {
                              if (product.isExpired || product.isCritical) {
                                final bool? confirmDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Ürünü Sil'),
                                    content: Text(
                                      '${product.name} ürününü silmek istediğinizden emin misiniz?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmDelete == true) {
                                  try {
                                    // Veritabanından ürünü sil
                                    await _productService.deleteProduct(product.id);

                                    setState(() {
                                      _removedFromShelf[product.id] = currentUser;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "${product.name} raftan kaldırıldı ve silindi ($currentUser)",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: colorScheme.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Ürün silinirken hata oluştu: $e",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: colorScheme.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  // Silme işlemi iptal edildiğinde listeyi yeniden oluştur
                                  setState(() {});
                                }
                              } else {
                                // Ürün silinemez, kullanıcıya bilgi ver
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${product.name} raftan kaldırılamaz. Sadece günü gelmiş veya geçmiş ürünler kaldırılabilir.",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: colorScheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                // Listeyi yeniden oluştur
                                setState(() {});
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              color: cardColor,
                              elevation: 1,
                              surfaceTintColor: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: borderColor.withOpacity(0.7),
                                  width: product.isCritical ? 2.2 : 1.3,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () async {
                                  await ProductDetailBottomSheet.show(
                                    context,
                                    product: product,
                                    onProductUpdated: () {
                                      // _loadProducts();
                                    },
                                    onProductDeleted: () {
                                      // _loadProducts();
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Ürün resmi gösterimi
                                          if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                product.imageUrl!,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  Icons.broken_image,
                                                  color: colorScheme.onSurfaceVariant,
                                                  size: 50,
                                                ),
                                              ),
                                            )
                                          else
                                            Icon(
                                              Icons.image_not_supported,
                                              color: colorScheme.onSurfaceVariant,
                                              size: 50,
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: contentTextColor ??
                                                        (product.isCritical
                                                            ? colorScheme.onSecondaryContainer
                                                            : colorScheme.onSurface),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Kategori: ${product.category}',
                                                  style: textTheme.bodyMedium?.copyWith(
                                                    color: contentTextColor ??
                                                        (product.isCritical
                                                            ? colorScheme.onSecondaryContainer.withOpacity(0.8)
                                                            : colorScheme.onSurfaceVariant),
                                                  ),
                                                ),
                                                // Eğer raftan kaldırıldıysa kullanıcıyı göster
                                                if (_removedFromShelf.containsKey(product.id))
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text(
                                                      "Raftan kaldıran: ${_removedFromShelf[product.id]}",
                                                      style: textTheme.bodySmall?.copyWith(
                                                        color: colorScheme.error,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: product.isExpired
                                                  ? colorScheme.errorContainer
                                                  : product.isCritical
                                                      ? colorScheme.secondaryContainer
                                                      : colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(10),
                                              border: product.isCritical
                                                  ? Border.all(color: colorScheme.secondary, width: 1.5)
                                                  : null,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  product.isExpired
                                                      ? Icons.warning_amber_rounded
                                                      : product.isCritical
                                                          ? Icons.error_outline
                                                          : Icons.schedule,
                                                  color: product.isExpired
                                                      ? colorScheme.error
                                                      : product.isCritical
                                                          ? colorScheme.secondary
                                                          : colorScheme.primary,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  product.isExpired
                                                      ? 'Süresi Geçmiş'
                                                      : product.isCritical
                                                          ? 'Kritik'
                                                          : '${product.daysUntilExpiry} gün',
                                                  style: textTheme.labelMedium?.copyWith(
                                                    color: product.isExpired
                                                        ? colorScheme.error
                                                        : product.isCritical
                                                            ? colorScheme.onSecondaryContainer
                                                            : colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Divider(
                                        height: 1,
                                        color: product.isCritical
                                            ? colorScheme.secondary.withOpacity(0.18)
                                            : colorScheme.outlineVariant.withOpacity(0.18),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.qr_code, size: 15, color: product.isCritical ? colorScheme.secondary : colorScheme.primary.withOpacity(0.7)),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        product.barcode,
                                                        style: textTheme.bodySmall?.copyWith(
                                                          color: contentTextColor ??
                                                              (product.isCritical
                                                                  ? colorScheme.onSecondaryContainer
                                                                  : colorScheme.onSurfaceVariant),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(Icons.shopping_basket_outlined, size: 15, color: product.isCritical ? colorScheme.secondary : colorScheme.primary.withOpacity(0.7)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${product.quantity} adet',
                                                      style: textTheme.bodySmall?.copyWith(
                                                        color: contentTextColor ??
                                                            (product.isCritical
                                                                ? colorScheme.onSecondaryContainer
                                                                : colorScheme.onSurfaceVariant),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  DateFormat('dd.MM.yyyy').format(product.expiryDate),
                                                  style: textTheme.bodyLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: contentTextColor ??
                                                        (product.isCritical
                                                            ? colorScheme.onSecondaryContainer
                                                            : colorScheme.primary),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Son Kul. Tarihi',
                                                  style: textTheme.bodySmall?.copyWith(
                                                    color: contentTextColor ??
                                                        (product.isCritical
                                                            ? colorScheme.onSecondaryContainer.withOpacity(0.8)
                                                            : colorScheme.onSurfaceVariant),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanBarcode, // Artık barkod tarama sayfasını açacak
        icon: Icon(Icons.add, color: colorScheme.onPrimary),
        label: const Text('Ürün Ekle'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// --- Barkod Tarama Sayfası Widget ---
class _BarcodeScannerPage extends StatefulWidget {
  final Future<void> Function(String barcode) onBarcodeScanned;
  const _BarcodeScannerPage({required this.onBarcodeScanned});

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  bool _flashOn = false;
  bool _autoFlashEnabled = true;
  final TextEditingController _searchController = TextEditingController();
  final MobileScannerController _cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.code128, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE, BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates, // Daha hassas ve hızlı okuma için
  );

  @override
  void initState() {
    super.initState();
    // İlk açılışta flaşı aç (veya ortam karanlıksa açmak için burada bir kontrol eklenebilir)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableAutoFlash();
    });
  }

  void _enableAutoFlash() async {
    // Otomatik flaş: ilk açılışta aç, kullanıcı kapatırsa tekrar açılmaz
    if (_autoFlashEnabled && !_flashOn) {
      await _cameraController.toggleTorch();
      setState(() {
        _flashOn = true;
      });
    }
  }

  void _toggleFlash() async {
    // Torch durumunu doğrudan controller'dan al ve güncelle
    final hasTorch = _cameraController.hasTorch; // düzeltildi: fonksiyon değil, getter
    if (!hasTorch) return;
    final torchState = _cameraController.torchState;
    if (torchState == TorchState.on) {
      await _cameraController.toggleTorch(); // düzeltildi: setTorchState yerine toggleTorch
      setState(() {
        _flashOn = false;
        _autoFlashEnabled = false;
      });
    } else {
      await _cameraController.toggleTorch(); // düzeltildi: setTorchState yerine toggleTorch
      setState(() {
        _flashOn = true;
        _autoFlashEnabled = false;
      });
    }
  }

  void _onManualSearch() {
    final code = _searchController.text.trim();
    if (code.isNotEmpty) {
      widget.onBarcodeScanned(code);
    }
  }

  Future<void> _onBarcodeDetected(String barcode) async {
    // Barkod okunduğunda kısa titreşim ve animasyon
    HapticFeedback.mediumImpact();
    // Eğer QR koddan gelen veri "1751-869188060918" gibi ise, sadece barkod kısmını al
    String processedBarcode = barcode;
    if (barcode.contains('-')) {
      final parts = barcode.split('-');
      if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.last)) {
        processedBarcode = parts.last;
      }
    }
    await widget.onBarcodeScanned(processedBarcode);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: colorScheme.surface.withOpacity(0.85),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Barkod Tara",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
          tooltip: "Kapat",
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: colorScheme.primary,
            ),
            onPressed: _toggleFlash,
            tooltip: "Fener",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Kamera preview Card - Expanded ile tüm alanı kaplar
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Card(
                  elevation: 3,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _cameraController,
                        fit: BoxFit.cover,
                        onDetect: (capture) {
                          // Birden fazla barkod olabilir, ilk geçerli barkodu bul
                          final barcode = capture.barcodes
                              .map((b) => b.rawValue)
                              .firstWhere((val) => val != null && val.isNotEmpty, orElse: () => null);
                          if (barcode != null && barcode.isNotEmpty) {
                            _onBarcodeDetected(barcode);
                          }
                        },
                        errorBuilder: (context, error, child) {
                          return Center(
                            child: Text(
                              'Kamera başlatılamadı: $error',
                              style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                            ),
                          );
                        },
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _BarcodeCornersPainter(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Alt panel: M3 Card ile arama ve bilgi
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Card(
                elevation: 2,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Arama kutusu
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Ürün Kodu veya Barkodu Ara",
                          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() => _searchController.clear()),
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _onManualSearch(),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      // Bilgi kutusu
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Kameradan veya manuel arama ile ürün ekleyebilirsiniz.",
                              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Listeye ekle butonu
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _searchController.text.isNotEmpty ? _onManualSearch : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary.withOpacity(
                                _searchController.text.isNotEmpty ? 1 : 0.18),
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("Ürünü Ekle"),
                        ),
                      ),
                    ],
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

// --- Köşe işaretleri için CustomPainter ---
class _BarcodeCornersPainter extends CustomPainter {
  final Color color;
  _BarcodeCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const double length = 36;
    const double margin = 48;

    // Sol üst
    canvas.drawLine(const Offset(margin, margin), const Offset(margin + length, margin), paint);
    canvas.drawLine(const Offset(margin, margin), const Offset(margin, margin + length), paint);

    // Sağ üst
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin - length, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + length), paint);

    // Sol alt
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + length, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin, size.height - margin - length), paint);

    // Sağ alt
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin - length, size.height - margin), paint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- BarcodeNotFoundDialog.show fonksiyonunun yeni tasarımı ---
class BarcodeNotFoundDialog {
  static Future<void> show(
    BuildContext context, {
    required String barcode,
    required VoidCallback onProductAdded,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 8,
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 54, color: colorScheme.primary),
                    const SizedBox(height: 18),
                    Text(
                      "Barkod Bulunamadı",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Sistemde bu barkoda ait bir ürün bulunamadı.",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            barcode,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurfaceVariant,
                              side: BorderSide(color: colorScheme.outlineVariant),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Vazgeç"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              Future.microtask(() async {
                                await AddProductBottomSheet.show(
                                  context,
                                  initialBarcode: barcode,
                                  onProductAdded: onProductAdded,
                                );
                              });
                            },
                            icon: Icon(Icons.add, color: colorScheme.onPrimary),
                            label: const Text("Ürün Ekle"),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}