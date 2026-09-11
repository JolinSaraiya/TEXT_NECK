// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Map<String, dynamic>?> pickImageFile() async {
  final completer = Completer<Map<String, dynamic>?>();

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;

  input.style.display = 'none';
  html.document.body?.append(input);

  input.onChange.listen((event) {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        final result = reader.result;
        Uint8List? bytes;
        if (result is Uint8List) {
          bytes = result;
        } else if (result is List<int>) {
          bytes = Uint8List.fromList(result);
        } else if (result is ByteBuffer) {
          bytes = result.asUint8List();
        }
        if (bytes != null) {
          completer.complete({
            'name': file.name,
            'bytes': bytes,
          });
        } else {
          completer.complete(null);
        }
        input.remove();
      });
      reader.onError.listen((event) {
        completer.complete(null);
        input.remove();
      });
    } else {
      completer.complete(null);
      input.remove();
    }
  });

  // Trigger browser file selector
  input.click();

  return completer.future;
}
