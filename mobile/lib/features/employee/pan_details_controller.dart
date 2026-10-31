import 'package:flutter/foundation.dart';
import '../../services/pan_lookup_service.dart';

class PanDetailsController extends ChangeNotifier {
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
    notifyListeners();
  }

  Future<void> fetch(String input) async {
    if (loading) return;
    customer = null;
    error = null;
    if (!PanLookupService.valid(input)) {
      error = 'Enter a valid PAN, for example QWERT1234L.';
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
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
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
