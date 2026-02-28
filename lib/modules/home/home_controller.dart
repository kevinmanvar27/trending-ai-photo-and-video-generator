import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SampleItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String type; // 'image' or 'video'

  SampleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.type,
  });
}

class HomeController extends GetxController {
  final selectedSample = Rxn<SampleItem>();
  final selectedFilter = 'all'.obs; // 'all', 'image', 'video'

  // Filtered samples based on selected filter
  List<SampleItem> get filteredSamples {
    switch (selectedFilter.value) {
      case 'image':
        return imageSamples;
      case 'video':
        return videoSamples;
      default:
        return allSamples;
    }
  }

  // All samples combined (images + videos)
  List<SampleItem> get allSamples => [...imageSamples, ...videoSamples];

  // Image conversion samples
  final List<SampleItem> imageSamples = [
    SampleItem(
      id: 'img_1',
      title: 'Animated Portrait',
      description: 'Transform your photo into a smooth animated video',
      imageUrl: 'https://picsum.photos/seed/portrait/400/400',
      type: 'image',
    ),
    SampleItem(
      id: 'img_2',
      title: 'Cartoon Style',
      description: 'Convert your image to animated cartoon video',
      imageUrl: 'https://picsum.photos/seed/cartoon/400/400',
      type: 'image',
    ),
    SampleItem(
      id: 'img_3',
      title: 'Cinematic Motion',
      description: 'Add cinematic motion effects to your photo',
      imageUrl: 'https://picsum.photos/seed/cinema/400/400',
      type: 'image',
    ),
    SampleItem(
      id: 'img_4',
      title: '3D Parallax',
      description: 'Create stunning 3D parallax video from image',
      imageUrl: 'https://picsum.photos/seed/3d/400/400',
      type: 'image',
    ),
    SampleItem(
      id: 'img_5',
      title: 'Vintage Film',
      description: 'Turn your photo into vintage film style video',
      imageUrl: 'https://picsum.photos/seed/vintage/400/400',
      type: 'image',
    ),
    SampleItem(
      id: 'img_6',
      title: 'Neon Glow',
      description: 'Add animated neon glow effects to your image',
      imageUrl: 'https://picsum.photos/seed/neon/400/400',
      type: 'image',
    ),
  ];

  // Video conversion samples
  final List<SampleItem> videoSamples = [
    SampleItem(
      id: 'vid_1',
      title: 'Key Frame Extract',
      description: 'Extract the best frame from your video',
      imageUrl: 'https://picsum.photos/seed/keyframe/400/400',
      type: 'video',
    ),
    SampleItem(
      id: 'vid_2',
      title: 'Poster Shot',
      description: 'Create high-quality poster from video',
      imageUrl: 'https://picsum.photos/seed/poster/400/400',
      type: 'video',
    ),
    SampleItem(
      id: 'vid_3',
      title: 'Thumbnail Grid',
      description: 'Generate contact sheet with multiple frames',
      imageUrl: 'https://picsum.photos/seed/grid/400/400',
      type: 'video',
    ),
    SampleItem(
      id: 'vid_4',
      title: 'Motion Blur',
      description: 'Capture motion blur effect in single image',
      imageUrl: 'https://picsum.photos/seed/blur/400/400',
      type: 'video',
    ),
    SampleItem(
      id: 'vid_5',
      title: 'Time-lapse Frame',
      description: 'Extract perfect moment from time-lapse',
      imageUrl: 'https://picsum.photos/seed/timelapse/400/400',
      type: 'video',
    ),
    SampleItem(
      id: 'vid_6',
      title: 'Collage Maker',
      description: 'Create artistic collage from video frames',
      imageUrl: 'https://picsum.photos/seed/collage/400/400',
      type: 'video',
    ),
  ];

  void selectSample(SampleItem sample) {
    selectedSample.value = sample;
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void uploadFile() {
    if (selectedSample.value != null) {
      Get.toNamed('/upload', arguments: {
        'selectedSample': selectedSample.value,
      });
    }
  }
}
