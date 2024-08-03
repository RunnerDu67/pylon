library pylon;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// Just a simple builder method, nothing to see here, move along
typedef PylonBuilder = Widget Function(BuildContext context);

/// Represents common route types for [Pylon.push]
enum PylonRouteType {
  /// Represents a [MaterialPageRoute]
  material,

  /// Represents a [CupertinoPageRoute]
  cupertino,
}

extension XStream<T> on Stream<T> {
  /// Converts a [Stream] to a [Pylon] with an initial value of [initial]
  Pylon<T> asPylon(
    T initial,
    PylonBuilder builder, {
    bool updateChildren = true,
    bool updateChildrenOnFocus = true,
  }) {
    return Pylon(
        key: ValueKey(initial),
        value: initial,
        builder: builder,
        updateChildren: updateChildren,
        updateChildrenOnFocus: updateChildrenOnFocus,
        valueStream: this);
  }
}

extension XStreamIterable<T> on Stream<Iterable<T>> {
  /// Converts a [Stream] of [Iterable] to a [Stream] of [Pylon]
  Stream<Iterable<Pylon<T>>> withPylons(
    PylonBuilder builder, {
    bool updateChildren = true,
    bool updateChildrenOnFocus = true,
  }) async* {
    await for (Iterable<T> i in this) {
      yield i.withPylons(builder,
          updateChildren: updateChildren,
          updateChildrenOnFocus: updateChildrenOnFocus);
    }
  }
}

extension XFuture<T> on Future<T> {
  // Converts a [Future] to a [Pylon] with an initial value of [initial]
  Pylon<T> asPylon(
    T initial,
    PylonBuilder builder, {
    bool updateChildren = true,
    bool updateChildrenOnFocus = true,
  }) {
    BehaviorSubject<T> subject = BehaviorSubject.seeded(initial);
    then((v) {
      subject.add(initial);
      subject.close();
    });
    return Pylon(
        key: ValueKey(initial),
        value: initial,
        builder: builder,
        updateChildren: updateChildren,
        updateChildrenOnFocus: updateChildrenOnFocus,
        valueStream: subject.stream);
  }
}

extension XIterable<T> on Iterable<T> {
  // Converts an [Iterable] to a
  List<Pylon<T>> withPylons(PylonBuilder builder,
          {bool updateChildren = true, bool updateChildrenOnFocus = true}) =>
      map((e) => Pylon(
          key: ValueKey(e),
          updateChildren: updateChildren,
          value: e,
          builder: builder,
          updateChildrenOnFocus: updateChildrenOnFocus)).toList();
}

extension XBuildContext on BuildContext {
  /// Finds the nearest ancestor [Pylon] of type [T] and returns its value
  T pylon<T>() => (Pylon.of<T>(this)?.value ?? Pylon.of<T?>(this)?.value)!;

  /// Sets the value of the nearest ancestor [Pylon] of type [T] to [value]
  void setPylon<T>(T value) => Pylon.of<T>(this)!.value = value;

  /// Modifies the value of the nearest ancestor [Pylon] of type [T] with [modifier]
  void modPylon<T>(T Function(T value) modifier) =>
      setPylon(modifier(pylon<T>()));

  /// Returns the value stream of the nearest ancestor [Pylon] of type [T]
  Stream<T> streamPylon<T>() =>
      (Pylon.of<T>(this)?.stream ?? Pylon.of<T?>(this)?.stream.whereType<T>())!;

  /// Builds a [StreamBuilder] with the value stream of the nearest ancestor [Pylon] of type [T]
  Widget streamBuildPylon<T>(Widget Function(T value) builder) =>
      StreamBuilder<T>(
          stream: streamPylon<T>(),
          builder: (context, snap) =>
              snap.hasData ? builder(snap.data as T) : const SizedBox.shrink());
}

/// A widget that provides a value to its descendants
/// Supports bridging pylons into new widgets across widget trees (navigation stacks)
/// Supports streaming the value to its descendants
/// Supports updating its children automatically when the value changes
class Pylon<T> extends StatefulWidget {
  /// The initial value of the [Pylon]
  final T value;

  /// The widget builder function that receives the [BuildContext] of the [Pylon]
  final PylonBuilder builder;

  /// Whether to update the children when the value changes
  final bool updateChildren;

  /// The value stream of the [Pylon] which will update the pylon from the stream
  final Stream<T>? valueStream;

  /// The upstream [Pylon] that will be updated when the value changes and backprop changes
  /// to the parent pylon. Don't define this it's used with Pylon.mirror()
  final BehaviorSubject<T>? $upstream;

