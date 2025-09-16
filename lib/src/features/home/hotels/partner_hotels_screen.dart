// partner_hotels_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/auth/hotels_provider.dart';
import '../../../core/api/api_service.dart';
import 'add_hotel_screen.dart';
import 'edit_hotel_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class PartnerHotelsScreen extends ConsumerStatefulWidget {
  const PartnerHotelsScreen({super.key});

  @override
  ConsumerState<PartnerHotelsScreen> createState() => _PartnerHotelsScreenState();
}

class _PartnerHotelsScreenState extends ConsumerState<PartnerHotelsScreen> {
  final Map<String, List<XFile>> _selectedFilesMap = {};
  final Map<String, Future<void>?> _uploadFuturesMap = {};

  Future<void> _pickAndSaveImages(String hotelId) async {
    final picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedFilesMap[hotelId] = [...?_selectedFilesMap[hotelId], ...images];
        _uploadFuturesMap[hotelId] = _uploadImagesToServer(hotelId, images);
      });
    }
  }

  Future<void> _uploadImagesToServer(String hotelId, List<XFile> images) async {
    final dio = ref.read(dioProvider);
    final String apiUrl = '${dio.options.baseUrl}/images/upload';

    final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..fields['hotelId'] = hotelId;

    for (var image in images) {
      request.files.add(await http.MultipartFile.fromPath('photos', image.path));
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final decoded = jsonDecode(respStr);

        if (decoded['photoUrls'] != null) {
          final hotels = ref.read(hotelsProvider).value ?? [];
          final hotelIndex = hotels.indexWhere((h) => h['_id'] == hotelId);
          if (hotelIndex != -1) {
            setState(() {
              hotels[hotelIndex]['photos'] = [
                ...?hotels[hotelIndex]['photos'],
                ...decoded['photoUrls']
              ];
              _selectedFilesMap[hotelId] = [];
            });
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photos uploaded successfully')),
          );
        }
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('❌ Failed upload: ${response.statusCode} - $respStr');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photos: $e')),
      );
    }
  }

  Future<void> _onEdit(Map<String, dynamic> hotel) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditHotelScreen(hotel: Map<String, dynamic>.from(hotel))),
    );
    if (result == true && mounted) {
      ref.refresh(hotelsProvider);
    }
  }

  Future<void> _onDelete(Map<String, dynamic> hotel) async {
    final hotelId = hotel['_id'] as String;
    final hotelName = hotel['name'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Partner Hotel'),
        content: Text('Are you sure you want to delete $hotelName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        final resp = await dio.delete('/partner-hotels/$hotelId');

        if ((resp.statusCode ?? 500) >= 200 && (resp.statusCode ?? 500) < 300) {
          if (mounted) {
            ref.refresh(hotelsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Partner Hotel deleted')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: ${resp.statusCode}')),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting hotel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(hotelsProvider);
    final dio = ref.read(dioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Hotels'),
        backgroundColor: Colors.blueAccent,
      ),
      body: hotelsAsync.when(
        data: (hotels) {
          if (hotels.isEmpty) {
            return const Center(child: Text('No partner hotels found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final hotel = hotels[index] as Map<String, dynamic>;
              final hotelId = hotel['_id'] as String;
              final photos = hotel['photos'] ?? [];
              final selectedFiles = _selectedFilesMap[hotelId] ?? [];

              return Slidable(
                key: ValueKey(hotelId),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.45,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _onEdit(hotel),
                      backgroundColor: Colors.blue.shade500,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    SlidableAction(
                      onPressed: (_) => _onDelete(hotel),
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ],
                ),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.hotel, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hotel['name'] ?? 'Unnamed Hotel',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Location: ${hotel['location'] ?? 'N/A'}'),
                        const SizedBox(height: 6),
                        Text('Rating: ${hotel['rating'] ?? 'N/A'}'),
                        const SizedBox(height: 6),
                        Text('Contact: ${hotel['contact'] ?? 'N/A'}'),
                        const SizedBox(height: 12),
                        const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _pickAndSaveImages(hotelId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Add Photos',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_uploadFuturesMap[hotelId] != null)
                          FutureBuilder<void>(
                            future: _uploadFuturesMap[hotelId],
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const LinearProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                              } else {
                                return const Text('Upload complete!', style: TextStyle(color: Colors.green));
                              }
                            },
                          ),
                        const SizedBox(height: 8),
                        photos.isEmpty && selectedFiles.isEmpty
                            ? const Text('No photos available.')
                            : SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length + selectedFiles.length,
                            itemBuilder: (context, photoIndex) {
                              if (photoIndex < photos.length) {
                                final photoUrl = photos[photoIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.network(
                                    "${dio.options.baseUrl}/partner-hotels/image/$photoUrl",
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, color: Colors.red),
                                  ),
                                );
                              } else {
                                final localIndex = (photoIndex - photos.length);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.file(
                                    File(selectedFiles[localIndex.toInt()].path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, color: Colors.red),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHotelScreen()),
          );
          if (result == true) {
            ref.refresh(hotelsProvider);
          }
        },
      ),
    );
  }
}
