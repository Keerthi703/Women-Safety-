import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("complaints").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          var complaints = snapshot.data!.docs;
          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var complaint = complaints[index];
              return ListTile(
                title: Text(
                  "${complaint["incident_type"]} - ${complaint["offender_name"]}",
                ),
                subtitle: Text(complaint["incident_description"]),
                trailing: Icon(
                  Icons.check_circle,
                  color:
                      complaint["status"] == "Resolved"
                          ? Colors.green
                          : Colors.red,
                ),
                onTap: () {
                  // Open detailed complaint view
                },
              );
            },
          );
        },
      ),
    );
  }
}
