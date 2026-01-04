import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class CallOverlayScreen extends StatefulWidget {
  final String phoneNumber;
  final Function(bool) onRecordPressed;
  final bool isRecording;

  const CallOverlayScreen({
    super.key,
    required this.phoneNumber,
    required this.onRecordPressed,
    required this.isRecording,
  });

  @override
  State<CallOverlayScreen> createState() => _CallOverlayScreenState();
}

class _CallOverlayScreenState extends State<CallOverlayScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.blue, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Call in Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () {
                    OverlaySupportEntry.of(context)?.dismiss();
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Phone Number
            Text(
              '📞 ${widget.phoneNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            // Record Button
            ElevatedButton.icon(
              onPressed: () {
                widget.onRecordPressed(!widget.isRecording);
              },
              icon: Icon(
                widget.isRecording ? Icons.stop : Icons.fiber_manual_record,
                color: Colors.white,
              ),
              label: Text(
                widget.isRecording ? 'STOP RECORDING' : 'RECORD CALL',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isRecording ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
            ),

            const SizedBox(height: 10),

            // Status
            Text(
              widget.isRecording ? '🎙️ Recording...' : 'Ready to record',
              style: TextStyle(
                color: widget.isRecording ? Colors.red : Colors.green,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
