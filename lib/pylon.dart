library pylon;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

typedef PylonBuilder = Widget Function(BuildContext context);

/// Represents common route types for [Pylon.push]
enum PylonRouteType {
  /// Represents a [MaterialPageRoute]
  material,

  /// Represents a [CupertinoPageRoute]
  cupertino,
}

/// Combines a [FutureBuilder] with a [Pylon] widget. When the future completes,
/// the value is passed to the [Pylon] widget with the builder function provided
class PylonFuture<T> extends StatelessWidget {
  final Future<T> future;
  final T? initialData;
  final PylonBuilder builder;
  final Widget loading;

  const PylonFuture(
      {super.key,
      required this.future,
      this.initialData,
      required this.builder,
      this.loading = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (context, snap) => snap.hasData
          ? Pylon<T>(
              value: snap.data as T,
              builder: builder,
            )
          : loading);
}

/// Combines a [StreamBuilder] with a [Pylon] widget. When the stream emits a value,
/// the value is passed to the [Pylon] widget with the builder function provided
class PylonStream<T> extends StatelessWidget {
  final Stream<T> stream;
  final T? initialData;
  final PylonBuilder builder;
  final Widget loading;

  const PylonStream(
      {super.key,
      required this.stream,
      this.initialData,
      required this.builder,
      this.loading = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snap) => snap.hasData
          ? Pylon<T>(
              value: snap.data as T,
              builder: builder,
            )
          : loading);
}

/// A widget that provides a value to its descendants. This is useful for passing values
/// to widgets that are not directly related to each other
class Pylon<T> extends StatelessWidget {
  final T value;
  final PylonBuilder? builder;
  final Widget? child;

  const Pylon({super.key, required this.value, required this.builder})
      : child = null;

  /// Use this constructor when you want to pass a value to a single child widget and dont need a builder function.
  /// You can use a child instead of a builder however if you need to use the value immediately in the child widget
  /// then it wont be available until either a builder function is used or the child widget build method uses it
  /// Use the regular constructor for lazy inlining
  const Pylon.withChild({super.key, required this.value, required this.child})
      : builder = null;

  /// This is primarily used for [PylonCluster]. Using this constructor produces a widget which will
  /// throw an error if built as it doesnt have a child or builder function
  const Pylon.data({super.key, required this.value})
      : builder = null,
        child = null;

  /// Returns the value of the nearest ancestor [Pylon] widget of type T or null
  static Pylon<T>? widgetOfOr<T>(BuildContext context) =>
      context.findAncestorWidgetOfExactType<Pylon<T>>();

  /// Returns the value of the nearest ancestor [Pylon] widget of type T or throws an error
  static Pylon<T> widgetOf<T>(BuildContext context) => widgetOfOr(context)!;

  /// Pushes all visible [Pylon] widgets into your builder function's parent widget. This is used for navigation
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget child, {
    PylonRouteType type = PylonRouteType.material,
    Route<T>? route,
  }) =>
      Navigator.push(
          context,
          route ??
              switch (type) {
                PylonRouteType.material =>
                  Pylon.materialPageRoute(context, (context) => child),
                PylonRouteType.cupertino =>
                  Pylon.cupertinoPageRoute(context, (context) => child),
              });

  /// Creates a [MaterialPageRoute] with the [Pylon] widgets mirrored into the builder function to transfer the values
  static MaterialPageRoute<T> materialPageRoute<T extends Object?>(
          BuildContext context, Widget Function(BuildContext) builder) =>
      MaterialPageRoute<T>(builder: mirror(context, builder));

  /// Creates a [CupertinoPageRoute] with the [Pylon] widgets mirrored into the builder function to transfer the values
  static CupertinoPageRoute<T> cupertinoPageRoute<T extends Object?>(
          BuildContext context, Widget Function(BuildContext) builder) =>
      CupertinoPageRoute<T>(builder: mirror(context, builder));

  /// Creates a builder function which produces a PylonCluster of all visible ancestor pylons
  /// from [context] and uses the provided [builder] function. Use this when building custom routes
  static Widget Function(BuildContext) mirror(
      BuildContext context, Widget Function(BuildContext) builder) {
    List<Pylon> providers = [];

    context.visitAncestorElements((element) {
      if (element.widget is Pylon) {
        Pylon p = element.widget as Pylon;

        if (!providers.any((i) => i.runtimeType == p.runtimeType)) {
          providers.add(p);
        }
      }

      return true;
    });

    Widget result = PylonCluster(
      pylons: providers.reversed.toList(),
      builder: builder,
    );

    return (context) => result;
  }

  @override
  Widget build(BuildContext context) => child ?? Builder(builder: builder!);

