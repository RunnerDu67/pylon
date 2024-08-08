import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';

void main() => runApp(CounterApp());

Stream<int> cnt() async* {
  int i = 0;
  while (true) {
    await Future.delayed(Duration(seconds: 1));
    yield i++;
  }
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Counter(),
      );
}

class Counter extends StatelessWidget {
  Counter({super.key});

  @override //                         Wrap in a pylon of type
  Widget build(BuildContext context) => Pylon<int>(
      value: 0,
      valueStream: cnt(),
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
            // Access the pylon value. You can use it immediately because pylons are builders
            child: Text("Count: ${context.pylon<int>()}"),
          )));
}

class InnerCounter extends StatelessWidget {
  InnerCounter({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text("Inner Counter")),
      // This accesses the inner pylon on context since
      // the previous screens pylon is not in this widget tree
      body: context.streamBuildPylon((i) => Text("Count: $i")));
}
