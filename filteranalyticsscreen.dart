import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishbook/chart2_screen.dart';

class FilterAnalyticsPage extends StatefulWidget {
  @override
  _FilterAnalyticsPageState createState() => _FilterAnalyticsPageState();
}

class _FilterAnalyticsPageState extends State<FilterAnalyticsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, Map<String, double>> filteredAnalyticsData = {};

  int? selectedYear;
  String? selectedMonth;
  String? organizationId;
  bool isHomeScreen = false;

  List<int> years = [];
  List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fetchYears();
  }

  List<int> _generateYears() {
    int currentYear = DateTime.now().year;
    List<int> yearList = [];
    for (int i = 1990; i <= currentYear + 20; i++) {
      yearList.add(i);
    }
    return yearList;
  }

  void _fetchYears() {
    setState(() {
      years = _generateYears();
      selectedYear = years.first;
    });
  }

  Future<void> _fetchFilteredAnalyticsData() async {
    try {
      final String orgId = await _getCurrentUserOrganizationId();
      final QuerySnapshot financeSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('finance')
          .get();

      filteredAnalyticsData.clear(); // Clear existing data

      financeSnapshot.docs.forEach((doc) {
        final dynamic month = doc['month'];
        final dynamic year = doc['year'];
        final double revenue = (doc['revenue'] ?? 0).toDouble();
        final double expense = (doc['expense'] ?? 0).toDouble();
        final double profit = (doc['profit'] ?? 0).toDouble();

        // Filter data based on selected year or month
        if ((selectedYear != null && year == selectedYear) ||
            (selectedMonth != null && month == selectedMonth)) {
          final key = '$month-$year';
          if (filteredAnalyticsData.containsKey(key)) {
            filteredAnalyticsData[key]!['totalRevenue'] =
                (filteredAnalyticsData[key]!['totalRevenue'] ?? 0.0) + revenue;
            filteredAnalyticsData[key]!['totalExpense'] =
                (filteredAnalyticsData[key]!['totalExpense'] ?? 0.0) + expense;
            filteredAnalyticsData[key]!['totalProfit'] =
                (filteredAnalyticsData[key]!['totalProfit'] ?? 0.0) + profit;
          } else {
            filteredAnalyticsData[key] = {
              'totalRevenue': revenue,
              'totalExpense': expense,
              'totalProfit': profit,
            };
          }
        }
      });
      setState(() {});
    } catch (error) {
      print('Error fetching filtered analytics data: $error');
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

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filtered Analytics'),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<int>(
              value: selectedYear,
              hint: Text('Select Year'),
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                  selectedMonth = null; // Reset selected month
                  _fetchFilteredAnalyticsData();
                });
              },
              items: years.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            DropdownButton<String>(
              value: selectedMonth,
              hint: Text('Select Month'),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value;
                  selectedYear = null; // Reset selected year
                  _fetchFilteredAnalyticsData();
                });
              },
              items: months.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: _buildFilteredAnalyticsTable(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _addToDatabase();
              },
              child: Text('Chart'),
            ),
            
          ],
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


 Widget _buildFilteredAnalyticsTable() {
  List<String> sortedKeys = filteredAnalyticsData.keys.toList();

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
    Map<String, double> value = filteredAnalyticsData[key]!;
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
            DataColumn(
              label: Text('Month-Year', style: TextStyle(color: Colors.black)),
            ),
            DataColumn(
              label: Text('Total Revenue', style: TextStyle(color: Colors.black)),
            ),
            DataColumn(
              label: Text('Total Expense', style: TextStyle(color: Colors.black)),
            ),
            DataColumn(
              label: Text('Total Profit', style: TextStyle(color: Colors.black)),
            ),
          ],
          rows: rows,
        ),
      ),
    );
  }

  Future<void> _addToDatabase() async {
    try {
      final String orgId = await _getCurrentUserOrganizationId();
      final CollectionReference filteredAnalyticsCollection = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('filtered_analytics');

      // Delete existing documents in the filtered analytics collection
      await filteredAnalyticsCollection.get().then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Add new filtered analytics data as documents
      filteredAnalyticsData.forEach((key, value) {
        filteredAnalyticsCollection.doc(key).set({
          'month-year': key,
          'totalRevenue': value['totalRevenue'],
          'totalExpense': value['totalExpense'],
          'totalProfit': value['totalProfit'],
        });
      });

      // Navigate to Chart2Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chart2Screen(),
        ),
      );
    } catch (error) {
      print('Error adding to database: $error');
    }
  }
}
