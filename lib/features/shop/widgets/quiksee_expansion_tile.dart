

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';

const Duration _kExpand = Duration(milliseconds: 200);

class QuikseeExpansionTileController {

  QuikseeExpansionTileController();

  _CustomExpansionTileState? _state;

  bool get isExpanded {
    assert(_state != null);
    return _state!._isExpanded;
  }

  void expand() {
    assert(_state != null);
    if (!isExpanded) {
      _state!._toggleExpansion();
    }
  }

  void collapse() {
    assert(_state != null);
    if (isExpanded) {
      _state!._toggleExpansion();
    }
  }

  static QuikseeExpansionTileController of(BuildContext context) {
    final _CustomExpansionTileState? result = context.findAncestorStateOfType<_CustomExpansionTileState>();
    if (result != null) {
      return result._tileController;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'QuikseeExpansionTileController.of() called with a context that does not contain a QuikseeExpansionTile.',
      ),
      ErrorDescription(
        'No QuikseeExpansionTile ancestor could be found starting from the context that was passed to QuikseeExpansionTileController.of(). '
            'This usually happens when the context provided is from the same StatefulWidget as that '
            'whose build function actually creates the QuikseeExpansionTile widget being sought.',
      ),
      ErrorHint(
        'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
            'context that is "under" the QuikseeExpansionTile. For an example of this, please see the '
            'documentation for QuikseeExpansionTileController.of():\n'
            '  https://api.flutter.dev/flutter/material/QuikseeExpansionTile/of.html',
      ),
      ErrorHint(
        'A more efficient solution is to split your build function into several widgets. This '
            'introduces a new context from which you can obtain the QuikseeExpansionTile. In this solution, '
            'you would have an outer widget that creates the QuikseeExpansionTile populated by instances of '
            'your new inner widgets, and then in these inner widgets you would use QuikseeExpansionTileController.of().\n'
            'An other solution is assign a GlobalKey to the QuikseeExpansionTile, '
            'then use the key.currentState property to obtain the QuikseeExpansionTile rather than '
            'using the QuikseeExpansionTileController.of() function.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  static QuikseeExpansionTileController? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_CustomExpansionTileState>()?._tileController;
  }
}

class QuikseeExpansionTile extends StatefulWidget {

