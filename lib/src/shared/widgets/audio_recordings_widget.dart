// lib/src/shared/widgets/audio_recordings_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/api/api_service.dart';

class AudioRecordingsWidget extends ConsumerStatefulWidget {
  final String bookingId;
  final List<dynamic> recordings;
  final VoidCallback onRecordingsChanged;

  const AudioRecordingsWidget({
    Key? key,
    required this.bookingId,
    required this.recordings,
    required this.onRecordingsChanged,
  }) : super(key: key);

  @override
  ConsumerState<AudioRecordingsWidget> createState() => _AudioRecordingsWidgetState();
}

class _AudioRecordingsWidgetState extends ConsumerState<AudioRecordingsWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  AudioPlayer? _audioPlayer;
  String? _currentPlayingId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    print('🎵 Audio player initialized');
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAudio() async {
    try {
      // Check limit
      if (widget.recordings.length >= 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 10 recordings per booking'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Pick audio file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;

      // Check file size (25MB)
      if (file.size > 25 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 25MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if file path is null (shouldn't happen, but safety check)
      if (file.path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to access file'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Prepare form data
      final dio = ref.read(dioProvider);

      // Use MultipartFile.fromFile with the file path
      final multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );

      final formData = FormData.fromMap({
        'audio': multipartFile,
      });

      // Upload
      await dio.post(
        '/bookings/${widget.bookingId}/recordings',
        data: formData,
        onSendProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onRecordingsChanged();

    } catch (e) {
      print('❌ Error uploading recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _deleteRecording(String recordingId, String filename) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text('Are you sure you want to delete "$filename"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/bookings/${widget.bookingId}/recordings/$recordingId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Stop playing if this was the current audio
      if (_currentPlayingId == recordingId) {
        await _audioPlayer?.stop();
        setState(() {
          _currentPlayingId = null;
          _isPlaying = false;
        });
      }

      widget.onRecordingsChanged();

    } catch (e) {
      print('❌ Error deleting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause(String recordingId, String url) async {
    if (_audioPlayer == null) {
      print('❌ Audio player not initialized');
      _initAudioPlayer();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      print('🎵 Attempting to play recording: $recordingId');
      print('🔗 URL: $url');

      if (_currentPlayingId == recordingId && _isPlaying) {
        // Pause current
        print('⏸️ Pausing audio');
        await _audioPlayer!.pause();
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      if (_currentPlayingId == recordingId && !_isPlaying) {
        // Resume current
        print('▶️ Resuming audio');
        await _audioPlayer!.play();
        setState(() {
          _isPlaying = true;
        });
        return;
      }

      // Play new audio
      print('🛑 Stopping any current playback');
      try {
        await _audioPlayer!.stop();
      } catch (e) {
        print('⚠️ No playback to stop: $e');
      }

      // Validate URL
      if (!url.startsWith('http')) {
        throw Exception('Invalid URL format: $url');
      }

      print('📡 Setting audio source...');

      // Try to set the URL
      try {
        await _audioPlayer!.setUrl(url);
        print('✅ Audio source set successfully');
      } catch (e) {
        print('❌ Failed to set audio source: $e');
        throw Exception('Could not load audio file. Error: ${e.toString()}');
      }

      print('▶️ Starting playback...');

      // Start playing
      await _audioPlayer!.play();

      setState(() {
        _currentPlayingId = recordingId;
        _isPlaying = true;
      });

      print('✅ Audio is now playing');

      // Listen for state changes
      _audioPlayer!.playerStateStream.listen((state) {
        print('🎵 Player state changed: ${state.processingState}');

        if (state.processingState == ProcessingState.completed) {
          print('🏁 Playback completed');
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
            // Reset for next play
            _audioPlayer!.seek(Duration.zero);
            _audioPlayer!.pause();
          }
        }

        if (state.processingState == ProcessingState.idle) {
          print('⏹️ Player is idle');
        }
      });

    } catch (e, stackTrace) {
      print('❌❌❌ Error playing audio: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot play audio: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Copy URL',
              textColor: Colors.white,
              onPressed: () {
                print('URL for debugging: $url');
              },
            ),
          ),
        );

        setState(() {
          _isPlaying = false;
          _currentPlayingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload progress indicator
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uploading...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
              ],
            ),
          ),

        // Recordings chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Add button chip (always visible)
            ActionChip(
              avatar: Icon(
                Icons.add,
                size: 18,
                color: _isUploading ? Colors.grey : Colors.blue.shade700,
              ),
              label: Text(
                widget.recordings.isEmpty ? 'Add Recording' : '',
                style: TextStyle(
                  fontSize: 12,
                  color: _isUploading ? Colors.grey : Colors.blue.shade700,
                ),
              ),
              backgroundColor: Colors.blue.shade50,
              side: BorderSide(color: Colors.blue.shade200),
              onPressed: _isUploading ? null : _pickAndUploadAudio,
            ),

            // Recording chips
            ...widget.recordings.map((recording) {
              // Handle both Map and dynamic types
              final recordingMap = recording is Map<String, dynamic>
                  ? recording
                  : recording as Map<String, dynamic>;

              final recordingId = recordingMap['_id']?.toString() ?? '';
              final filename = recordingMap['filename']?.toString() ?? 'Unknown';
              final url = recordingMap['url']?.toString() ?? '';

              // Debug print
              print('📀 Recording chip - ID: $recordingId, URL: $url');

              if (recordingId.isEmpty || url.isEmpty) {
                print('⚠️ Skipping invalid recording: $recordingMap');
                return const SizedBox.shrink();
              }

              final isCurrentPlaying = _currentPlayingId == recordingId;

              // FIX: Use InkWell wrapper instead of Chip with GestureDetector avatar
              return InkWell(
                onTap: () {
                  print('🖱️ Play button tapped for: $filename');
                  _togglePlayPause(recordingId, url);
                },
                borderRadius: BorderRadius.circular(16),
                child: Chip(
                  avatar: Icon(
                    isCurrentPlaying && _isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    size: 20,
                    color: isCurrentPlaying && _isPlaying
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                  label: Text(
                    _truncateFilename(filename),
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _deleteRecording(recordingId, filename),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  String _truncateFilename(String filename) {
    if (filename.length <= 20) return filename;
    final ext = filename.substring(filename.lastIndexOf('.'));
    final name = filename.substring(0, filename.lastIndexOf('.'));
    return '${name.substring(0, 15)}...$ext';
  }
}