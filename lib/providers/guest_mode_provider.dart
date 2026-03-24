import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final guestModeProvider = StateProvider<bool>((ref) => false);

/// Persist guest mode and update the provider state.
Future<void> enterGuestMode(StateController<bool> notifier) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('guest_mode', true);
  notifier.state = true;
}

Future<void> exitGuestMode(StateController<bool> notifier) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('guest_mode', false);
  notifier.state = false;
}
