import 'package:flutter/widgets.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// The three layouts of the cashier home: phone, landscape tablet (options
/// side by side and the quick sale next to its label) and portrait tablet
/// (options side by side, the quick sale below its label).
enum PosHomeVariant {
  phone,
  tabletLandscape,
  tabletPortrait;

  /// Picks the layout from the window [size] (a tablet is 600 dp or more on its
  /// shorter side, as in [AppLayout.isTablet]).
  static PosHomeVariant fromSize(Size size) {
    if (size.shortestSide < AppLayout.tabletBreakpoint) return phone;
    return size.width > size.height ? tabletLandscape : tabletPortrait;
  }

  bool get isTablet => this != phone;
}

/// Measures of the cashier home taken from the design, per [PosHomeVariant].
class PosHomeMetrics {
  const PosHomeMetrics._({
    required this.variant,
    required this.greetingScale,
    required this.titleSize,
    required this.subtitleSize,
    required this.cardHeight,
    required this.cardRadius,
    required this.cardGap,
    required this.cardPadding,
    required this.iconBox,
    required this.iconRadius,
    required this.iconSize,
    required this.iconGap,
    required this.optionTitleSize,
    required this.optionSubtitleSize,
    required this.labelSize,
    required this.buttonHeight,
    required this.buttonPadding,
    required this.buttonTextSize,
    required this.buttonIconSize,
    required this.gridMaxWidth,
    required this.sideMargin,
    required this.bottomMargin,
    required this.shadowAlpha,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  factory PosHomeMetrics.of(PosHomeVariant variant) => switch (variant) {
    PosHomeVariant.phone => _phone,
    PosHomeVariant.tabletLandscape => _tabletLandscape,
    PosHomeVariant.tabletPortrait => _tabletPortrait,
  };

  static const PosHomeMetrics _phone = PosHomeMetrics._(
    variant: PosHomeVariant.phone,
    greetingScale: 1,
    titleSize: 23,
    subtitleSize: 15,
    cardHeight: 132,
    cardRadius: AppRadius.xl,
    cardGap: AppSpacing.block,
    cardPadding: 20,
    iconBox: 76,
    iconRadius: AppRadius.card,
    iconSize: 42,
    iconGap: 18,
    optionTitleSize: 20,
    optionSubtitleSize: 14,
    labelSize: 13.5,
    buttonHeight: 60,
    buttonPadding: AppSpacing.xxl,
    buttonTextSize: 18,
    buttonIconSize: 22,
    gridMaxWidth: double.infinity,
    sideMargin: AppSpacing.page,
    bottomMargin: AppSpacing.xxl,
    shadowAlpha: 0.06,
    shadowBlur: 18,
    shadowOffset: 6,
  );

  static const PosHomeMetrics _tabletLandscape = PosHomeMetrics._(
    variant: PosHomeVariant.tabletLandscape,
    greetingScale: 1.2,
    titleSize: 30,
    subtitleSize: 17,
    cardHeight: 300,
    cardRadius: AppRadius.xxl,
    cardGap: AppSpacing.xl,
    cardPadding: 28,
    iconBox: 112,
    iconRadius: AppRadius.xxl,
    iconSize: 62,
    iconGap: 18,
    optionTitleSize: 24,
    optionSubtitleSize: 16,
    labelSize: 16,
    buttonHeight: 64,
    buttonPadding: 36,
    buttonTextSize: 19,
    buttonIconSize: 24,
    gridMaxWidth: 760,
    sideMargin: AppSpacing.pageWide,
    bottomMargin: 56,
    shadowAlpha: 0.07,
    shadowBlur: 22,
    shadowOffset: 8,
  );

  static const PosHomeMetrics _tabletPortrait = PosHomeMetrics._(
    variant: PosHomeVariant.tabletPortrait,
    greetingScale: 1.2,
    titleSize: 32,
    subtitleSize: 18,
    cardHeight: 360,
    cardRadius: AppRadius.xxl,
    cardGap: AppSpacing.xl,
    cardPadding: 28,
    iconBox: 124,
    iconRadius: AppRadius.iconXl,
    iconSize: 68,
    iconGap: 20,
    optionTitleSize: 25,
    optionSubtitleSize: 16,
    labelSize: 16,
    buttonHeight: 64,
    buttonPadding: 40,
    buttonTextSize: 19,
    buttonIconSize: 24,
    gridMaxWidth: double.infinity,
    sideMargin: AppSpacing.pageWide,
    bottomMargin: 80,
    shadowAlpha: 0.07,
    shadowBlur: 22,
    shadowOffset: 8,
  );

  final PosHomeVariant variant;
  final double greetingScale;
  final double titleSize;
  final double subtitleSize;

  /// Height of an option card on a tablet; the minimum height on a phone.
  final double cardHeight;
  final double cardRadius;
  final double cardGap;
  final double cardPadding;
  final double iconBox;
  final double iconRadius;
  final double iconSize;

  /// Space between the icon and the text of an option card.
  final double iconGap;
  final double optionTitleSize;
  final double optionSubtitleSize;
  final double labelSize;
  final double buttonHeight;
  final double buttonPadding;
  final double buttonTextSize;
  final double buttonIconSize;
  final double gridMaxWidth;
  final double sideMargin;
  final double bottomMargin;
  final double shadowAlpha;
  final double shadowBlur;
  final double shadowOffset;

  /// Option cards side by side with the icon above the text (tablet), or one
  /// under the other with the icon at the left (phone).
  bool get stacked => variant.isTablet;

  /// The quick sale button sits next to its label (landscape tablet only).
  bool get quickSaleInline => variant == PosHomeVariant.tabletLandscape;

  /// Distance between the header and the title of a phone.
  static const double phoneTitleTop = 48;
}
