import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/audio_recorder_service.dart';
import '../services/call_detector_service.dart';
import '../services/auth_service.dart';
import '../utils/shared_prefs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userEmail;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _startServices();
    });
  }

  Future<void> _loadUserData() async {
    final userData = await SharedPrefs.getUser();
    if (userData != null) {
      setState(() {
        _userEmail = userData['email'];
        _isLoggedIn = true;
      });
    }
  }

  void _startServices() {
    final callDetector = Provider.of<CallDetectionService>(
      context,
      listen: false,
    );
    final recorder = Provider.of<AudioRecorderService>(context, listen: false);

    callDetector.startDetection();

    recorder.loadRecordings();
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recorder = Provider.of<AudioRecorderService>(context);
    final callDetector = Provider.of<CallDetectionService>(context);
    final recentRecordings = recorder.recordings.reversed.take(10).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Recorder Pro'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isLoggedIn)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') _logout();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),

            Row(
              children: [
                _buildStatusIndicator(
                  'Login',
                  _isLoggedIn ? Icons.check_circle : Icons.circle,
                  _isLoggedIn ? Colors.green : Colors.grey,
                ),
                _buildStatusIndicator(
                  'Detection',
                  callDetector.isRunning ? Icons.check_circle : Icons.circle,
                  callDetector.isRunning ? Colors.green : Colors.grey,
                ),
                _buildStatusIndicator(
                  'Recording',
                  recorder.isRecording ? Icons.mic : Icons.mic_none,
                  recorder.isRecording ? Colors.red : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (recorder.isRecording)
              _buildLiveRecordingCard(recorder, callDetector),

            const SizedBox(height: 20),
            const Text(
              'Recent Recordings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: recentRecordings.isEmpty
                  ? const Center(
                      child: Text(
                        'No recordings found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: recentRecordings.length,
                      itemBuilder: (context, index) =>
                          _buildRecordingItem(recentRecordings[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isLoggedIn
                  ? 'Welcome, ${_userEmail?.split('@').first ?? 'User'}!'
                  : 'Welcome!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _isLoggedIn
                  ? 'Background service is active and monitoring calls.'
                  : 'Please login to start recording.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveRecordingCard(
    AudioRecorderService recorder,
    CallDetectionService callDetector,
  ) {
    return Card(
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.mic, color: Colors.red, size: 30),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECORDING NOW',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                Text(
                  recorder.formattedDuration,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (callDetector.phoneNumber != null)
                  Text(
                    'Call: ${callDetector.phoneNumber}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingItem(RecordingItem recording) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: recording.isUploaded
              ? Colors.green[50]
              : Colors.orange[50],
          child: Icon(
            recording.isUploaded ? Icons.cloud_done : Icons.cloud_upload,
            color: recording.isUploaded ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          recording.phoneNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, HH:mm').format(recording.timestamp)} • ${recording.fileSize}',
        ),
        trailing: recording.isUploaded
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.sync_outlined, color: Colors.orange),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
