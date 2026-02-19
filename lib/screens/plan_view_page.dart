import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import '../models/models.dart';
import '../services/plan_print_service.dart';
import '../utils/formatters.dart';

class PlanViewPage extends StatefulWidget {
  const PlanViewPage({
    super.key,
    required this.result,
    required this.people,
    required this.locations,
    required this.aktifPeople,
    required this.onClearPlan,
    required this.onReassignAssignment,
    required this.onFillUnfilledSlot,
    required this.onShowInterstitialAd,
  });

  final ScheduleResult? result;
  final List<Person> people;
  final List<DutyLocation> locations;
  final List<Person> aktifPeople;
  final Future<void> Function() onClearPlan;
  final Future<void> Function(Assignment assignment, int personId)
  onReassignAssignment;
  final Future<void> Function(UnfilledSlot slot, int personId)
  onFillUnfilledSlot;
  final Future<void> Function() onShowInterstitialAd;

  @override
  State<PlanViewPage> createState() => _PlanViewPageState();
}

class _PlanViewPageState extends State<PlanViewPage> {
  DateTime? _visibleMonth;

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _supportsManualPdfSaveDialog => !kIsWeb;

  @override
  void didUpdateWidget(covariant PlanViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureVisibleMonth();
  }

  @override
  Widget build(BuildContext context) {
    final ScheduleResult? result = widget.result;
    if (result == null) {
      return const Center(
        child: Text('Henuz plan uretilmedi. Plan Olustur ekranindan baslayin.'),
      );
    }

    _ensureVisibleMonth();

    final DateTime periodStart = _dateOnly(result.request.baslangicTarihi);
    final DateTime periodEnd = _dateOnly(result.request.bitisTarihi);
    final DateTime minMonth = DateTime(periodStart.year, periodStart.month, 1);
    final DateTime maxMonth = DateTime(periodEnd.year, periodEnd.month, 1);
    final DateTime visibleMonth = _visibleMonth!;
    final List<DateTime> months = _monthsInRange(minMonth, maxMonth);

    final Map<int, String> personMap = {
      for (final p in widget.people) p.id: p.adSoyad,
    };
    final Map<int, String> locationMap = {
      for (final l in widget.locations) l.id: l.ad,
    };

    final Map<int, List<Assignment>> atamaMap = <int, List<Assignment>>{};
    for (final Assignment atama in result.assignments) {
      atamaMap
          .putIfAbsent(_dayKey(atama.shiftStart), () => <Assignment>[])
          .add(atama);
    }

    final Map<int, List<UnfilledSlot>> bosMap = <int, List<UnfilledSlot>>{};
    for (final UnfilledSlot slot in result.unfilledSlots) {
      bosMap
          .putIfAbsent(_dayKey(slot.shiftStart), () => <UnfilledSlot>[])
          .add(slot);
    }

    final List<DateTime> cells = _monthCells(visibleMonth);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 760;
        final bool wide = constraints.maxWidth >= 1280;
        final double aspectRatio = compact ? 0.95 : (wide ? 1.2 : 1.05);

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${formatDate(periodStart)} - ${formatDate(periodEnd)}',
                          ),
                          Text('Atama sayisi: ${result.assignments.length}'),
                          Text(
                            'Bos slot sayisi: ${result.unfilledSlots.length}',
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: compact
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final ScaffoldMessengerState messenger =
                                        ScaffoldMessenger.of(context);

                                    String? targetDirectoryPath;
                                    String? targetFileName;
                                    if (_supportsManualPdfSaveDialog) {
                                      final _PdfSaveSelection? selection =
                                          await _showPdfSaveDialog(
                                            context,
                                            title: 'Liste PDF Kaydet',
                                            initialFileName:
                                                _defaultListPdfName(result),
                                          );
                                      if (selection == null) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Kaydetme iptal edildi.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      targetDirectoryPath =
                                          selection.directoryPath;
                                      targetFileName = selection.fileName;
                                    }

                                    await widget.onShowInterstitialAd();
                                    final exportResult =
                                        await PlanPrintService.exportPlanListPdf(
                                          result: result,
                                          people: widget.people,
                                          locations: widget.locations,
                                          targetDirectoryPath:
                                              targetDirectoryPath,
                                          targetFileName: targetFileName,
                                        );
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(exportResult.message),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.print_outlined),
                                  label: const Text('Liste PDF Kaydet'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final ScaffoldMessengerState messenger =
                                        ScaffoldMessenger.of(context);

                                    String? targetDirectoryPath;
                                    String? targetFileName;
                                    if (_supportsManualPdfSaveDialog) {
                                      final _PdfSaveSelection? selection =
                                          await _showPdfSaveDialog(
                                            context,
                                            title: 'Takvim PDF Kaydet',
                                            initialFileName:
                                                _defaultCalendarPdfName(result),
                                          );
                                      if (selection == null) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Kaydetme iptal edildi.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      targetDirectoryPath =
                                          selection.directoryPath;
                                      targetFileName = selection.fileName;
                                    }

                                    await widget.onShowInterstitialAd();
                                    final exportResult =
                                        await PlanPrintService.exportPlanCalendarPdf(
                                          result: result,
                                          people: widget.people,
                                          locations: widget.locations,
                                          targetDirectoryPath:
                                              targetDirectoryPath,
                                          targetFileName: targetFileName,
                                        );
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(exportResult.message),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                  label: const Text('Takvim PDF Kaydet'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await widget.onClearPlan();
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Plani Temizle'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: _isSameMonth(visibleMonth, minMonth)
                            ? null
                            : () => setState(
                                () => _visibleMonth = DateTime(
                                  visibleMonth.year,
                                  visibleMonth.month - 1,
                                  1,
                                ),
                              ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DateTime>(
                              value: visibleMonth,
                              items: months
                                  .map(
                                    (m) => DropdownMenuItem<DateTime>(
                                      value: m,
                                      child: Text(
                                        '${m.month.toString().padLeft(2, '0')}.${m.year}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _visibleMonth = value);
                              },
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSameMonth(visibleMonth, maxMonth)
                            ? null
                            : () => setState(
                                () => _visibleMonth = DateTime(
                                  visibleMonth.year,
                                  visibleMonth.month + 1,
                                  1,
                                ),
                              ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  _WeekHeader(compact: compact),
                  const SizedBox(height: 6),
                  Expanded(
                    child: GridView.builder(
                      itemCount: cells.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final DateTime day = cells[index];
                        final bool currentMonth =
                            day.month == visibleMonth.month;
                        final bool inRange =
                            !day.isBefore(periodStart) &&
                            !day.isAfter(periodEnd);
                        final int key = _dayKey(day);
                        final List<Assignment> dayAtamalar =
                            atamaMap[key] ?? <Assignment>[];
                        final List<UnfilledSlot> dayBoslar =
                            bosMap[key] ?? <UnfilledSlot>[];
                        final int toplamKayit =
                            dayAtamalar.length + dayBoslar.length;

                        return InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap:
                              (!inRange ||
                                  (dayAtamalar.isEmpty && dayBoslar.isEmpty))
                              ? null
                              : () => _showDayDetails(
                                  context,
                                  day: day,
                                  atamalar: dayAtamalar,
                                  boslar: dayBoslar,
                                  personMap: personMap,
                                  locationMap: locationMap,
                                ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(6),
                              color: !currentMonth
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest
                                  : Theme.of(context).colorScheme.surface,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: currentMonth ? null : Colors.black38,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (!inRange)
                                  const SizedBox.shrink()
                                else
                                  Expanded(
                                    child: toplamKayit == 0
                                        ? const Text(
                                            'Kayit yok',
                                            style: TextStyle(fontSize: 10),
                                          )
                                        : SingleChildScrollView(
                                            child: Column(
                                              children: <Widget>[
                                                ...dayAtamalar.map(
                                                  (a) => _calendarDutyTile(
                                                    label:
                                                        '${locationMap[a.locationId] ?? 'Yer'} - ${_timeRange(a.shiftStart, a.shiftEnd)} - ${personMap[a.personId] ?? 'Kisi'}',
                                                    accentColor: Colors.green,
                                                  ),
                                                ),
                                                ...dayBoslar.map(
                                                  (u) => _calendarDutyTile(
                                                    label:
                                                        '${locationMap[u.locationId] ?? 'Yer'} - ${_timeRange(u.shiftStart, u.shiftEnd)} - BOS',
                                                    accentColor: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _ensureVisibleMonth() {
    final ScheduleResult? result = widget.result;
    if (result == null) {
      _visibleMonth = null;
      return;
    }
    final DateTime start = _dateOnly(result.request.baslangicTarihi);
    final DateTime end = _dateOnly(result.request.bitisTarihi);
    final DateTime minMonth = DateTime(start.year, start.month, 1);
    final DateTime maxMonth = DateTime(end.year, end.month, 1);

    if (_visibleMonth == null) {
      _visibleMonth = minMonth;
      return;
    }
    if (_visibleMonth!.isBefore(minMonth)) {
      _visibleMonth = minMonth;
    } else if (_visibleMonth!.isAfter(maxMonth)) {
      _visibleMonth = maxMonth;
    }
  }

  List<DateTime> _monthCells(DateTime month) {
    final DateTime monthStart = DateTime(month.year, month.month, 1);
    final DateTime monthEnd = DateTime(month.year, month.month + 1, 0);
    final DateTime gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday - DateTime.monday),
    );
    final DateTime gridEnd = monthEnd.add(
      Duration(days: DateTime.sunday - monthEnd.weekday),
    );

    final List<DateTime> out = <DateTime>[];
    for (
      DateTime d = gridStart;
      !d.isAfter(gridEnd);
      d = d.add(const Duration(days: 1))
    ) {
      out.add(d);
    }
    return out;
  }

  List<DateTime> _monthsInRange(DateTime minMonth, DateTime maxMonth) {
    final List<DateTime> out = <DateTime>[];
    for (
      DateTime m = DateTime(minMonth.year, minMonth.month, 1);
      !m.isAfter(maxMonth);
      m = DateTime(m.year, m.month + 1, 1)
    ) {
      out.add(m);
    }
    return out;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  int _dayKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

  String _timeRange(DateTime start, DateTime end) {
    final TimeOfDay startTime = TimeOfDay.fromDateTime(start);
    final TimeOfDay endTime = TimeOfDay.fromDateTime(end);
    return '${formatTime(startTime)}-${formatTime(endTime)}';
  }

  Widget _calendarDutyTile({
    required String label,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: accentColor.withValues(alpha: 0.95),
        ),
      ),
    );
  }

  void _showDayDetails(
    BuildContext context, {
    required DateTime day,
    required List<Assignment> atamalar,
    required List<UnfilledSlot> boslar,
    required Map<int, String> personMap,
    required Map<int, String> locationMap,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${formatDate(day)} Detay'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...atamalar.map(
                    (a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${locationMap[a.locationId] ?? 'Yer'} - ${personMap[a.personId] ?? 'Kisi'}',
                      ),
                      subtitle: Text(
                        '${formatDateTime(a.shiftStart)} - ${formatDateTime(a.shiftEnd)}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Nobetci degistir',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final NavigatorState navigator = Navigator.of(
                            context,
                          );
                          final int? personId = await _pickPerson(
                            context,
                            title: 'Nobetci sec',
                          );
                          if (personId == null) return;
                          await widget.onReassignAssignment(a, personId);
                          if (navigator.mounted) navigator.pop();
                        },
                      ),
                    ),
                  ),
                  ...boslar.map(
                    (u) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${locationMap[u.locationId] ?? 'Yer'} - BOS',
                      ),
                      subtitle: Text(
                        '${formatDateTime(u.shiftStart)} - ${formatDateTime(u.shiftEnd)}\n${u.reason}',
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final NavigatorState navigator = Navigator.of(
                            context,
                          );
                          final int? personId = await _pickPerson(
                            context,
                            title: 'Bos slot icin nobetci sec',
                          );
                          if (personId == null) return;
                          await widget.onFillUnfilledSlot(u, personId);
                          if (navigator.mounted) navigator.pop();
                        },
                        child: const Text('Doldur'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _pickPerson(
    BuildContext context, {
    required String title,
  }) async {
    final List<Person> active = widget.aktifPeople;
    if (active.isEmpty) return null;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(title),
          children: active
              .map(
                (p) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(p.id),
                  child: Text(p.adSoyad),
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _defaultListPdfName(ScheduleResult result) {
    return 'nobet-plan-liste-${_stamp(result.request.baslangicTarihi)}-${_stamp(result.request.bitisTarihi)}.pdf';
  }

  String _defaultCalendarPdfName(ScheduleResult result) {
    return 'nobet-plan-takvim-${_stamp(result.request.baslangicTarihi)}-${_stamp(result.request.bitisTarihi)}.pdf';
  }

  String _stamp(DateTime dt) {
    final String y = dt.year.toString();
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  Future<_PdfSaveSelection?> _showPdfSaveDialog(
    BuildContext context, {
    required String title,
    required String initialFileName,
  }) async {
    return showDialog<_PdfSaveSelection>(
      context: context,
      builder: (dialogContext) {
        return _PdfSaveDialog(
          title: title,
          initialFileName: initialFileName,
          requireFolderPath: !_isMobilePlatform,
        );
      },
    );
  }
}

class _PdfSaveDialog extends StatefulWidget {
  const _PdfSaveDialog({
    required this.title,
    required this.initialFileName,
    required this.requireFolderPath,
  });

  final String title;
  final String initialFileName;
  final bool requireFolderPath;

  @override
  State<_PdfSaveDialog> createState() => _PdfSaveDialogState();
}

class _PdfSaveDialogState extends State<_PdfSaveDialog> {
  late final TextEditingController _fileNameController;
  late final TextEditingController _folderController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.initialFileName);
    _folderController = TextEditingController();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _fileNameController,
                decoration: const InputDecoration(
                  labelText: 'Dosya adi',
                  hintText: 'ornek.pdf',
                ),
              ),
              const SizedBox(height: 12),
              if (widget.requireFolderPath)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _folderController,
                        decoration: const InputDecoration(
                          labelText: 'Klasor yolu',
                          hintText: r'C:\Klasor\AltKlasor',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _pickFolder,
                      child: const Text('Klasor Sec'),
                    ),
                  ],
                )
              else
                const Text(
                  'Android/iOS: Klasor secimi desteklenmiyor. Kaydet ile sistem kaydetme menusu acilir.',
                ),
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Iptal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Kaydet')),
      ],
    );
  }

  Future<void> _pickFolder() async {
    try {
      final String? selectedPath = await getDirectoryPath(
        confirmButtonText: 'Klasor Sec',
      );
      if (!mounted || selectedPath == null) return;
      setState(() {
        _folderController.text = selectedPath;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Klasor secimi basarisiz.');
    }
  }

  void _submit() {
    final String fileName = _fileNameController.text.trim();
    final String folderPath = _folderController.text.trim();
    if (fileName.isEmpty || (widget.requireFolderPath && folderPath.isEmpty)) {
      setState(() {
        _errorMessage = widget.requireFolderPath
            ? 'Dosya adi ve klasor yolu zorunludur.'
            : 'Dosya adi zorunludur.';
      });
      return;
    }

    final String normalizedName = fileName.toLowerCase().endsWith('.pdf')
        ? fileName
        : '$fileName.pdf';
    Navigator.of(context).pop(
      _PdfSaveSelection(directoryPath: folderPath, fileName: normalizedName),
    );
  }
}

class _PdfSaveSelection {
  const _PdfSaveSelection({
    required this.directoryPath,
    required this.fileName,
  });

  final String directoryPath;
  final String fileName;
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    const List<String> names = <String>[
      'Pzt',
      'Sal',
      'Car',
      'Per',
      'Cum',
      'Cmt',
      'Paz',
    ];
    return Row(
      children: names
          .map(
            (e) => Expanded(
              child: Center(
                child: Text(
                  e,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11 : 13,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
