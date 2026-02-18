import 'pdf_save_result.dart';

Future<PdfSaveResult> savePdfBytes({
  required List<int> bytes,
  required String suggestedName,
  String? directoryPath,
  String? fileName,
}) async {
  return const PdfSaveResult(
    success: false,
    message: 'Bu platformda PDF kaydetme desteklenmiyor.',
  );
}
