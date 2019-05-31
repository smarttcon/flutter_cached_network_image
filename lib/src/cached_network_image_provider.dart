import 'dart:async' show Future;
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui show instantiateImageCodec, Codec;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

typedef void ErrorListener();

class CachedNetworkImageProvider
    extends ImageProvider<CachedNetworkImageProvider> {
  /// Creates an ImageProvider which loads an image from the [url], using the [scale].
  /// When the image fails to load [errorListener] is called.
  const CachedNetworkImageProvider(this.url,
      {this.minWidth: 1920,
      this.minHeight: 1080,
      this.quality: 70,
      this.rotate: 0,
      this.scale: 1.0,
      this.errorListener,
      this.headers,
      this.cacheManager})
      : assert(url != null),
        assert(scale != null);

  final int minWidth;
  final int minHeight;
  final int quality;
  final int rotate;

  final BaseCacheManager cacheManager;

  /// Web url of the image to load
  final String url;

  /// Scale of the image
  final double scale;

  /// Listener to be called when images fails to load.
  final ErrorListener errorListener;

  // Set headers for the image provider, for example for authentication
  final Map<String, String> headers;

  @override
  Future<CachedNetworkImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return new SynchronousFuture<CachedNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(CachedNetworkImageProvider key) {
    return new MultiFrameImageStreamCompleter(
        codec: _loadAsync(key), scale: key.scale);
  }

  Future<ui.Codec> _loadAsync(CachedNetworkImageProvider key) async {
    var mngr = cacheManager ?? DefaultCacheManager();
    var file = await mngr.getSingleFile(url, headers: headers);
    if (file == null) {
      if (errorListener != null) errorListener();
      return Future<ui.Codec>.error("Couldn't download or retrieve file.");
    }
    return await _loadAsyncFromFile(key, file);
  }

  Future<ui.Codec> _loadAsyncFromFile(
      CachedNetworkImageProvider key, File file) async {
    assert(key == this);
    Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes == 0) {
      if (errorListener != null) errorListener();
      throw new Exception("File was empty");
    } else {
      bytes = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: minHeight,
        minWidth: minWidth,
        quality: quality,
        rotate: rotate,
      );
    }
    return await ui.instantiateImageCodec(bytes);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final CachedNetworkImageProvider typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
