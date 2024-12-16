import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:toxic_flutter/extensions/stream.dart';

List<BehaviorSubject> $conduitStreams = [];

class Conduit<T> extends StatelessWidget {
  final Widget Function(BuildContext context, T? value) builder;
  final T? defaultData;

  const Conduit({super.key, required this.builder, this.defaultData});

  @override
  Widget build(BuildContext context) => stream<T>()
      .buildNullable((value) => builder(context, value ?? defaultData));

  static void push<T>(T t) => subject<T>().add(t);

  static void mod<T>(T Function(T) f) => push<T>(f(pull<T>()));

  static void modOr<T>(T Function(T?) f) =>
      push<T>(f(subject<T>().valueOrNull));

  static void destroyAllConduits() => $conduitStreams.clear();

  static void destroy<T>() =>
      $conduitStreams.removeWhere((e) => e is BehaviorSubject<T>);

  static T pull<T>() => subject<T>().value;

  static T pullOr<T>(T t) => subject<T>().valueOrNull ?? t;

  static Stream<T> stream<T>() => subject<T>().stream;

  static BehaviorSubject<T> subject<T>() {
    BehaviorSubject<T>? s =
        $conduitStreams.whereType<BehaviorSubject<T>>().firstOrNull;

    if (s == null) {
      s = BehaviorSubject<T>();
      $conduitStreams.add(s);
    }

    return s;
  }
}
