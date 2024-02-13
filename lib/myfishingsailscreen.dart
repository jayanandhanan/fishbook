import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyFishingSailScreen extends StatefulWidget {
  @override
  _MyFishingSailScreenState createState() => _MyFishingSailScreenState();
}

class _MyFishingSailScreenState extends State<MyFishingSailScreen> {
  String? currentUserId;
  List<DocumentSnapshot> paymentDocuments = [];
  String? userRole;
  bool isHomeScreen = false;
  String? organizationId;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    _fetchUserRole();
  }

  Future<void> getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      await fetchOrganizationId();
      fetchPaymentDocuments();
    }
  }

  Future<void> _fetchUserRole() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      setState(() {
        userRole = userSnapshot['role'];
      });
    }
  }

  Future<void> fetchOrganizationId() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    setState(() {
      organizationId = userDoc['organizationId'];
    });
  }

  Future<void> fetchPaymentDocuments() async {
    if (organizationId != null) {
      QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('paymentdetails')
          .where('inchargeid', isEqualTo: currentUserId)
          .get();
      setState(() {
        paymentDocuments = paymentSnapshot.docs;
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('My Fishing Payment'),
      backgroundColor: Colors.blue,
    ),
    bottomNavigationBar: buildBottomNavigationBar(context,false),
    body: Padding(
      padding: EdgeInsets.only(top: 16.0), // Add padding to the top
      child: SingleChildScrollView(
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
                DataColumn(label: Text('Payment Date')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Paid Amount')),
                DataColumn(label: Text('Pending Amount')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Mode Of Payment')), 
              ],
              rows: paymentDocuments.map((doc) {

                // Convert date timestamp to DateTime
                DateTime? date = (doc['paymentdate'] as Timestamp?)?.toDate();
                // Convert date DateTime to formatted string
                String formattedDate = date != null
                    ? '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}'
                    : '';

                String amountValue = userRole == 'Crewmember'
                    ? (doc['amount'] ?? 0.0)
                    : (doc['remainingamountshare'] ?? 0.0);

                return DataRow(cells: [
                  DataCell(Text(formattedDate)), 
                  DataCell(Text(doc['name'] ?? '')),
                  DataCell(Text(amountValue)),
                  DataCell(Text(doc['paidamount'] ?? '')),
                  DataCell(Text(doc['pendingamount'] ?? '')),
                  DataCell(Text(doc['payment'] ?? '')),
                  DataCell(Text(doc['modeofpayment'] ?? '')),
                ]);
              }).toList(),
            ),
          ),
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
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              });
              break;
          }
        });
      },
    );
  }

}
