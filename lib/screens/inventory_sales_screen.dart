// lib/screens/inventory_sales_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class InventorySalesScreen extends StatefulWidget {
  const InventorySalesScreen({super.key});

  @override
  State<InventorySalesScreen> createState() => _InventorySalesScreenState();
}

class _InventorySalesScreenState extends State<InventorySalesScreen> {
  late final String userId;
  late final String userRole;
  List<String> unsoldDates = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      userId = auth.phoneNumber ?? "";
      userRole = auth.role ?? "";

      if (userRole == 'staff') {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu ekrana erişim yetkiniz yok.')),
        );
        return;
      }

      _loadUnsoldDays();
    });
  }

  Future<void> _loadUnsoldDays() async {
    final today = DateTime.now();
    final List<String> daysToCheck = List.generate(7, (i) {
      final date = today.subtract(Duration(days: i));
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    });

    List<String> result = [];

    for (var dateStr in daysToCheck) {
      final countDoc = await FirebaseFirestore.instance
          .collection('inventoryCounts')
          .doc(dateStr)
          .get();

      if (countDoc.exists) {
        final data = countDoc.data();
        if (data != null && data['userCounts'] != null) {
          final userCounts = data['userCounts'] as Map<String, dynamic>;
          bool anyMissing = false;
          userCounts.forEach((userId, userData) {
            if (userData is Map) {
              userData.forEach((role, products) {
                if (products is Map) {
                  products.forEach((productId, productData) {
                    if (productData is Map) {
                      if (!productData.containsKey('sales') || !productData.containsKey('difference')) {
                        anyMissing = true;
                      }
                    }
                  });
                }
              });
            }
          });
          if (anyMissing) {
            result.add(dateStr);
          }
        }
      }
    }

    setState(() {
      unsoldDates = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Satış Girişleri',
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.secondaryContainer,
        centerTitle: true,
      ),
      body: unsoldDates.isEmpty
          ? Center(
              child: Text('Tüm sayımlar için satış girilmiş.',
                  style: textTheme.bodyLarge),
            )
          : ListView.builder(
              itemCount: unsoldDates.length,
              itemBuilder: (context, index) {
                final date = unsoldDates[index];
                return ListTile(
                  leading: const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange),
                  title: const Text('Sayım var, satış eksik'),
                  subtitle: Text(date),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Satış kaydet fonksiyonu
Future<void> saveSalesForDay(String dateStr, Map<String, int> sales, Map<String, int> differences) async {
  final docRef = FirebaseFirestore.instance.collection('inventoryCounts').doc(dateStr);
  final doc = await docRef.get();
  if (!doc.exists) return;

  final data = doc.data();
  if (data == null || data['userCounts'] == null) return;

  final userCounts = data['userCounts'] as Map<String, dynamic>;
  final Map<String, dynamic> updatedUserCounts = {};

  userCounts.forEach((userId, userData) {
    if (userData is Map) {
      final Map<String, dynamic> updatedRoles = {};
      userData.forEach((role, products) {
        if (products is Map) {
          final Map<String, dynamic> updatedProducts = {};
          products.forEach((productId, productData) {
            if (productData is Map) {
              updatedProducts[productId] = {
                ...productData,
                'sales': sales[productId] ?? 0,
                'difference': differences[productId] ?? 0,
              };
            }
          });
          updatedRoles[role] = updatedProducts;
        }
      });
      updatedUserCounts[userId] = updatedRoles;
    }
  });

  await docRef.update({'userCounts': updatedUserCounts});
}

// Buradan satış giriş ekranına yönlendirme yapılabilir
                  },
                );
              },
            ),
    );
  }
}
