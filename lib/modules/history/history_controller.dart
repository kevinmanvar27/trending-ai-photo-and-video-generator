import 'package:get/get.dart';
import '../../core/services/generation_api_service.dart';
import '../../core/models/generation_model.dart';
import 'package:flutter/material.dart';

class HistoryItem {
  final String id;
  final String type;
  final String date;
  final String status;
  final String? imageUrl;
  final String? templateTitle;

  HistoryItem({
    required this.id,
    required this.type,
    required this.date,
    required this.status,
    this.imageUrl,
    this.templateTitle,
  });
}

class HistoryController extends GetxController {
  final GenerationApiService _generationApiService = GenerationApiService();
  
  final historyItems = <HistoryItem>[].obs;
  final generations = <GenerationModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final currentPage = 1.obs;
  final hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSubmissions();
  }

  // Load submissions from API
  Future<void> loadSubmissions({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMore.value = true;
      generations.clear();
      historyItems.clear();
    }

    if (!hasMore.value || isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await _generationApiService.getGenerationHistory(
        page: currentPage.value,
        limit: 20,
      );
      
      final List<dynamic> data = response['data'];
      
      if (data.isEmpty) {
        hasMore.value = false;
      } else {
        final newGenerations = data
            .map((json) => GenerationModel.fromJson(json))
            .toList();
        
        generations.addAll(newGenerations);
        
        // Convert to HistoryItems
        final newHistoryItems = newGenerations.map((generation) {
          return HistoryItem(
            id: generation.generationId,
            type: generation.type ?? 'image',
            date: _formatDate(generation.createdAt ?? DateTime.now()),
            status: generation.status,
            imageUrl: generation.generatedOutput ?? generation.originalImage,
            templateTitle: generation.templateName,
          );
        }).toList();
        
        historyItems.addAll(newHistoryItems);
        currentPage.value++;
      }
      
      print('✅ Loaded ${data.length} generations');
    } catch (e) {
      errorMessage.value = 'Failed to load history: $e';
      print('❌ Error loading generations: $e');
      
      // Fallback to sample data
      if (generations.isEmpty) {
        _loadSampleData();
      }
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _loadSampleData() {
    historyItems.value = [
      HistoryItem(
        id: '1',
        type: 'image',
        date: '2026-02-27',
        status: 'completed',
      ),
      HistoryItem(
        id: '2',
        type: 'video',
        date: '2026-02-26',
        status: 'completed',
      ),
      HistoryItem(
        id: '3',
        type: 'image',
        date: '2026-02-25',
        status: 'processing',
      ),
      HistoryItem(
        id: '4',
        type: 'video',
        date: '2026-02-24',
        status: 'completed',
      ),
    ];
  }

  // Get submission by ID
  Future<GenerationModel?> getSubmissionById(String generationId) async {
    try {
      // Try to find in local list first
      final generation = generations.firstWhereOrNull(
        (gen) => gen.generationId == generationId,
      );
      
      if (generation != null) {
        return generation;
      }
      
      // If not found locally, return null (we don't have a direct get endpoint)
      print('⚠️ Generation not found in local list: $generationId');
      return null;
    } catch (e) {
      print('❌ Error getting generation: $e');
      return null;
    }
  }

  // Delete submission
  Future<void> deleteSubmission(String generationId) async {
    try {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Generation'),
          content: const Text('Are you sure you want to delete this generation?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _generationApiService.deleteGeneration(generationId);
        
        // Remove from local lists
        historyItems.removeWhere((item) => item.id == generationId);
        generations.removeWhere((gen) => gen.generationId == generationId);
      }
    } catch (e) {
      Get.snackbar(
        '❌ Error',
        'Failed to delete generation: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void downloadAgain(String generationId) {
    final generation = generations.firstWhereOrNull(
      (gen) => gen.generationId == generationId,
    );
    
    if (generation?.generatedOutput != null) {
      // TODO: Implement download functionality
    } else {
      Get.snackbar(
        'Error',
        'File not available for download',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Refresh submissions
  Future<void> refresh() async {
    await loadSubmissions(refresh: true);
  }
}
