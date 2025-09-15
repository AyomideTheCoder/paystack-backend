import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class WalletActivityPage extends StatefulWidget {
  const WalletActivityPage({super.key});

  @override
  State<WalletActivityPage> createState() => _WalletActivityPageState();
}

class _WalletActivityPageState extends State<WalletActivityPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _transactions = [];
  String selectedCategory = 'All Categories';
  String selectedStatus = 'Any Status';
  bool _isLoading = true;
  int _page = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _transactions.clear();
        _hasMore = true;
      });
    }

    if (!_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      const maxRetries = 3;
      for (int i = 0; i < maxRetries; i++) {
        try {
          final response = await _supabase
              .from('transactions')
              .select()
              .eq('user_id', user.id) // Match AddMoneyPage schema
              .order('created_at', ascending: false)
              .range(_page * _pageSize, (_page + 1) * _pageSize - 1);

          setState(() {
            _transactions.addAll(List<Map<String, dynamic>>.from(response));
            _hasMore = response.length == _pageSize;
            _page++;
            _isLoading = false;
          });
          return;
        } catch (e) {
          if (i == maxRetries - 1) throw e;
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _loadTransactions(),
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get categories {
    final uniqueCategories = {for (var tx in _transactions) tx['title'] ?? 'Unknown'}.toList();
    return ['All Categories', ...uniqueCategories];
  }

  List<String> get statuses {
    final uniqueStatuses = {for (var tx in _transactions) tx['type'] ?? 'Unknown'}.toList();
    return ['Any Status', ...uniqueStatuses];
  }

  List<Map<String, dynamic>> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesCategory = selectedCategory == 'All Categories' || tx['title'] == selectedCategory;
      final matchesStatus = selectedStatus == 'Any Status' || tx['type'] == selectedStatus.toLowerCase();
      return matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadTransactions(reset: true),
      color: const Color(0xFF10214B),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10214B),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        items: statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10214B),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Transaction List',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading && _transactions.isEmpty)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF10214B)))
                  else if (_transactions.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'No transactions available.',
                            style: TextStyle(color: Color(0xFF10214B), fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/add_money');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10214B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Fund Wallet', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredTransactions.asMap().entries.map((entry) {
                      final tx = entry.value;
                      final isCredit = tx['type'] == 'credit';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          dense: true,
                          leading: Icon(
                            isCredit ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                            color: isCredit ? Colors.green : Colors.red,
                            size: 24,
                          ),
                          title: Text(
                            tx['title'] ?? 'Transaction',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10214B),
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            tx['created_at'] != null
                                ? DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(tx['created_at']))
                                : 'Unknown Date',
                            style: const TextStyle(
                              color: Color(0xFF10214B),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            '${isCredit ? '+' : '-'}₦${(tx['amount'] as num).toDouble().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCredit ? Colors.green : Colors.red,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  if (_hasMore && !_isLoading)
                    Center(
                      child: ElevatedButton(
                        onPressed: _loadTransactions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10214B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Load More', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}