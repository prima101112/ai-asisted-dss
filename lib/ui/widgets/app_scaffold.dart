import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onNewChat;
  final VoidCallback? onHistoryTap;

  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.onNewChat,
    this.onHistoryTap,
  });

  String _getThemeName(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case ThemeMode.system:
        return l10n.translate('systemTheme');
      case ThemeMode.light:
        return l10n.translate('lightTheme');
      case ThemeMode.dark:
        return l10n.translate('darkTheme');
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.wb_sunny;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? l10n.translate('appTitle')),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: l10n.translate('menu'),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: actions,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withAlpha(150),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.translate('smartDss'),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Navigation items
              _DrawerItem(
                icon: Icons.add_comment_outlined,
                label: l10n.translate('newChat'),
                onTap: () {
                  Navigator.pop(context);
                  onNewChat?.call();
                },
              ),
              _DrawerItem(
                icon: Icons.history,
                label: l10n.translate('history'),
                onTap: () {
                  Navigator.pop(context);
                  onHistoryTap?.call();
                },
              ),

              const Spacer(),

              const Divider(),

              // Theme Switcher in Drawer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _getThemeIcon(themeMode),
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.translate('theme'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DropdownButton<ThemeMode>(
                      value: themeMode,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          ref.read(themeProvider.notifier).setTheme(newValue);
                        }
                      },
                      items: ThemeMode.values.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(_getThemeName(context, mode)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Language Switcher in Drawer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.translate('language'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: locale.languageCode,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          ref.read(localeProvider.notifier).setLocale(Locale(newValue));
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🇺🇸'),
                              const SizedBox(width: 8),
                              Text(l10n.translate('english')),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'id',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🇮🇩'),
                              const SizedBox(width: 8),
                              Text(l10n.translate('indonesian')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // User section at bottom
              const Divider(height: 1),
              if (user != null)
                _UserSection(user: user),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
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

class _UserSection extends ConsumerWidget {
  final dynamic user;

  const _UserSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayNameOrEmail ?? l10n.translate('user'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: l10n.translate('signOut'),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}
