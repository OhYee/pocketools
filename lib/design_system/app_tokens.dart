import 'package:flutter/material.dart';

import '../core/tools/tool_module.dart';

abstract final class AppSpacing {
  static const zero = 0.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
  static const huge = 64.0;
}

abstract final class AppRadii {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const extraLarge = 24.0;
  static const full = 999.0;
}

/// Shared elevation steps keep the physical hierarchy consistent across the
/// home catalog, tool stages, and result surfaces.
abstract final class AppElevation {
  static const none = 0.0;
  static const control = 1.0;
  static const section = 2.0;
  static const entity = 6.0;
  static const result = 4.0;
}

abstract final class AppSizes {
  static const minimumTapTarget = 48.0;
  static const navigationRail = 88.0;
  static const navigationSidebar = 240.0;
  static const contentMax = 1120.0;
  static const formColumn = 520.0;
  static const playingCardWidth = 104.0;
  static const playingCardHeight = 156.0;
  static const cardRevealTravel = 40.0;
  static const cardStackOffset = 8.0;
  static const d20CoreMobile = 176.0;
  static const d20CoreDesktop = 208.0;
  static const coinSingleSize = 160.0;
  static const coinSequenceSize = 48.0;
  static const coinDetailedRevealLimit = 10;
  static const tarotCardWidth = 144.0;
  static const tarotCardHeight = 216.0;
  static const tarotSymbolSize = 48.0;
  static const liuyaoLineWidth = 224.0;
  static const liuyaoLineThickness = 10.0;
  static const liuyaoYinGap = 20.0;
  static const liuyaoCoinSize = 48.0;
  static const liuyaoLineLift = 8.0;
  static const intentionFieldMaxLines = 3;
  static const smallPagePadding = 16.0;
  static const tabletPagePadding = 24.0;
  static const desktopPagePadding = 32.0;
  // The entity stage keeps implicit animations inside a predictable visual
  // plane. Keep the slot within the small-screen stage budget so the action
  // remains reachable without scrolling on a compact viewport.
  static const entityStageSlotHeight = 320.0;
  // Dice of different counts share one physical presentation slot. The slot
  // height is independent of the pool size so adding dice never moves the
  // controls or changes the page rhythm.
  static const dicePhysicalStageSlotHeight = 288.0;
  static const generationStateSlotHeight = 88.0;
  static const tarotRevealSlotHeight = 288.0;
}

/// Materials that must remain recognizable as physical objects in either
/// light or dark app themes.
abstract final class AppPhysicalColors {
  static const cardPaper = Color(0xFFFFFBF2);
  static const cardInk = Color(0xFF1D1B19);
  static const cardRed = Color(0xFFBA1A30);
  static const cardBorder = Color(0xFFD8CCBC);
  static const cardBackBorder = Color(0xFFE1D5C4);
}

abstract final class AppBreakpoints {
  static const tablet = 600.0;
  static const desktop = 1024.0;
  static const wide = 1440.0;
}

abstract final class AppMotionValues {
  static const buttonPressTranslation = 1.0;
  static const buttonPressScale = 0.985;
  static const cardRevealInitialScale = 0.96;
  static const cardCompleteInitialScale = 1.02;
  static const completeInitialScale = 1.02;
  static const latestCardRevealStart = 0.5;
  static const coinInitialScale = 0.94;
  static const coinLift = 48.0;
  static const coinApex = 64.0;
  static const coinSettleBounce = 2.0;
  static const coinRotationTurns = 2.0;
  static const coinPerspective = 0.001;
  static const coinLiftEnd = 0.25;
  static const coinApexProgress = 0.5;
  static const coinFlipEnd = 0.75;
  static const coinImpactProgress = 0.94;
  static const coinStreamWindow = 0.72;
  static const d20Perspective = 0.001;
  static const d20RollTurns = 1.75;
  static const d20StopProgress = 0.78;
  static const cardShuffleRotationDegrees = 2.0;
  static const cardRevealRotationDegrees = 4.0;
  static const tarotRevealTravel = 12.0;
  static const tarotRevealInitialScale = 0.96;
  static const tarotPerspective = 0.001;
  static const tarotFlipProgress = 0.5;
}

@immutable
final class AppMotionTokens extends ThemeExtension<AppMotionTokens> {
  const AppMotionTokens({
    required this.press,
    required this.reduced,
    required this.base,
    required this.complete,
    required this.generate,
    required this.tarotCard,
    required this.tarotStagger,
    required this.tarotRitual,
    required this.coinGenerate,
    required this.coinReveal,
    required this.coinLargeBatchReveal,
    required this.shuffle,
    required this.revealStagger,
    required this.reveal,
  });

