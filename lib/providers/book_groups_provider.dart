import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_group.dart';
import '../data/bible_sections.dart';
import '../services/supabase_service.dart';
import '../services/local_data_service.dart';
import 'auth_provider.dart';
import 'guest_mode_provider.dart';

class BookGroupsNotifier extends AsyncNotifier<List<BibleGroup>> {
  @override
  Future<List<BibleGroup>> build() async {
    final isGuest = ref.watch(guestModeProvider);
    if (isGuest) return LocalDataService.fetchBookGroups();
    final user = ref.watch(currentUserProvider);
    if (user == null) return List.from(defaultBookGroups);
    final groups = await SupabaseService.fetchBookGroups();
    return groups.isNotEmpty ? groups : List.from(defaultBookGroups);
  }

  Future<void> _save(List<BibleGroup> groups) async {
    if (ref.read(guestModeProvider)) {
      await LocalDataService.saveBookGroups(groups);
    } else {
      await SupabaseService.saveBookGroups(groups);
    }
  }

  /// Applies [next] optimistically, persists it, and rolls back to
  /// [previous] (rethrowing) if the write fails — so a dropped connection
  /// or rejected write doesn't leave the UI showing an edit that was never
  /// actually saved.
  Future<void> _applyAndSave(
    List<BibleGroup> previous,
    List<BibleGroup> next,
  ) async {
    state = AsyncData(next);
    try {
      await _save(next);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> addGroup(BibleGroup group) async {
    final previous = List<BibleGroup>.from(state.valueOrNull ?? []);
    final next = List<BibleGroup>.from(previous)..add(group);
    await _applyAndSave(previous, next);
  }

  Future<void> updateGroup(int index, BibleGroup group) async {
    final previous = List<BibleGroup>.from(state.valueOrNull ?? []);
    final next = List<BibleGroup>.from(previous)..[index] = group;
    await _applyAndSave(previous, next);
  }

  Future<void> removeGroup(int index) async {
    final previous = List<BibleGroup>.from(state.valueOrNull ?? []);
    final next = List<BibleGroup>.from(previous)..removeAt(index);
    await _applyAndSave(previous, next);
  }

  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    final previous = List<BibleGroup>.from(state.valueOrNull ?? []);
    if (newIndex > oldIndex) newIndex--;
    final next = List<BibleGroup>.from(previous);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    await _applyAndSave(previous, next);
  }

  Future<void> setGroups(List<BibleGroup> groups) async {
    final previous = List<BibleGroup>.from(state.valueOrNull ?? []);
    await _applyAndSave(previous, List<BibleGroup>.from(groups));
  }

  Future<void> resetToDefaults() async {
    final previous = List<BibleGroup>.from(state.valueOrNull ?? []);
    final defaults = List<BibleGroup>.from(defaultBookGroups);
    // Always persist the actual defaults (not an empty row) so the stored
    // data reflects what's displayed rather than relying on build()'s
    // empty-list fallback to infer it.
    await _applyAndSave(previous, defaults);
  }
}

final bookGroupsProvider =
    AsyncNotifierProvider<BookGroupsNotifier, List<BibleGroup>>(
  BookGroupsNotifier.new,
);
