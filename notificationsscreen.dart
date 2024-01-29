import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          NotificationItem(message: 'You have a new message'),
          NotificationItem(message: 'Reminder: Meeting at 2 PM'),
          NotificationItem(message: 'Congratulations! You have a new follower'),
          // Add more NotificationItem widgets as needed
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String message;

  const NotificationItem({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(message),
        // Add more details or actions if needed
      ),
    );
  }
}
