import 'package:get/get.dart';
import '../../services/pan_lookup_service.dart';

class PanDetailsController extends GetxController {
  PanDetailsController(this.api);
  final PanLookupService? api;
  bool loading = false;
  bool _disposed = false;
  String? error;
  CustomerDetails? customer;
  void clear() {
    if (loading) return;
    customer = null;
    error = null;
    update();
  }

  Future<void> fetch(String input) async {
    if (loading) return;
    customer = null;
    error = null;
    if (!PanLookupService.valid(input)) {
      error = 'Enter a valid PAN, for example QWERT1234L.';
      update();
      return;
    }
    loading = true;
    update();
    try {
      if (api == null) {
        throw Exception('Employee session unavailable. Please sign in again.');
      }
      final result = await api!.lookup(input);
      if (!_disposed) customer = result;
    } catch (e) {
      if (!_disposed) error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (!_disposed) {
        loading = false;
        update();
      }
    }
  }

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }
}
