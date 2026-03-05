import 'package:get/get.dart';

/// Manages video playback across the home screen
/// Ensures only one video plays at a time
class VideoPlaybackManager extends GetxController {
  static VideoPlaybackManager get instance => Get.find<VideoPlaybackManager>();
  
  // Currently playing video URL
  final currentPlayingVideo = Rxn<String>();
  
  // Is user currently scrolling
  final isScrolling = false.obs;
  
  // Request to play a video
  void requestPlay(String videoUrl) {
    if (!isScrolling.value) {
      currentPlayingVideo.value = videoUrl;
    }
  }
  
  // Stop all videos
  void stopAll() {
    currentPlayingVideo.value = null;
  }
  
  // Called when user starts scrolling
  void onScrollStart() {
    isScrolling.value = true;
    stopAll();
  }
  
  // Called when user stops scrolling
  void onScrollEnd() {
    isScrolling.value = false;
  }
  
  // Check if a specific video should be playing
  bool shouldPlay(String videoUrl) {
    return !isScrolling.value && currentPlayingVideo.value == videoUrl;
  }
}
