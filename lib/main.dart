import 'package:flutter/widgets.dart';

import 'app/app_composition.dart';
import 'app/pocketools_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final composition = await PocketoolsComposition.production();
  runApp(PocketoolsApp.production(composition: composition));
}
