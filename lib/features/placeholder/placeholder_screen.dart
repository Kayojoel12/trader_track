import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../shell/app_shell.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.titleKey});
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, kNavInset),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(context.tr(titleKey), style: Theme.of(context).textTheme.headlineSmall),
        ),
      ),
    );
  }
}
