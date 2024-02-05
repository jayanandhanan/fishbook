// ignore_for_file: unused_import

import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishbook/chart_screen.dart';
import 'package:fishbook/filteranalyticsscreen.dart'; 


class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? organizationId;
  bool isHomeScreen = false;
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
        title: Text('Monthly Analytics'),
      backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, false),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: _buildAnalyticsTable(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addToDatabase,
                child: Text('Chart'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/filter');
                },
                child: Text('Filter and Create Chart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

BottomNavigationBar buildBottomNavigationBar(BuildContext context, bool isHomeScreen) {
    return BottomNavigationBar(
      currentIndex: 0,
      fixedColor: Colors.grey , 
      items: [
        BottomNavigationBarItem(
           icon: Icon(Icons.home, color: Colors.grey), 
          label: "Home",
           backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wrap_text),
          label: "Statements",
           backgroundColor: Color(0xFFF9D8C5),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.exit_to_app),
          label: "Logout",
           backgroundColor: Color(0xFFF9D8C5),
        ),
      ],
      onTap: (index) {
        setState(() {
          switch (index) {
            case 0:
              // Navigate to HomeScreen only if it's not the current screen
              if (!isHomeScreen) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen(organizationId: organizationId)),
                );
              }
              break;
            case 1:
              // Navigate to StatementScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatementScreen()),
              );
              break;
            case 2:
              // Logout
              FirebaseAuth.instance.signOut().then((value) {
                print("Signed Out");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen(userType: '')),
                );
              });
              break;
          }
        });
      },
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
      Map<String, int> monthOrder = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      
      return monthOrder[partsA[0]]!.compareTo(monthOrder[partsB[0]]!);
    }
  });

  List<DataRow> rows = [];

  // Iterate through the sorted keys to build rows
  for (String key in sortedKeys) {
    Map<String, double> value = analyticsData[key]!;
    rows.add(DataRow(
      cells: [
        DataCell(Text(key, style: TextStyle(color: Colors.black))),
        DataCell(Text(value['totalRevenue'].toString(), style: TextStyle(color: Colors.black))),
        DataCell(Text(value['totalExpense'].toString(), style: TextStyle(color: Colors.black))),
        DataCell(Text(value['totalProfit'].toString(), style: TextStyle(color: Colors.black))),
      ],
    ));
  }

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
 child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black), // Add black border around the table
          ),
          child: DataTable(
            showCheckboxColumn: false,
            columnSpacing: 16.0,
            headingRowColor: MaterialStateColor.resolveWith((states) => Color(0xFFF9D8C5)), // Set header row color
            dividerThickness: 1.0, // Add separator lines between columns
          
          columns: [
            DataColumn(label: Text('Month-Year', style: TextStyle(color: Colors.black))),
            DataColumn(label: Text('Total Revenue', style: TextStyle(color: Colors.black))),
            DataColumn(label: Text('Total Expense', style: TextStyle(color: Colors.black))),
            DataColumn(label: Text('Total Profit', style: TextStyle(color: Colors.black))),
          ],
          rows: rows,
        ),
      ),
    ),
  );
}


}
