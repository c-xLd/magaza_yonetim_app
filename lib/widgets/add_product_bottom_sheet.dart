import 'package:flutter/material.dart';
import '../models/expiry_product.dart';
import '../models/product_category.dart';
import '../services/expiry_product_service.dart';

class AddProductBottomSheet extends StatefulWidget {
  final VoidCallback? onProductAdded;
  final String? initialBarcode;

  const AddProductBottomSheet({super.key, this.onProductAdded, this.initialBarcode});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onProductAdded,
    String? initialBarcode,
  }) async {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 420),
      ),
      builder: (BuildContext context) {
        return AddProductBottomSheet(
          onProductAdded: onProductAdded,
          initialBarcode: initialBarcode,
        );
      },
    );
  }

  @override
  State<AddProductBottomSheet> createState() => _AddProductBottomSheetState();
}

class _AddProductBottomSheetState extends State<AddProductBottomSheet> {
  final ExpiryProductService _productService = ExpiryProductService();
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));

  void _processCode(String code) {
    if (code.isEmpty) return;
    if (code.length == 8 && RegExp(r'^\d{8}$').hasMatch(code)) {
      setState(() {
        _productCodeController.text = code;
        final category = ProductCategory.fromCode(code);
        if (category != null) {
          _categoryController.text = category.name;
        }
        _barcodeController.text = '';
      });
    } else if (code.length > 8 && RegExp(r'^\d+$').hasMatch(code)) {
      final productCode = ProductCategory.extractProductCodeFromBarcode(code);
      setState(() {
        _barcodeController.text = code;
        if (productCode != null) {
          _productCodeController.text = productCode;
          final category = ProductCategory.fromCode(productCode);
          if (category != null) {
            _categoryController.text = category.name;
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialBarcode != null) {
      _barcodeController.text = widget.initialBarcode!;
      _processCode(widget.initialBarcode!);
    }
    _quantityController.text = '1';
    _expiryDateController.text = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    void showCustomSnackBar(String message) {
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).size.height * 0.10,
          left: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      overlay.insert(overlayEntry);
      Future.delayed(const Duration(seconds: 2), () {
        overlayEntry.remove();
      });
    }

    if (_nameController.text.isEmpty) {
      showCustomSnackBar('Ürün adı boş olamaz!');
      return false;
    }
    if (_barcodeController.text.isEmpty) {
      showCustomSnackBar('Barkod veya Ürün Kodu boş olamaz!');
      return false;
    }
    if (_categoryController.text.isEmpty) {
      showCustomSnackBar('Kategori boş olamaz!');
      return false;
    }
    if (_quantityController.text.isEmpty) {
      showCustomSnackBar('Adet boş olamaz!');
      return false;
    }
    if (_expiryDateController.text.isEmpty) {
      showCustomSnackBar('Son Kullanma Tarihi boş olamaz!');
      return false;
    }
    try {
      int.parse(_quantityController.text);
    } catch (e) {
      showCustomSnackBar('Lütfen geçerli bir adet sayısı girin');
      return false;
    }
    return true;
  }

  Future<void> _addProduct() async {
    if (!_validateForm()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      int quantity = int.parse(_quantityController.text);
      final newProduct = ExpiryProduct(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        code: '', // Eklenen: zorunlu kod parametresi
        barcode: _barcodeController.text,
        category: _categoryController.text,
        location: null,
        quantity: quantity,
        expiryDate: _selectedDate,
        imageUrl: '',
        storeId: 'store1',
        batchNumber: 'B${DateTime.now().millisecondsSinceEpoch % 10000}',
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        addedBy: 'user1',
        addedAt: DateTime.now(),
        isActive: true,
      );
      await _productService.addProduct(newProduct);
      widget.onProductAdded?.call();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün başarıyla eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    double bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutExpo,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.93,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(36),
              topRight: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.13),
                blurRadius: 36,
                offset: const Offset(0, -16),
              ),
            ],
          ),
          child: Column(
            children: [
              // Üstte ikon ve başlık
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 4),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      radius: 22,
                      child: Icon(Icons.add_circle_rounded, color: colorScheme.onPrimary, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Yeni Ürün Ekle',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ürün bilgilerini doldurun.",
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Ana içerik
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Form(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Bilgi başlığı
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: colorScheme.primary, size: 26),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Ürün Bilgileri",
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              // Ürün Adı
                              TextFormField(
                                controller: _nameController,
                                style: textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  labelText: "Ürün Adı *",
                                  prefixIcon: Icon(Icons.shopping_bag_outlined, color: colorScheme.primary),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              // Barkod veya Ürün Kodu alanı
                              TextFormField(
                                controller: _barcodeController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: 'Barkod veya Ürün Kodu *',
                                  prefixIcon: Icon(Icons.qr_code, color: colorScheme.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.sync, color: colorScheme.primary),
                                    onPressed: () {
                                      if (_barcodeController.text.isNotEmpty) {
                                        _processCode(_barcodeController.text);
                                      }
                                    },
                                    tooltip: 'Otomatik tespit et',
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.length >= 8) {
                                    _processCode(value);
                                  }
                                },
                              ),
                              const SizedBox(height: 22),
                              // Ürün kodu (sadece okunur)
                              TextFormField(
                                controller: _productCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Ürün Kodu',
                                  prefixIcon: Icon(Icons.code, color: colorScheme.primary),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                ),
                                readOnly: true,
                              ),
                              const SizedBox(height: 22),
                              // Kategori
                              TextFormField(
                                controller: _categoryController,
                                style: textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  labelText: "Kategori *",
                                  prefixIcon: Icon(Icons.category_outlined, color: colorScheme.primary),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              // Son Kullanma Tarihi
                              TextField(
                                controller: _expiryDateController,
                                style: textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  labelText: "Son Kullanma Tarihi *",
                                  prefixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: colorScheme.brightness == Brightness.dark
                                              ? colorScheme.copyWith(surface: colorScheme.surface)
                                              : colorScheme,
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDate = picked;
                                      _expiryDateController.text =
                                          "${picked.day}/${picked.month}/${picked.year}";
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 22),
                              // Adet
                              TextField(
                                controller: _quantityController,
                                style: textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  labelText: "Adet *",
                                  prefixIcon: Icon(Icons.numbers, color: colorScheme.primary),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 22),
                              // Notlar
                              TextField(
                                controller: _notesController,
                                style: textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  labelText: "Notlar",
                                  prefixIcon: Icon(Icons.notes_outlined, color: colorScheme.primary),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 36),
                              // Ekle ve İptal butonları
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colorScheme.primary,
                                        side: BorderSide(color: colorScheme.primary),
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: const Text('İptal'),
                                    ),
                                  ),
                                  const SizedBox(width: 22),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _isLoading ? null : _addProduct,
                                      icon: Icon(Icons.check_circle, color: colorScheme.onPrimary),
                                      label: const Text(
                                        'Ürün Ekle',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 36),
                              // Alt bilgi
                              Center(
                                child: Text(
                                  "Zorunlu alanlar * ile belirtilmiştir.",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
