library bottom_navy_bar;

import 'package:flutter/material.dart';
import 'package:quiksee/utill/dimensions.dart';

/// A beautiful and animated bottom navigation that paints a rounded shape
/// around its [items] to provide a wonderful look.
/// Update [selectedIndex] to change the selected item.
/// [selectedIndex] is required and must not be null.
class BottomNavBarWidget extends StatelessWidget {

  const BottomNavBarWidget({
    super.key,
    this.selectedIndex = 0,
    this.showElevation = true,
    this.iconSize = 20,
    this.backgroundColor,
    this.itemCornerRadius = 50,
    this.containerHeight = 60,
    this.animationDuration = const Duration(milliseconds: 270),
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    required this.items,
    required this.onItemSelected,
    this.curve = Curves.linear,
  }) : assert(items.length >= 2 && items.length <= 5);

  /// The selected item is index. Changing this property will change and animate
  /// the item being selected. Defaults to zero.
  final int selectedIndex;

  /// The icon size of all items. Defaults to 24.
  final double iconSize;

  /// The background color of the navigation bar. It defaults to
  /// [Theme.bottomAppBarColor] if not provided.
  final Color? backgroundColor;

  /// Whether this navigation bar should show a elevation. Defaults to true.
  final bool showElevation;

  /// Use this to change the item's animation duration. Defaults to 270ms.
  final Duration animationDuration;

  /// Defines the appearance of the buttons that are displayed in the bottom
  /// navigation bar. This should have at least two items and five at most.
  final List<BottomNavyBarItem> items;

  /// A callback that will be called when a item is pressed.
  final ValueChanged<int> onItemSelected;

  /// Defines the alignment of the items.
  /// Defaults to [MainAxisAlignment.spaceBetween].
  final MainAxisAlignment mainAxisAlignment;

  /// The [items] corner radius, if not set, it defaults to 50.
  final double itemCornerRadius;

  /// Defines the bottom navigation bar height. Defaults to 56.
  final double containerHeight;

  /// Used to configure the animation curve. Defaults to [Curves.linear].
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).bottomAppBarTheme.color??Theme.of(context).cardColor;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          if (showElevation)
            BoxShadow(
              color: Colors.black12,
              blurRadius: Dimensions.radiusSmall,
              spreadRadius: Dimensions.iconSizeSmall,
            ),
        ],
        borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.fontSizeLarge), topRight: Radius.circular(Dimensions.fontSizeLarge))
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeOverLarge, vertical: Dimensions.paddingSizeDefault),
          child: SizedBox(
            width: double.infinity,
            height: containerHeight,
            child: Row(mainAxisAlignment: mainAxisAlignment,
              children: items.map((item) {
                var index = items.indexOf(item);
                return GestureDetector(
                  onTap: () => onItemSelected(index),
                  child: _ItemWidget(
                    item: item,
                    iconSize: iconSize,
                    isSelected: index == selectedIndex,
                    backgroundColor: bgColor,
                    itemCornerRadius: itemCornerRadius,
                    animationDuration: animationDuration,
                    curve: curve,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemWidget extends StatelessWidget {
  final double iconSize;
  final bool isSelected;
  final BottomNavyBarItem item;
  final Color backgroundColor;
  final double itemCornerRadius;
  final Duration animationDuration;
  final Curve curve;

  const _ItemWidget({
    required this.item,
    required this.isSelected,
    required this.backgroundColor,
    required this.animationDuration,
    required this.itemCornerRadius,
    required this.iconSize,
    this.curve = Curves.linear,
  });

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Semantics(
      container: false,
      selected: isSelected,
      child: AnimatedContainer(
        alignment: Alignment.center,
        width: isSelected ? size.width * 0.35 : 30,
        height: 40,
        duration: animationDuration,
        curve: curve,
        decoration: BoxDecoration(
          color:
          isSelected ? item.activeColor : backgroundColor,
          borderRadius: BorderRadius.circular(itemCornerRadius),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(mainAxisSize: MainAxisSize.max,
            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              IconTheme(
                data: IconThemeData(
                  size: iconSize,
                  color: isSelected
                      ? item.activeColor.withValues(alpha:1)
                      : item.inactiveColor ?? item.activeColor,
                ),
                child: item.icon,
              ),
              if (isSelected)
                DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 10,
                    color: item.activeColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  textAlign: item.textAlign,
                  child: item.title,
                ),

            ],
          ),
        ),
      ),
    );
  }
}

/// The [BottomNavBarWidget.items] definition.
class BottomNavyBarItem {

  BottomNavyBarItem({
    required this.icon,
    required this.title,
    this.activeColor = Colors.blue,
    this.textAlign,
    this.inactiveColor,
  });

  /// Defines this item's icon which is placed in the right side of the [title].
  final Widget icon;

  /// Defines this item's title which placed in the left side of the [icon].
  final Widget title;

  /// The [icon] and [title] color defined when this item is selected. Defaults
  /// to [Colors.blue].
  final Color activeColor;

  /// The [icon] and [title] color defined when this item is not selected.
  final Color? inactiveColor;

  /// The alignment for the [title].
  /// This will take effect only if [title] it a [Text] widget.
  final TextAlign? textAlign;

}
