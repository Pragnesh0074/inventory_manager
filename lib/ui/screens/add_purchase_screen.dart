import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/purchase.dart';
import '../../models/purchase_party.dart';
import '../../models/inventory_item.dart';
import '../../database/database_helper.dart';

class AddPurchaseScreen extends StatefulWidget {
  final InventoryItem item;
  final int purchaseQuantity;

  const AddPurchaseScreen({
    Key? key,
    required this.item,
    required this.purchaseQuantity,
  }) : super(key: key);

  @override
  _AddPurchaseScreenState createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purchasePriceController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Purchase party form controllers
  final _partyNameController = TextEditingController();
  final _partyAddressController = TextEditingController();
  final _partyPhoneController = TextEditingController();
  final _partyEmailController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  List<PurchaseParty> _purchaseParties = [];
  PurchaseParty? _selectedParty;
  bool _isNewParty = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPurchaseParties();
    _purchasePriceController.addListener(_updateTotalAmount);
  }

  @override
  void dispose() {
    _purchasePriceController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    _partyNameController.dispose();
    _partyAddressController.dispose();
    _partyPhoneController.dispose();
    _partyEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadPurchaseParties() async {
    try {
      final parties = await DatabaseHelper().getAllPurchaseParties();
      setState(() {
        _purchaseParties = parties;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading purchase parties: $e')),
      );
    }
  }

  void _updateTotalAmount() {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
    final totalAmount = purchasePrice * widget.purchaseQuantity;
    _totalAmountController.text = totalAmount.toStringAsFixed(2);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      
      // Create or get purchase party
      PurchaseParty party;
      if (_isNewParty) {
        party = PurchaseParty(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _partyNameController.text,
          address: _partyAddressController.text,
          phone: _partyPhoneController.text.isEmpty ? null : _partyPhoneController.text,
          email: _partyEmailController.text.isEmpty ? null : _partyEmailController.text,
          createdDate: DateTime.now(),
        );
        await dbHelper.insertPurchaseParty(party);
      } else {
        party = _selectedParty!;
      }

      // Create purchase record
      final purchase = Purchase(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemId: widget.item.id,
        itemName: widget.item.name,
        purchasePartyId: party.id,
        quantity: widget.purchaseQuantity,
        purchasePrice: double.parse(_purchasePriceController.text),
        totalAmount: double.parse(_totalAmountController.text),
        paidAmount: double.tryParse(_paidAmountController.text) ?? 0.0,
        purchaseDate: _purchaseDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdDate: DateTime.now(),
        purchaseParty: party,
      );

      await dbHelper.insertPurchase(purchase);

      // Update item's purchase price if not set
      if (widget.item.purchasePrice == null) {
        final updatedItem = InventoryItem(
          id: widget.item.id,
          name: widget.item.name,
          sellingPrice: widget.item.sellingPrice,
          purchasePrice: purchase.purchasePrice,
          quantity: widget.item.quantity,
          createdDate: widget.item.createdDate,
          lastUpdated: DateTime.now(),
          stockEntries: widget.item.stockEntries,
        );
        await dbHelper.updateInventoryItem(updatedItem);
      }

      Navigator.of(context).pop(purchase);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving purchase: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Purchase Details'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePurchase,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Item Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Item: ${widget.item.name}'),
                    Text('Quantity: ${widget.purchaseQuantity}'),
                    if (widget.item.sellingPrice > 0)
                      Text('Current Selling Price: ₹${widget.item.sellingPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Purchase Party Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Party',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Select Existing'),
                            value: false,
                            groupValue: _isNewParty,
                            onChanged: (value) {
                              setState(() {
                                _isNewParty = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Add New'),
                            value: true,
                            groupValue: _isNewParty,
                            onChanged: (value) {
                              setState(() {
                                _isNewParty = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (!_isNewParty) ...[
                      DropdownButtonFormField<PurchaseParty>(
                        value: _selectedParty,
                        decoration: const InputDecoration(
                          labelText: 'Select Purchase Party',
                          border: OutlineInputBorder(),
                        ),
                        items: _purchaseParties.map((party) {
                          return DropdownMenuItem<PurchaseParty>(
                            value: party,
                            child: Text('${party.name} - ${party.address}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedParty = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a purchase party';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _partyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Party Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter party name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _partyAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _partyPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _partyEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Purchase Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    ListTile(
                      title: const Text('Purchase Date'),
                      subtitle: Text('${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price (per unit)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter purchase price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      controller: _totalAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      controller: _paidAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Paid Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        helperText: 'Leave empty if not paid yet',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final paidAmount = double.tryParse(value);
                          final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
                          if (paidAmount == null || paidAmount < 0) {
                            return 'Please enter a valid amount';
                          }
                          if (paidAmount > totalAmount) {
                            return 'Paid amount cannot exceed total amount';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
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
}