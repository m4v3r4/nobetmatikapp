import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'controller/app_controller.dart';
import 'services/ads/ads_service.dart';
import 'services/local_storage_service.dart';
import 'services/scheduler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppController controller = AppController(
    storage: LocalStorageService(),
    scheduler: SchedulerService(),
  );
  final AdsService adsService = AdsService();
  await controller.initialize();
  await adsService.initialize();

  runApp(NobetmatikApp(controller: controller, adsService: adsService));
}
