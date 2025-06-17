import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'district_model.dart';

class POIDialog extends StatefulWidget {
  final LatLng location;
  const POIDialog({required this.location, Key? key}) : super(key: key);

  @override
  State<POIDialog> createState() => _POIDialogState();
}

class _POIDialogState extends State<POIDialog> {
  String? _selectedType = PointOfInterest.types.first;
  final TextEditingController _nameController = TextEditingController();
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neuer Punkt von Interesse'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: PointOfInterest.types
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val),
              decoration: const InputDecoration(labelText: 'Typ'),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Bild wählen'),
                  onPressed: () async {
                    // TODO: Implement image picker
                    // For now, just simulate
                    setState(() {
                      _imagePath = 'dummy_path.jpg';
                    });
                  },
                ),
                if (_imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text('Bild ausgewählt'),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty || _selectedType == null)
              return;
            Navigator.of(context).pop(
              PointOfInterest(
                name: _nameController.text.trim(),
                type: _selectedType!,
                location: LatLngSerializable(
                  latitude: widget.location.latitude,
                  longitude: widget.location.longitude,
                ),
                imagePath: _imagePath,
              ),
            );
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
