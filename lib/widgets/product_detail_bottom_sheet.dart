import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expiry_product.dart';

class ProductDetailBottomSheet {
  // A101 ürün görseli URL'sini tahmin et (örnek: https://cdn.a101.com.tr/kapida0/urun/{productCode}/{productCode}-1_600x600.jpg)
  // Burada barkodun ürün kodu ile aynı olduğu varsayılıyor, gerçek projede ürün kodu ile barkod eşleştirmesi gerekir.
  static String getA101ImageUrl(String barcode) {
    // Eğer barkod 8 haneli ve sadece rakamlardan oluşuyorsa ürün kodu olarak kullan
    final isLikelyProductCode = RegExp(r'^\d{8}$').hasMatch(barcode);
    if (isLikelyProductCode) {
      return 'https://cdn.a101.com.tr/kapida0/urun/$barcode/$barcode-1_600x600.jpg';
    }
    // Değilse eski fallback URL (çoğu zaman çalışmaz)
    return 'https://www.a101.com.tr/urun-resimleri/$barcode.jpg';
  }

  // DuckDuckGo görsel arama ile ürün adına göre ilk görseli bulur
  static Future<String?> fetchImageByProductName(String productName) async {
    try {
      final query = Uri.encodeComponent(productName);
      final url = 'https://duckduckgo.com/?q=$query&iax=images&ia=images';
      // DuckDuckGo görsel arama için token almak gerekiyor
      final tokenRes = await http.get(Uri.parse(url));
      final tokenMatch = RegExp(r'vqd=([\d-]+)\&').firstMatch(tokenRes.body);
      if (tokenMatch == null) return null;
      final vqd = tokenMatch.group(1);
      final apiUrl = 'https://duckduckgo.com/i.js?l=tr-tr&o=json&q=$query&vqd=$vqd';
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['image'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> show(
    BuildContext context, {
    required ExpiryProduct product,
    required VoidCallback onProductUpdated,
    required VoidCallback onProductDeleted,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd.MM.yyyy');

    String? imageUrl;
    bool loading = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<String?>(
          future: fetchImageByProductName(product.name),
          builder: (context, snapshot) {
            imageUrl = snapshot.data;
            loading = snapshot.connectionState == ConnectionState.waiting;
            return Padding(
              padding: MediaQuery.of(ctx).viewInsets,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
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
                        // Ürün görseli veya ikon
                        SizedBox(
                          height: 90,
                          width: 90,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: loading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : (imageUrl != null
                                    ? Image.network(
                                        imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: colorScheme.surfaceContainerHighest,
                                          child: Icon(
                                            Icons.inventory_2_rounded,
                                            size: 54,
                                            color: product.isExpired
                                                ? colorScheme.error
                                                : product.isCritical
                                                    ? colorScheme.secondary
                                                    : colorScheme.primary,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.inventory_2_rounded,
                                          size: 54,
                                          color: product.isExpired
                                              ? colorScheme.error
                                              : product.isCritical
                                                  ? colorScheme.secondary
                                                  : colorScheme.primary,
                                        ),
                                      )),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          product.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Kategori: ${product.category}",
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Bilgi alanları
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            Chip(
                              avatar: Icon(Icons.qr_code, size: 18, color: colorScheme.primary),
                              label: Text(product.barcode, style: textTheme.labelLarge),
                              backgroundColor: colorScheme.primaryContainer,
                              labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                            ),
                            Chip(
                              avatar: Icon(Icons.shopping_basket_outlined, size: 18, color: colorScheme.secondary),
                              label: Text('${product.quantity} adet', style: textTheme.labelLarge),
                              backgroundColor: colorScheme.secondaryContainer,
                              labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.secondary),
                            ),
                            Chip(
                              avatar: Icon(Icons.schedule, size: 18, color: colorScheme.primary),
                              label: Text(
                                product.isExpired
                                    ? 'Süresi Geçmiş'
                                    : product.isCritical
                                        ? 'Kritik'
                                        : '${product.daysUntilExpiry} gün',
                                style: textTheme.labelLarge,
                              ),
                              backgroundColor: product.isExpired
                                  ? colorScheme.errorContainer
                                  : product.isCritical
                                      ? colorScheme.secondaryContainer
                                      : colorScheme.primaryContainer,
                              labelStyle: textTheme.labelLarge?.copyWith(
                                color: product.isExpired
                                    ? colorScheme.error
                                    : product.isCritical
                                        ? colorScheme.secondary
                                        : colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Divider(
                          color: colorScheme.outlineVariant.withOpacity(0.18),
                          thickness: 1,
                        ),
                        const SizedBox(height: 10),
                        // Tarih ve ekleyen
                        Row(
                          children: [
                            Icon(Icons.calendar_month, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Son Kul. Tarihi: ',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              dateFormat.format(product.expiryDate ?? DateTime(0)),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, color: colorScheme.secondary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Ekleyen: ',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              product.addedBy ?? "-",
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: colorScheme.outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Eklenme: ',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              dateFormat.format(product.addedAt),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Aksiyon butonları
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  onProductDeleted();
                                },
                                icon: Icon(Icons.delete, color: colorScheme.error),
                                label: const Text("Sil"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                  side: BorderSide(color: colorScheme.error),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  // Ürün güncelleme için bir ekran açılabilir
                                  // Burada örnek olarak sadece güncellendi mesajı veriyoruz
                                  Navigator.pop(ctx);
                                  onProductUpdated();
                                },
                                icon: Icon(Icons.edit, color: colorScheme.onPrimary),
                                label: const Text("Düzenle"),
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
      },
    );
  }
}
