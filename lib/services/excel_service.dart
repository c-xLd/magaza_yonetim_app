import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

/// Excel dosyalarını işlemek için servis sınıfı
class ExcelService {
  /// Excel dosyasını seçmek için dosya seçici açar
  Future<PlatformFile?> pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    
    if (result != null) {
      return result.files.first;
    }
    
    return null;
  }
  
  /// Excel dosyasını işler ve ürünleri role'a atar
  Future<ExcelResult> processExcelFile(String filePath, String role) async {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      
      // İşlenen ürün sayısı
      int processedRows = 0;
      List<Map<String, dynamic>> products = [];
      
      if (excel.tables.keys.isNotEmpty) {
        final sheet = excel.tables[excel.tables.keys.first];
        
        if (sheet != null) {
          // Başlıkları atlayarak 2. satırdan başla (genelde 1. satır başlık olur)
          for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
            final row = sheet.row(rowIndex);
            // En az 5 sütun olmalı: barcode, kod, ad, birim, koli içi miktar
            if (row.length >= 5 && row[1]?.value != null && row[2]?.value != null && row[3]?.value != null && row[4]?.value != null) {
              final productBarcode = row[0]?.value?.toString() ?? '';
              final productCode = row[1]?.value?.toString() ?? '';
              final productName = row[2]?.value?.toString() ?? '';
              final unit = row[3]?.value?.toString() ?? '';
              final packageQuantity = int.tryParse(row[4]?.value?.toString() ?? '') ?? 1;
              products.add({
                'barcode': productBarcode,
                'code': productCode,
                'name': productName,
                'unit': unit,
                'packageQuantity': packageQuantity,
                'role': role,
              });
              processedRows++;
            }
          }
          
          return ExcelResult(
            success: true,
            message: '$processedRows ürün başarıyla "$role" grubuna atandı.',
            processedCount: processedRows,
            products: products,
          );
        }
      }
      
      return ExcelResult(
        success: false,
        message: 'Excel dosyasında geçerli bir sayfa bulunamadı.',
        processedCount: 0,
        products: [],
      );
    } catch (e) {
      return ExcelResult(
        success: false,
        message: 'Excel dosyası işlenirken bir hata oluştu: $e',
        processedCount: 0,
        products: [],
      );
    }
  }
}

/// Excel işleme sonucunu temsil eden sınıf
class ExcelResult {
  final bool success;
  final String message;
  final int processedCount;
  final List<Map<String, dynamic>> products;
  
  ExcelResult({
    required this.success,
    required this.message,
    required this.processedCount,
    required this.products,
  });
}
