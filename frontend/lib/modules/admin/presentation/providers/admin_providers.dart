import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which admin section is open (drawer / rail / sidebar selection).
final adminActiveNavIndexProvider = StateProvider<int>((ref) => 0);
