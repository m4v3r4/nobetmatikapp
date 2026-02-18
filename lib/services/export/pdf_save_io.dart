import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

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

  if (directoryPath != null && directoryPath.trim().isNotEmpty) {
    try {
      final String dir = directoryPath.trim();
      final bool hasSlash = dir.endsWith('/') || dir.endsWith(r'\');
      final String fullPath = hasSlash
          ? '$dir$effectiveFileName'
          : '$dir${Platform.pathSeparator}$effectiveFileName';
      final File file = File(fullPath);
      await file.writeAsBytes(bytes, flush: true);
      return PdfSaveResult(
        success: true,
        message: 'PDF kaydedildi: ${file.path}',
      );
    } catch (e) {
      if (!(Platform.isAndroid || Platform.isIOS)) {
        return PdfSaveResult(
          success: false,
          message: 'PDF kaydetme hatasi: $e',
        );
      }
    }
  }

  if (Platform.isAndroid || Platform.isIOS) {
    final String? savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: Uint8List.fromList(bytes),
        fileName: effectiveFileName,
      ),
    );
    if (savedPath == null) {
      return const PdfSaveResult(
        success: false,
        message: 'Kaydetme iptal edildi.',
      );
    }
    return PdfSaveResult(success: true, message: 'PDF kaydedildi: $savedPath');
  }

  const XTypeGroup pdfType = XTypeGroup(
    label: 'PDF',
    extensions: <String>['pdf'],
  );

  final FileSaveLocation? location = await getSaveLocation(
    suggestedName: effectiveFileName,
    acceptedTypeGroups: <XTypeGroup>[pdfType],
  );

  if (location == null) {
    return const PdfSaveResult(
      success: false,
      message: 'Kaydetme iptal edildi.',
    );
  }

  final File file = File(location.path);
  await file.writeAsBytes(bytes, flush: true);
  return PdfSaveResult(success: true, message: 'PDF kaydedildi: ${file.path}');
}
