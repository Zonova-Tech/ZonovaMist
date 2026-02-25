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
  double _rating = 5.0; 
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.todo.rating != null) {
      _rating = widget.todo.rating!;
    }
    if (widget.todo.ratingComment != null) {
      _commentController.text = widget.todo.ratingComment!;
    }
  }

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
            // Main Content (Scrollable)
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image carousel
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
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
                        final isVideo = image.resourceType == 'video' || image.url.contains('.mp4');
                        
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
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 80,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Tap to play video',
                                          style: TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                        const Text(
                                          '(Opens in external player)',
                                          style: TextStyle(color: Colors.white54, fontSize: 11),
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
                                        size: 48,
                                      ),
                                    );
                                  },
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Dot indicators if multiple images
                  if (widget.todo.images.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.todo.images.asMap().entries.map((entry) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(
                                _currentIndex == entry.key ? 0.9 : 0.4,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Info, Rating & Comment Card
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
                          widget.todo.status == 'Approved' ? 'Update Feedback' : 'Review Task',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.todo.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Rating Header
                        const Text(
                          'Performance Rating',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Rating Stars - Improved Hit Areas and Visuals
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final isFilled = index < _rating;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _rating = index + 1.0;
                                  });
                                  debugPrint('Rating set to: $_rating');
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutBack,
                                    tween: Tween(begin: 1.0, end: isFilled ? 1.15 : 1.0),
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            if (isFilled)
                                              Icon(
                                                Icons.star,
                                                color: Colors.amber.withOpacity(0.3),
                                                size: 52,
                                              ),
                                            Icon(
                                              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                                              color: isFilled ? Colors.amber : Colors.grey.shade400,
                                              size: 46,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Comment Field
                        TextField(
                          controller: _commentController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Optional Comment / Feedback',
                            hintText: 'Great work! / Needs improvement because...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        // Reject Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final comment = _commentController.text.trim();
                               if (comment.isEmpty) {
                                  _showErrorAlert('Comment Required', 'Please explain why this task needs to be redone.');
                                  return;
                                }
                              _showConfirmDialog(
                                context: context,
                                title: 'Confirm Rejection',
                                content: 'This will reset the task to "New" and clear the current media proof.',
                                buttonText: 'Confirm Reject',
                                buttonColor: Colors.red,
                                onConfirm: () => widget.onReject(comment),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Do it Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Approve Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showConfirmDialog(
                                context: context,
                                title: 'Confirm Approval',
                                content: 'Mark this task as approved with a ${_rating.toInt()} star rating?',
                                buttonText: 'Approve',
                                buttonColor: Colors.green,
                                onConfirm: () => widget.onApprove(_rating, _commentController.text.trim()),
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
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

            // Close button overlay
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

  void _showErrorAlert(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
