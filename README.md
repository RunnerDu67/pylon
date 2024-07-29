Pylon is a very simple package that works very similarly to the [provider](https://pub.dev/packages/provider) package with less features but with more reliability without the headaches.

### Design Philosophy
Unlike other state management packages, Pylon's job is to manage the state. That means we will always trade efficiency and speed for reliability. If it doesnt work 10% of the time, and requires the developer to understand the inner workings of the system, then it's not a good package. Pylon is designed to be simple and reliable, and it will always prioritize that over anything else.

### A Pylon is a Provider

* Pylons work very similarly to providers, except they actually work how you would expect them to.
* Pylons work across navigation routes by bridging them using Pylon.push
* You can stream the value of Pylons using Pylon.stream
* Pylons automatically update their children when they change
* You can access a pylon even if it's the immediate parent of the widget accessing it.
* Pylons bridged backpropagate their values to their ancestor pylons
* Pylons update if the last built value is different from the current value when focus changes. This means when popping the navigator, any pylons updated will actually rebuild on the parent screen.

# Usage

Pylons are quite simple to use. You can simply wrap values into the widget tree and access them without any worry about being able to get it later.

#### Basic Counter

```dart
import 'package:pylon/pylon.dart';

class Counter extends StatelessWidget {
  Counter({super.key});

  @override //               Wrap in a pylon of type
  Widget build(BuildContext context) => Pylon<int>(
    value: 0,
    builder: (context) => Scaffold(
      body: Center(
        // Access the pylon value. You can use it immediately 
        // because pylons are builders
        child: Text("Count: ${context.pylon<int>()}"),
      ), 
      floatingActionButton: FloatingActionButton(
        // You can use modPylon<T>((T) => T) to modify the value
        // You could also just use setPylon(T);
        onPressed: () => context.modPylon<int>((t) => t + 1),
        child: Icon(Icons.add),
      )
    )
  );
}
```

#### Bridging Pylons
In this example we have a list of dog objects which we show in a list view. Each dog is represented by a dog tile widget, onTap will send them to a DogScreen which allows them to modify the age. When popping the screen the list tile we tapped will have the updated age automatically.

```dart
// Basic dog class with copywith
class Dog {
  final String name;
  final int age;
  
  Dog(this.name, this.age);
  
  static Dog copyWith(Dog dog, {String? name, int? age}) =>
      Dog(name ?? dog.name, age ?? dog.age);
}

// A list of dogs
List<Dog> dogs = [
  Dog("Fido", 3),
  Dog("Rex", 5),
  Dog("Spot", 2),
];

// A convenient extension to access the pylon value
extension XContext on BuildContext {
  Dog get dog => pylon<Dog>();
  set dog(Dog value) => setPylon(value);
}

// A list view of our dogs
class DogList extends StatelessWidget {
  const DogList({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    // Map each dog into a Pylon<Dog>(value: e, builder: () => DogTile())
    children: dogs.withPylons((context) => DogTile()),
  );
}

// A list tile for a dog
class DogTile extends StatelessWidget {
  const DogTile({super.key});

  @override
  // Build the tile based on the dog in the parent pylon
  Widget build(BuildContext context) => ListTile(
      title: Text(context.dog.name),
      trailing: Text("${context.dog.age}y old"),
      // Use pylon.push to navigate to the dog screen and keep the context.dog available
      onTap: () => Pylon.push(context, DogScreen()));
}

class DogScreen extends StatelessWidget {
  const DogScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(context.dog.name)),
      body: Center(
        child: Text("Age: ${context.dog.age}"),
      ),
      floatingActionButton: FloatingActionButton(
        // Increment the age on dog which will update this screen & the parent list tile view automatically
        onPressed: () => context.dog = context.dog
            .copyWith(age: context.dog.age + 1),
        child: Icon(Icons.add),
      ));
}
```