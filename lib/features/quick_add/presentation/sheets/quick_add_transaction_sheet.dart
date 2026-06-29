import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/transaction_service.dart';

class QuickAddTransactionSheet extends StatefulWidget {
  const QuickAddTransactionSheet({super.key});

  @override
  State<QuickAddTransactionSheet> createState() =>
      _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState extends State<QuickAddTransactionSheet> {
  String _amountString = "0";
  bool _hasDecimal = false;
  String _transactionType = "expense";
  int _selectedCategoryId = 1;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Food', 'icon': Icons.restaurant},
    {'id': 2, 'name': 'Transport', 'icon': Icons.directions_car},
    {'id': 3, 'name': 'Groceries', 'icon': Icons.shopping_cart},
    {'id': 4, 'name': 'Fun', 'icon': Icons.sports_esports},
  ];

  void _onKeyPress(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_amountString == "0" && value != ".") {
        _amountString = value;
      } else {
        if (value == "." && _hasDecimal) return;
        if (value == ".") _hasDecimal = true;
        if (_hasDecimal &&
            _amountString.split('.').length > 1 &&
            _amountString.split('.')[1].length >= 2)
          return;
        if (_amountString.length > 9) return;
        _amountString += value;
      }
    });
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_amountString.length > 1) {
        if (_amountString.endsWith('.')) _hasDecimal = false;
        _amountString = _amountString.substring(0, _amountString.length - 1);
      } else {
        _amountString = "0";
        _hasDecimal = false;
      }
    });
  }

  Future<void> _handleSave() async {
    final parsedAmount = double.tryParse(_amountString) ?? 0.0;

    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be greater than 0')));
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await TransactionService.saveTransaction(
        amount: parsedAmount,
        type: _transactionType,
        categoryId: _selectedCategoryId,
        note: _noteController.text,
      );

      // If it reaches this line, the save was successful!
      if (mounted) Navigator.pop(context);

    } catch (e) {
      // THIS WAS MISSING: Actually show the database error to the user!
      if (mounted) {
        setState(() => _isSaving = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Failed'),
            content: Text(e.toString()), // This will tell us EXACTLY what Supabase is rejecting
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK')
              )
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = _amountString.split('.');
    final wholeNumber = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '.00';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16.0),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      children: [
                        _buildTypeToggle('expense', 'Expense'),
                        _buildTypeToggle('income', 'Income'),
                      ],
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Amount',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '\$',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: wholeNumber,
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: _amountString.contains('.')
                                ? decimalPart
                                : '.00',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 64.0,
                        vertical: 24.0,
                      ),
                      child: TextField(
                        controller: _noteController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Add note...',
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'View All',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategoryId == cat['id'];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                            ),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _selectedCategoryId = cat['id'],
                              ),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Icon(
                                      cat['icon'],
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat['name'],
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        children: [
                          _buildNumpadRow(['7', '8', '9', '÷']),
                          const SizedBox(height: 12),
                          _buildNumpadRow(['4', '5', '6', '×']),
                          const SizedBox(height: 12),
                          _buildNumpadRow(['1', '2', '3', '−']),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildNumpadKey('.'),
                              _buildNumpadKey('0'),
                              _buildNumpadIconKey(
                                Icons.backspace_outlined,
                                _onBackspace,
                              ),
                              _buildNumpadKey('+'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(64),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32.0),
                              ),
                            ),
                            onPressed: _isSaving ? null : _handleSave,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: const Text(
                              'Save Transaction',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String type, String label) {
    final theme = Theme.of(context);
    final isSelected = _transactionType == type;
    return GestureDetector(
      onTap: () => setState(() => _transactionType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) => _buildNumpadKey(key)).toList(),
    );
  }

  Widget _buildNumpadKey(String label) {
    final theme = Theme.of(context);
    final isOperator = ['÷', '×', '−', '+'].contains(label);
    final color = isOperator
        ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final textColor = isOperator
        ? theme.colorScheme.secondary
        : theme.colorScheme.onSurface;

    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: color,
        fixedSize: const Size(64, 64),
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
      ),
      onPressed: () => _onKeyPress(label),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNumpadIconKey(IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        fixedSize: const Size(64, 64),
        shape: const CircleBorder(),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: theme.colorScheme.onSurface, size: 24),
    );
  }
}
