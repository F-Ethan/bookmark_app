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
