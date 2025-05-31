import 'package:flutter/material.dart';

/// Kullanıcı ayarları için sliding panel içeriği
class UserSettingsPanel extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback onProfileEdit;
  final VoidCallback onAdminSettings;
  final VoidCallback onLogout;
  final String userName;
  final String userRole;
  final bool isAdmin;

  const UserSettingsPanel({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onProfileEdit,
    required this.onAdminSettings,
    required this.onLogout,
    required this.userName,
    required this.userRole,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.person, color: colorScheme.onPrimary, size: 32),
            ),
            title: Text(userName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(userRole, style: textTheme.bodySmall),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: colorScheme.primary),
              onPressed: onProfileEdit,
              tooltip: 'Profili Düzenle',
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colorScheme.outlineVariant),
          ListTile(
            leading: Icon(Icons.settings, color: colorScheme.secondary),
            title: Text('Kullanıcı Ayarları', style: textTheme.bodyLarge),
            onTap: () {},
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          if (isAdmin == true)
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: colorScheme.tertiary),
              title: Text('Yönetici Ayarları', style: textTheme.bodyLarge),
              onTap: onAdminSettings,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          Divider(height: 24, color: colorScheme.outlineVariant),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text('Çıkış Yap', style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
            onTap: onLogout,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ],
      ),
    );
  }
}

/// Ürün detayları için bottom sheet içeriği (Material 3 Expressive)
class ProductDetailsPanel extends StatelessWidget {
  final String productName;
  final String productCode;
  final int stock;
  final String? imageUrl;
  final String? category;
  final String? description;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductDetailsPanel({
    super.key,
    required this.productName,
    required this.productCode,
    required this.stock,
    this.imageUrl,
    this.category,
    this.description,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    Color stockColor = stock > 10
        ? colorScheme.secondary
        : stock > 0
            ? colorScheme.tertiary
            : colorScheme.error;
    Color stockBg = stock > 10
        ? colorScheme.secondaryContainer
        : stock > 0
            ? colorScheme.tertiaryContainer
            : colorScheme.errorContainer;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(imageUrl!, fit: BoxFit.cover),
                      )
                    : Icon(Icons.inventory_2, color: colorScheme.primary, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Kod: $productCode', style: textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text('Stok: $stock', style: textTheme.labelLarge?.copyWith(color: stockColor)),
                      backgroundColor: stockBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (category != null) ...[
            const SizedBox(height: 16),
            _buildDetailSection(context, title: 'Kategori', value: category!, icon: Icons.category),
          ],
          if (description != null) ...[
            const SizedBox(height: 16),
            _buildDetailSection(context, title: 'Açıklama', value: description!, icon: Icons.description, isMultiLine: true),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Sil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    bool isMultiLine = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodySmall?.copyWith(
                  color: textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodySmall,
                maxLines: isMultiLine ? 5 : 1,
                overflow:
                    isMultiLine ? TextOverflow.ellipsis : TextOverflow.clip,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
