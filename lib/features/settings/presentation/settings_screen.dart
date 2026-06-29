import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/settings_provider.dart';

class _CurrencySelectorSheet extends ConsumerStatefulWidget {
  const _CurrencySelectorSheet();

  @override
  ConsumerState<_CurrencySelectorSheet> createState() => _CurrencySelectorSheetState();
}

class _CurrencySelectorSheetState extends ConsumerState<_CurrencySelectorSheet> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _allCurrencies = [
    'USD (\$)', 'EUR (€)', 'GBP (£)', 'PKR (₨)',
    'INR (₹)', 'JPY (¥)', 'AUD (\$)', 'CAD (\$)',
    'CHF (CHF)', 'CNY (¥)', 'SEK (kr)', 'NZD (\$)'
  ];

  List<String> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = _allCurrencies;
    _searchController.addListener(_filterCurrencies);
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = _allCurrencies.where((c) => c.toLowerCase().contains(query)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16.0),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Text('Select Currency', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24.0),
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  return ListTile(
                    title: Text(
                        currency,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)
                    ),
                    onTap: () {
                      ref.read(currencyProvider.notifier).updateCurrency(currency);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Personal Info', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              try {
                final userId = Supabase.instance.client.auth.currentUser!.id;
                await Supabase.instance.client
                    .from('profiles')
                    .update({'full_name': newName})
                    .eq('id', userId);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showCurrencySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CurrencySelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final isDarkModeToggle = ref.watch(darkModeProvider);
    final hasNotifications = ref.watch(notificationsProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final currentBudget = ref.watch(budgetProvider);

    final profileAsync = ref.watch(profileProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final fallbackEmail = currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
          onPressed: () {},
        ),
        title: Text('FinTrack', style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 24, letterSpacing: -0.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_outlined, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? LinearGradient(colors: [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surfaceContainerHighest])
                  : const LinearGradient(
                colors: [Color(0xFFC9F0D8), Color(0xFFE4F9EC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40.0),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: profileAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => const Text('Failed to load profile'),
                    data: (profile) {
                      final displayName = profile['full_name'] as String? ?? 'User';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? theme.colorScheme.onSurface : const Color(0xFF191C1D),
                            ),
                          ),
                          Text(
                            fallbackEmail,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDarkMode ? theme.colorScheme.onSurfaceVariant : const Color(0xFF3D4A3E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: isDarkMode ? 0.3 : 0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Pro Member',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text('ACCOUNT & SYNC', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
              side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    child: Icon(Icons.cloud_sync, color: theme.colorScheme.secondary),
                  ),
                  title: const Text('Cloud Sync', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Last synced: Just now'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Active', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing data securely to cloud...')));
                  },
                ),
                Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.05), indent: 24, endIndent: 24),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
                    child: Icon(Icons.manage_accounts, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  title: const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    final currentName = profileAsync.value?['full_name'] as String? ?? '';
                    _showEditProfileDialog(context, currentName);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text('PREFERENCES', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
              side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
                    child: Icon(Icons.dark_mode, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: Switch(
                    value: isDarkModeToggle,
                    activeThumbColor: Colors.white,
                    activeTrackColor: theme.colorScheme.primary,
                    onChanged: (value) => ref.read(darkModeProvider.notifier).toggle(value),
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.05), indent: 24, endIndent: 24),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
                    child: Icon(Icons.payments, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  title: const Text('Default Currency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currentCurrency, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () => _showCurrencySelector(context),
                ),
                Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.05), indent: 24, endIndent: 24),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
                    child: Icon(Icons.account_balance_wallet, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  title: const Text('Daily Budget Limit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${currentBudget.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    final controller = TextEditingController(text: currentBudget.toInt().toString());
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Set Daily Budget'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(prefixText: '\$ '),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          FilledButton(
                            onPressed: () {
                              final newBudget = double.tryParse(controller.text) ?? 200.0;
                              ref.read(budgetProvider.notifier).updateBudget(newBudget);
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.05), indent: 24, endIndent: 24),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.3 : 0.5),
                    child: Icon(Icons.notifications_active, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  trailing: Switch(
                    value: hasNotifications,
                    activeThumbColor: Colors.white,
                    activeTrackColor: theme.colorScheme.primary,
                    onChanged: (value) => ref.read(notificationsProvider.notifier).toggle(value),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text('DANGER ZONE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.error)),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            color: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100.0),
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                child: Icon(Icons.logout, color: theme.colorScheme.error),
              ),
              title: Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.error, fontSize: 16)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
              },
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}