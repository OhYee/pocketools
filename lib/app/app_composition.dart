import '../core/feedback/feedback_service.dart';
import '../core/random/random_source.dart';
import '../core/presets/preset_controller.dart';
import '../core/presets/preset_id_source.dart';
import '../core/presets/preset_repository.dart';
import '../core/session/local_string_store.dart';
import '../core/session/persistent_session_repository.dart';
import '../core/session/resilient_session_repository.dart';
import '../core/session/session_history.dart';
import '../core/session/session_id_source.dart';
import '../core/tools/session_actions.dart';
import '../core/tools/tool_registry.dart';
import 'platform/local_settings_store.dart';
import 'platform/platform_share_service.dart';
import 'platform/shared_preferences_async_store.dart';
import 'platform/system_feedback_service.dart';
import 'presentation/app_settings_controller.dart';
import 'presentation/app_warning_controller.dart';
import 'registry/default_tool_registry.dart';

final class PocketoolsComposition {
  const PocketoolsComposition({
    required this.registry,
    required this.randomSource,
    required this.sessionRepository,
    required this.historyRepository,
    required this.sessionIdSource,
    required this.settings,
    required this.sessionActions,
    required this.presets,
    required this.feedbackService,
    required this.warnings,
  });

  final ToolRegistry registry;
  final RandomSource randomSource;
  final ResilientSessionRepository sessionRepository;
  final SessionHistoryRepository historyRepository;
  final SessionIdSource sessionIdSource;
  final AppSettingsController settings;
  final SessionActionsController sessionActions;
  final PresetController presets;
  final FeedbackService feedbackService;
  final AppWarningController warnings;

  static Future<PocketoolsComposition> production({
    LocalStringStore? stringStore,
    RandomSource? randomSource,
    SessionIdSource? sessionIdSource,
    SessionTextGateway? textGateway,
    FeedbackService? feedbackService,
  }) async {
    final warnings = AppWarningController();
    final resolvedStringStore =
        stringStore ?? SharedPreferencesAsyncStringStore.pocketools();
    final settingsStore = LocalSettingsStore(store: resolvedStringStore);
    final settings = await AppSettingsController.load(
      store: settingsStore,
      onWarning: warnings.show,
    );
    final persistent = PersistentSessionRepository(store: resolvedStringStore);
    final repository = ResilientSessionRepository(
      persistentRepository: persistent,
      persistentHistory: persistent,
      historyEnabled: () => settings.historyEnabled,
      onWarning: warnings.show,
    );
    final resolvedSessionIdSource = sessionIdSource ?? SecureSessionIdSource();
    final registry = buildDefaultToolRegistry(
      sessionRepository: repository,
      sessionIdSource: resolvedSessionIdSource,
    );
    final presets = PresetController(
      registry: registry,
      repository: ResilientPresetRepository(
        persistentRepository: PersistentPresetRepository(
          store: resolvedStringStore,
        ),
        onWarning: warnings.show,
      ),
      idSource: SecurePresetIdSource(),
      onWarning: warnings.show,
    );
    await presets.load();
    final shareService = textGateway ?? PlatformShareService.system();
    final sessionActions = SessionActionsController(
      registry: registry,
      historyRepository: repository,
      textGateway: shareService,
    );
    final report = await repository.loadReport();
    if (report.issues.any(
      (issue) => issue.code == SessionLoadIssueCode.storageUnavailable,
    )) {
      warnings.show('本地存储暂时不可用；应用已启动，结果将保留在本次会话。');
    } else if (report.hasIssues) {
      warnings.show('部分本地历史无法读取，已隔离损坏或不兼容记录。');
    }
    return PocketoolsComposition(
      registry: registry,
      randomSource: randomSource ?? SecureRandomSource(),
      sessionRepository: repository,
      historyRepository: repository,
      sessionIdSource: resolvedSessionIdSource,
      settings: settings,
      sessionActions: sessionActions,
      presets: presets,
      feedbackService: feedbackService ?? const SystemFeedbackService(),
      warnings: warnings,
    );
  }
}
