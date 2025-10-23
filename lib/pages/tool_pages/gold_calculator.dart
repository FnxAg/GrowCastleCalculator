import 'package:flutter/material.dart';

class GoldCalculator extends StatelessWidget {
  const GoldCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Calculator'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(child: Text('Gold Calculator')),
    );
  }
}
