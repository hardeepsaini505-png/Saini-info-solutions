import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const SainiApp());
}

// =====================================================
// STORE
// =====================================================

class Store {
  static final Store instance = Store._();

  Store._();

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> bills = [];

  int billNo = 1;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    products = _decode(prefs.getString('products'));
    customers = _decode(prefs.getString('customers'));
    bills = _decode(prefs.getString('bills'));

    billNo = prefs.getInt('billNo') ?? 1;
  }

  List<Map<String, dynamic>> _decode(String? data) {
    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(data);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'products',
      jsonEncode(products),
    );

    await prefs.setString(
      'customers',
      jsonEncode(customers),
    );

    await prefs.setString(
      'bills',
      jsonEncode(bills),
    );

    await prefs.setInt(
      'billNo',
      billNo,
    );
  }
}

// =====================================================
// APP
// =====================================================

class SainiApp extends StatelessWidget {
  const SainiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saini Info Solutions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomePage(),
    );
  }
}

// =====================================================
// HOME PAGE
// =====================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final List<Widget> pages = const [
    Dashboard(),
    ProductsPage(),
    CustomersPage(),
    BillsPage(),
  ];

  @override
  void initState() {
    super.initState();

    Store.instance.load().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saini Info Solutions',
        ),
      ),

      body: pages[index],

      floatingActionButton: index == 1
          ? FloatingActionButton.extended(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Product'),
            )
          : index == 2
              ? FloatingActionButton.extended(
                  onPressed: _addCustomer,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Customer'),
                )
              : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
        ],
      ),
    );
  }

  // ===================================================
  // ADD PRODUCT
  // ===================================================

  Future<void> _addProduct() async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final priceController = TextEditingController();
    final lowController = TextEditingController(text: '2');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Product'),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening stock',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Sale price',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: lowController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
  labelText: 'Low stock limit',
  border: OutlineInputBorder(),
),
                   
