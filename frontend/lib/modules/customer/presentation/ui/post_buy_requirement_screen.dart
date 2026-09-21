import 'package:flutter/material.dart';

class PostBuyRequirementScreen extends StatefulWidget {
  const PostBuyRequirementScreen({super.key});

  @override
  State<PostBuyRequirementScreen> createState() =>
      _PostBuyRequirementScreenState();
}

class _PostBuyRequirementScreenState extends State<PostBuyRequirementScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Buy Requirement')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            // Submit
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Requirement Posted!')),
            );
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
                _buildDropdown('Year', ['2020+', '2018+', '2015+']),
                const SizedBox(height: 16),
                _buildDropdown('Fuel Type', [
                  'Petrol',
                  'Diesel',
                  'CNG',
                  'Electric',
                ]),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Budget & Location'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown('Budget', [
                  'Under ₹5 Lakh',
                  '₹5 - ₹10 Lakh',
                  '₹10 - ₹20 Lakh',
                  'Above ₹20 Lakh',
                ]),
                const SizedBox(height: 16),
                _buildDropdown('City', [
                  'Bengaluru',
                  'Delhi',
                  'Mumbai',
                  'Chennai',
                ]),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Review & Submit'),
            content: const Text(
              'Please review your requirements before posting to dealers.',
            ),
            isActive: _currentStep >= 2,
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
