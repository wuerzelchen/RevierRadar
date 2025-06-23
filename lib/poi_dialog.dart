import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'district_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class POIDialog extends StatefulWidget {
  final LatLng location;
  final PointOfInterest? initialPOI;
  const POIDialog({required this.location, this.initialPOI, Key? key})
    : super(key: key);

  @override
  State<POIDialog> createState() => _POIDialogState();
}

class _POIDialogState extends State<POIDialog> {
  late String? _selectedType;
  late TextEditingController _nameController;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialPOI?.type ?? PointOfInterest.types.first;
    _nameController = TextEditingController(
      text: widget.initialPOI?.name ?? '',
    );
    _imagePath = widget.initialPOI?.imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neuer Punkt von Interesse'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (_imagePath != null && _imagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  height: 120,
                  child: Image.file(
                    File(_imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('Bild nicht gefunden'),
                  ),
                ),
              ),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Bild wählen'),
                  onPressed: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Aus Galerie wählen'),
                              onTap: () => Navigator.of(
                                context,
                              ).pop(ImageSource.gallery),
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Mit Kamera aufnehmen'),
                              onTap: () =>
                                  Navigator.of(context).pop(ImageSource.camera),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (source != null) {
                      final picked = await _picker.pickImage(
                        source: source,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        setState(() {
                          _imagePath = picked.path;
                        });
                      }
                    }
                  },
                ),
                if (_imagePath != null && _imagePath!.isNotEmpty)
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
