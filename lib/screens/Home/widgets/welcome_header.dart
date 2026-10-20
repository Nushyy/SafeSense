import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key, this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final firstName = (name ?? '').trim().split(' ').first;

    return Text(
      firstName.isEmpty ? 'Welcome' : 'Welcome, $firstName',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19),
    );
  }
}