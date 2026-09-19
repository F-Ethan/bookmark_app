import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/supporter.dart';
import '../services/supabase_service.dart';

class SupportersScreen extends StatefulWidget {
  const SupportersScreen({super.key});

  @override
  State<SupportersScreen> createState() => _SupportersScreenState();
}

class _SupportersScreenState extends State<SupportersScreen> {
  late final Future<List<Supporter>> _future = SupabaseService.fetchSupporters();
  final _emailTapRecognizer = TapGestureRecognizer()
    ..onTap = () => launchUrl(
          Uri(
            scheme: 'mailto',
            path: AppConstants.supporterContactEmail,
            query: 'subject=Supporting Bookmark',
          ),
        );

  @override
  void dispose() {
    _emailTapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supporters'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: _DeveloperNote(emailTapRecognizer: _emailTapRecognizer),
          ),
          Expanded(
            child: FutureBuilder<List<Supporter>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const _SupportersMessage(
                    text: 'Could not load supporters. Check your connection.',
                  );
                }
                final supporters = snapshot.data ?? [];
                if (supporters.isEmpty) {
                  return const _SupportersMessage(
                    text: 'No supporters listed yet — be the first!',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  itemCount: supporters.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _SupporterTile(supporter: supporters[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A personal note from the developer — this app has no Patreon/paid tier
/// yet, so this is currently the only way anyone finds out they *can*
/// support it.
class _DeveloperNote extends StatelessWidget {
  final TapGestureRecognizer emailTapRecognizer;
  const _DeveloperNote({required this.emailTapRecognizer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 8),
              Text(
                'A note from Ethan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
              children: [
                const TextSpan(
                  text: 'Bookmark is a personal project I built and maintain '
                      "myself — thank you for using it! If you'd like to "
                      'support my work, reach out at ',
                ),
                TextSpan(
                  text: AppConstants.supporterContactEmail,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: emailTapRecognizer,
                ),
                const TextSpan(text: " and I'll add you here."),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportersMessage extends StatelessWidget {
  final String text;
  const _SupportersMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _SupporterTile extends StatelessWidget {
  final Supporter supporter;
  const _SupporterTile({required this.supporter});

  @override
  Widget build(BuildContext context) {
    final hasLink = (supporter.linkUrl ?? '').isNotEmpty;
    return GestureDetector(
      onTap: hasLink
          ? () => launchUrl(Uri.parse(supporter.linkUrl!),
              mode: LaunchMode.externalApplication)
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _SupporterAvatar(supporter: supporter),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supporter.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if ((supporter.tier ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      supporter.tier!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (hasLink)
              const Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SupporterAvatar extends StatelessWidget {
  final Supporter supporter;
  const _SupporterAvatar({required this.supporter});

  @override
  Widget build(BuildContext context) {
    final logoUrl = supporter.logoUrl;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          logoUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _InitialAvatar(name: supporter.displayName),
        ),
      );
    }
    return _InitialAvatar(name: supporter.displayName);
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;
  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          initial,
          style:
              const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
