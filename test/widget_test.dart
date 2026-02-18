import 'package:flutter_test/flutter_test.dart';
import 'package:nobetmatik/app/app.dart';
import 'package:nobetmatik/controller/app_controller.dart';
import 'package:nobetmatik/services/ads/admob_service.dart';
import 'package:nobetmatik/services/local_storage_service.dart';
import 'package:nobetmatik/services/scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Nobetmatik aciliyor', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final AppController controller = AppController(
      storage: LocalStorageService(),
      scheduler: SchedulerService(),
    );
    await controller.initialize();
    final AdMobService adMobService = AdMobService();

    await tester.pumpWidget(
      NobetmatikApp(controller: controller, adMobService: adMobService),
    );
    expect(find.text('Nobetmatik MVP'), findsOneWidget);
  });
}
