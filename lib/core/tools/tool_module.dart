import 'package:flutter/material.dart';

import '../feedback/feedback_service.dart';
import '../random/random_source.dart';
import '../session/session.dart';
import 'session_actions.dart';
import 'tool_capabilities.dart';

enum ToolAccent { tarot, liuyao, d20, coin, cards, neutral }

enum ToolAvailability { available, designInProgress }

@immutable
final class ToolDescriptor {
  const ToolDescriptor({
    required this.id,
    required this.name,
    required this.description,
    required this.route,
    required this.icon,
    required this.accent,
    this.availability = ToolAvailability.available,
  });

  final String id;
  final String name;
  final String description;
  final String route;
  final IconData icon;
  final ToolAccent accent;
  final ToolAvailability availability;
}

/// Runtime capabilities supplied by the app without coupling a feature to it.
@immutable
final class ToolModuleContext {
  const ToolModuleContext({
    required this.randomSource,
    required this.feedbackService,
    required this.reduceMotion,
    required this.feedbackEnabled,
    this.launchRequest,
    this.sessionActions,
    this.onBack,
  });

  final RandomSource randomSource;
  final FeedbackService feedbackService;
  final bool reduceMotion;
  final bool feedbackEnabled;
  final ToolLaunchRequest? launchRequest;
  final SessionActionsController? sessionActions;
  final VoidCallback? onBack;
}

/// Presentation adapter registered with the app shell.
abstract interface class ToolModule {
  ToolDescriptor get descriptor;

  ToolSessionCodec get sessionCodec;

  Widget buildConfig(BuildContext context, ToolModuleContext moduleContext);
}
