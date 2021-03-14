import 'frames.dart' as f;
import 'dart:async' as async;

typedef Handler = async.FutureOr<void> Function(f.Frame frame);
typedef Middleware = Handler Function(Handler handler);

class Pipeline {
  Pipeline _parent;
  Middleware _middleware;

  Pipeline(){
    this._middleware = null;
    this._parent = null;
  }

  Pipeline.fromParent(this._middleware, this._parent);

  Pipeline addMiddleware(Middleware middleware) => Pipeline.fromParent(middleware, this);

  Handler addHandler(Handler handler) {
    Handler res;
    if (_middleware == null) {
      res = handler;
    }
    else{
      res = _parent.addHandler(_middleware(handler));
    }
    return res;
  }

  Middleware get middleware => addHandler;
}
