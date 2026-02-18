// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import '../../models/models.dart';

Future<bool> openPrintablePlanHtml({
  required ScheduleResult result,
  required List<Person> people,
  required List<DutyLocation> locations,
}) async {
  final Map<int, String> personMap = {for (final p in people) p.id: p.adSoyad};
  final Map<int, String> locationMap = {for (final l in locations) l.id: l.ad};

  final StringBuffer rows = StringBuffer();
  for (final Assignment a in result.assignments) {
    rows.writeln(
      '<tr>'
      '<td>${_e(_d(a.shiftStart))}</td>'
      '<td>${_e(locationMap[a.locationId] ?? 'Yer')}</td>'
      '<td>${_e(personMap[a.personId] ?? 'Kisi')}</td>'
      '<td>${_e(_dt(a.shiftStart))}</td>'
      '<td>${_e(_dt(a.shiftEnd))}</td>'
      '<td>${a.durationHours.toStringAsFixed(1)}</td>'
      '</tr>',
    );
  }

  final StringBuffer unfilledRows = StringBuffer();
  for (final UnfilledSlot u in result.unfilledSlots) {
    unfilledRows.writeln(
      '<tr>'
      '<td>${_e(_d(u.shiftStart))}</td>'
      '<td>${_e(locationMap[u.locationId] ?? 'Yer')}</td>'
      '<td>${_e(_dt(u.shiftStart))}</td>'
      '<td>${_e(_dt(u.shiftEnd))}</td>'
      '<td>${_e(u.reason)}</td>'
      '</tr>',
    );
  }

  final String htmlContent = '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Nobetmatik Plan</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 24px; color: #1f2937; }
    h1 { margin: 0 0 8px 0; color: #004D9B; }
    .meta { margin-bottom: 16px; font-size: 14px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    th, td { border: 1px solid #d1d5db; padding: 8px; font-size: 12px; text-align: left; }
    th { background: #eaf2fb; color: #0f172a; }
    .section { margin-top: 12px; }
    .print-btn { background: #004D9B; color: white; border: none; padding: 10px 16px; cursor: pointer; border-radius: 6px; }
    @media print {
      .no-print { display: none !important; }
      body { margin: 10mm; }
      h1 { color: black; }
    }
  </style>
</head>
<body>
  <div class="no-print" style="margin-bottom: 16px;">
    <button class="print-btn" onclick="window.print()">Yazdir</button>
  </div>
  <h1>Nobetmatik Plan</h1>
  <div class="meta">
    Donem: ${_e(_d(result.request.baslangicTarihi))} - ${_e(_d(result.request.bitisTarihi))}<br/>
    Toplam Atama: ${result.assignments.length} | Bos Slot: ${result.unfilledSlots.length}
  </div>

  <div class="section">
    <h3>Atamalar</h3>
    <table>
      <thead>
        <tr>
          <th>Tarih</th>
          <th>Yer</th>
          <th>Nobetci</th>
          <th>Baslangic</th>
          <th>Bitis</th>
          <th>Saat</th>
        </tr>
      </thead>
      <tbody>
        ${rows.isEmpty ? '<tr><td colspan="6">Atama yok</td></tr>' : rows.toString()}
      </tbody>
    </table>
  </div>

  <div class="section">
    <h3>Doldurulamayan Slotlar</h3>
    <table>
      <thead>
        <tr>
          <th>Tarih</th>
          <th>Yer</th>
          <th>Baslangic</th>
          <th>Bitis</th>
          <th>Neden</th>
        </tr>
      </thead>
      <tbody>
        ${unfilledRows.isEmpty ? '<tr><td colspan="5">Bos slot yok</td></tr>' : unfilledRows.toString()}
      </tbody>
    </table>
  </div>
</body>
</html>
''';

  final String encoded = Uri.dataFromString(
    htmlContent,
    mimeType: 'text/html',
    encoding: utf8,
  ).toString();

  final html.WindowBase newWindow = html.window.open(encoded, '_blank');
  return newWindow.closed != true;
}

String _e(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _d(DateTime dt) {
  final String day = dt.day.toString().padLeft(2, '0');
  final String month = dt.month.toString().padLeft(2, '0');
  return '$day.$month.${dt.year}';
}

String _dt(DateTime dt) {
  return '${_d(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
