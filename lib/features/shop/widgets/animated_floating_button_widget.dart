
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class ScrollingFabAnimated extends StatefulWidget {

  final GestureTapCallback onPress;

  final double elevation;

  final double width;

  final double height;

  final Duration duration;

  final Widget icon;

  final Widget text;

  final Curve? curve;

  final ScrollController scrollController;

  final double limitIndicator;

  final Color? color;

  final bool animateIcon;

  final bool inverted;

  final double? radius;

  const ScrollingFabAnimated(
      {super.key,
        required this.icon,
        required this.text,
        required this.onPress,
        required this.scrollController,
        this.elevation = 5.0,
        this.width = 120.0,
        this.height = 60.0,
        this.duration = const Duration(milliseconds: 250),
        this.curve,
        this.limitIndicator = 10.0,
        this.color,
        this.animateIcon = true,
        this.inverted = false,
        this.radius});

  @override
  ScrollingFabAnimatedState createState() => ScrollingFabAnimatedState();
}

class ScrollingFabAnimatedState extends State<ScrollingFabAnimated> {

  double _endTween = 100;

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
    if (widget.inverted) {
      setState(() {
        _endTween = 0;
      });
    }
    _handleScroll();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(() {});
    super.dispose();
  }

  void _handleScroll() {
    ScrollController scrollController = widget.scrollController;
    scrollController.addListener(() {
      if (scrollController.position.pixels > widget.limitIndicator &&
          scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
        setState(() {
          _endTween = widget.inverted ? 100 : 0;
        });
      } else if (scrollController.position.pixels <= widget.limitIndicator &&
          scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        setState(() {
          _endTween = widget.inverted ? 0 : 100;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        boxShadow: ThemeShadow.getShadow(context)
      ),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: _endTween),
        duration: widget.duration,
        builder: (BuildContext _, double size, Widget? child) {
          double widthPercent = (widget.width - widget.height).abs() / 100;
          bool isFull = _endTween == 100;
          double radius = widget.radius ?? (widget.height / 2);
          return Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                color: widget.color ?? Theme.of(context).primaryColor),
            height: widget.height,
            width: widget.height + widthPercent * size,
            child: InkWell(
              onTap: widget.onPress,
              child: Ink(
                child: Row(
                  mainAxisAlignment: isFull
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
                  children: [

                    ...(isFull
                        ? [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: AnimatedOpacity(
                            opacity: size > 90 ? 1 : 0,
                            duration: const Duration(milliseconds: 100),
                            child: widget.text,
                          ),
                        ),
                      )
                    ]
                        : []),

                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Transform.rotate(
                          angle: widget.animateIcon
                              ? (3.6 * math.pi / 180) * size
                              : 0,
                          child: widget.icon,
                        )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
