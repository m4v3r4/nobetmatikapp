import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/models.dart';
import 'export/pdf_save_result.dart';
import 'export/pdf_save_stub.dart'
    if (dart.library.io) 'export/pdf_save_io.dart'
    if (dart.library.html) 'export/pdf_save_web.dart';

class PlanPrintService {
  static Future<pw.ThemeData> _pdfTheme() async {
    final pw.Font base = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final pw.Font bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    return pw.ThemeData.withFont(base: base, bold: bold);
  }

  static Future<PdfSaveResult> exportPlanListPdf({
    required ScheduleResult result,
    required List<Person> people,
    required List<DutyLocation> locations,
    String? targetDirectoryPath,
    String? targetFileName,
  }) async {
    final Map<int, String> personMap = {
      for (final p in people) p.id: p.adSoyad,
    };
    final Map<int, String> locationMap = {
      for (final l in locations) l.id: l.ad,
    };

    final pw.Document doc = pw.Document();

    final List<List<String>> assignmentRows = result.assignments
        .map(
          (a) => <String>[
            _date(a.shiftStart),
            locationMap[a.locationId] ?? 'Yer',
            personMap[a.personId] ?? 'Kişi',
            _dateTime(a.shiftStart),
            _dateTime(a.shiftEnd),
            a.durationHours.toStringAsFixed(1),
          ],
        )
        .toList(growable: false);

    final List<List<String>> unfilledRows = result.unfilledSlots
        .map(
          (u) => <String>[
            _date(u.shiftStart),
            locationMap[u.locationId] ?? 'Yer',
            _dateTime(u.shiftStart),
            _dateTime(u.shiftEnd),
            u.reason,
          ],
        )
        .toList(growable: false);

    final pw.ThemeData theme = await _pdfTheme();

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return <pw.Widget>[
            _header(result),
            pw.SizedBox(height: 12),
            pw.Text(
              'Atamalar',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const <String>[
                'Tarih',
                'Yer',
                'Nöbetçi',
                'Başlangıç',
                'Bitiş',
                'Saat',
              ],
              data: assignmentRows.isEmpty
                  ? <List<String>>[
                      <String>['-', 'Atama yok', '-', '-', '-', '-'],
                    ]
                  : assignmentRows,
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FlexColumnWidth(1.0),
                1: const pw.FlexColumnWidth(1.3),
                2: const pw.FlexColumnWidth(1.3),
                3: const pw.FlexColumnWidth(1.6),
                4: const pw.FlexColumnWidth(1.6),
                5: const pw.FlexColumnWidth(0.6),
              },
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Doldurulamayan Slotlar',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: const <String>[
                'Tarih',
                'Yer',
                'Başlangıç',
                'Bitiş',
                'Neden',
              ],
              data: unfilledRows.isEmpty
                  ? <List<String>>[
                      <String>['-', 'Bos slot yok', '-', '-', '-'],
                    ]
                  : unfilledRows,
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FlexColumnWidth(1.0),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(1.4),
                4: const pw.FlexColumnWidth(2.2),
              },
            ),
          ];
        },
      ),
    );

    final List<int> bytes = await doc.save();
    final String fileName =
        'nobet-plan-liste-${_stamp(result.request.baslangicTarihi)}-${_stamp(result.request.bitisTarihi)}.pdf';

    return savePdfBytes(
      bytes: bytes,
      suggestedName: fileName,
      directoryPath: targetDirectoryPath,
      fileName: targetFileName,
    );
  }

  static Future<PdfSaveResult> exportPlanCalendarPdf({
    required ScheduleResult result,
    required List<Person> people,
    required List<DutyLocation> locations,
    String? targetDirectoryPath,
    String? targetFileName,
  }) async {
    final Map<int, String> personMap = {
      for (final p in people) p.id: p.adSoyad,
    };
    final Map<int, String> locationMap = {
      for (final l in locations) l.id: l.ad,
    };

    final Map<int, List<Assignment>> assignmentMap = <int, List<Assignment>>{};
    for (final a in result.assignments) {
      assignmentMap
          .putIfAbsent(_dayKey(a.shiftStart), () => <Assignment>[])
          .add(a);
    }

    final Map<int, List<UnfilledSlot>> unfilledMap =
        <int, List<UnfilledSlot>>{};
    for (final u in result.unfilledSlots) {
      unfilledMap
          .putIfAbsent(_dayKey(u.shiftStart), () => <UnfilledSlot>[])
          .add(u);
    }

    final DateTime start = DateTime(
      result.request.baslangicTarihi.year,
      result.request.baslangicTarihi.month,
      result.request.baslangicTarihi.day,
    );
    final DateTime end = DateTime(
      result.request.bitisTarihi.year,
      result.request.bitisTarihi.month,
      result.request.bitisTarihi.day,
    );

    final pw.Document doc = pw.Document();

    for (
      DateTime month = DateTime(start.year, start.month, 1);
      !month.isAfter(DateTime(end.year, end.month, 1));
      month = DateTime(month.year, month.month + 1, 1)
    ) {
      final DateTime monthStart = month;
      final DateTime monthEnd = DateTime(month.year, month.month + 1, 0);
      final DateTime gridStart = monthStart.subtract(
        Duration(days: monthStart.weekday - DateTime.monday),
      );
      final DateTime gridEnd = monthEnd.add(
        Duration(days: DateTime.sunday - monthEnd.weekday),
      );

      final List<List<String>> rows = <List<String>>[];
      List<String> week = <String>[];
      for (
        DateTime d = gridStart;
        !d.isAfter(gridEnd);
        d = d.add(const Duration(days: 1))
      ) {
        String cell = '';
        final bool inMonth = d.month == month.month;
        final bool inRange = !d.isBefore(start) && !d.isAfter(end);
        if (inMonth) {
          cell = '${d.day}';
          if (inRange) {
            final int key = _dayKey(d);
            final List<Assignment> dayA = assignmentMap[key] ?? <Assignment>[];
            final List<UnfilledSlot> dayU =
                unfilledMap[key] ?? <UnfilledSlot>[];

            for (final a in dayA) {
              cell +=
                  '\n${locationMap[a.locationId] ?? 'Yer'} - ${personMap[a.personId] ?? 'Kişi'}';
            }
            for (final u in dayU) {
              cell += '\n${locationMap[u.locationId] ?? 'Yer'} - BOS';
            }
          }
        }

        week.add(cell);
        if (week.length == 7) {
          rows.add(week);
          week = <String>[];
        }
      }

      final pw.ThemeData theme = await _pdfTheme();

      doc.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(18),
          build: (context) {
            return <pw.Widget>[
              if (month == DateTime(start.year, start.month, 1))
                _header(result),
              if (month == DateTime(start.year, start.month, 1))
                pw.SizedBox(height: 8),
              pw.Text(
                '${_monthName(month.month)} ${month.year}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: const <String>[
                  'Pzt',
                  'Sal',
                  'Car',
                  'Per',
                  'Cum',
                  'Cmt',
                  'Paz',
                ],
                data: rows,
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellHeight: 70,
                cellAlignments: const <int, pw.Alignment>{
                  0: pw.Alignment.topLeft,
                  1: pw.Alignment.topLeft,
                  2: pw.Alignment.topLeft,
                  3: pw.Alignment.topLeft,
                  4: pw.Alignment.topLeft,
                  5: pw.Alignment.topLeft,
                  6: pw.Alignment.topLeft,
                },
                columnWidths: const <int, pw.TableColumnWidth>{
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(1),
                  5: pw.FlexColumnWidth(1),
                  6: pw.FlexColumnWidth(1),
                },
              ),
            ];
          },
        ),
      );
    }

    final List<int> bytes = await doc.save();
    final String fileName =
        'nobet-plan-takvim-${_stamp(result.request.baslangicTarihi)}-${_stamp(result.request.bitisTarihi)}.pdf';

    return savePdfBytes(
      bytes: bytes,
      suggestedName: fileName,
      directoryPath: targetDirectoryPath,
      fileName: targetFileName,
    );
  }

  static pw.Widget _header(ScheduleResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'Nobetmatik Plan',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Donem: ${_date(result.request.baslangicTarihi)} - ${_date(result.request.bitisTarihi)}',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          'Toplam Atama: ${result.assignments.length} | Bos Slot: ${result.unfilledSlots.length}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static String _monthName(int month) {
    const List<String> names = <String>[
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return names[month - 1];
  }

  static int _dayKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static String _stamp(DateTime dt) {
    final String y = dt.year.toString();
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static String _date(DateTime dt) {
    final String d = dt.day.toString().padLeft(2, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }

  static String _dateTime(DateTime dt) {
    final String h = dt.hour.toString().padLeft(2, '0');
    final String min = dt.minute.toString().padLeft(2, '0');
    return '${_date(dt)} $h:$min';
  }
}
