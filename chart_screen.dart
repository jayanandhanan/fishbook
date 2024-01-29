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

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      final String orgId = await _getCurrentUserOrganizationId();
      final QuerySnapshot analyticsSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('analytics')
          .get();

      setState(() {
        chartData = analyticsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chart'),
      ),
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
}
