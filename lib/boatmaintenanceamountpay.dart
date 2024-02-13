import 'package:fishbook/home_screen.dart';
import 'package:fishbook/login_screen.dart';
import 'package:fishbook/statementsscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class BoatMaintenanceAmountPage extends StatefulWidget {
  @override
  _BoatMaintenanceAmountPageState createState() =>
      _BoatMaintenanceAmountPageState();
}

class _BoatMaintenanceAmountPageState
    extends State<BoatMaintenanceAmountPage> {
  String? organizationId;
  String? selectedMaintenanceDocumentId;
  List<DocumentSnapshot> ownerDetails = [];
  List<DocumentSnapshot> boatMaintenanceAmounts = [];
  bool paymentprocessed = false;
  bool isHomeScreen = false;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentUserId = user.uid;
      await fetchOrganizationId(currentUserId);
      await fetchOwnerDetails();
      await fetchBoatMaintenanceAmounts();
    }
  }

  Future<void> fetchOrganizationId(String currentUserId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    setState(() {
      organizationId = userDoc['organizationId'];
    });
  }

  Future<void> fetchOwnerDetails() async {
    if (organizationId != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('ownerdetails')
          .get();
      setState(() {
        ownerDetails = querySnapshot.docs;
      });
    }
  }

  Future<void> fetchBoatMaintenanceAmounts() async {
    if (organizationId != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('boatmaintenanceamounts')
          .get();
      setState(() {
        boatMaintenanceAmounts = querySnapshot.docs;
      });
    }
  }

  Future<void> updateBoatMaintenanceAmounts() async {
    if (organizationId != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('boatmaintenanceamounts')
          .get();
      setState(() {
        boatMaintenanceAmounts = querySnapshot.docs;
      });
    }
  }

Future<void> _showAssignSailingDateDialog() async {
  List<DocumentSnapshot> filteredDocuments = boatMaintenanceAmounts.where((document) => document['remainingboatmaintenanceamount'] != 0).toList();

  String? selectedDocumentId = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Select Sailing Date'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: filteredDocuments.length,
            itemBuilder: (context, index) {
              var document = filteredDocuments[index];
              Timestamp sailingDateTimestamp = document['sailingdate'];
              DateTime sailingDate = sailingDateTimestamp.toDate();
              String formattedDate = DateFormat('dd-MM-yyyy').format(sailingDate);
              return ListTile(
                title: Text('Sailing Date: $formattedDate'),
                subtitle: Text('Remaining Maintenance Amount: ${document['remainingboatmaintenanceamount']}'),
                onTap: () {
                  Navigator.pop(context, document.id);
                },
              );
            },
          ),
        ),
      );
    },
  );

  if (selectedDocumentId != null) {
    setState(() {
      selectedMaintenanceDocumentId = selectedDocumentId;
    });
  }
}


  Future<void> _payBoatMaintenance() async {
    if (selectedMaintenanceDocumentId != null) {
      var selectedDocument = boatMaintenanceAmounts.firstWhereOrNull(
        (element) => element.id == selectedMaintenanceDocumentId,
      );
      if (selectedDocument != null) {
        double remainingMaintenanceAmount =
            selectedDocument['remainingboatmaintenanceamount'];
        double boatMaintenanceAmount =
            selectedDocument['boatmaintenanceamount'];
        if (remainingMaintenanceAmount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Cannot pay for maintenance with zero remaining amount!')),
          );
          return;
        }

        String paymentDateField = 'paymentdate';
        String amountField = 'amount';
        String paymentField = 'payment';
        String modeOfPaymentField = 'modeofpayment';
        String inChargeIdField = 'inchargeid';
        String userField = 'user';

        String? selectedPaymentMethod = 'Cash'; // Initial value 'Cash'
        await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select Payment Method'),
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return DropdownButton<String>(
                    hint: Text('Select Payment Method'),
                    value: selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value;
                      });
                    },
                    items: ['Cash', 'UPI', 'Net Banking']
                        .map<DropdownMenuItem<String>>(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Add payment details to maintenancepayments sub-collection
                    DateTime now = DateTime.now();
                    // Extracting date without time
                    DateTime dateOnly = DateTime(now.year, now.month, now.day);
                    Timestamp formattedDate =
                        Timestamp.fromDate(dateOnly);

                    for (var ownerDetail in ownerDetails) {
                      double share = double.parse(ownerDetail['share']);
                      double remainingAmountShare =
                          (share / 100) * remainingMaintenanceAmount;
                      await FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(organizationId!)
                          .collection('maintenancepayments')
                          .add({
                        'name': ownerDetail['name'],
                        paymentDateField: formattedDate, // Storing Timestamp
                        amountField: remainingAmountShare,
                        paymentField: 'Paid',
                        modeOfPaymentField: selectedPaymentMethod,
                        inChargeIdField: ownerDetail.id,
                        userField:'Owner',
                      });
                    }

                    // Update boat maintenance amount document
                    await FirebaseFirestore.instance
                        .collection('organizations')
                        .doc(organizationId!)
                        .collection('boatmaintenanceamounts')
                        .doc(selectedMaintenanceDocumentId)
                        .update({
                      'usedamount': boatMaintenanceAmount,
                      'remainingboatmaintenanceamount': 0,
                    });
                    await updateBoatMaintenanceAmounts();
                    setState(() {
                      paymentprocessed = true;
                      // Set the selectedMaintenanceDocumentId to null to reset the selection
                      selectedMaintenanceDocumentId = null;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Payments processed successfully!')),
                    );
                    
                    Navigator.pop(context);
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Boat Maintenance Amounts'),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAssignSailingDateDialog,
              child: Text('Select Boat Maintenance Amount'),
            ),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.0),
                ),
                headingRowColor: MaterialStateColor.resolveWith(
                    (states) => Color(0xFFF9D8C5)),
                columnSpacing: 16.0,
              columns: [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Invest')),
                DataColumn(label: Text('Share')),
                DataColumn(label: Text('Boatmaintenance Amount Share')),
              ],
              rows: ownerDetails.map((ownerDetail) {
                double share = double.parse(ownerDetail['share']);
                double remainingAmountShare = 0.0;

                if (selectedMaintenanceDocumentId != null) {
                  var selectedDocument = boatMaintenanceAmounts
                      .firstWhereOrNull((element) =>
                          element.id == selectedMaintenanceDocumentId);
                  if (selectedDocument != null) {
                    double remainingMaintenanceAmount =
                        selectedDocument['remainingboatmaintenanceamount'];
                    remainingAmountShare =
                        (share / 100) * remainingMaintenanceAmount;
                  }
                }

                return DataRow(cells: [
                  DataCell(Text(ownerDetail['name'].toString())),
                  DataCell(Text(ownerDetail['email'].toString())),
                  DataCell(Text(ownerDetail['phone'].toString())),
                  DataCell(Text(ownerDetail['invest'].toString())),
                  DataCell(Text(ownerDetail['share'].toString())),
                  DataCell(Text(
                      selectedMaintenanceDocumentId == null
                          ? '0'
                          : remainingAmountShare.toString())),
                ]);
              }).toList(),
            ),),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedMaintenanceDocumentId == null
                  ? null
                  : _payBoatMaintenance,
              child: Text('Pay'),
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
