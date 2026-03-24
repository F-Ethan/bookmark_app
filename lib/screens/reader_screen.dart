import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/appearance_provider.dart';
import '../providers/reading_plan_provider.dart';
import '../providers/translation_provider.dart';
import '../services/bible_service.dart';

// ── Args passed via go_router extra ───────────────────────────────────────────

class ReaderArgs {
  final List<String> dayChapters;
  final int initialIndex;
  final int readingDay;

  const ReaderArgs({
    required this.dayChapters,
    required this.initialIndex,
    required this.readingDay,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class ReaderScreen extends ConsumerStatefulWidget {
  final ReaderArgs args;

  const ReaderScreen({super.key, required this.args});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late int _index;
  final _scrollController = ScrollController();
  bool _downloading = false;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _index = widget.args.initialIndex;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get _chapterRef => widget.args.dayChapters[_index];
  bool get _isLast => _index == widget.args.dayChapters.length - 1;

  (String book, int chapter) get _parsed {
    final parts = _chapterRef.trim().split(' ');
    final chapter = int.tryParse(parts.last) ?? 1;
    final book = parts.sublist(0, parts.length - 1).join(' ');
    return (book, chapter);
  }

  List<String> _verses(String translation) {
    if (!BibleService.instance.isLoaded) return [];
    final (book, chapter) = _parsed;
    return BibleService.instance.getChapter(book, chapter);
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _nextChapter() {
    setState(() => _index++);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _markDayAsRead() async {
    final plan = ref.read(readingPlanProvider).valueOrNull;
    if (plan == null) return;
    if (widget.args.readingDay >= plan.currentDay) {
      await ref
          .read(readingPlanProvider.notifier)
          .setCurrentDay(widget.args.readingDay + 1);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _switchTranslation(String translation) async {
    setState(() {
      _downloading = true;
      _downloadError = null;
    });
    try {
      await ref.read(translationProvider.notifier).setTranslation(translation);
    } catch (_) {
      if (mounted) {
        setState(() => _downloadError = 'Download failed. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final translation = ref.watch(translationProvider);
    final appearance = ref.watch(appearanceProvider);
    final plan = ref.watch(readingPlanProvider).valueOrNull;
    final alreadyRead = plan != null &&
        widget.args.readingDay < plan.currentDay;
    final verses = _verses(translation);

    return Scaffold(
      appBar: AppBar(
        title: Text(_chapterRef),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _TranslationButton(
              current: translation,
              onSwitch: _switchTranslation,
            ),
          ),
        ],
      ),
      body: _downloading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Downloading translation…'),
                ],
              ),
            )
          : _downloadError != null
              ? _ErrorView(
                  message: _downloadError!,
                  onRetry: () => _switchTranslation(translation),
                )
              : verses.isEmpty
                  ? const Center(child: Text('No content available.'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      itemCount: verses.length,
                      itemBuilder: (context, i) => Padding(
                        padding: EdgeInsets.only(
                            bottom: appearance.lineHeight * 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${i + 1}',
                                style: appearance.readerTextStyle(
                                  size: appearance.fontSize * 0.75,
                                ).copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                verses[i],
                                textAlign: appearance.textAlign,
                                style: appearance.readerTextStyle(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

      // ── Bottom bar ───────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          child: _isLast
              ? FilledButton.icon(
                  onPressed: alreadyRead ? () => Navigator.of(context).pop() : _markDayAsRead,
                  icon: Icon(alreadyRead
                      ? Icons.check_circle_outline_rounded
                      : Icons.check_circle_rounded),
                  label: Text(alreadyRead ? 'Done' : 'Mark Day as Read'),
                )
              : FilledButton.icon(
                  onPressed: _downloading ? null : _nextChapter,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    'Next: ${widget.args.dayChapters[_index + 1]}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Translation button ─────────────────────────────────────────────────────────

class _TranslationButton extends ConsumerWidget {
  final String current;
  final Future<void> Function(String) onSwitch;

  const _TranslationButton({required this.current, required this.onSwitch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded,
                color: AppTheme.primary, size: 16),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TranslationSheet(
        current: current,
        onSwitch: onSwitch,
      ),
    );
  }
}

// ── Translation bottom sheet ───────────────────────────────────────────────────

class _TranslationSheet extends ConsumerStatefulWidget {
  final String current;
  final Future<void> Function(String) onSwitch;

  const _TranslationSheet({
    required this.current,
    required this.onSwitch,
  });

  @override
  ConsumerState<_TranslationSheet> createState() => _TranslationSheetState();
}

class _TranslationSheetState extends ConsumerState<_TranslationSheet> {
  // translation key → is downloaded
  Map<String, bool> _downloaded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final statuses = <String, bool>{};
    for (final key in translationLabels.keys) {
      statuses[key] = await BibleService.instance.isTranslationDownloaded(key);
    }
    if (mounted) setState(() {
      _downloaded = statuses;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Translation',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Keep as many as you like',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ...translationLabels.entries.map((entry) {
              final key = entry.key;
              final isActive = key == widget.current;
              final isDownloaded = _downloaded[key] ?? false;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppTheme.primary : null,
                  ),
                ),
                subtitle: Text(
                  isActive
                      ? 'Active'
                      : isDownloaded
                          ? 'Downloaded'
                          : 'Tap to download',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive
                        ? AppTheme.primary.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                  ),
                ),
                leading: Icon(
                  isActive
                      ? Icons.check_circle_rounded
                      : isDownloaded
                          ? Icons.offline_pin_rounded
                          : Icons.download_rounded,
                  color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                ),
                trailing: isDownloaded && !isActive && key != 'kjv'
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.danger, size: 20),
                        tooltip: 'Remove download',
                        onPressed: () async {
                          await ref
                              .read(translationProvider.notifier)
                              .deleteTranslation(key);
                          setState(() => _downloaded[key] = false);
                        },
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  widget.onSwitch(key);
                },
              );
            }),
        ],
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
