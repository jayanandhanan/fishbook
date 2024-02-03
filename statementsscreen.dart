import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatementScreen extends StatefulWidget {
  @override
  _StatementScreenState createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  String? organizationId;
  String role = '';

  @override
  void initState() {
    super.initState();
    _fetchOrganizationIdAndUserRole();
  }

  Future<void> _fetchOrganizationIdAndUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String? userOrganizationId = userDoc.get('organizationId');
      String? userRole = userDoc.get('role');

      if (userOrganizationId != null && userRole != null) {
        setState(() {
          organizationId = userOrganizationId;
          role = userRole;
        });
      } else {
        // Handle the case where organizationId or user role is not found
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statements'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: FutureBuilder(
          future: _fetchStatements(role),
          builder: (context, AsyncSnapshot<Map<String, List<QueryDocumentSnapshot>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              List<QueryDocumentSnapshot> paymentDetails = snapshot.data!['paymentdetails']!;
              List<QueryDocumentSnapshot> workManagement = snapshot.data!['workmanagement']!;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16.0,
                  columns: [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Mode of Payment')),
                    DataColumn(label: Text('Amount Given To')),
                  ],
                  rows: _buildDataRows(paymentDetails, workManagement),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  List<DataRow> _buildDataRows(List<QueryDocumentSnapshot> paymentDetails,
      List<QueryDocumentSnapshot> workManagement) {
    List<DataRow> rows = [];

    paymentDetails.forEach((paymentDoc) {
      Timestamp timestamp = paymentDoc['date'] ?? Timestamp.now();
      String formattedDate = DateFormat('dd-MM-yyyy').format(timestamp.toDate());

      String amount = '';
if (paymentDoc.exists) {
  var data = paymentDoc.data() as Map<String, dynamic>;
  if (data.containsKey('amount')) {
    amount = data['amount'].toString();
  } else if (data.containsKey('remainingamountshare')) {
    amount = data['remainingamountshare'].toString();
  }
}

      String status = paymentDoc['payment'] ?? '';
      String modeOfPayment = paymentDoc['modeofpayment'] ?? '';
      String amountGivenTo = paymentDoc['name'] ?? '';

      rows.add(DataRow(cells: [
        DataCell(Text(formattedDate)),
        DataCell(Text(amount)),
        DataCell(Text(status)),
        DataCell(Text(modeOfPayment)),
        DataCell(Text(amountGivenTo)),
      ]));
    });

    workManagement.forEach((workDoc) {
      Timestamp timestamp = workDoc['paymentdate'] ?? Timestamp.now();
      String formattedDate = DateFormat('dd-MM-yyyy').format(timestamp.toDate());

  String amount = '';
if (workDoc.exists) {
  var data = workDoc.data() as Map<String, dynamic>;
  if (data.containsKey('amount')) {
    amount = data['amount'].toString();
  } else if (data.containsKey('paidamount')) {
    amount = data['paidamount'].toString();
  }
}

      String status = workDoc['payment'] ?? '';
      String modeOfPayment = workDoc['modeofpayment'] ?? '';
      String amountGivenTo = workDoc['incharge'] ?? '';

      rows.add(DataRow(cells: [
        DataCell(Text(formattedDate)),
        DataCell(Text(amount)),
        DataCell(Text(status)),
        DataCell(Text(modeOfPayment)),
        DataCell(Text(amountGivenTo)),
      ]));
    });

    return rows;
  }

  Future<Map<String, List<QueryDocumentSnapshot>>> _fetchStatements(String userRole) async {
    Map<String, List<QueryDocumentSnapshot>> data = {};
    List<QueryDocumentSnapshot> paymentDetails = [];
    List<QueryDocumentSnapshot> workManagement = [];

    QuerySnapshot paymentDetailsSnapshot;
    QuerySnapshot workManagementSnapshot;

    if (role == 'Crewmember') {
      paymentDetailsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('paymentdetails')
          .where('user', isEqualTo: 'Crew Member')
          .get();

      workManagementSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('workmanagement')
          .where('user', isEqualTo: 'Crew Member')
          .get();
    } else {
      paymentDetailsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('paymentdetails')
          .get();

      workManagementSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('workmanagement')
          .get();
    }

    paymentDetails.addAll(paymentDetailsSnapshot.docs);
    workManagement.addAll(workManagementSnapshot.docs);

    data['paymentdetails'] = paymentDetails;
    data['workmanagement'] = workManagement;

    return data;
  }
}
