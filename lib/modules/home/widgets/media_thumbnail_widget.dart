import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:get/get.dart';
import '../controllers/video_playback_manager.dart';

/// A widget that displays either an image or video thumbnail based on the type
class MediaThumbnailWidget extends StatefulWidget {
  final String mediaUrl;
  final String type; // 'image' or 'video'
  final BoxFit fit;
  final double? width;
  final double? height;

  const MediaThumbnailWidget({
    Key? key,
    required this.mediaUrl,
    required this.type,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<MediaThumbnailWidget> createState() => _MediaThumbnailWidgetState();
}

class _MediaThumbnailWidgetState extends State<MediaThumbnailWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isInitializing = false;
  bool _hasError = false;
  bool _isVisible = false;
  VideoPlaybackManager? _playbackManager;
  int _retryCount = 0;
  static const int _maxRetries = 2; // Reduced retries
  bool _disposed = false; // Track disposal state

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      try {
        _playbackManager = Get.find<VideoPlaybackManager>();
      } catch (e) {
        // Manager not initialized yet
        debugPrint('⚠️ VideoPlaybackManager not found, initializing...');
        Get.put(VideoPlaybackManager());
        _playbackManager = Get.find<VideoPlaybackManager>();
      }
      // Don't initialize immediately - wait for visibility
      // This prevents loading all videos at once
    }
  }

  Future<void> _initializeVideo() async {
    if (_isInitializing || _isVideoInitialized || _videoController != null || _disposed) {
      return; // Already initializing, initialized, or disposed
    }
    
    try {
      _isInitializing = true;
      debugPrint('🎬 Initializing video: ${widget.mediaUrl}');
      
      // Validate URL before attempting to load
      if (!widget.mediaUrl.startsWith('http')) {
        throw Exception('Invalid video URL: ${widget.mediaUrl}');
      }
      
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.mediaUrl),
      );
      
      // Add timeout to prevent hanging
      await _videoController!.initialize().timeout(
        const Duration(seconds: 15), // Increased timeout
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );
      
      if (_disposed) {
        // Widget was disposed during initialization
        _videoController?.dispose();
        _videoController = null;
        return;
      }
      
      // Set video to loop and mute by default for thumbnail preview
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(0);
      
      if (mounted && !_disposed) {
        setState(() {
          _isVideoInitialized = true;
          _isInitializing = false;
          _hasError = false;
          _retryCount = 0;
        });
        
        debugPrint('✅ Video initialized: ${widget.mediaUrl}');
        
        // Listen to playback manager
        _playbackManager?.currentPlayingVideo.listen((playingUrl) {
          if (!mounted || _videoController == null || _disposed) return;
          
          if (playingUrl == widget.mediaUrl) {
            // This video should play
            if (!_videoController!.value.isPlaying) {
              _videoController!.play();
            }
          } else {
            // This video should pause
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing video (attempt ${_retryCount + 1}/$_maxRetries): $e');
      debugPrint('❌ Video URL: ${widget.mediaUrl}');
      
      if (_disposed) {
        // Widget was disposed, clean up and exit
        _videoController?.dispose();
        _videoController = null;
        return;
      }
      
      if (mounted && !_disposed) {
        setState(() {
          _isInitializing = false;
        });
        
        // Retry logic - only retry once for network issues
        if (_retryCount < _maxRetries && !e.toString().contains('Invalid video URL')) {
          _retryCount++;
          debugPrint('🔄 Retrying video initialization in ${_retryCount} seconds...');
          
          // Clean up failed controller
          _videoController?.dispose();
          _videoController = null;
          
          // Retry after delay with exponential backoff
          await Future.delayed(Duration(seconds: _retryCount));
          if (mounted && _isVisible && !_disposed) {
            _initializeVideo();
          }
        } else {
          debugPrint('⚠️ Giving up on video, showing fallback UI');
          if (mounted && !_disposed) {
            setState(() {
              _hasError = true;
            });
          }
        }
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted || _playbackManager == null || _disposed) return;
    
    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.7; // Increased threshold for better UX
    
    // When this video becomes visible and wasn't before
    if (_isVisible && !wasVisible) {
      // Initialize video if not already done
      if (!_isVideoInitialized && !_isInitializing && !_hasError) {
        debugPrint('👁️ Video became visible, initializing: ${widget.mediaUrl}');
        _initializeVideo();
      }
      
      // Request to play this video (manager will decide)
      if (_isVideoInitialized && _videoController != null) {
        _playbackManager!.requestPlay(widget.mediaUrl);
      }
    } else if (!_isVisible && wasVisible) {
      // Video is no longer visible
      if (_videoController != null && _videoController!.value.isPlaying) {
        _videoController!.pause();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true; // Mark as disposed first
    _videoController?.pause(); // Pause before disposing
    _videoController?.dispose();
    _videoController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Display video
    if (widget.type == 'video') {
      if (_hasError) {
        // Show image thumbnail as fallback for failed videos
        return _buildVideoFallback();
      }
      
      if (!_isVideoInitialized) {
        // Show loading with visibility detector to trigger initialization
        return VisibilityDetector(
          key: Key('video_loading_${widget.mediaUrl}'),
          onVisibilityChanged: _onVisibilityChanged,
          child: _buildLoadingWidget(),
        );
      }

      return VisibilityDetector(
        key: Key('video_${widget.mediaUrl}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: Stack(
          children: [
            SizedBox(
              width: widget.width ?? double.infinity,
              height: widget.height ?? double.infinity,
              child: FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: _videoController?.value.size.width ?? 16,
                  height: _videoController?.value.size.height ?? 9,
                  child: _videoController != null 
                      ? VideoPlayer(_videoController!)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            // Video indicator badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Display image
    return Image.network(
      widget.mediaUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingWidget(
          progress: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget('Image not available');
      },
    );
  }

  Widget _buildVideoFallback() {
    // Try to show the video thumbnail as a static image
    return Stack(
      children: [
        Container(
          color: Colors.grey[800],
          child: Center(
            child: Icon(
              Icons.videocam_off,
              color: Colors.grey[600],
              size: 40,
            ),
          ),
        ),
        // Video indicator badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget({double? progress}) {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: Colors.grey[800],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: Colors.grey[600],
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
