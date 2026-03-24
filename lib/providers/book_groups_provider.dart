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

  Future<void> addGroup(BibleGroup group) async {
    final current = List<BibleGroup>.from(state.valueOrNull ?? []);
    current.add(group);
    state = AsyncData(current);
    await _save(current);
  }

  Future<void> updateGroup(int index, BibleGroup group) async {
    final current = List<BibleGroup>.from(state.valueOrNull ?? []);
    current[index] = group;
    state = AsyncData(current);
    await _save(current);
  }

  Future<void> removeGroup(int index) async {
    final current = List<BibleGroup>.from(state.valueOrNull ?? []);
    current.removeAt(index);
    state = AsyncData(current);
    await _save(current);
  }

  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    final current = List<BibleGroup>.from(state.valueOrNull ?? []);
    if (newIndex > oldIndex) newIndex--;
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    state = AsyncData(current);
    await _save(current);
  }

  Future<void> setGroups(List<BibleGroup> groups) async {
    state = AsyncData(List.from(groups));
    await _save(groups);
  }

  Future<void> resetToDefaults() async {
    final defaults = List<BibleGroup>.from(defaultBookGroups);
    state = AsyncData(defaults);
    if (ref.read(guestModeProvider)) {
      await LocalDataService.saveBookGroups(defaults);
    } else {
      await SupabaseService.saveBookGroups([]);
    }
  }
}

final bookGroupsProvider =
    AsyncNotifierProvider<BookGroupsNotifier, List<BibleGroup>>(
  BookGroupsNotifier.new,
);
