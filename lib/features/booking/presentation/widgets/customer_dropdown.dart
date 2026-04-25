import 'package:flutter/material.dart';

class CustomerDropdown extends StatelessWidget {
  const CustomerDropdown({
    required this.customers,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<String> customers;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(labelText: 'Customer'),
      items: customers
          .map((customer) => DropdownMenuItem<String>(
                value: customer,
                child: Text(customer),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
