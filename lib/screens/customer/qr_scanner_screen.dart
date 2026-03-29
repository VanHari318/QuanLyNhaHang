import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã trên bàn'),
        actions: [
          if (!kIsWeb)
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                if (state.torchState == TorchState.unavailable) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  onPressed: () => _controller.toggleTorch(),
                  icon: Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                  ),
                );
              },
            ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  _processScannedLink(code);
                  break;
                }
              }
            },
          ),
          // Overlay giao diện quét
          _buildOverlay(context),
        ],
      ),
    );
  }

  void _processScannedLink(String link) {
    try {
      String? tableId;
      String? sessionId;

      if (link.contains('tableId=')) {
        final Uri uri = Uri.parse(link);
        tableId = uri.queryParameters['tableId'];
        sessionId = uri.queryParameters['sessionId'];
      } else if (link.startsWith('table_')) {
        tableId = link;
      }

      if (tableId != null && tableId.isNotEmpty) {
        setState(() => _isScanned = true);
        final sid = sessionId ?? _buildSessionId(tableId);
        
        // Cập nhật context bàn toàn cục
        if (mounted) {
          context.read<CartProvider>().setTableConfig(tableId, sid);
        }

        Navigator.pop(context, {
          'tableId': tableId,
          'sessionId': sid,
        });
      }
    } catch (_) {
      // Bỏ qua
    }
  }

  String _buildSessionId(String tableId) {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    return '${tableId}_${now.year}$mo${d}_$h$mi';
  }

  Widget _buildOverlay(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: cs.primary, width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Hướng camera vào mã QR dán trên bàn',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
