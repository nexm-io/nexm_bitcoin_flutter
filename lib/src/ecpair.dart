import 'dart:typed_data';
import 'dart:math';
import 'package:bip32/src/utils/ecurve.dart' as ecc;
import 'package:bip32/src/utils/wif.dart' as wif;
import 'models/networks.dart';

class ECPair {
   Uint8List? _privateKey;
   Uint8List? _publicKey;
 late NetworkType network;
   late bool compressed;
  ECPair(Uint8List? _privateKeyInput, Uint8List? _publicKeyInput,
      {NetworkType?
  network,
    bool? compressed}) {
    this._privateKey = _privateKeyInput;
    this._publicKey = _publicKeyInput;
    this.network = network ?? bitcoin;
    this.compressed = compressed ?? true;
  }
  Uint8List get publicKey {
    if (_privateKey == null) {
      throw   ArgumentError('Missing private key');
    }
    if (_publicKey == null) _publicKey = ecc.pointFromScalar(_privateKey!, compressed);
    return _publicKey!;
  }

  Uint8List? get privateKey => _privateKey;
  String toWIF() {
    if (privateKey == null) {
      throw   ArgumentError('Missing private key');
    }
    return wif.encode( wif.WIF(
        version: network.wif, privateKey: privateKey!, compressed:
    compressed));
  }

  Uint8List sign(Uint8List hash) {
    if (privateKey == null) {
      throw   ArgumentError('Missing private key');
    }
    return ecc.sign(hash, privateKey!);
  }

  bool verify(Uint8List hash, Uint8List signature) {
    return ecc.verify(hash, publicKey, signature);
  }

  factory ECPair.fromWIF(String w, {NetworkType? network}) {
    wif.WIF decoded = wif.decode(w);
    final version = decoded.version;

    NetworkType nw;
    if (network != null) {
      nw = network;
      if (nw.wif != version) throw  ArgumentError('Invalid network version');
    } else {
      if (version == bitcoin.wif) {
        nw = bitcoin;
      } else if (version == testnet.wif) {
        nw = testnet;
      } else {
        throw  ArgumentError('Unknown network version');
      }
    }
    return ECPair.fromPrivateKey(decoded.privateKey,
        compressed: decoded.compressed, network: nw);
  }
  factory ECPair.fromPublicKey(Uint8List publicKey,
      {NetworkType? network, bool? compressed}) {
    if (!ecc.isPoint(publicKey)) {
      throw  ArgumentError('Point is not on the curve');
    }
    return  ECPair(null, publicKey,
        network: network, compressed: compressed);
  }
  factory ECPair.fromPrivateKey(Uint8List privateKey,
      {NetworkType? network, bool? compressed}) {
    if (privateKey.length != 32)
      throw  ArgumentError(
          'Expected property privateKey of type Buffer(Length: 32)');
    if (!ecc.isPrivate(privateKey))
      throw  ArgumentError('Private key not in range [1, n)');
    return  ECPair(privateKey, null,
        network: network, compressed: compressed);
  }
  factory ECPair.makeRandom(
      {NetworkType? network, bool? compressed, Function? rng}) {
    final rFunc = rng ?? _randomBytes;
    Uint8List d;
    do {
      d = rFunc(32);
      if (d.length != 32) throw ArgumentError('Expected Buffer(Length: 32)');
    } while (!ecc.isPrivate(d));
    return ECPair.fromPrivateKey(d, network: network, compressed: compressed);
  }
}

const int _SIZE_BYTE = 255;
Uint8List _randomBytes(int size) {
  final rng = Random.secure();
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = rng.nextInt(_SIZE_BYTE);
  }
  return bytes;
}
