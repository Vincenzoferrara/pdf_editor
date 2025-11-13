import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/pdf_service.dart';

/// Provider per il servizio di creazione PDF
final pdfCreationProvider = Provider<PdfCreationService>((ref) {
  return PdfCreationService();
});

/// Servizio per la creazione e modifica di PDF
/// Estende le funzionalità base di PdfService con UI interattiva
class PdfCreationService {
  /// Crea un PDF di fattura con interfaccia guidata
  Future<String> createInvoicePdf(BuildContext context) async {
    try {
      // Dati di esempio per la fattura
      final title = "Fattura";
      final companyName = "Azienda Demo S.r.l.";
      
      final vendorInfo = {
        "name": "Vendor: Shop11",
        "address": "Via Roma 123",
        "city": "00100 Roma, Italia",
        "phone": "+39 06 123456"
      };
      
      final shipToInfo = {
        "name": "Ship To: Cliente Demo",
        "address": "Via Milano 456",
        "city": "20100 Milano, Italia", 
        "phone": "+39 02 987654"
      };
      
      final tableData = [
        {"name": "APPLE", "quantity": 3, "price": 20, "amount": 60},
        {"name": "POP CORN", "quantity": 20, "price": 10, "amount": 200},
        {"name": "MANGO", "quantity": 2, "price": 15, "amount": 30},
      ];
      
      final totals = {
        "subtotal": 290,
        "discount": 90,
        "grandTotal": 200
      };
      
      return await PdfService.createCustomPdf(
        title: title,
        companyName: companyName,
        tableData: tableData,
        vendorInfo: vendorInfo,
        shipToInfo: shipToInfo,
        totals: totals,
      );
    } catch (e) {
      throw Exception('Errore nella creazione della fattura: $e');
    }
  }
  
  /// Crea un PDF vuoto con template base
  Future<String> createBlankPdf() async {
    return await PdfService.createSimplePdf(text: "Documento vuoto");
  }
  
  /// Mostra dialog per la creazione PDF personalizzata
  Future<String?> showCreationDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Crea Nuovo PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Fattura'),
                subtitle: const Text('Crea una fattura con template predefinito'),
                leading: const Icon(Icons.receipt),
                onTap: () {
                  Navigator.of(context).pop('invoice');
                },
              ),
              ListTile(
                title: const Text('Documento vuoto'),
                subtitle: const Text('Crea un PDF vuoto'),
                leading: const Icon(Icons.description),
                onTap: () {
                  Navigator.of(context).pop('blank');
                },
              ),
              ListTile(
                title: const Text('Personalizzato'),
                subtitle: const Text('Crea un PDF completamente personalizzato'),
                leading: const Icon(Icons.edit),
                onTap: () {
                  Navigator.of(context).pop('custom');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }
  
  /// Gestisce la creazione basata sulla scelta dell'utente
  Future<String?> handleCreationChoice(BuildContext context, String choice) async {
    try {
      switch (choice) {
        case 'invoice':
          return await createInvoicePdf(context);
        case 'blank':
          return await createBlankPdf();
        case 'custom':
          // TODO: Implementare creazione personalizzata avanzata
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creazione personalizzata in sviluppo')),
          );
          return null;
        default:
          return null;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
      return null;
    }
  }
}