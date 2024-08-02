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

class A {
  int v = 0;
  String toString() => "A: $v";
}

class B {
  int v = 0;
  String toString() => "B: $v";
}

class C {
  int v = 0;
  String toString() => "C: $v";
}

Stream<A> sa() async* {
  int g = 0;
  while (true) {
    await Future.delayed(Duration(seconds: 1));
    yield A()..v = g++;
  }
}

Stream<B> sb() async* {
  int g = 0;
  while (true) {
    await Future.delayed(Duration(seconds: 3));
    yield B()..v = g++;
  }
}

Stream<C> sc() async* {
  int g = 0;
  while (true) {
    await Future.delayed(Duration(seconds: 7));
    yield C()..v = g++;
  }
}

GlobalKey b = GlobalKey();
GlobalKey c = GlobalKey();

class Counter extends StatelessWidget {
  Counter({super.key});

  @override //                         Wrap in a pylon of type
  Widget build(BuildContext context) => Pylon<A>(
      value: A(),
      valueStream: sa(),
      builder: (context) => Pylon<B>(
          value: B(),
          valueStream: sb(),
          builder: (context) => Pylon<C>(
              value: C(),
              valueStream: sc(),
              builder: (context) => Scaffold(
                      body: Center(
                    // Access the pylon value. You can use it immediately because pylons are builders
                    child: Column(
                      children: [
                        Text("Count A: ${context.pylon<A>().v}"),
                        Text("Count B: ${context.pylon<B>().v}"),
                        Text("Count C: ${context.pylon<C>().v}"),
                      ],
                    ),
                  )))));
}
