import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class ChartData {
  final String monthYear;
  final double totalRevenue;
  final double totalExpense;
  final double totalProfit;

  ChartData({
    required this.monthYear,
    required this.totalRevenue,
    required this.totalExpense,
    required this.totalProfit,
  });

  factory ChartData.fromMap(Map<String, dynamic> map) {
    return ChartData(
      monthYear: map['month-year'],
      totalRevenue: map['totalRevenue'].toDouble(),
      totalExpense: map['totalExpense'].toDouble(),
      totalProfit: map['totalProfit'].toDouble(),
    );
  }
}

class Chart2Screen extends StatefulWidget {
  const Chart2Screen({Key? key}) : super(key: key);

  @override
  _Chart2ScreenState createState() => _Chart2ScreenState();
}

class _Chart2ScreenState extends State<Chart2Screen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    String? organizationId;
  bool isHomeScreen = false;

  List<Map<String, dynamic>> chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchFilteredAnalyticsData();
  }

  Future<void> _fetchFilteredAnalyticsData() async {
    try {
      final String orgId = await _getCurrentUserOrganizationId();
      final QuerySnapshot filteredAnalyticsSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('filtered_analytics')
          .get();

      setState(() {
        chartData = filteredAnalyticsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
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
        title: Text('Chart'),
         backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, false),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              _buildBarChart(),
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

  Widget _buildBarChart() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // Set height to 70% of the screen height
      width: MediaQuery.of(context).size.width * 0.9, // Set width to 90% of the screen width
      child: charts.BarChart(
        _buildSeries(),
        animate: true,
        domainAxis: charts.OrdinalAxisSpec(
          renderSpec: charts.SmallTickRendererSpec(
            labelStyle: charts.TextStyleSpec(
              color: charts.MaterialPalette.black,
            ),
          ),
        ),
        behaviors: [
          charts.SeriesLegend(
            position: charts.BehaviorPosition.bottom,
            horizontalFirst: false,
            cellPadding: EdgeInsets.all(4.0),
            entryTextStyle: charts.TextStyleSpec(
              color: charts.MaterialPalette.black,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<charts.Series<ChartData, String>> _buildSeries() {
    List<ChartData> chartDataList =
        chartData.map((data) => ChartData.fromMap(data)).toList();

    // Sort the data by month and year
    chartDataList.sort((a, b) {
      List<String> partsA = a.monthYear.split('-');
      List<String> partsB = b.monthYear.split('-');

      int yearComparison = partsA[1].compareTo(partsB[1]);
      if (yearComparison != 0) {
        return yearComparison;
      } else {
        // If years are the same, compare months
        return _getMonthNumber(partsA[0]).compareTo(_getMonthNumber(partsB[0]));
      }
    });

    return [
      charts.Series<ChartData, String>(
        id: 'Revenue',
        domainFn: (ChartData data, _) => data.monthYear,
        measureFn: (ChartData data, _) => data.totalRevenue,
        data: chartDataList,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      ),
      charts.Series<ChartData, String>(
        id: 'Expense',
        domainFn: (ChartData data, _) => data.monthYear,
        measureFn: (ChartData data, _) => data.totalExpense,
        data: chartDataList,
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      ),
      charts.Series<ChartData, String>(
        id: 'Profit',
        domainFn: (ChartData data, _) => data.monthYear,
        measureFn: (ChartData data, _) => data.totalProfit,
        data: chartDataList,
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      ),
    ];
  }

  // Helper function to get the month number from its name
  int _getMonthNumber(String monthName) {
    switch (monthName.toLowerCase()) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
      default:
        return 0; // Return 0 for unknown month
    }
  }
}
