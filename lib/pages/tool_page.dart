import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';

class ToolPage extends StatefulWidget {
  const ToolPage({super.key});

  @override
  State<ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tool),
        elevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     style: ElevatedButton.styleFrom(
            //       alignment: Alignment.centerLeft,
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 16,
            //         vertical: 20,
            //       ),
            //     ),
            //     icon: Icon(Icons.build),
            //     label: Text('Button'),
            //     onPressed: () {},
            //   ),
            // ),
            // SizedBox(height: 8),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     style: ElevatedButton.styleFrom(
            //       alignment: Alignment.centerLeft,
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 16,
            //         vertical: 20,
            //       ),
            //     ),
            //     icon: Icon(Icons.build),
            //     label: Text('Button'),
            //     onPressed: () {},
            //   ),
            // ),
            // SizedBox(height: 8),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     style: ElevatedButton.styleFrom(
            //       alignment: Alignment.centerLeft,
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 16,
            //         vertical: 20,
            //       ),
            //     ),
            //     icon: Icon(Icons.build),
            //     label: Text('Button'),
            //     onPressed: () {},
            //   ),
            // ),
            // SizedBox(height: 8),
            Center(child: Text(AppLocalizations.of(context)!.todo)),
          ],
        ),
      ),
    );
  }
}
