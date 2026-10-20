import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/presentation/blocs/auth/auth_cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthCubit>().state.user;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainer,
        title: Text(l10n.appName),
        actions: [
          IconButton(
            tooltip: l10n.actionSignOut,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await context.read<AuthCubit>().signOut();
              messenger.hideCurrentSnackBar();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.dashboardSignedIn,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? l10n.dashboardUser,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              if (user?.storeName != null && user!.storeName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.dashboardStore(user.storeName!),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                l10n.dashboardNextStep,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
