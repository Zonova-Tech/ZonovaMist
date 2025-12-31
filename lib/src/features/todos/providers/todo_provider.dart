import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import '../models/todo_model.dart';
import '../../../core/api/api_service.dart';

// State class for todos
class TodoState {
  final List<Todo> todos;
  final bool isLoading;
  final String? error;

  TodoState({
    required this.todos,
    this.isLoading = false,
    this.error,
  });

  TodoState copyWith({
    List<Todo>? todos,
    bool? isLoading,
    String? error,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Todo Provider (for tasks I created)
class TodoNotifier extends StateNotifier<TodoState> {
  final Dio dio;

  TodoNotifier(this.dio) : super(TodoState(todos: []));

  // Fetch todos created by me
  Future<void> fetchTodos() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await dio.get('/todos');

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> todosJson = response.data['todos'];
        final todos = todosJson.map((json) => Todo.fromJson(json)).toList();

        state = state.copyWith(todos: todos, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to fetch todos',
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Network error',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Create new todo
  Future<bool> createTodo({
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required String assignedTo,
  }) async {
    try {
      final response = await dio.post('/todos', data: {
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'priority': priority,
        'assignedTo': assignedTo,
      });

      if (response.statusCode == 201 && response.data['success']) {
        await fetchTodos();
        return true;
      }

      state = state.copyWith(
        error: response.data['message'] ?? 'Failed to create todo',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'Network error',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred');
      return false;
    }
  }

  // Update todo
  Future<bool> updateTodo({
    required String id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? assignedTo,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (dueDate != null) data['dueDate'] = dueDate.toIso8601String();
      if (priority != null) data['priority'] = priority;
      if (assignedTo != null) data['assignedTo'] = assignedTo;

      final response = await dio.put('/todos/$id', data: data);

      if (response.statusCode == 200 && response.data['success']) {
        await fetchTodos();
        return true;
      }

      state = state.copyWith(
        error: response.data['message'] ?? 'Failed to update todo',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'Network error',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred');
      return false;
    }
  }

  // Approve todo
  Future<bool> approveTodo(String id) async {
    try {
      final response = await dio.patch('/todos/$id/approve');

      if (response.statusCode == 200 && response.data['success']) {
        await fetchTodos();
        return true;
      }

      state = state.copyWith(
        error: response.data['message'] ?? 'Failed to approve todo',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'Network error',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred');
      return false;
    }
  }

  // Reject todo
  Future<bool> rejectTodo(String id) async {
    try {
      final response = await dio.patch('/todos/$id/reject');

      if (response.statusCode == 200 && response.data['success']) {
        await fetchTodos();
        return true;
      }

      state = state.copyWith(
        error: response.data['message'] ?? 'Failed to reject todo',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'Network error',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred');
      return false;
    }
  }

  // Delete todo
  Future<bool> deleteTodo(String id) async {
    try {
      final response = await dio.delete('/todos/$id');

      if (response.statusCode == 200 && response.data['success']) {
        await fetchTodos();
        return true;
      }

      state = state.copyWith(
        error: response.data['message'] ?? 'Failed to delete todo',
      );
      return false;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'Network error',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred');
      return false;
    }
  }
}

// My Todos Provider (for tasks assigned to me)
class MyTodoNotifier extends StateNotifier<TodoState> {
  final Dio dio;

  MyTodoNotifier(this.dio) : super(TodoState(todos: []));

  // Fetch todos assigned to me
  Future<void> fetchMyTodos() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await dio.get('/todos/my');

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> todosJson = response.data['todos'];
        final todos = todosJson.map((json) => Todo.fromJson(json)).toList();

        state = state.copyWith(todos: todos, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to fetch todos',
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Network error',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Complete todo with images (with compression)
  Future<bool> completeTodo(String id, List<String> imagePaths) async {
    try {
      print('🔵 Starting completeTodo');
      print('Todo ID: $id');
      print('Images: ${imagePaths.length}');

      FormData formData = FormData();

      for (var i = 0; i < imagePaths.length; i++) {
        final path = imagePaths[i];
        print('Processing image $i: $path');

        // Get original file size
        final originalFile = File(path);
        final originalSize = await originalFile.length();
        print('Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');

        // Compress image
        final compressedPath = path.replaceAll('.jpg', '_compressed.jpg');

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          path,
          compressedPath,
          quality: 70,
          minWidth: 1920,
          minHeight: 1080,
        );

        if (compressedFile == null) {
          print('❌ Compression failed for image $i');
          continue;
        }

        final compressedSize = await compressedFile.length();
        print('Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        print('Saved: ${((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)}%');

        final fileName = compressedFile.path.split('/').last;

        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              compressedFile.path,
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            ),
          ),
        );
      }

      if (formData.files.isEmpty) {
        state = state.copyWith(error: 'No images to upload');
        return false;
      }

      print('📤 Uploading ${formData.files.length} compressed images...');

      final response = await dio.post(
        '/todos/$id/complete',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(minutes: 2),
        ),
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          print('Upload progress: $progress%');
        },
      );

      print('✅ Upload complete: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success']) {
        await fetchMyTodos();
        return true;
      }

      state = state.copyWith(
        error: response.data['message'] ?? 'Failed to complete todo',
      );
      return false;
    } on DioException catch (e) {
      print('❌ Dio error: ${e.message}');
      print('Error type: ${e.type}');

      String errorMessage = 'Network error';
      if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Upload timed out. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? 'Upload failed';
      }

      state = state.copyWith(error: errorMessage);
      return false;
    } catch (e) {
      print('❌ Error: $e');
      state = state.copyWith(error: 'Error: $e');
      return false;
    }
  }
}

// Provider definitions
final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>((ref) {
  final dio = ref.watch(dioProvider);
  return TodoNotifier(dio);
});

final myTodoProvider = StateNotifierProvider<MyTodoNotifier, TodoState>((ref) {
  final dio = ref.watch(dioProvider);
  return MyTodoNotifier(dio);
});

// Users provider (for assignee selection)
final usersProvider = FutureProvider<List<User>>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get('/users');

    if (response.statusCode == 200 && response.data['success']) {
      final List<dynamic> usersJson = response.data['users'];
      return usersJson.map((json) => User.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    print('Error fetching users: $e');
    return [];
  }
});