import 'package:flutter/material.dart';

class PostSellListingScreen extends StatefulWidget {
  const PostSellListingScreen({super.key});

  @override
  State<PostSellListingScreen> createState() => _PostSellListingScreenState();
}

class _PostSellListingScreenState extends State<PostSellListingScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Sell Listing')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            // Submit
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Listing Posted!')));
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        steps: [
          Step(
            title: const Text('Car Details'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown('Make', [
                  'Maruti Suzuki',
                  'Hyundai',
                  'Tata',
                  'Toyota',
                ]),
                const SizedBox(height: 16),
                _buildDropdown('Model', ['Swift', 'Creta', 'Nexon', 'Innova']),
                const SizedBox(height: 16),
                _buildDropdown('Year', ['2020', '2019', '2018']),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Condition'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Km Driven'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildDropdown('Number of Owners', [
                  '1st',
                  '2nd',
                  '3rd',
                  '4th+',
                ]),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Photos & Price'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Expected Selling Price (₹)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Review & Submit'),
            content: const Text(
              'Please review your car listing before submitting to dealers.',
            ),
            isActive: _currentStep >= 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: options
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) {},
    );
  }
}
