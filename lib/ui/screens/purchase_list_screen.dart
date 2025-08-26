import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/purchase.dart';
import '../../database/database_helper.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({Key? key}) : super(key: key);

  @override
  _PurchaseListScreenState createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  List<Purchase> _purchases = [];
  List<Purchase> _filteredPurchases = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, unpaid, paid, partial
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadPurchases();
    _loadSummary();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final purchases = await DatabaseHelper().getAllPurchases();
      setState(() {
        _purchases = purchases;
        _applyFilter();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading purchases: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await DatabaseHelper().getPurchaseSummary();
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading summary: $e')),
      );
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_filterStatus) {
        case 'unpaid':
          _filteredPurchases = _purchases.where((p) => p.isUnpaid).toList();
          break;
        case 'paid':
          _filteredPurchases = _purchases.where((p) => p.isFullyPaid).toList();
          break;
        case 'partial':
          _filteredPurchases = _purchases.where((p) => p.isPartiallyPaid).toList();
          break;
        default:
          _filteredPurchases = _purchases;
      }
    });
  }

  Future<void> _updatePayment(Purchase purchase) async {
    final TextEditingController amountController = TextEditingController();
    amountController.text = purchase.paidAmount.toString();

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Payment - ${purchase.itemName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Amount: ₹${purchase.totalAmount.toStringAsFixed(2)}'),
              Text('Current Paid: ₹${purchase.paidAmount.toStringAsFixed(2)}'),
              Text('Remaining: ₹${purchase.remainingAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Paid Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount >= 0 && amount <= purchase.totalAmount) {
                  Navigator.of(context).pop(amount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await DatabaseHelper().updatePurchasePayment(purchase.id, result);
        _loadPurchases();
        _loadSummary();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment: $e')),
        );
      }
    }
  }

  Color _getStatusColor(Purchase purchase) {
    if (purchase.isFullyPaid) return Colors.green;
    if (purchase.isPartiallyPaid) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(Purchase purchase) {
    if (purchase.isFullyPaid) return 'Paid';
    if (purchase.isPartiallyPaid) return 'Partial';
    return 'Unpaid';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Records'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
              _applyFilter();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Purchases')),
              const PopupMenuItem(value: 'unpaid', child: Text('Unpaid Only')),
              const PopupMenuItem(value: 'partial', child: Text('Partially Paid')),
              const PopupMenuItem(value: 'paid', child: Text('Fully Paid')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                if (_summary.isNotEmpty) ...[
                  Card(
                    margin: const EdgeInsets.all(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase Summary',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Purchases: ${_summary['totalPurchases']}'),
                                  Text('Total Amount: ₹${(_summary['totalAmount'] as double).toStringAsFixed(2)}'),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Paid: ₹${(_summary['paidAmount'] as double).toStringAsFixed(2)}'),
                                  Text(
                                    'Remaining: ₹${(_summary['remainingAmount'] as double).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: (_summary['remainingAmount'] as double) > 0 ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Filter Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Filter: ${_filterStatus.toUpperCase()}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${_filteredPurchases.length} purchases',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),

                // Purchase List
                Expanded(
                  child: _filteredPurchases.isEmpty
                      ? const Center(
                          child: Text('No purchases found'),
                        )
                      : ListView.builder(
                          itemCount: _filteredPurchases.length,
                          itemBuilder: (context, index) {
                            final purchase = _filteredPurchases[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                title: Text(
                                  purchase.itemName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (purchase.purchaseParty != null)
                                      Text('Supplier: ${purchase.purchaseParty!.name}'),
                                    Text('Quantity: ${purchase.quantity} | Price: ₹${purchase.purchasePrice.toStringAsFixed(2)}'),
                                    Text('Date: ${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}'),
                                    Row(
                                      children: [
                                        Text('Total: ₹${purchase.totalAmount.toStringAsFixed(2)}'),
                                        const SizedBox(width: 16),
                                        Text('Paid: ₹${purchase.paidAmount.toStringAsFixed(2)}'),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Remaining: ₹${purchase.remainingAmount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: purchase.remainingAmount > 0 ? Colors.red : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(purchase),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(purchase),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (!purchase.isFullyPaid)
                                      IconButton(
                                        icon: const Icon(Icons.payment),
                                        onPressed: () => _updatePayment(purchase),
                                        iconSize: 20,
                                      ),
                                  ],
                                ),
                                onTap: () => _showPurchaseDetails(purchase),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showPurchaseDetails(Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(purchase.itemName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Item ID', purchase.itemId),
                if (purchase.purchaseParty != null) ...[
                  _buildDetailRow('Supplier', purchase.purchaseParty!.name),
                  _buildDetailRow('Address', purchase.purchaseParty!.address),
                  if (purchase.purchaseParty!.phone != null)
                    _buildDetailRow('Phone', purchase.purchaseParty!.phone!),
                  if (purchase.purchaseParty!.email != null)
                    _buildDetailRow('Email', purchase.purchaseParty!.email!),
                ],
                const Divider(),
                _buildDetailRow('Quantity', purchase.quantity.toString()),
                _buildDetailRow('Purchase Price', '₹${purchase.purchasePrice.toStringAsFixed(2)}'),
                _buildDetailRow('Total Amount', '₹${purchase.totalAmount.toStringAsFixed(2)}'),
                _buildDetailRow('Paid Amount', '₹${purchase.paidAmount.toStringAsFixed(2)}'),
                _buildDetailRow('Remaining Amount', '₹${purchase.remainingAmount.toStringAsFixed(2)}'),
                _buildDetailRow('Purchase Date', '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}'),
                if (purchase.notes != null)
                  _buildDetailRow('Notes', purchase.notes!),
                const Divider(),
                _buildDetailRow('Status', _getStatusText(purchase)),
                _buildDetailRow('Created', '${purchase.createdDate.day}/${purchase.createdDate.month}/${purchase.createdDate.year}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (!purchase.isFullyPaid)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _updatePayment(purchase);
                },
                child: const Text('Update Payment'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}