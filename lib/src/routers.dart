import 'dart:typed_data' as t;
import 'dart:async' as async;

import 'handlers.dart' as h;
import 'frames.dart' as f;


typedef Listener = async.FutureOr<void> Function(dynamic bytes);

typedef Logger = void Function(String msg);

class Router{
  h.Middleware _middleware ;
  Logger _logger;
  Map<String, h.Handler> _handlers;

  Router([h.Middleware middleware, Logger logger]){
    this._middleware = middleware ?? (h.Handler handler) => handler;
    this._logger = logger ?? print;
    this._handlers = <String, h.Handler>{};
  }

  void add(String url, h.Handler handler){
    ArgumentError.checkNotNull(url);
    ArgumentError.checkNotNull(handler);
    if (!url.startsWith('/')){
      throw ArgumentError('Url ${url} must start with /');
    };
    if (this._handlers.containsKey(url)){
      throw ArgumentError('Url ${url} has been repeated');
    }
    this._handlers[url] = this._middleware(handler);
  }

  void mount(String prefix, Router router, [h.Middleware middleware]){
    ArgumentError.checkNotNull(prefix);
    ArgumentError.checkNotNull(router);
    if (!prefix.startsWith('/')){
      throw ArgumentError('Prefix ${prefix} must start with /');
    };
    if (!prefix.endsWith('/')){
      throw ArgumentError('Prefix ${prefix} must end with /');
    };

    String new_url;
    if (middleware == null){
      middleware = (h.Handler handler) => handler;
    }

    for (String url in router._handlers.keys){
      new_url = prefix + url.replaceFirst('/', '');
      this._handlers[new_url] = this._middleware(middleware(router._handlers[url]));
    }
  }

  Listener getlistener([h.Middleware middleware]) {
    return (dynamic bytes) async{
      middleware = middleware ?? (h.Handler handler) => handler;
      f.Frame frame;
      try {
        frame = f.Frame.read(bytes as t.Uint8List);
      }
      catch (e, s) {
        this._logger('Message is not a frame');
        this._logger('Exception details:\n $e');
        this._logger('Stack trace:\n $s');
      }

      if (frame != null){
        if (!this._handlers.containsKey(frame.url)){
          this._logger('No handler for ${frame.url}');
        }
        else{
          try {
            await middleware(this._handlers[frame.url])(frame);
          }
          catch (e, s) {
            this._logger('Handler ${frame.url} crashed');
            this._logger('Exception details:\n $e');
            this._logger('Stack trace:\n $s');
          }
        }
      }
    };
  }
}

t.Uint8List getMsgBytes(t.Uint8List payload, String url, [Map<String, String> headers]){
  f.Frame frame = f.Frame(payload, url, headers);
  return frame.write();
}