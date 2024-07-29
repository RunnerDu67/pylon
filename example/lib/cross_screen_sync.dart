import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';

void main() => runApp(PylonExampleApp());

class PylonExampleApp extends StatelessWidget {
  const PylonExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Counter(),
      );
}

// Simple counter screen just like in counter_app
// This demonstrates the parent updating when popping the inner
// screen back to this counter screen
class Counter extends StatelessWidget {
  Counter({super.key});

  @override
  Widget build(BuildContext context) => Pylon<int>(
      value: 0,
      builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("Counter"),
            actions: [
              IconButton(
                  // Pushes a new screen with a root of all visible ancestor
                  // pylons as the new ancestors of this new screen
                  onPressed: () => Pylon.push(context, InnerCounter()),
                  icon: Icon(Icons.navigate_next))
            ],
          ),
          body: Center(
            child: Text("Count: ${context.pylon<int>()}"),
          ),
          floatingActionButton: FloatingActionButton(
            // Updates the outer pylon
            onPressed: () => context.modPylon<int>((t) => t + 1),
            child: Icon(Icons.add),
          )));
}

class InnerCounter extends StatelessWidget {
  InnerCounter({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text("Inner Counter")),
      // This accesses the inner pylon on context since
      // the previous screens pylon is not in this widget tree
      body: Text("Count: ${context.pylon<int>()}"),
      floatingActionButton: FloatingActionButton(
        // Updates the inner bridged pylon and the outer pylon at the same time
        onPressed: () => context.modPylon<int>((t) => t - 1),
        child: Icon(Icons.exposure_minus_1),
      ));
}
