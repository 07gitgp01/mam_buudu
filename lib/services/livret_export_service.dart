import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class LivretExportService {
  // Export HTML uniquement (partageable)
  static Future<void> exporterHtml(String htmlContent, {String? nomFichier}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = nomFichier ?? 'livret_famille_${DateTime.now().millisecondsSinceEpoch}.html';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(htmlContent);
      
      // Partager le fichier HTML
      await Share.shareXFiles([XFile(filePath)], text: 'Livret de famille');
      
      debugPrint('✅ HTML exporté: $filePath');
    } catch (e) {
      debugPrint('❌ Erreur export HTML: $e');
    }
  }
  
  // Export PDF (utilise le package printing + pdf)
  static Future<void> exporterPdf(String htmlContent, {String? nomFichier}) async {
    try {
      // Générer le PDF depuis le HTML
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => Uint8List.fromList(htmlContent.codeUnits),
        name: 'Livret de Famille',
        format: PdfPageFormat.a4,
      );
      
      debugPrint('✅ PDF exporté');
    } catch (e) {
      debugPrint('❌ Erreur export PDF: $e');
    }
  }
  
  // Capture l'arbre actuel en image
  static Future<Uint8List> captureArbre(GlobalKey key) async {
    try {
      final RenderRepaintBoundary boundary = key.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(
        pixelRatio: 3.0,
      );
      
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Erreur capture arbre: $e');
      return Uint8List(0);
    }
  }
  
  // Générer le HTML avec l'image de l'arbre intégrée
  static Future<String> genererHtmlAvecArbre({
    required String htmlBase,
    required Uint8List? arbreImage,
  }) async {
    if (arbreImage == null) return htmlBase;
    
    final base64Image = 'data:image/png;base64,${base64Encode(arbreImage)}';
    
    // Remplacer le placeholder par l'image réelle
    return htmlBase.replaceFirst(
      'L\'arbre généalogique complet sera affiché ici',
      '<img src="$base64Image" alt="Arbre généalogique" class="arbre-image">',
    );
  }
}
