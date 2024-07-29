import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';

void main() => runApp(CounterApp());

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
      builder: (context) => Scaffold(
          body: Center(
            // Access the pylon value. You can use it immediately because pylons are builders
            child: Text("Count: ${context.pylon<int>()}"),
          ),
          floatingActionButton: FloatingActionButton(
            // You can use modPylon<T>((T) => T) to modify the value
            // You could also just use setPylon(T);
            onPressed: () => context.modPylon<int>((t) => t + 1),
            child: Icon(Icons.add),
          )));
}
