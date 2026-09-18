import 'package:flutter/material.dart';
import 'tabs/buy_leads_tab.dart';
import 'tabs/sell_leads_tab.dart';
import 'tabs/dealer_inventory_tab.dart';

class DealerShell extends StatefulWidget {
  const DealerShell({super.key});

  @override
  State<DealerShell> createState() => _DealerShellState();
}

class _DealerShellState extends State<DealerShell> {
  int _currentIndex = 0;

  final _tabs = const [
    BuyLeadsTab(),
    SellLeadsTab(),
    DealerInventoryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Buy Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell_outlined),
            label: 'Sell Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Inventory',
          ),
        ],
      ),
    );
  }
}
