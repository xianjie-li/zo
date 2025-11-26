import "package:flutter/material.dart";

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 20)),
    );
  }
}
