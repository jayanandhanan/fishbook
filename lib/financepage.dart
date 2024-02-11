// ignore_for_file: unused_local_variable

import 'package:fishbook/analyticsscreen.dart';
import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FinancePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentUser(),
      builder: (context, AsyncSnapshot<User?> userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (userSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${userSnapshot.error}'),
            ),
          );
        }
        final user = userSnapshot.data!;
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> userDataSnapshot) {
            if (userDataSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (userDataSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error: ${userDataSnapshot.error}'),
                ),
              );
            }
            final organizationId = userDataSnapshot.data!['organizationId'];
            final userRole = userDataSnapshot.data!['role'];
            return _buildFinancePage(context,organizationId, userRole);
          },
        );
      },
    );
  }

bool isHomeScreen = false;

  Widget _buildFinancePage(BuildContext context, String organizationId, String userRole) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Page'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _addToDatabase(context, organizationId, userRole),
              child: Text('Monthly Analytics and Chart'),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: _buildFinanceTable(organizationId, userRole),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, organizationId, userRole),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context, String organizationId, String userRole) {
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
        switch (index) { case 0:
            // Navigate to HomeScreen only if it's not the current screen
            if (!isHomeScreen) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(organizationId: organizationId),
                ),
              );
            }
            break;
          case 1:
            // Navigate to StatementScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatementScreen(),
              ),
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
      },
    );
  }

Future<void> _addToDatabase(BuildContext context, String organizationId, String userRole) async {
  try {
    final String orgId = await _getCurrentUserOrganizationId();
    final CollectionReference financeCollection = FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgId)
        .collection('finance');

    // Delete existing documents in the finance collection
    await financeCollection.get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.delete();
      }
    });

    // Fetch the data to be added
    final List<QueryDocumentSnapshot> newEntries = await _fetchNewEntries(orgId);

    // Add new entries to the finance collection
    for (final entry in newEntries) {
      // Add the entry to the finance collection
      await financeCollection.add({
        'month': entry['monthconsidered'],
        'year': _extractYearBasedOnMonthConsidered(entry['monthconsidered'], entry['sailingdate'], entry['returndate']),
        'revenue': await _calculateTotalAmount(entry.reference.collection('revenue'), 'amount'),
        'expense': await _calculateTotalAmount(entry.reference.collection('expense'), 'expenseamount'),
        'profit': entry['remainingamount'],
        'sailingdate': entry['sailingdate'], // Add sailing date
        'returndate': entry['returndate'],   // Add return date
      });
    }

    // Show a SnackBar to indicate successful addition of finance data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Finance data added to database.'),
      ),
    );

    // Navigate to the AnalyticsPage after adding data
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnalyticsPage()),
    );
  } catch (error) {
    // Show a SnackBar if there's an error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
      ),
    );
  }
}


  Future<List<QueryDocumentSnapshot>> _fetchNewEntries(String orgId) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgId)
        .collection('newentry')
        .get();
    return querySnapshot.docs;
  }
  
