import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewEntryScreen extends StatelessWidget {
  final CollectionReference newEntryCollection =
      FirebaseFirestore.instance.collection('newentry');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Entry Screen'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: newEntryCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: documents.map((document) {
                  var documentData = document.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Entry:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        buildMainDocumentTable(documentData),
                        SizedBox(height: 10),
                        Text(
                          'Revenue:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        RevenueTable(document.id, context),
                        SizedBox(height: 10),
                        Text(
                          'Expense:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        ExpenseTable(document.id),
                        SizedBox(height: 10),
                        Text(
                          'Owner Share:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        OwnerShareTable(document.id),
                        SizedBox(height: 10),
                        Text(
                          'Salary to Crew Members:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        SalaryToCrewMembersTable(document.id),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildMainDocumentTable(Map<String, dynamic> documentData) {
    return Table(
      border: TableBorder.all(),
      children: [
        buildTableRow(['Sailing Date', documentData['sailingdate']]),
        buildTableRow(['Return Date', documentData['returndate']]),
        buildTableRow(['Month Considered', documentData['monthconsidered']]),
        buildTableRow(['Total Profit', documentData['totalprofit'].toString()]),
      ],
    );
  }

  TableRow buildTableRow(List<String> values) {
    return TableRow(
      children: values.map((value) => TableCell(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      )).toList(),
    );
  }

  Widget SalaryToCrewMembersTable(String documentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: newEntryCollection.doc(documentId).collection('salarytocrewmembers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<DocumentSnapshot> subcollectionDocuments = snapshot.data!.docs;
          return buildSubcollectionTable('Salary to Crew Members', subcollectionDocuments);
        }
      },
    );
  }

  Widget OwnerShareTable(String documentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: newEntryCollection.doc(documentId).collection('ownershare').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<DocumentSnapshot> subcollectionDocuments = snapshot.data!.docs;
          return buildSubcollectionTable('Owner Share', subcollectionDocuments);
        }
      },
    );
  }

  Widget RevenueTable(String documentId, BuildContext context) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: newEntryCollection.doc(documentId).collection('revenue').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              List<DocumentSnapshot> subcollectionDocuments = snapshot.data!.docs;
              return buildSubcollectionTable('Revenue', subcollectionDocuments);
            }
          },
        ),
        ElevatedButton(
          onPressed: () {
            _showAddRevenueDialog(context, documentId);
          },
          child: Text('Add Revenue'),
        ),
      ],
    );
  }

  void _showAddRevenueDialog(BuildContext context, String documentId) {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Revenue'),
          content: Column(
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addRevenue(context, documentId, double.parse(amountController.text));
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addRevenue(BuildContext context, String documentId, double amount) {
    CollectionReference revenueCollection = newEntryCollection.doc(documentId).collection('revenue');

    revenueCollection.add({
      'amount': amount,
      // Add other fields if any
    });
  }

  Widget ExpenseTable(String documentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: newEntryCollection.doc(documentId).collection('expense').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<DocumentSnapshot> subcollectionDocuments = snapshot.data!.docs;
          return buildSubcollectionTable('Expense', subcollectionDocuments);
        }
      },
    );
  }

  Widget buildSubcollectionTable(String subcollectionName, List<DocumentSnapshot> subcollectionDocuments) {
    if (subcollectionDocuments.isEmpty) {
      return Container(); // Return an empty container if there are no documents
    }

    List<String> subcollectionFieldNames = (subcollectionDocuments[0].data() as Map<String, dynamic>).keys.toList();

    List<TableRow> rows = [
      TableRow(
        children: subcollectionFieldNames.map((fieldName) => TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(fieldName),
          ),
        )).toList(),
      ),
    ];

    for (var subDoc in subcollectionDocuments) {
      var subDocData = subDoc.data() as Map<String, dynamic>;

      List<String> rowValues = subcollectionFieldNames.map((fieldName) {
        return subDocData[fieldName]?.toString() ?? ''; // Handle null values
      }).toList();

      rows.add(TableRow(
        children: rowValues.map((value) => TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(value),
          ),
        )).toList(),
      ));
    }

    return Table(
      border: TableBorder.all(),
      children: rows,
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: NewEntryScreen(),
  ));
}
