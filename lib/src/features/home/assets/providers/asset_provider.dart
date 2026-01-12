import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Zonova_Mist/src/core/api/api_service.dart';
import 'package:Zonova_Mist/src/features/home/assets/models/asset_model.dart';

// Service class to handle asset-related API calls
class AssetService {
  final Dio _dio;

  AssetService(this._dio);

  Future<List<AssetModel>> fetchAssets() async {
    final response = await _dio.get('/assets');
    final data = response.data as List;
    return data.map((json) => AssetModel.fromJson(json)).toList();
  }

  Future<AssetModel> addAsset(AssetModel asset) async {
    final response = await _dio.post('/assets', data: asset.toJson());
    return AssetModel.fromJson(response.data);
  }

  Future<AssetModel> updateAsset(AssetModel asset) async {
    final response = await _dio.put('/assets/${asset.id}', data: asset.toJson());
    return AssetModel.fromJson(response.data);
  }

  Future<void> deleteAsset(String assetId) async {
    await _dio.delete('/assets/$assetId');
  }
}

// Provider for the AssetService
final assetServiceProvider = Provider<AssetService>((ref) {
  final dio = ref.watch(dioProvider);
  return AssetService(dio);
});

// StateNotifierProvider that manages the state of the assets list
final assetsProvider = StateNotifierProvider<AssetNotifier, AsyncValue<List<AssetModel>>>((ref) {
  final assetService = ref.watch(assetServiceProvider);
  return AssetNotifier(assetService);
});

class AssetNotifier extends StateNotifier<AsyncValue<List<AssetModel>>> {
  final AssetService _assetService;

  AssetNotifier(this._assetService) : super(const AsyncValue.loading()) {
    loadAssets();
  }

  Future<void> loadAssets() async {
    state = const AsyncValue.loading();
    try {
      final assets = await _assetService.fetchAssets();
      state = AsyncValue.data(assets);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<AssetModel> addAsset(AssetModel asset) async {
    // Store previous state for rollback
    final previousState = state;
    
    // Optimistically add the asset to the list (only if we have data)
    state = state.whenData((assets) => [...assets, asset]);

    try {
      final newAsset = await _assetService.addAsset(asset);
      await loadAssets();
      return newAsset;
    } catch (e) {
      // Rollback to previous state on error
      state = previousState;
      rethrow;
    }
  }

  Future<void> updateAsset(AssetModel asset) async {
    // Store previous state for rollback
    final previousState = state;
    
    // Optimistically update the asset in the list (only if we have data)
    state = state.whenData((assets) => [for (final a in assets) a.id == asset.id ? asset : a]);

    try {
      await _assetService.updateAsset(asset);
      await loadAssets();
    } catch (e) {
      // Rollback to previous state on error
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteAsset(String assetId) async {
    // Store previous state for rollback
    final previousState = state;
    
    // Optimistically remove the asset from the list (only if we have data)
    state = state.whenData((assets) => assets.where((a) => a.id != assetId).toList());

    try {
      await _assetService.deleteAsset(assetId);
      await loadAssets();
    } catch (e) {
      // Rollback to previous state on error
      state = previousState;
      rethrow;
    }
  }
}