import 'package:flutter/material.dart';

Future<String> showDistrictNameDialog(BuildContext context) async {
  String name = "";
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('District Name'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter district name'),
          onChanged: (value) => name = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
  return name.trim();
}
