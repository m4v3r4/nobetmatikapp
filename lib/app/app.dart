import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/app_controller.dart';
import '../screens/locations_page.dart';
import '../screens/people_page.dart';
import '../screens/plan_builder_page.dart';
import '../screens/plan_view_page.dart';
import '../services/ads/ads_service.dart';
import '../widgets/ad_banner_strip.dart';

class NobetmatikApp extends StatefulWidget {
  const NobetmatikApp({
    super.key,
    required this.controller,
    required this.adsService,
  });

  final AppController controller;
  final AdsService adsService;

  @override
  State<NobetmatikApp> createState() => _NobetmatikAppState();
}

class _NobetmatikAppState extends State<NobetmatikApp> {
  static const String _tutorialSeenKey = 'nobetmatik_tutorial_seen_v1';

  int _tabIndex = 0;
  bool _isGeneratingPlan = false;
  bool _isTutorialOpen = false;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey _helpKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowTutorialOnFirstOpen();
    });
  }

  @override
  void dispose() {
    widget.adsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ColorScheme lightScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF005A9C),
          brightness: Brightness.light,
        );
        final ColorScheme darkScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF005A9C),
          brightness: Brightness.dark,
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nobetmatik',
          navigatorKey: _navigatorKey,
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
            fontFamily: 'NotoSans',
            scaffoldBackgroundColor: const Color(0xFFF4F7FB),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: lightScheme.outlineVariant),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
            fontFamily: 'NotoSans',
          ),
          themeMode: widget.controller.themeMode,
          home: widget.controller.isReady
              ? _buildScaffold()
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }

  List<NavigationDestination> get _destinations =>
      const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Kisiler',
        ),
        NavigationDestination(
          icon: Icon(Icons.place_outlined),
          selectedIcon: Icon(Icons.place),
          label: 'Yerler',
        ),
        NavigationDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build),
          label: 'Plan Olustur',
        ),
        NavigationDestination(
          icon: Icon(Icons.view_list_outlined),
          selectedIcon: Icon(Icons.view_list),
          label: 'Plan',
        ),
      ];

  List<Widget> _buildPages() {
    return <Widget>[
      PeoplePage(
        people: widget.controller.people,
        onAdd: (name) => widget.controller.addPerson(name),
        onToggle: (id, value) => widget.controller.togglePerson(id, value),
        onDelete: (id) => widget.controller.deletePerson(id),
      ),
      LocationsPage(
        locations: widget.controller.locations,
        onAdd: (ad, kapasite) => widget.controller.addLocation(ad, kapasite),
        onDelete: (id) => widget.controller.deleteLocation(id),
      ),
      PlanBuilderPage(
        periodStart: widget.controller.periodStart,
        periodEnd: widget.controller.periodEnd,
        vardiyalar: widget.controller.vardiyalar,
        seciliHaftaGunleri: widget.controller.seciliHaftaGunleri,
        minRestHours: widget.controller.minRestHours,
        weeklyMaxShifts: widget.controller.weeklyMaxShifts,
        onPeriodStartChanged: (value) =>
            widget.controller.setPeriodStart(value),
        onPeriodEndChanged: (value) => widget.controller.setPeriodEnd(value),
        onAddVardiya: () => widget.controller.addVardiya(),
        onRemoveVardiya: (id) => widget.controller.removeVardiya(id),
        onSetVardiyaStart: (id, value) =>
            widget.controller.setVardiyaStart(id, value),
        onSetVardiyaEnd: (id, value) =>
            widget.controller.setVardiyaEnd(id, value),
        onSeciliHaftaGunleriChanged: (value) =>
            widget.controller.setSeciliHaftaGunleri(value),
        onMinRestChanged: (value) => widget.controller.setMinRestHours(value),
        onWeeklyMaxChanged: (value) =>
            widget.controller.setWeeklyMaxShifts(value),
        isGenerating: _isGeneratingPlan,
        onGenerate: _handleGeneratePlan,
      ),
      PlanViewPage(
        result: widget.controller.lastResult,
        people: widget.controller.people,
        locations: widget.controller.locations,
        aktifPeople: widget.controller.aktifPeople,
        onShowInterstitialAd: () =>
            widget.adsService.showInterstitialIfAvailable(),
        onClearPlan: () async {
          final bool onay = await _showPlanClearDialog() ?? false;
          if (!onay) return;
          await widget.controller.clearPlan();
        },
        onReassignAssignment: (assignment, personId) =>
            widget.controller.reassignAssignment(assignment, personId),
        onFillUnfilledSlot: (slot, personId) =>
            widget.controller.fillUnfilledSlot(slot, personId),
      ),
    ];
  }

  Future<void> _handleGeneratePlan() async {
    if (_isGeneratingPlan) return;
    setState(() => _isGeneratingPlan = true);
    try {
      if (widget.controller.hasCurrentPlanOverlap()) {
        final bool onay = await _showPlanOverwriteDialog() ?? false;
        if (!onay) return;
      }

      await widget.adsService.showInterstitialIfAvailable();
      await widget.controller.generatePlan();
      final int bos = widget.controller.lastResult?.unfilledSlots.length ?? 0;
      if (bos == 0) {
        if (!mounted) return;
        setState(() => _tabIndex = 3);
        return;
      }

      final int ekKisi = widget.controller.gerekenEkKisiSayisi();
      if (!mounted) return;
      final bool bosBirak =
          await _showUnfilledDecisionDialog(
            bosSlotSayisi: bos,
            ekKisiSayisi: ekKisi,
          ) ??
          false;
      if (!mounted) return;
      setState(() => _tabIndex = bosBirak ? 3 : 2);
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPlan = false);
      }
    }
  }

  Widget _buildScaffold() {
    final List<Widget> pages = _buildPages();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Nobetmatik'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: _helpKey,
            tooltip: 'Yardim',
            onPressed: _startTutorialFromHelp,
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: 'Tema degistir',
            onPressed: () => widget.controller.toggleThemeMode(),
            icon: Icon(
              widget.controller.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isDesktop = constraints.maxWidth >= 980;
          if (!isDesktop) {
            return IndexedStack(index: _tabIndex, children: pages);
          }

          return Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: _tabIndex,
                onDestinationSelected: (value) =>
                    setState(() => _tabIndex = value),
                labelType: NavigationRailLabelType.all,
                minWidth: 86,
                destinations: _destinations
                    .map(
                      (NavigationDestination d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.05),
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: IndexedStack(
                                index: _tabIndex,
                                children: pages,
                              ),
                            ),
                          ),
                        ),
                      ),
                      AdBannerStrip(enabled: widget.adsService.isAdsEnabled),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 980
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: AdBannerStrip(enabled: widget.adsService.isAdsEnabled),
                ),
                NavigationBar(
                  selectedIndex: _tabIndex,
                  onDestinationSelected: (value) =>
                      setState(() => _tabIndex = value),
                  destinations: _destinations,
                ),
              ],
            ),
    );
  }

  Future<void> _maybeShowTutorialOnFirstOpen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool seen = prefs.getBool(_tutorialSeenKey) ?? false;
    if (seen || !mounted) return;
    await _runTutorial();
    await prefs.setBool(_tutorialSeenKey, true);
  }

  Future<void> _startTutorialFromHelp() async {
    await _runTutorial();
  }

  Future<void> _runTutorial() async {
    if (!mounted || _isTutorialOpen) return;
    final BuildContext dialogContext = _navigatorKey.currentContext ?? context;
    final List<_TutorialStep> steps = <_TutorialStep>[
      _TutorialStep(
        tabIndex: 0,
        title: 'Kisiler',
        description:
            'Bu sayfada nobet yazilacak personeli ekler, aktif/pasif yapar ve listeden silebilirsin.',
      ),
      _TutorialStep(
        tabIndex: 1,
        title: 'Yerler',
        description:
            'Nobet tutulacak birimleri burada tanimlarsin. Her yer icin kapasite belirlenir.',
      ),
      _TutorialStep(
        tabIndex: 2,
        title: 'Planlama Parametreleri',
        description:
            'Tarih araligi, vardiyalar ve kurallari bu ekranda ayarlayip Plan Uret ile plani olusturursun.',
      ),
      _TutorialStep(
        tabIndex: 3,
        title: 'Plan',
        description:
            'Uretilen plani takvim/liste olarak gorur, duzenler, PDF kaydeder ve plani temizlersin.',
      ),
    ];

    setState(() => _tabIndex = 0);
    _isTutorialOpen = true;
    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => _TabTutorialDialog(
        steps: steps,
        onStepChanged: (int tabIndex) {
          if (!mounted) return;
          setState(() => _tabIndex = tabIndex);
        },
      ),
    );
    _isTutorialOpen = false;
  }

  Future<bool?> _showUnfilledDecisionDialog({
    required int bosSlotSayisi,
    required int ekKisiSayisi,
  }) {
    final BuildContext dialogContext = _navigatorKey.currentContext ?? context;
    return showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tum slotlar doldurulamadi'),
          content: Text(
            'Bos kalan slot: $bosSlotSayisi\n'
            'Yaklasik gerekli ek kisi: $ekKisiSayisi\n\n'
            'Bos kalanlarla plan gosterilsin mi?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tekrar duzenle'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Bos kalsin, plani goster'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showPlanOverwriteDialog() {
    final BuildContext dialogContext = _navigatorKey.currentContext ?? context;
    return showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Plan cakismasi bulundu'),
          content: const Text(
            'Bu tarih araligi icin mevcut plan kaydi var. Yeni plan uretilirse eski plan verisi silinecek. Devam edilsin mi?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Devam et'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showPlanClearDialog() {
    final BuildContext dialogContext = _navigatorKey.currentContext ?? context;
    return showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Plani temizle'),
          content: const Text(
            'Kayitli plan tamamen silinecek. Onayliyor musun?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgec'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.tabIndex,
    required this.title,
    required this.description,
  });

  final int tabIndex;
  final String title;
  final String description;
}

class _TabTutorialDialog extends StatefulWidget {
  const _TabTutorialDialog({required this.steps, required this.onStepChanged});

  final List<_TutorialStep> steps;
  final ValueChanged<int> onStepChanged;

  @override
  State<_TabTutorialDialog> createState() => _TabTutorialDialogState();
}

class _TabTutorialDialogState extends State<_TabTutorialDialog> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onStepChanged(widget.steps.first.tabIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final _TutorialStep current = widget.steps[_index];
    final bool isLast = _index == widget.steps.length - 1;

    return AlertDialog(
      title: Text('${_index + 1}/${widget.steps.length} - ${current.title}'),
      content: Text(current.description),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Gec'),
        ),
        FilledButton(
          onPressed: () {
            if (isLast) {
              Navigator.of(context).pop();
              return;
            }
            final int next = _index + 1;
            setState(() => _index = next);
            widget.onStepChanged(widget.steps[next].tabIndex);
          },
          child: Text(isLast ? 'Bitir' : 'Ileri'),
        ),
      ],
    );
  }
}
