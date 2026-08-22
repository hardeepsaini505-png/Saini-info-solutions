DropdownButtonFormField<String>(
  value: customer,
  items: customerNames.map((name) {
    return DropdownMenuItem<String>(
      value: name,
      child: Text(name),
    );
  }).toList(),
  onChanged: (value) {
    if (value != null) {
      setDialogState(() {
        customer = value;
      });
    }
  },
  decoration: const InputDecoration(
    labelText: 'Customer',
  ),
),
