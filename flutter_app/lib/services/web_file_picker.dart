import 'dart:typed_data';
import 'web_file_picker_stub.dart'
    if (dart.library.html) 'web_file_picker_web.dart' as picker;

class WebFilePickerResult {
  final String name;
  final Uint8List bytes;

  const WebFilePickerResult({required this.name, required this.bytes});
}

class WebFilePicker {
  static Future<WebFilePickerResult?> pickImage() async {
    final res = await picker.pickImageFile();
    if (res != null && res['bytes'] is Uint8List) {
      return WebFilePickerResult(
        name: res['name']?.toString() ?? 'uploaded_image.jpg',
        bytes: res['bytes'] as Uint8List,
      );
    }
    return null;
  }
}
