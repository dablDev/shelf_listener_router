import 'dart:async' as async;
import 'dart:typed_data' as t;
import 'package:messagepack/messagepack.dart' as pack;

import 'package:shelf_listener_router/listener_router.dart' as lr;

void main(){
  lr.Router external_router = lr.Router(
      (lr.Handler handler){
        return (lr.Frame frame) {
          print('Middleware in external router on url ${frame.url}');
          handler(frame);
        };
      }
  );
  lr.Router internal_router = lr.Router();
  internal_router.add('/url', (lr.Frame frame) {
    print('Handler in /url ${frame.payload}');
  });

  external_router.mount('/gen/', internal_router, (lr.Handler handler){
    return (lr.Frame frame) {
      print('Middleware in internal router, headers: ${frame.headers}');
      handler(frame);
    };
  });


  pack.Packer p = pack.Packer();
  p.packInt(2);

  async.StreamController<t.Uint8List> s = async.StreamController<t.Uint8List>.broadcast();
  s.stream.listen(external_router.getlistener(
          (lr.Handler handler) =>
          (lr.Frame frame) {
            print('Middleware in listener');
            handler(frame);
          }
  ));

  s.sink.add(lr.getMsgBytes(p.takeBytes(), '/gen/url', <String, String>{'f': '2'}));
}