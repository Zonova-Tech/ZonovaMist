import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/todo_model.dart';

class ApproveRejectDialog extends StatefulWidget {
  final Todo todo;
  final Function(double rating, String comment) onApprove; // Corrected signature
  final Function(String comment) onReject;

  const ApproveRejectDialog({
    super.key,
    required this.todo,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<ApproveRejectDialog> createState() => _ApproveRejectDialogState();
}

class _ApproveRejectDialogState extends State<ApproveRejectDialog> {
  int _currentIndex = 0;
  double _rating = 5.0; // Default rating
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.todo.images.isEmpty) {
      return AlertDialog(
        title: const Text('No Images'),
        content: const Text('This task has no images to review.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image carousel
                  Expanded(
                    child: CarouselSlider(
                      options: CarouselOptions(
                        height: double.infinity,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: widget.todo.images.length > 1,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                      ),
                      items: widget.todo.images.map((image) {
                        final isVideo = image.resourceType == 'video';
                        
                        return InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: isVideo 
                              ? GestureDetector(
                                  onTap: () async {
                                    final Uri url = Uri.parse(image.url);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Container(
                                    color: Colors.black,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 100,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Tap to play video',
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                        Text(
                                          '(Opens in external player)',
                                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Image.network(
                                  image.url,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    );
                                  },
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Info & Rating Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.todo.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showConfirmDialog(
                                context: context,
                                title: 'Confirm Approval',
                                content: 'Mark this task as approved?',
                                buttonText: 'Done',
                                buttonColor: Colors.green,
                                onConfirm: () => widget.onApprove(5.0, ''),
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Done'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close confirm dialog
              onConfirm();
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
