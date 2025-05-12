import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ComplaintFormScreen extends StatefulWidget {
  @override
  _ComplaintFormScreenState createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _offenderNameController = TextEditingController();
  final TextEditingController _offenderDetailsController =
      TextEditingController();
  final TextEditingController _incidentDetailsController =
      TextEditingController();
  String _incidentType = "Domestic Violence";
  File? _evidenceFile;

  Future<void> _pickEvidence() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _evidenceFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadEvidence(File file) async {
    try {
      String filePath = "evidence/${DateTime.now().millisecondsSinceEpoch}.jpg";
      TaskSnapshot uploadTask = await FirebaseStorage.instance
          .ref(filePath)
          .putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    String? evidenceUrl;
    if (_evidenceFile != null) {
      evidenceUrl = await _uploadEvidence(_evidenceFile!);
    }

    await FirebaseFirestore.instance.collection("complaints").add({
      "offender_name": _offenderNameController.text,
      "offender_details": _offenderDetailsController.text,
      "incident_type": _incidentType,
      "incident_description": _incidentDetailsController.text,
      "evidence_url": evidenceUrl ?? "",
      "timestamp": Timestamp.now(),
      "status": "Pending",
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Complaint Submitted!")));
    _formKey.currentState!.reset();
    setState(() => _evidenceFile = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Report a Safety Threat")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _incidentType,
                onChanged: (value) => setState(() => _incidentType = value!),
                items:
                    ["Domestic Violence", "Office Harassment", "Public Threat"]
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
              ),
              TextFormField(
                controller: _offenderNameController,
                decoration: InputDecoration(labelText: "Offender Name"),
              ),
              TextFormField(
                controller: _offenderDetailsController,
                decoration: InputDecoration(
                  labelText: "Offender Contact/Details",
                ),
              ),
              TextFormField(
                controller: _incidentDetailsController,
                decoration: InputDecoration(labelText: "Incident Description"),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              _evidenceFile == null
                  ? Text("No Evidence Uploaded")
                  : Image.file(_evidenceFile!, height: 100, width: 100),
              TextButton.icon(
                onPressed: _pickEvidence,
                icon: Icon(Icons.upload),
                label: Text("Upload Evidence"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitComplaint,
                child: Text("Submit Complaint"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
