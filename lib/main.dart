import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/utils/helpers/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const AaravPosApp());
}