  const AppMotionTokens.standard()
    : press = const Duration(milliseconds: 90),
      reduced = const Duration(milliseconds: 80),
      base = const Duration(milliseconds: 180),
      complete = const Duration(milliseconds: 240),
      generate = const Duration(milliseconds: 360),
      tarotCard = const Duration(milliseconds: 480),
      tarotStagger = const Duration(milliseconds: 80),
      tarotRitual = const Duration(milliseconds: 960),
      coinGenerate = const Duration(milliseconds: 120),
      coinReveal = const Duration(milliseconds: 720),
      coinLargeBatchReveal = const Duration(milliseconds: 200),
      shuffle = const Duration(milliseconds: 520),
      revealStagger = const Duration(milliseconds: 90),
      reveal = const Duration(milliseconds: 640);

  final Duration press;
  final Duration reduced;
  final Duration base;
  final Duration complete;
  final Duration generate;
  final Duration tarotCard;
  final Duration tarotStagger;
  final Duration tarotRitual;
  final Duration coinGenerate;
  final Duration coinReveal;
  final Duration coinLargeBatchReveal;
  final Duration shuffle;
  final Duration revealStagger;
  final Duration reveal;

  @override
  AppMotionTokens copyWith({
    Duration? press,
    Duration? reduced,
    Duration? base,
    Duration? complete,
    Duration? generate,
    Duration? tarotCard,
    Duration? tarotStagger,
    Duration? tarotRitual,
    Duration? coinGenerate,
    Duration? coinReveal,
    Duration? coinLargeBatchReveal,
    Duration? shuffle,
    Duration? revealStagger,
    Duration? reveal,
  }) => AppMotionTokens(
    press: press ?? this.press,
    reduced: reduced ?? this.reduced,
    base: base ?? this.base,
    complete: complete ?? this.complete,
    generate: generate ?? this.generate,
    tarotCard: tarotCard ?? this.tarotCard,
    tarotStagger: tarotStagger ?? this.tarotStagger,
    tarotRitual: tarotRitual ?? this.tarotRitual,
    coinGenerate: coinGenerate ?? this.coinGenerate,
    coinReveal: coinReveal ?? this.coinReveal,
    coinLargeBatchReveal: coinLargeBatchReveal ?? this.coinLargeBatchReveal,
    shuffle: shuffle ?? this.shuffle,
    revealStagger: revealStagger ?? this.revealStagger,
    reveal: reveal ?? this.reveal,
  );

  @override
  AppMotionTokens lerp(AppMotionTokens? other, double t) => this;
}

/// Theme-aware surface colors used by shared component chrome.
///
/// Semantic tool colors remain in [AppSemanticColors]. These values describe
/// the neutral canvas and the depth cues around it, so light and dark themes
/// can change together without page-level color literals.
@immutable
final class AppSurfaceTokens extends ThemeExtension<AppSurfaceTokens> {
  const AppSurfaceTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceInset,
    required this.shadow,
    required this.shadowStrong,
    required this.highlight,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceInset;
  final Color shadow;
  final Color shadowStrong;
  final Color highlight;

  static const light = AppSurfaceTokens(
    canvas: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceInset: Color(0xFFE8EBE8),
    shadow: Color(0x141B1D1F),
    shadowStrong: Color(0x241B1D1F),
    highlight: Color(0xFFFFFFFF),
  );

  static const dark = AppSurfaceTokens(
    canvas: Color(0xFF111416),
    surface: Color(0xFF181C1F),
    surfaceRaised: Color(0xFF293036),
    surfaceInset: Color(0xFF101619),
    shadow: Color(0x52000000),
    shadowStrong: Color(0x80000000),
    highlight: Color(0x334D6975),
  );

  @override
  AppSurfaceTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceInset,
    Color? shadow,
    Color? shadowStrong,
    Color? highlight,
  }) => AppSurfaceTokens(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceInset: surfaceInset ?? this.surfaceInset,
    shadow: shadow ?? this.shadow,
    shadowStrong: shadowStrong ?? this.shadowStrong,
    highlight: highlight ?? this.highlight,
  );

  @override
  AppSurfaceTokens lerp(AppSurfaceTokens? other, double t) {
    if (other == null) return this;
    return AppSurfaceTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceInset: Color.lerp(surfaceInset, other.surfaceInset, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      shadowStrong: Color.lerp(shadowStrong, other.shadowStrong, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
    );
  }
}

