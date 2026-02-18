// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import 'pdf_save_result.dart';

Future<PdfSaveResult> savePdfBytes({
  required List<int> bytes,
  required String suggestedName,
  String? directoryPath,
  String? fileName,
}) async {
  final String effectiveFileName =
      (fileName != null && fileName.trim().isNotEmpty)
      ? fileName.trim()
      : suggestedName;
  final String base64Data = base64Encode(bytes);
  final html.AnchorElement anchor =
      html.AnchorElement(href: 'data:application/pdf;base64,$base64Data')
        ..download = effectiveFileName
        ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  return const PdfSaveResult(
    success: true,
    message: 'PDF indiriliyor. Tarayici indirme konumunu kullanir.',
  );
}
