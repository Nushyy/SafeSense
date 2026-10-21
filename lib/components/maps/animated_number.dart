import 'package:flutter/material.dart';

class AnimatedNumber extends StatefulWidget {

  final int value;

  const AnimatedNumber({
    super.key,
    required this.value,
  });

  @override
  State<AnimatedNumber> createState() =>
      _AnimatedNumberState();
}

class _AnimatedNumberState
    extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  late Animation<int> animation;

  @override
  void initState() {

    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    animation = IntTween(
      begin: 0,
      end: widget.value,
    ).animate(controller);

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: animation,
      builder: (_,__) {

        return Text(
          animation.value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        );
      },
    );
  }
}