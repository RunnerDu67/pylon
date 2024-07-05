Pylon is a very simple package that works very similarly to the [provider](https://pub.dev/packages/provider) package with less features but with more reliability without the headaches.

### A Pylon is a Provider

* When you place a pylon, you always use the builder pattern instead of just a chuld. This ensures that the context is deep enough to find your child.
* Utility Widget PylonCluster for creating multiple pylons nested at once.
* Transfer all visible pylons to a new context (such as navigation) easily

## Placing Pylons

When you place pylons make sure to use the builder pattern, here's why: 

```dart
import 'package:pylon/pylon.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Pylon<String>(
      value: "Hello World", // VISIBLE!
      builder: (context) => Text(context.pylon<String>()),
      //         ^^^ context is here
    );
  }
}
```

However if you use the child only (DON'T)

```dart
import 'package:pylon/pylon.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) { // context is here!
    return Pylon<String>.withChild(
      value: "Hello World", // NOT VISIBLE!
      child: Text(context.pylon<String>()), // null exception!
    );
  }
}
```

### Pylon Clusters

You can create multiple pylons easily with a PylonCluster

```dart
import 'package:pylon/pylon.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PylonCluster(
      pylons: [
        Pylon<String>.data("hello"),
        Pylon<int>.data(42),
      ],
      builder: (context) => Column(
        children: [
          Text(context.pylon<String>()),
          Text(context.pylon<int>().toString()),
        ],
      ),
    );
  }
}
```

### Transfer Pylons

If you are using standard material navigators this is really easy for you
```dart
import 'package:pylon/pylon.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Pylon<String>(
      value: "Hello World",
      builder: (context) => ElevatedButton(
        onPressed: () => Pylon.push(context, AScreen()),
        child: Text("Go to other widget"),
      ),
    );
  }
}

class AScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    // finds Hello World!
    appBar: AppBar(title: Text(context.pylon<String>())),
  );
}
```

When using another type of navigation or flyouts, here's the blown out way of navigating so you can put together your own call

```dart
Navigator.push(context, 
    MaterialPageRoute(
        builder: Pylon.mirror(context, (context) => AScreen())
    )
);
```

### Pylons on Lists of Data 
```dart
import 'package:pylon/pylon.dart';

List<String> people = ["a", "b", "c"];

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      ...people.withPylons((context) => Text(context.pylon<String>())),
    ]
  );
}
```

### Pylons on Futures
```dart
import 'package:pylon/pylon.dart';

Future<String> f = Future.value("Hello World");

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) 
      => f.withPylon((context) => Text(context.pylon<String>());
}
```