Widget _buildFinanceTable(String organizationId, String userRole) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('newentry')
        .snapshots(),
    builder: (context, newEntrySnapshot) {
      if (newEntrySnapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (newEntrySnapshot.hasError) {
        return Center(child: Text('Error: ${newEntrySnapshot.error}'));
      }
      final newEntries = newEntrySnapshot.data!.docs;
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
                DataColumn(
                  label: Text('Month', style: TextStyle(color: Colors.black)),
                ),
                DataColumn(
                  label: Text('Year', style: TextStyle(color: Colors.black)),
                ),
                DataColumn(
                  label: Text('Revenue', style: TextStyle(color: Colors.black)),
                ),
                DataColumn(
                  label: Text('Expense', style: TextStyle(color: Colors.black)),
                ),
                DataColumn(
                  label: Text('Profit', style: TextStyle(color: Colors.black)),
                ),
                DataColumn(
                  label: Text('Sailing Date', style: TextStyle(color: Colors.black)),
                ),
                DataColumn(
                  label: Text('Return Date', style: TextStyle(color: Colors.black)),
                ),
              ],
              rows: _buildDataRowList(newEntries),
            ),
          ),
        ),
      );
    },
  );
}

  List<DataRow> _buildDataRowList(List<QueryDocumentSnapshot> newEntries) {
    // Sort the newEntries based on year and month
    newEntries.sort((a, b) {
      // Extract year and month from each entry
      final String monthConsideredA = a['monthconsidered'].toLowerCase();
      final String monthConsideredB = b['monthconsidered'].toLowerCase();
      final Timestamp sailingDateA = a['sailingdate'] as Timestamp;
      final Timestamp sailingDateB = b['sailingdate'] as Timestamp;
      final Timestamp returnDateA = a['returndate'] as Timestamp;
      final Timestamp returnDateB = b['returndate'] as Timestamp;
      final int yearA = _extractYearBasedOnMonthConsidered(monthConsideredA, sailingDateA, returnDateA);
      final int yearB = _extractYearBasedOnMonthConsidered(monthConsideredB, sailingDateB, returnDateB);

      // Compare years first
      if (yearA != yearB) {
        return yearA.compareTo(yearB);
      } else {
        // If years are the same, compare months
        final Map<String, int> monthsOrder = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        };
        final int monthOrderA = monthsOrder[monthConsideredA]!;
        final int monthOrderB = monthsOrder[monthConsideredB]!;
        return monthOrderA.compareTo(monthOrderB);
      }
    });

    List<DataRow> dataRows = [];

    for (final newEntry in newEntries) {
      final monthConsidered = newEntry['monthconsidered'];
      final totalProfit = newEntry['remainingamount'];
      final sailingDate = newEntry['sailingdate'] as Timestamp;
      final returnDate = newEntry['returndate'] as Timestamp;
      final year = _extractYearBasedOnMonthConsidered(monthConsidered, sailingDate, returnDate);

      dataRows.add(
        DataRow(
          cells: [
            DataCell(Text(monthConsidered)),
            DataCell(Text(year.toString())),
            DataCell(
              FutureBuilder(
                future: _calculateTotalAmount(newEntry.reference.collection('revenue'), 'amount'),
                builder: (context, AsyncSnapshot<double> revenueSnapshot) {
                  if (revenueSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  return Text(revenueSnapshot.data.toString());
                },
              ),
            ),
            DataCell(
              FutureBuilder(
                future: _calculateTotalAmount(newEntry.reference.collection('expense'), 'expenseamount'),
                builder: (context, AsyncSnapshot<double> expenseSnapshot) {
                  if (expenseSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  return Text(expenseSnapshot.data.toString());
                },
              ),
            ),
            DataCell(Text(totalProfit.toString())),
            DataCell(Text(_formatDate(sailingDate))), // Display sailing date
            DataCell(Text(_formatDate(returnDate))),  // Display return date
          ],
        ),
      );
    }

    return dataRows;
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('dd-MM-yyyy').format(date);
  }

  Future<String> _getCurrentUserOrganizationId() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      final DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        return userDoc['organizationId'];
      } else {
        throw 'User document does not exist.';
      }
    } else {
      throw 'User is not logged in.';
    }
  }

  Future<double> _calculateTotalAmount(CollectionReference collectionRef, String fieldName) async {
    double totalAmount = 0.0;
    final snapshot = await collectionRef.get();

    for (var doc in snapshot.docs) {
      totalAmount += doc[fieldName] ?? 0.0;
    }

    return totalAmount;
  }

  int _extractYearBasedOnMonthConsidered(String monthConsidered, Timestamp sailingDate, Timestamp returnDate) {
    DateFormat formatter = DateFormat('dd-MM-yyyy');

    DateTime sailingDateTime = sailingDate.toDate();
    DateTime returnDateTime = returnDate.toDate();

    String sailingDateString = formatter.format(sailingDateTime);
    String returnDateString = formatter.format(returnDateTime);

    List<String> sailingDateParts = sailingDateString.split('-');
    List<String> returnDateParts = returnDateString.split('-');

    int year;

    if (sailingDateParts[1] == '01' && monthConsidered.toLowerCase() == 'jan') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '02' && monthConsidered.toLowerCase() == 'feb') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '03' && monthConsidered.toLowerCase() == 'mar') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '04' && monthConsidered.toLowerCase() == 'apr') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '05' && monthConsidered.toLowerCase() == 'may') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '06' && monthConsidered.toLowerCase() == 'jun') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '07' && monthConsidered.toLowerCase() == 'jul') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '08' && monthConsidered.toLowerCase() == 'aug') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '09' && monthConsidered.toLowerCase() == 'sep') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '10' && monthConsidered.toLowerCase() == 'oct') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '11' && monthConsidered.toLowerCase() == 'nov') {
      year = int.parse(sailingDateParts[2]);
    } else if (sailingDateParts[1] == '12' && monthConsidered.toLowerCase() == 'dec') {
      year = int.parse(sailingDateParts[2]);
    } else {
      year = int.parse(sailingDateParts[2]); // Default to sailing date year
    }

    return year;
  }
  
  Future<User?> _getCurrentUser() async {
    return _auth.currentUser;
  }
}
