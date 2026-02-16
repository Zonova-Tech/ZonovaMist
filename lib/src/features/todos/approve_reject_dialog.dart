import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'models/todo_model.dart';

class ApproveRejectDialog extends StatefulWidget {
  final Todo todo;
  final Function(double rating, String comment) onApprove; // Corrected signature
  final VoidCallback onReject;

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
                        return InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.network(
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
                        
                        // Rating Section
                        const Text(
                          'Rate Performance:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            color: Colors.grey,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              onPressed: () => setState(() => _rating = index + 1.0),
                              icon: Icon(
                                index < _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        
                        // Comment Section
                        TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment (optional)...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8,
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Reject Task'),
                                  content: const Text(
                                    'Are you sure you want to reject this task? '
                                        'It will be reset to "New" status and images will be removed.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context); // Close confirm dialog
                                        widget.onReject();
                                      },
                                      child: const Text('Reject'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
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
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Approve Task'),
                                  content: Text(
                                    'Approve this task with a rating of $_rating/5?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context); // Close confirm dialog
                                        widget.onApprove(
                                          _rating, 
                                          _commentController.text.trim(),
                                        );
                                      },
                                      child: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle),
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
}
