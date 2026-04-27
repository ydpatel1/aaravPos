import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'core/utils/helpers/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(AppRouter.navigatorKey);
  runApp(const AaravPosApp());
}
