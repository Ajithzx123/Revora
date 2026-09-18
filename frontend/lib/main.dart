import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'init/app_initializer.dart';

void main() async {
  await AppInitializer.initialize();

  runApp(
    const ProviderScope(
      child: RevoraApp(),
    ),
  );
}
