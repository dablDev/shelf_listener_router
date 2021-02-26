import 'dart:typed_data' as t;
import 'package:messagepack/messagepack.dart' as pack;


class Frame{

  String _url;
  Map<String, String> _headers;
  t.Uint8List _payload;

  String get url => _url;
  Map<String, String> get headers => _headers;
  t.Uint8List get payload => _payload;

  Frame(this._payload, this._url, [this._headers]);

  t.Uint8List write(){
    pack.Packer p = pack.Packer();
    if (this._headers == null){
      p.packInt(0);
    }
    else {
      p.packInt(this._headers.length);
      for (String key in this._headers.keys){
        p.packString(key);
        p.packString(this._headers[key]);
      }
    }
    p.packString(this._url);
    p.packBinary(this._payload);
    return p.takeBytes();
  }

  Frame.read(t.Uint8List bytes){
    pack.Unpacker u = pack.Unpacker(bytes);
    int map_length = u.unpackInt();
    if (map_length > 0){
      this._headers = <String, String>{};
      int i = 0;
      String key, value;
      while (i < map_length){
        key = u.unpackString();
        value = u.unpackString();
        this._headers[key] = value;
        i = i + 1;
      }
    }
    this._url = u.unpackString();
    this._payload = t.Uint8List.fromList(u.unpackBinary());
  }

}