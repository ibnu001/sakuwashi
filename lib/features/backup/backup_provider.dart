import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple provider that can be invalidated to trigger refresh
/// after restore operations.
final backupRefreshProvider = StateProvider<int>((ref) => 0);