  /// If [updateChildren] is true, this will update the children when the nearest ancestor
  /// focus scope has regained focus, but only if the state value is different from the last-built
  /// value. This ensures pylons update their children when popping the navigation stack and the resumed
  /// screen has the latest pylons values actually built.
  final bool updateChildrenOnFocus;

  const Pylon({
    super.key,
    this.valueStream,
    this.$upstream,
    required this.value,
    required this.builder,
    this.updateChildren = true,
    this.updateChildrenOnFocus = true,
  });

  @override
  State<Pylon<T>> createState() => PylonState();

  /// Gets the pylon state of type [T] from the [BuildContext]
  static PylonState<T>? of<T>(BuildContext context) =>
      context.findAncestorStateOfType<PylonState<T>>();

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

  /// Mirrors the [Pylon] widgets observable to [context] as an ancestor tree of [builder]
  /// This also bridges the pylons back to this pylon such that modifications on the mirror
  /// are bridged back to the original pylon
  static Widget Function(BuildContext) mirror(
      BuildContext context, Widget Function(BuildContext) builder) {
    List<(Pylon, PylonState)> providers = [];

    context.visitAncestorElements((element) {
      if (element.widget is Pylon) {
        Pylon p = element.widget as Pylon;

        if (!providers.any((i) => i.$1.runtimeType == p.runtimeType)) {
          PylonState state = (element as StatefulElement).state as PylonState;
          providers.add((p, state));
        }
      }

      return true;
    });

    return (context) {
      Widget finalChild = Builder(builder: builder);

      for ((Pylon, PylonState) i in providers.reversed) {
        Widget at = finalChild;
        finalChild = i.$2.bridge((context) => at);
      }

      return finalChild;
    };
  }
}

/// The state of a [Pylon] widget
class PylonState<T> extends State<Pylon<T>> {
  late T _initialValue;
  late BehaviorSubject<T> _subject;
  late StreamSubscription<T>? _upstreamListener;
  late StreamSubscription<T>? _valueStreamListener;
  bool _ignoreNextEvent = false;
  VoidCallback? _focusListener;
  late FocusScopeNode? _focusScope;
  late T? _lastBuilt;

  /// The value of the [Pylon]
  T get value => _subject.value;

  /// Sets the value of the [Pylon], updating the upstream [Pylon] if it exists
  /// If [Pylon.updateChildren] is true, it will also update the children by
  /// calling setState
  set value(T value) {
    if (widget.$upstream != null && !_ignoreNextEvent) {
      widget.$upstream!.add(value);
    }

    _subject.add(value);
    _tryUpdateChildren();
  }

  void _tryUpdateChildren() {
    if (widget.updateChildren && mounted) {
      try {
        setState(() {});
      } catch (e) {
        if (kDebugMode) {
          print(
              "Failed to call setState on mounted $runtimeType with updateChildren = true $e");
        }
      }
    }
  }

  Stream<T> get stream => _subject.stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.updateChildrenOnFocus) {
      _focusScope = FocusScope.of(context);
    }
  }

  void _setupFocusListener() {
    if (widget.updateChildrenOnFocus) {
      _focusListener = () {
        if (widget.updateChildren && mounted && _lastBuilt != value) {
          try {
            if (FocusScope.of(context).hasFocus) {
              setState(() {});
            }
          } catch (e) {
            if (kDebugMode) {
              print("Failed to call setState on mounted $runtimeType $e");
            }
          }
        }
      };
      _focusScope?.addListener(_focusListener!);
    }
  }

  /// Creates a new pylon that bridges the pylons upstream to the downstream
  /// This is used for bridging pylons across widget trees (pylon mirrors)
  Pylon<T> bridge(PylonBuilder builder) => Pylon<T>(
      $upstream: _subject,
      value: value,
      builder: builder,
      updateChildren: widget.updateChildren,
      updateChildrenOnFocus: widget.updateChildrenOnFocus);

  @override
  void initState() {
    _initialValue = widget.value;
    _subject = BehaviorSubject.seeded(widget.value);
    _valueStreamListener = widget.valueStream?.listen((v) => value = v);
    _upstreamListener = widget.$upstream?.listen((value) {
      if (!_ignoreNextEvent) {
        _subject.add(value);
        _tryUpdateChildren();
      }

      _ignoreNextEvent = false;
    });

    if (widget.updateChildrenOnFocus) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _setupFocusListener());
    }
    super.initState();
  }

  @override
  void dispose() {
    _upstreamListener?.cancel();
    _valueStreamListener?.cancel();
    _subject.close();

    if (_focusListener != null) {
      _focusScope?.removeListener(_focusListener!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _lastBuilt = value;

    return KeyedSubtree(
        key: ValueKey<T>(_initialValue),
        child: Builder(
          builder: widget.builder,
        ));
  }
}
