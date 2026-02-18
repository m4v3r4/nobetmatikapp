import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'controller/app_controller.dart';
import 'services/ads/admob_service.dart';
import 'services/local_storage_service.dart';
import 'services/scheduler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppController controller = AppController(
    storage: LocalStorageService(),
    scheduler: SchedulerService(),
  );
  final AdMobService adMobService = AdMobService();
  await controller.initialize();
  await adMobService.initialize();

  runApp(NobetmatikApp(controller: controller, adMobService: adMobService));
}
