library pylon;

import 'package:flutter/material.dart';
import 'package:toxic_flutter/extensions/future.dart';
import 'package:toxic_flutter/extensions/stream.dart';

extension XBuildContext on BuildContext {
  /// Finds the nearest ancestor [Pylon] of [T] widget and returns its value
  T pylon<T>({T? or}) => (findAncestorWidgetOfExactType<Pylon<T>>()?.value ??
      findAncestorWidgetOfExactType<Pylon<T?>>()?.value ??
      or)!;
}

/// A [PylonCluster] is a widget that hosts nested [Pylon] widgets
class PylonCluster extends StatelessWidget {
  final List<Pylon> pylons;
  final Widget Function(BuildContext context) builder;

  const PylonCluster({super.key, required this.pylons, required this.builder});

  @override
  Widget build(BuildContext context) {
    Widget p = Builder(builder: builder);

    for (Pylon i in pylons.reversed) {
      p = i.modChild(p);
    }

    return p;
  }
}

/// A [Pylon] is a widget that provides a value to its children. When placing a [Pylon] in your widget tree,
/// we use the builder instead of just a child to get the [BuildContext] closer to where it actually is.
/// The reason why the provider package requires builder widgets everywhere is the same reason.
/// By forcing the builder method by default we can ensure objects can always be found even when accessed from a direct child widget.
class Pylon<T> extends StatelessWidget {
  /// The value that this pylon provides
  final T value;

  /// The builder that will be used to build the child widget
  final Widget Function(BuildContext context)? builder;

  /// The child widget that will be used if we arent using a builder
  final Widget? child;

  /// The preferred method, use the builder
  const Pylon(
      {super.key, required this.value, required this.builder, this.child});

  /// Only use this if you have multiple [Pylon] widgets nested and intend to use it after a new context is provided
  const Pylon.withChild({super.key, required this.value, this.child})
      : builder = null;

  /// This is used with [PylonCluster] to provide a value to multiple [Pylon] widgets without providing a builder or child as it will be built for you later
  const Pylon.data(this.value, {super.key})
      : builder = null,
        child = null;

  /// Copies this [Pylon] with a new child
  Pylon<T> modChild(Widget child) => Pylon.withChild(
        key: key,
        value: value,
        child: child,
      );

  @override
  Widget build(BuildContext context) =>
      child ?? Builder(builder: (context) => builder!(context));

  /// Pushes all visible [Pylon] widgets into your builder function's parent widget. This is used for navigation
  static Future<T?> push<T extends Object?>(
          BuildContext context, Widget child) =>
      Navigator.push(context, Pylon.route(context, (context) => child));

  /// Creates a [MaterialPageRoute] with the [Pylon] widgets mirrored into the builder function to transfer the values
  static MaterialPageRoute<T> route<T extends Object?>(
          BuildContext context, Widget Function(BuildContext) builder) =>
      MaterialPageRoute<T>(builder: mirror(context, builder));

  /// Mirrors the [Pylon] widgets into the builder function to transfer the values
  /// Example:
  /// Navigator.push(context, MaterialPageRoute(builder: Pylon.mirror((context) => MyWidget())));
  static Widget Function(BuildContext) mirror(
      BuildContext context, Widget Function(BuildContext) builder) {
    List<Pylon> providers = [];
    context.visitAncestorElements((element) {
      if (element.widget is Pylon) {
        providers.add(element.widget as Pylon);
      }
      return true;
    });

    return (context) {
      Widget p = Builder(builder: builder);

      for (Pylon i in providers.reversed) {
        p = i.modChild(p);
      }

      return p;
    };
  }
}

extension XIterable<T> on Iterable<T> {
  /// Builds [Pylon] widgets for each item in the list with your builder
  Iterable<Widget> withPylons(BuildContext context,
          Widget Function(BuildContext context) builder) =>
      map((t) => Pylon<T>(value: t, builder: (context) => builder(context)));
}

extension XFuture<T> on Future<T> {
  /// Builds a [FutureBuilder] with parent pylon available for use
  Widget withPylon(
          BuildContext context, Widget Function(BuildContext context) builder,
          {Widget? loading}) =>
      build((t) => Pylon<T>(value: t, builder: builder), loading: loading);
}

extension XStream<T> on Stream<T> {
  /// Builds a [StreamBuilder] with parent pylon available for use
  Widget withPylon(
          BuildContext context, Widget Function(BuildContext context) builder,
          {Widget? loading}) =>
      build((t) => Pylon<T>(value: t, builder: builder), loading: loading);
}
