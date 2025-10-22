import 'package:flutter/material.dart';

Widget buildTabPage(
  String title,
  IconData icon, {
  required Widget child,
}) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.deepPurpleAccent,
      title: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
    body: child,
  );
}