  const QuikseeExpansionTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onExpansionChanged,
    this.children = const Placeholder(),
    this.trailing,
    this.showTrailingIcon = true,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.textColor,
    this.collapsedTextColor,
    this.iconColor,
    this.collapsedIconColor,
    this.shape,
    this.collapsedShape,
    this.clipBehavior,
    this.controlAffinity,
    this.controller,
    this.dense,
    this.visualDensity,
    this.minTileHeight,
    this.enableFeedback = true,
    this.enabled = true,
    this.expansionAnimationStyle,
  }) : assert(
  expandedCrossAxisAlignment != CrossAxisAlignment.baseline,
  'CrossAxisAlignment.baseline is not supported since the expanded children '
      'are aligned in a column, not a row. Try to use another constant.',
  );

  final Widget? leading;

  final Widget title;

  final Widget? subtitle;

  final ValueChanged<bool>? onExpansionChanged;

  final Widget children;

  final Color? backgroundColor;

  final Color? collapsedBackgroundColor;

  final Widget? trailing;

  final bool showTrailingIcon;

  final bool initiallyExpanded;

  final bool maintainState;

  final EdgeInsetsGeometry? tilePadding;

  final Alignment? expandedAlignment;

  final CrossAxisAlignment? expandedCrossAxisAlignment;

  final EdgeInsetsGeometry? childrenPadding;

  final Color? iconColor;

  final Color? collapsedIconColor;

  final Color? textColor;

  final Color? collapsedTextColor;

  final ShapeBorder? shape;

  final ShapeBorder? collapsedShape;

  final Clip? clipBehavior;

  final ListTileControlAffinity? controlAffinity;

  final QuikseeExpansionTileController? controller;

  final bool? dense;

  final VisualDensity? visualDensity;

  final double? minTileHeight;

  final bool? enableFeedback;

  final bool enabled;

  final AnimationStyle? expansionAnimationStyle;

  @override
  State<QuikseeExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<QuikseeExpansionTile> with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);

  final ShapeBorderTween _borderTween = ShapeBorderTween();
  final ColorTween _headerColorTween = ColorTween();
  final ColorTween _iconColorTween = ColorTween();
  final ColorTween _backgroundColorTween = ColorTween();
  final Tween<double> _heightFactorTween = Tween<double>(begin: 0.0, end: 1.0);

  late AnimationController _animationController;
  late Animation<double> iconTurns;
  late CurvedAnimation _heightFactor;
  late Animation<ShapeBorder?> _border;
  late Animation<Color?> headerColor;
  late Animation<Color?> iconColor;
  late Animation<Color?> _backgroundColor;

  bool _isExpanded = false;
  late QuikseeExpansionTileController _tileController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: _kExpand, vsync: this);
    _heightFactor = CurvedAnimation(
      parent: _animationController.drive(_heightFactorTween),
      curve: Curves.easeIn,
    );
    iconTurns = _animationController.drive(_halfTween.chain(_easeInTween));
    _border = _animationController.drive(_borderTween.chain(_easeOutTween));
    headerColor = _animationController.drive(_headerColorTween.chain(_easeInTween));
    iconColor = _animationController.drive(_iconColorTween.chain(_easeInTween));
    _backgroundColor = _animationController.drive(_backgroundColorTween.chain(_easeOutTween));

    _isExpanded = PageStorage.maybeOf(context)?.readState(context) as bool? ?? widget.initiallyExpanded;
    if (_isExpanded) {
      _animationController.value = 1.0;
    }

    assert(widget.controller?._state == null);
    _tileController = widget.controller ?? QuikseeExpansionTileController();
    _tileController._state = this;
  }

  @override
  void dispose() {
    _tileController._state = null;
    _animationController.dispose();
    _heightFactor.dispose();
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _toggleExpansion() {
    final TextDirection textDirection = WidgetsLocalizations.of(context).textDirection;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String stateHint = _isExpanded ? localizations.expandedHint : localizations.collapsedHint;
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse().then<void>((void value) {
          if (!mounted) {
            return;
          }
          setState(() {

          });
        });
      }
      PageStorage.maybeOf(context)?.writeState(context, _isExpanded);
    });
    widget.onExpansionChanged?.call(_isExpanded);

    if (defaultTargetPlatform == TargetPlatform.iOS) {

      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 1), () {
        SemanticsService.announce(stateHint, textDirection);
        _timer?.cancel();
        _timer = null;
      });
    } else {
      SemanticsService.announce(stateHint, textDirection);
    }
  }

  void _handleTap() {
    _toggleExpansion();
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    final ThemeData theme = Theme.of(context);
    final ExpansionTileThemeData customExpansionTileTheme = ExpansionTileTheme.of(context);
    final Color backgroundColor = _backgroundColor.value ?? customExpansionTileTheme.backgroundColor ?? Colors.transparent;
    final ShapeBorder customExpansionTileBorder = _border.value ?? const Border(
      top: BorderSide(color: Colors.transparent),
      bottom: BorderSide(color: Colors.transparent),
    );
    final Clip clipBehavior = widget.clipBehavior ?? customExpansionTileTheme.clipBehavior ?? Clip.antiAlias;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String onTapHint = _isExpanded
        ? localizations.expansionTileExpandedTapHint
        : localizations.expansionTileCollapsedTapHint;
    String? semanticsHint;
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        semanticsHint = _isExpanded
            ? '${localizations.collapsedHint}\n ${localizations.expansionTileExpandedHint}'
            : '${localizations.expandedHint}\n ${localizations.expansionTileCollapsedHint}';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }

    final Decoration decoration = ShapeDecoration(
      color: backgroundColor,
      shape: customExpansionTileBorder,
    );

    final Widget tile = Padding(
      padding: decoration.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            hint: semanticsHint,
            onTapHint: onTapHint,
            child:  InkWell(
              highlightColor: Theme.of(context).primaryColor.withValues(alpha:0),
              splashColor: Theme.of(context).primaryColor.withValues(alpha:0),
              onTap: () {_handleTap();},
              child: Padding(
                padding: const EdgeInsets.only(left: Dimensions.iconSizeSmall, top: Dimensions.paddingSizeSmall, right:Dimensions.iconSizeSmall, bottom: Dimensions.paddingSizeSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      if (widget.showTrailingIcon && widget.trailing != null)
                        Transform.translate(offset: const Offset(0, -11),
                          child: SizedBox(
                          child: widget.trailing,)
                        ) else Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Theme.of(context).hintColor),
                          shape: BoxShape.circle
                        ),
                          padding: const EdgeInsets.all(Dimensions.paddingSizeVeryTiny),
                          child: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 15)
                        ),

                      const SizedBox(width: Dimensions.paddingSizeSmall,),

                      Expanded(child: SizedBox(child: widget.title)),

                    ],),

                  ],),
              ),
            ),
          ),
          ClipRect(
            child: Align(
              alignment: widget.expandedAlignment
                  ?? customExpansionTileTheme.expandedAlignment
                  ?? Alignment.center,
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
        ],
      ),
    );

    final bool isShapeProvided = widget.shape != null || customExpansionTileTheme.shape != null
        || widget.collapsedShape != null || customExpansionTileTheme.collapsedShape != null;

    if (isShapeProvided) {
      return Material(
        clipBehavior: clipBehavior,
        color: backgroundColor,
        shape: customExpansionTileBorder,
        child: tile,
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: tile,
    );
  }

  @override
  void didUpdateWidget(covariant QuikseeExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ThemeData theme = Theme.of(context);
    final ExpansionTileThemeData customExpansionTileTheme = ExpansionTileTheme.of(context);

    if (widget.collapsedShape != oldWidget.collapsedShape
        || widget.shape != oldWidget.shape) {
      _updateShapeBorder(customExpansionTileTheme, theme);
    }
    if (widget.collapsedTextColor != oldWidget.collapsedTextColor
        || widget.textColor != oldWidget.textColor) {
      _updateHeaderColor(customExpansionTileTheme, customExpansionTileTheme);
    }
    if (widget.collapsedIconColor != oldWidget.collapsedIconColor
        || widget.iconColor != oldWidget.iconColor) {
      _updateIconColor(customExpansionTileTheme, customExpansionTileTheme);
    }
    if (widget.backgroundColor != oldWidget.backgroundColor
        || widget.collapsedBackgroundColor != oldWidget.collapsedBackgroundColor) {
      _updateBackgroundColor(customExpansionTileTheme);
    }
    if (widget.expansionAnimationStyle != oldWidget.expansionAnimationStyle) {
      _updateAnimationDuration(customExpansionTileTheme);
      _updateHeightFactorCurve(customExpansionTileTheme);
    }
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    final ExpansionTileThemeData customExpansionTileTheme = ExpansionTileTheme.of(context);

    _updateAnimationDuration(customExpansionTileTheme);
    _updateShapeBorder(customExpansionTileTheme, theme);
    _updateHeaderColor(customExpansionTileTheme, customExpansionTileTheme);
    _updateIconColor(customExpansionTileTheme, customExpansionTileTheme);
    _updateBackgroundColor(customExpansionTileTheme);
    _updateHeightFactorCurve(customExpansionTileTheme);
    super.didChangeDependencies();
  }

  void _updateAnimationDuration(ExpansionTileThemeData customExpansionTileTheme) {
    _animationController.duration = widget.expansionAnimationStyle?.duration
        ?? customExpansionTileTheme.expansionAnimationStyle?.duration
        ?? _kExpand;
  }

  void _updateShapeBorder(ExpansionTileThemeData customExpansionTileTheme, ThemeData theme) {
    _borderTween
      ..begin = widget.collapsedShape
          ?? customExpansionTileTheme.collapsedShape
          ?? const Border(
            top: BorderSide(color: Colors.transparent),
            bottom: BorderSide(color: Colors.transparent),
          )
      ..end = widget.shape
          ?? customExpansionTileTheme.shape
          ?? Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha:0)),
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha:0)),
          );
  }

  void _updateHeaderColor(ExpansionTileThemeData customExpansionTileTheme, ExpansionTileThemeData defaults) {
    _headerColorTween
      ..begin = widget.collapsedTextColor
          ?? customExpansionTileTheme.collapsedTextColor
          ?? defaults.collapsedTextColor
      ..end = widget.textColor ?? customExpansionTileTheme.textColor ?? defaults.textColor;
  }

  void _updateIconColor(ExpansionTileThemeData customExpansionTileTheme, ExpansionTileThemeData defaults) {
    _iconColorTween
      ..begin = widget.collapsedIconColor
          ?? customExpansionTileTheme.collapsedIconColor
          ?? defaults.collapsedIconColor
      ..end = widget.iconColor ?? customExpansionTileTheme.iconColor ?? defaults.iconColor;
  }

  void _updateBackgroundColor(ExpansionTileThemeData customExpansionTileTheme) {
    _backgroundColorTween
      ..begin = widget.collapsedBackgroundColor ?? customExpansionTileTheme.collapsedBackgroundColor
      ..end = widget.backgroundColor ?? customExpansionTileTheme.backgroundColor;
  }

  void _updateHeightFactorCurve(ExpansionTileThemeData customExpansionTileTheme) {
    _heightFactor.curve = widget.expansionAnimationStyle?.curve
        ?? customExpansionTileTheme.expansionAnimationStyle?.curve
        ?? Curves.easeIn;
    _heightFactor.reverseCurve = widget.expansionAnimationStyle?.reverseCurve
        ?? customExpansionTileTheme.expansionAnimationStyle?.reverseCurve;
  }

  @override
  Widget build(BuildContext context) {
    final ExpansionTileThemeData customExpansionTileTheme = ExpansionTileTheme.of(context);
    final bool closed = !_isExpanded && _animationController.isDismissed;
    final bool shouldRemoveChildren = closed && !widget.maintainState;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(
        enabled: !closed,
        child: Padding(
          padding: widget.childrenPadding ?? customExpansionTileTheme.childrenPadding ?? EdgeInsets.zero,
          child: widget.children,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _animationController.view,
      builder: _buildChildren,
      child: shouldRemoveChildren ? null : result,
    );
  }
}

