import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const SainiApp());

class Store {
  static final Store instance = Store._();
  Store._();
  List<Map<String,dynamic>> products = [];
  List<Map<String,dynamic>> customers = [];
  List<Map<String,dynamic>> bills = [];
  int billNo = 1;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    products = _decode(p.getString('products'));
    customers = _decode(p.getString('customers'));
    bills = _decode(p.getString('bills'));
    billNo = p.getInt('billNo') ?? 1;
  }
  List<Map<String,dynamic>> _decode(String? s) {
    if (s == null) return [];
    return List<Map<String,dynamic>>.from(
      (jsonDecode(s) as List).map((e) => Map<String,dynamic>.from(e))
    );
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('products', jsonEncode(products));
    await p.setString('customers', jsonEncode(customers));
    await p.setString('bills', jsonEncode(bills));
    await p.setInt('billNo', billNo);
  }
}

class SainiApp extends StatelessWidget {
  const SainiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Saini Info Solutions',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  final pages = const [Dashboard(), ProductsPage(), CustomersPage(), BillsPage()];
  @override
  void initState() { super.initState(); Store.instance.load().then((_) => setState((){})); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Saini Info Solutions')),
    body: pages[index],
    floatingActionButton: index == 1
      ? FloatingActionButton.extended(onPressed: () => _addProduct(), icon: const Icon(Icons.add), label: const Text('Product'))
      : index == 2
      ? FloatingActionButton.extended(onPressed: () => _addCustomer(), icon: const Icon(Icons.person_add), label: const Text('Customer'))
      : null,
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index=i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label:'Dashboard'),
        NavigationDestination(icon: Icon(Icons.inventory_2), label:'Stock'),
        NavigationDestination(icon: Icon(Icons.people), label:'Customers'),
        NavigationDestination(icon: Icon(Icons.receipt_long), label:'Bills'),
      ],
    ),
  );

  Future<void> _addProduct() async {
    final name = TextEditingController(), qty=TextEditingController(), price=TextEditingController(), low=TextEditingController(text:'2');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Add Product'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller:name, decoration:const InputDecoration(labelText:'Product name')),
        TextField(controller:qty, keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Opening stock')),
        TextField(controller:price, keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Sale price')),
        TextField(controller:low, keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Low stock limit')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Save'))],
    ));
    if(ok==true && name.text.trim().isNotEmpty){
      Store.instance.products.add({'name':name.text.trim(),'qty':int.tryParse(qty.text)??0,'price':double.tryParse(price.text)??0,'low':int.tryParse(low.text)??2});
      await Store.instance.save(); setState((){});
    }
  }

  Future<void> _addCustomer() async {
    final name=TextEditingController(), phone=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
      title:const Text('Add Customer'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Customer / Party name')),
        TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Mobile number')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Save'))],
    ));
    if(ok==true && name.text.trim().isNotEmpty){
      Store.instance.customers.add({'name':name.text.trim(),'phone':phone.text.trim(),'balance':0.0});
      await Store.instance.save(); setState((){});
    }
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final s=Store.instance;
    final low=s.products.where((p)=>(p['qty']??0)<= (p['low']??2) && (p['qty']??0)>0).length;
    final nil=s.products.where((p)=>(p['qty']??0)<=0).length;
    final today=DateFormat('dd-MM-yyyy').format(DateTime.now());
    final sales=s.bills.where((b)=>b['date']==today).fold<double>(0,(x,b)=>x+(b['total']??0));
    return RefreshIndicator(onRefresh:()=>s.save(),child:ListView(padding:const EdgeInsets.all(16),children:[
      Text('Welcome to Saini Info Solutions',style:Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height:16),
      Wrap(spacing:12,runSpacing:12,children:[
        _card(context,'Products',s.products.length,Icons.inventory_2),
        _card(context,'Low Stock',low,Icons.warning),
        _card(context,'Nil Stock',nil,Icons.remove_shopping_cart),
        _card(context,'Customers',s.customers.length,Icons.people),
        _card(context,"Today's Sales",sales,Icons.currency_rupee),
        _card(context,'Bills',s.bills.length,Icons.receipt_long),
      ]),
    ]));
  }
  Widget _card(BuildContext c,String title,dynamic value,IconData icon)=>SizedBox(width:160,height:120,child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon),Text(title),Text('$value',style:Theme.of(c).textTheme.titleLarge)]))));
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override State<ProductsPage> createState()=>_ProductsPageState();
}
class _ProductsPageState extends State<ProductsPage>{
  @override Widget build(BuildContext context)=>ListView.builder(
    padding:const EdgeInsets.all(8), itemCount:Store.instance.products.length,
    itemBuilder:(c,i){final p=Store.instance.products[i];final q=p['qty']??0;return Card(child:ListTile(
      leading:const Icon(Icons.inventory_2),title:Text(p['name']),subtitle:Text('Sale: ₹${p['price']}  |  Stock: $q'),
      trailing:Chip(label:Text(q<=0?'NIL':q<=p['low']?'LOW':'OK')),
    ));});
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override State<CustomersPage> createState()=>_CustomersPageState();
}
class _CustomersPageState extends State<CustomersPage>{
  @override Widget build(BuildContext context)=>ListView.builder(
    padding:const EdgeInsets.all(8),itemCount:Store.instance.customers.length,
    itemBuilder:(c,i){final x=Store.instance.customers[i];return Card(child:ListTile(
      leading:const Icon(Icons.person),title:Text(x['name']),subtitle:Text(x['phone']??''),trailing:Text('₹${x['balance']??0}'),
    ));});
}

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});
  @override State<BillsPage> createState()=>_BillsPageState();
}
class _BillsPageState extends State<BillsPage>{
  @override Widget build(BuildContext context)=>Column(children:[
    Padding(padding:const EdgeInsets.all(12),child:FilledButton.icon(onPressed:_newBill,icon:const Icon(Icons.add),label:const Text('New Sale Bill'))),
    Expanded(child:ListView.builder(itemCount:Store.instance.bills.length,itemBuilder:(c,i){
      final b=Store.instance.bills.reversed.toList()[i];
      return ListTile(leading:const Icon(Icons.receipt),title:Text('Bill #${b['no']} - ${b['customer']}'),subtitle:Text(b['date']),trailing:Text('₹${b['total']}'));
    }))
  ]);

