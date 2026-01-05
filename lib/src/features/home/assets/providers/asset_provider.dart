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
    try {
      final newAsset = await _assetService.addAsset(asset);
      await loadAssets();
      return newAsset;
    } catch (e) {
      await loadAssets();
      rethrow;
    }
  }

  Future<void> updateAsset(AssetModel asset) async {
    state.whenData((assets) {
      final updatedAssets = [for (final a in assets) a.id == asset.id ? asset : a];
      state = AsyncValue.data(updatedAssets);
    });

    try {
      await _assetService.updateAsset(asset);
      await loadAssets();
    } catch (e) {
      await loadAssets();
      rethrow;
    }
  }

  Future<void> deleteAsset(String assetId) async {
    state.whenData((assets) {
      assets.removeWhere((a) => a.id == assetId);
      state = AsyncValue.data(List.from(assets));
    });

    try {
      await _assetService.deleteAsset(assetId);
      await loadAssets();
    } catch (e) {
      await loadAssets();
      rethrow;
    }
  }
}