  /// Returns a copy of this widget with the child widget set to [child]
  Pylon<T> copyWithChild(Widget child) =>
      Pylon.withChild(value: value, child: child);

  /// Returns a copy of this widget with the builder function set to [builder]
  Pylon<T> copyWithBuilder(PylonBuilder builder) =>
      Pylon(value: value, builder: builder);
}

/// A widget that combines multiple [Pylon] widgets into a single widget. This is essentially the same as
/// nesting multiple pylon widgets, but with the advantage of not spamming builder widgets in the widget tree
/// All pylons are built with just an immediate child of the next, with the last pylon provided containing your builder method
/// this ensures all pylons are immediately available to the builder method without spamming builder widgets
class PylonCluster extends StatelessWidget {
  /// Use Pylon<T>.data()
  final List<Pylon> pylons;
  final PylonBuilder builder;

  const PylonCluster({super.key, required this.pylons, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (pylons.isEmpty) {
      return builder(context);
    }

    if (pylons.length == 1) {
      return pylons.first.copyWithBuilder(builder);
    }

    Widget result = pylons.last.copyWithBuilder(builder);

    for (int i = pylons.length - 2; i >= 0; i--) {
      result = pylons[i].copyWithChild(result);
    }

    return result;
  }
}

extension XPylonStream<T> on Stream<T> {
  Widget asPylon(PylonBuilder builder,
          {Key? key,
          T? initialData,
          Widget loading = const SizedBox.shrink()}) =>
      PylonStream<T>(
        key: key,
        stream: this,
        initialData: initialData,
        builder: builder,
        loading: loading,
      );
}

extension XPylonIterable<T> on Iterable<T> {
  List<Widget> withPylons(PylonBuilder builder) =>
      map((e) => Pylon<T>(value: e, builder: builder)).toList();
}

extension XContext on BuildContext {
  /// Returns the value of the nearest ancestor [Pylon] widget of type T or null
  T? pylonOr<T>() =>
      Pylon.widgetOfOr<T>(this)?.value ?? Pylon.widgetOfOr<T?>(this)?.value;

  /// Returns the value of the nearest ancestor [Pylon] widget of type T or throws an error
  T pylon<T>() => pylonOr<T>()!;

  /// Sets the value of the nearest ancestor [MutablePylon] widget of type T
  /// This will throw an error if the pylon is not mutable or if there is
  /// no [MutablePylon] of type T
  void setPylon<T>(T value) => MutablePylon.of<T>(this).value = value;

  /// Modifies the value of the nearest ancestor [MutablePylon] widget of type T
  void modPylon<T>(T Function(T) modifier) {
    MutablePylonState<T> v = MutablePylon.of<T>(this);
    v.value = modifier(v.value);
  }

  /// Returns the stream of the nearest ancestor [MutablePylon] widget of type T
  Stream<T> streamPylon<T>() => MutablePylon.of<T>(this).stream;

  /// Watch (stream) a pylon value of a [MutablePylon] widget of type T
  /// This does not provide a build context, this is just for small widgets
  Widget watchPylon<T>(Widget Function(T data) builder) => StreamBuilder<T>(
        stream: streamPylon<T>(),
        initialData: pylonOr<T>(),
        builder: (context, snap) =>
            snap.hasData ? builder(snap.data as T) : const SizedBox.shrink(),
      );
}

class MutablePylon<T> extends StatefulWidget {
  final T value;
  final PylonBuilder builder;
  final bool rebuildChildren;

  const MutablePylon(
      {super.key,
      required this.value,
      required this.builder,
      this.rebuildChildren = false});

  static MutablePylonState<T>? ofOr<T>(BuildContext context) =>
      context.findAncestorStateOfType<MutablePylonState<T>>();

  static MutablePylonState<T> of<T>(BuildContext context) => ofOr<T>(context)!;

  @override
  State<MutablePylon> createState() => MutablePylonState<T>();
}

class MutablePylonState<T> extends State<MutablePylon> {
  BehaviorSubject<T>? _subject;

  late T _value;

  T get value => _value;

  set value(T value) {
    if (widget.rebuildChildren) {
      try {
        setState(() {
          _value = value;
        });
      } catch (e, es) {
        _value = value;
        debugPrintStack(label: e.toString(), stackTrace: es);
      }
    } else {
      _value = value;
    }
    _subject?.add(value);
  }

  Stream<T> get stream => _subject ??= BehaviorSubject.seeded(_value);

  @override
  void initState() {
    _value = widget.value;
    super.initState();
  }

  @override
  void dispose() {
    _subject?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Pylon<T>(
        value: value,
        builder: widget.builder,
      );
}