  Future<void> _newBill() async {
    final s=Store.instance; if(s.products.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('पहले product add करें')));return;}
    String customer='Cash Sale'; final items=<Map<String,dynamic>>{};
    for(final p in s.products){items[p['name']]=p;}
    final selected=<String>{}; 
    final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:Text('New Bill #${s.billNo}'),
      content:SizedBox(width:360,child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:customer,items:['Cash Sale',...s.customers.map((e)=>e['name'] as String)].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setD(()=>customer=v!),decoration:const InputDecoration(labelText:'Customer')),
        ...s.products.map((p)=>CheckboxListTile(value:selected.contains(p['name']),onChanged:(v)=>setD(()=>v==true?selected.add(p['name']):selected.remove(p['name'])),title:Text(p['name']),subtitle:Text('₹${p['price']} | stock ${p['qty']}'))),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Save Bill'))],
    )));
    if(ok==true && selected.isNotEmpty){
      double total=0; final billItems=[];
      for(final name in selected){final p=s.products.firstWhere((x)=>x['name']==name);final q=p['qty']??0;if(q>0){p['qty']=q-1;total+=p['price'];billItems.add({'name':name,'price':p['price'],'qty':1});}}
      final date=DateFormat('dd-MM-yyyy').format(DateTime.now());
      s.bills.add({'no':s.billNo++,'date':date,'customer':customer,'total':total,'items':billItems});
      await s.save();setState((){});_printBill(s.bills.last);
    }
  }

  Future<void> _printBill(Map<String,dynamic> b) async {
    final doc=pw.Document();
    doc.addPage(pw.Page(build:(ctx)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
      pw.Text('SAINI INFO SOLUTIONS',style:pw.TextStyle(fontSize:20,fontWeight:pw.FontWeight.bold)),
      pw.Text('Bill No: ${b['no']}    Date: ${b['date']}'),
      pw.Text('Customer: ${b['customer']}'),
      pw.SizedBox(height:15),
      ...(b['items'] as List).map((x)=>pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('${x['name']} x${x['qty']}'),pw.Text('₹${x['price']}')])),
      pw.Divider(),pw.Text('TOTAL: ₹${b['total']}',style:pw.TextStyle(fontSize:16,fontWeight:pw.FontWeight.bold)),
    ])));
    await Printing.layoutPdf(onLayout:(format)=>doc.save());
  }
}
