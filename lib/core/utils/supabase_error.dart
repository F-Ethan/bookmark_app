import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

/// Returns true when the error indicates the Supabase project is paused/archived.
bool isSupabasePaused(Object error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('project is paused') ||
      msg.contains('database is paused') ||
      msg.contains('service unavailable')) {
    return true;
  }
  if (error is PostgrestException) {
    return error.code == '503' ||
        (error.message.toLowerCase().contains('paused'));
  }
  return false;
}

/// Full-page error with a retry action, for use in an AsyncValue.error branch.
/// Standardizes what was previously a bare `Text('Error: $e')` scattered
/// across screens, with no way for the user to recover without restarting
/// the app.
class ErrorRetryView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorRetryView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 40, color: AppTheme.danger),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-page error shown when the Supabase project is archived due to inactivity.
class SupabasePausedScreen extends StatelessWidget {
  const SupabasePausedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 36,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Service Temporarily Unavailable',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The database has been paused due to inactivity. '
                  'Please reach out to us and we\'ll reactivate it right away.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'support@gamelogic.dev',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
