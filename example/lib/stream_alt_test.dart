import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';

void main() {
  dPylonDebugTypes.add(int);
  runApp(CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Counter(),
      );
}

Stream<int> itr() async* {
  int i = 0;
  while (true) {
    await Future.delayed(Duration(seconds: 1));
    yield i++;
  }
}

class Counter extends StatelessWidget {
  Counter({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
        stream: itr(),
        builder: (context, s) => Pylon<int>(
            value: s.data ?? 0,
            builder: (context) => Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () => Pylon.push(context, SecondScreen()),
                ),
                body: Center(
                  child: Text("Count: ${context.pylon<int>()}"),
                ))),
      );
}

class SecondScreen extends StatelessWidget {
  SecondScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: context.streamBuildPylon<int>((c) => Text("Count: $c")),
      );
}
