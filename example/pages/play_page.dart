import "package:flutter/material.dart";

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DatePickerDialog(
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialCalendarMode: DatePickerMode.year,
            ),
          ],
        ),
      ),
    );
  }
}
