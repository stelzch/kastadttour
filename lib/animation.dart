import 'package:flutter/material.dart';

Route createAnimatedRoute(Widget target, [dynamic args]) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => target,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var tween = Tween(begin: Offset(1.0, 0.0), end: Offset.zero);
      var tween2 = Tween(end: Offset(-1.0, 0.0), begin: Offset.zero);

      return SlideTransition(
        position: tween.animate(animation),
        child: SlideTransition(
            position: tween2.animate(secondaryAnimation), child: target),
      );
    },
    settings: RouteSettings(arguments: args),
  );
}
