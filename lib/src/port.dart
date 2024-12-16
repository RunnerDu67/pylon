import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';
import 'package:pylon/src/util/address_bar_io.dart'
    if (dart.library.js_interop) 'package:pylon/src/util/address_bar_js.dart'
    if (dart.library.html) 'package:pylon/src/util/address_bar_html.dart';
import 'package:toxic/extensions/future.dart';

class PylonPort<T extends PylonCodec> extends StatefulWidget {
  final String tag;
  final PylonBuilder builder;
  final Widget loading;
  final Widget error;

  /// Setting nullable to true will never show a loading screen. Instead the pylons will just be null.
  final bool nullable;

  /// Setting errorsAreNull to true will treat errors as null values. This can only be used if nullable is true
  final bool errorsAreNull;

  const PylonPort(
      {super.key,
      required this.tag,
      required this.builder,
      this.nullable = false,
      this.errorsAreNull = false,
      this.loading = const SizedBox.shrink(),
      this.error = const Text("Something went wrong")})
      : assert((errorsAreNull && nullable) || !errorsAreNull,
            'errorsAreNull can only be true if nullable is true');

  @override
  State<PylonPort> createState() => _PylonPortState<T>();
}

class _PylonPortState<T extends PylonCodec> extends State<PylonPort<T>> {
  late Future<T?> value;
  late PylonCodec codec;
  T? initialData;

  @override
  void initState() {
    assert(pylonCodecs[T] != null,
        'No codec registered for type $T. Use registerPylonCodec<$T>(const $T()); somewhere in your main before app launch!');
    codec = pylonCodecs[T] as PylonCodec;
    T? value = context.pylonOr<T>();

    if (value != null) {
      pushUrl(value);
      initialData = value;
      this.value = Future.value(value);
    } else {
      this.value = pullUrl().bang.thenRun((u) => pushUrl(u));
    }

    this.value = this.value.catchError((e, ex) {
      if (kDebugMode) {
        print("PylonPort Error $e, $ex");
      }
    });

    if (widget.errorsAreNull) {
      this.value = this.value.catchError((e) => null);
    }

    super.initState();
  }

  void pushUrl(T value) {
    if (kIsWeb) {
      Uri uri = Uri.parse($hrefPylon);
      $pushHrefPylon(
          null,
          "",
          uri.replace(queryParameters: {
            ...uri.queryParameters,
            widget.tag: codec.pylonEncode(value)
          }).toString());
    }
  }

  Future<T?> pullUrl() async {
    if (kIsWeb) {
      Uri uri = Uri.parse($hrefPylon);
      String? value = uri.queryParameters[widget.tag];
      if (value != null) {
        return codec.pylonDecode(value).then((v) => v as T);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => PylonFuture<T?>(
      future: value,
      builder: widget.builder,
      error: widget.error,
      loading: widget.nullable
          ? Pylon<T?>(value: null, builder: widget.builder)
          : widget.loading,
      initialData: initialData);
}
