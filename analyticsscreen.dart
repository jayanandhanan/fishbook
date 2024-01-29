import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chart_screen.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, Map<String, double>> analyticsData = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      final String orgId = await _getCurrentUserOrganizationId();
      final QuerySnapshot financeSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('finance')
          .get();
      financeSnapshot.docs.forEach((doc) {
        final dynamic month = doc['month'];
        final dynamic year = doc['year'];
        final double revenue = (doc['revenue'] ?? 0).toDouble(); // Convert to double
        final double expense = (doc['expense'] ?? 0).toDouble(); // Convert to double
        final double profit = (doc['profit'] ?? 0).toDouble(); // Convert to double

        if (month != null && year != null) {
          final key = '$month-$year'; // Convert to string
          if (analyticsData.containsKey(key)) {
            // Update existing entry
            analyticsData[key]!['totalRevenue'] =
                (analyticsData[key]!['totalRevenue'] ?? 0.0) + revenue;
            analyticsData[key]!['totalExpense'] =
                (analyticsData[key]!['totalExpense'] ?? 0.0) + expense;
            analyticsData[key]!['totalProfit'] =
                (analyticsData[key]!['totalProfit'] ?? 0.0) + profit;
          } else {
            // Add new entry
            analyticsData[key] = {
              'totalRevenue': revenue,
              'totalExpense': expense,
              'totalProfit': profit,
            };
          }
        }
      });
      setState(() {}); // Refresh UI
    } catch (error) {
      print('Error fetching analytics data: $error');
    }
  }

  Future<String> _getCurrentUserOrganizationId() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        return userDoc['organizationId'];
      } else {
        throw 'User document does not exist.';
      }
    } else {
      throw 'User is not logged in.';
    }
  }

  Future<void> _addToDatabase() async {
    try {
      final String orgId = await _getCurrentUserOrganizationId();
      final CollectionReference analyticsCollection = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('analytics');

      // Delete existing documents in the analytics collection
      await analyticsCollection.get().then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Add new analytics data as documents
      analyticsData.forEach((key, value) {
        analyticsCollection.doc(key).set({
          'month-year': key,
          'totalRevenue': value['totalRevenue'],
          'totalExpense': value['totalExpense'],
          'totalProfit': value['totalProfit'],
        });
      });

      // Navigate to ChartScreen
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen()));
    } catch (error) {
      print('Error adding to database: $error');
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Finance Analytics'),
    ),
    body: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width, // Set width to screen width
                  child: _buildAnalyticsTable(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _addToDatabase,
              child: Text('Add to Database'),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildAnalyticsTable() {
  // Convert map keys to a list of strings
  List<String> sortedKeys = analyticsData.keys.toList();

  // Sort the list of keys by month and year
  sortedKeys.sort((a, b) {
    List<String> partsA = a.split('-');
    List<String> partsB = b.split('-');
    int yearComparison = partsA[1].compareTo(partsB[1]);
    if (yearComparison != 0) {
      return yearComparison;
    } else {
      // If years are the same, compare months
      return partsA[0].compareTo(partsB[0]);
    }
  });

  List<DataRow> rows = [];

  // Iterate through the sorted keys to build rows
  for (String key in sortedKeys) {
    Map<String, double> value = analyticsData[key]!;
    rows.add(DataRow(
      cells: [
        DataCell(Text(key)),
        DataCell(Text(value['totalRevenue'].toString())),
        DataCell(Text(value['totalExpense'].toString())),
        DataCell(Text(value['totalProfit'].toString())),
      ],
    ));
  }

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 16.0, // Adjust column spacing as needed
        columns: [
          DataColumn(label: Text('Month-Year')),
          DataColumn(label: Text('Total Revenue')),
          DataColumn(label: Text('Total Expense')),
          DataColumn(label: Text('Total Profit')),
        ],
        rows: rows,
      ),
    ),
  );
}

}