@immutable
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.surfaceMuted,
    required this.surfaceInset,
    required this.border,
    required this.borderStrong,
    required this.textSecondary,
    required this.success,
    required this.successSurface,
    required this.d20,
    required this.d20Surface,
    required this.tarot,
    required this.tarotAccent,
    required this.tarotSurface,
    required this.liuyao,
    required this.liuyaoSurface,
    required this.coin,
    required this.coinSurface,
    required this.cards,
    required this.cardsSurface,
    required this.tarotOnAccent,
    required this.liuyaoOnAccent,
    required this.d20OnAccent,
    required this.coinOnAccent,
    required this.cardsOnAccent,
    required this.neutral,
  });

  final Color surfaceMuted;
  final Color surfaceInset;
  final Color border;
  final Color borderStrong;
  final Color textSecondary;
  final Color success;
  final Color successSurface;
  final Color d20;
  final Color d20Surface;
  final Color tarot;
  final Color tarotAccent;
  final Color tarotSurface;
  final Color liuyao;
  final Color liuyaoSurface;
  final Color coin;
  final Color coinSurface;
  final Color cards;
  final Color cardsSurface;
  final Color tarotOnAccent;
  final Color liuyaoOnAccent;
  final Color d20OnAccent;
  final Color coinOnAccent;
  final Color cardsOnAccent;
  final Color neutral;

  static const light = AppSemanticColors(
    surfaceMuted: Color(0xFFF0F1EF),
    surfaceInset: Color(0xFFE8EBE8),
    border: Color(0xFFD6DADD),
    borderStrong: Color(0xFF9FA6AC),
    textSecondary: Color(0xFF555B61),
    success: Color(0xFF176B45),
    successSurface: Color(0xFFE8F5EE),
    d20: Color(0xFF006D82),
    d20Surface: Color(0xFFEAF6F8),
    tarot: Color(0xFF5B3A86),
    tarotAccent: Color(0xFF8A6200),
    tarotSurface: Color(0xFFF5EFFA),
    liuyao: Color(0xFF285B46),
    liuyaoSurface: Color(0xFFF5F1E7),
    coin: Color(0xFFA65B00),
    coinSurface: Color(0xFFFFF3DF),
    cards: Color(0xFFB4232A),
    cardsSurface: Color(0xFFFFF0F0),
    tarotOnAccent: Color(0xFFFFFFFF),
    liuyaoOnAccent: Color(0xFFFFFFFF),
    d20OnAccent: Color(0xFFFFFFFF),
    coinOnAccent: Color(0xFFFFFFFF),
    cardsOnAccent: Color(0xFFFFFFFF),
    neutral: Color(0xFF245E73),
  );

  static const dark = AppSemanticColors(
    surfaceMuted: Color(0xFF22282C),
    surfaceInset: Color(0xFF101619),
    border: Color(0xFF46515A),
    borderStrong: Color(0xFF697680),
    textSecondary: Color(0xFFBEC6CC),
    success: Color(0xFF72D3A3),
    successSurface: Color(0xFF173528),
    d20: Color(0xFF75D2E3),
    d20Surface: Color(0xFF172A31),
    tarot: Color(0xFFC7A9EA),
    tarotAccent: Color(0xFFE4BC63),
    tarotSurface: Color(0xFF2A2034),
    liuyao: Color(0xFF8CC9AB),
    liuyaoSurface: Color(0xFF1D2A24),
    coin: Color(0xFFF2B65D),
    coinSurface: Color(0xFF30251A),
    cards: Color(0xFFFF9CA5),
    cardsSurface: Color(0xFF321C20),
    tarotOnAccent: Color(0xFF24162F),
    liuyaoOnAccent: Color(0xFF10271D),
    d20OnAccent: Color(0xFF092A31),
    coinOnAccent: Color(0xFF30200B),
    cardsOnAccent: Color(0xFF321318),
    neutral: Color(0xFF79CBE3),
  );

  @override
  AppSemanticColors copyWith({
    Color? surfaceMuted,
    Color? surfaceInset,
    Color? border,
    Color? borderStrong,
    Color? textSecondary,
    Color? success,
    Color? successSurface,
    Color? d20,
    Color? d20Surface,
    Color? tarot,
    Color? tarotAccent,
    Color? tarotSurface,
    Color? liuyao,
    Color? liuyaoSurface,
    Color? coin,
    Color? coinSurface,
    Color? cards,
    Color? cardsSurface,
    Color? tarotOnAccent,
    Color? liuyaoOnAccent,
    Color? d20OnAccent,
    Color? coinOnAccent,
    Color? cardsOnAccent,
    Color? neutral,
  }) => AppSemanticColors(
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    surfaceInset: surfaceInset ?? this.surfaceInset,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    textSecondary: textSecondary ?? this.textSecondary,
    success: success ?? this.success,
    successSurface: successSurface ?? this.successSurface,
    d20: d20 ?? this.d20,
    d20Surface: d20Surface ?? this.d20Surface,
    tarot: tarot ?? this.tarot,
    tarotAccent: tarotAccent ?? this.tarotAccent,
    tarotSurface: tarotSurface ?? this.tarotSurface,
    liuyao: liuyao ?? this.liuyao,
    liuyaoSurface: liuyaoSurface ?? this.liuyaoSurface,
    coin: coin ?? this.coin,
    coinSurface: coinSurface ?? this.coinSurface,
    cards: cards ?? this.cards,
    cardsSurface: cardsSurface ?? this.cardsSurface,
    tarotOnAccent: tarotOnAccent ?? this.tarotOnAccent,
    liuyaoOnAccent: liuyaoOnAccent ?? this.liuyaoOnAccent,
    d20OnAccent: d20OnAccent ?? this.d20OnAccent,
    coinOnAccent: coinOnAccent ?? this.coinOnAccent,
    cardsOnAccent: cardsOnAccent ?? this.cardsOnAccent,
    neutral: neutral ?? this.neutral,
  );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceInset: Color.lerp(surfaceInset, other.surfaceInset, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      d20: Color.lerp(d20, other.d20, t)!,
      d20Surface: Color.lerp(d20Surface, other.d20Surface, t)!,
      tarot: Color.lerp(tarot, other.tarot, t)!,
      tarotAccent: Color.lerp(tarotAccent, other.tarotAccent, t)!,
      tarotSurface: Color.lerp(tarotSurface, other.tarotSurface, t)!,
      liuyao: Color.lerp(liuyao, other.liuyao, t)!,
      liuyaoSurface: Color.lerp(liuyaoSurface, other.liuyaoSurface, t)!,
      coin: Color.lerp(coin, other.coin, t)!,
      coinSurface: Color.lerp(coinSurface, other.coinSurface, t)!,
      cards: Color.lerp(cards, other.cards, t)!,
      cardsSurface: Color.lerp(cardsSurface, other.cardsSurface, t)!,
      tarotOnAccent: Color.lerp(tarotOnAccent, other.tarotOnAccent, t)!,
      liuyaoOnAccent: Color.lerp(liuyaoOnAccent, other.liuyaoOnAccent, t)!,
      d20OnAccent: Color.lerp(d20OnAccent, other.d20OnAccent, t)!,
      coinOnAccent: Color.lerp(coinOnAccent, other.coinOnAccent, t)!,
      cardsOnAccent: Color.lerp(cardsOnAccent, other.cardsOnAccent, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }

  Color accentFor(ToolAccent accent) => switch (accent) {
    ToolAccent.tarot => tarot,
    ToolAccent.liuyao => liuyao,
    ToolAccent.d20 => d20,
    ToolAccent.coin => coin,
    ToolAccent.cards => cards,
    ToolAccent.neutral => neutral,
  };

  Color accentSurfaceFor(ToolAccent accent) => switch (accent) {
    ToolAccent.tarot => tarotSurface,
    ToolAccent.cards => cardsSurface,
    ToolAccent.d20 => d20Surface,
    ToolAccent.coin => coinSurface,
    ToolAccent.liuyao => liuyaoSurface,
    _ => surfaceMuted,
  };

  Color onAccentFor(ToolAccent accent) => switch (accent) {
    ToolAccent.tarot => tarotOnAccent,
    ToolAccent.liuyao => liuyaoOnAccent,
    ToolAccent.d20 => d20OnAccent,
    ToolAccent.coin => coinOnAccent,
    ToolAccent.cards => cardsOnAccent,
    ToolAccent.neutral => neutral,
  };
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get appColors =>
      Theme.of(this).extension<AppSemanticColors>()!;

  AppMotionTokens get appMotion => Theme.of(this).extension<AppMotionTokens>()!;

  AppSurfaceTokens get appSurfaces =>
      Theme.of(this).extension<AppSurfaceTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppSurfaceTokens.dark
          : AppSurfaceTokens.light);
}
