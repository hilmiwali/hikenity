// admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hikenity_app/pages/admin/certificate_viewer_page.dart';


class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Approvals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('organisers')
                    .where('isApproved', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No pending approvals.'),
                    );
                  }

                  final pendingOrganisers = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: pendingOrganisers.length,
                    itemBuilder: (context, index) {
                      final organiser = pendingOrganisers[index];
                      final organiserData = organiser.data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(organiserData['fullName'] ?? 'No Name'),
                          subtitle: Text(organiserData['email'] ?? 'No Email'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () async {
                                  await _approveOrganiser(organiser.id);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () async {
                                  await _rejectOrganiser(organiser.id);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            if (organiserData['certificateUrl'] != null) {
                              _viewCertificate(organiserData['certificateUrl']);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No certificate URL provided.')),
                                );
                              }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveOrganiser(String organiserId) async {
    try {
      await _firestore.collection('organisers').doc(organiserId).update({
        'isApproved': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organiser approved successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve organiser: $e')),
      );
    }
  }

  Future<void> _rejectOrganiser(String organiserId) async {
    try {
      await _firestore.collection('organisers').doc(organiserId).update({
        'isApproved': 'rejected',
        'rejectionReason': 'The certificate did not meet our standards.',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organiser has been notified.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject organiser: $e')),
      );
    }
  }

  void _viewCertificate(String certificateUrl) {
  if (certificateUrl.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateViewerPage(certificateUrl: certificateUrl),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Certificate URL not found.')),
    );
  }
}


}
