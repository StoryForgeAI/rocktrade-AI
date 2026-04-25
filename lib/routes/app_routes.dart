import 'package:flutter/material.dart';

import '../presentation/camera_scan_screen/camera_scan_screen.dart';
import '../presentation/results_screen/results_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String cameraScanScreen = '/camera-scan-screen';
  static const String resultsScreen = '/results-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const CameraScanScreen(),
    cameraScanScreen: (context) => const CameraScanScreen(),
    resultsScreen: (context) => const ResultsScreen(),
  };
}
