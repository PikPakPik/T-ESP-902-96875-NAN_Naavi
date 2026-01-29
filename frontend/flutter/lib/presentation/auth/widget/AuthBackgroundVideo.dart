import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AuthBackgroundVideo extends StatefulWidget {
  const AuthBackgroundVideo({super.key});

  @override
  State<AuthBackgroundVideo> createState() => _AuthBackgroundVideoState();
}

class _AuthBackgroundVideoState extends State<AuthBackgroundVideo> {
  VideoPlayerController? _currentController;
  VideoPlayerController? _nextController;
  int _currentVideoIndex = 0;
  bool _hasTriggeredChange = false;
  bool _isChangingVideo = false;
  DateTime? _videoStartTime;

  final List<String> _videoUrls = [
    'https://naavi-images.s3.fr-par.scw.cloud/flutter/auth-page/video1.mp4',
    'https://naavi-images.s3.fr-par.scw.cloud/flutter/auth-page/video2.mp4',
    'https://naavi-images.s3.fr-par.scw.cloud/flutter/auth-page/video3.mp4',
    'https://naavi-images.s3.fr-par.scw.cloud/flutter/auth-page/video4.mp4',
    'https://naavi-images.s3.fr-par.scw.cloud/flutter/auth-page/video5.mp4',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFirstVideo();
  }

  Future<void> _initializeFirstVideo() async {
    final random = Random();
    _currentVideoIndex = random.nextInt(_videoUrls.length);
    await _loadCurrentVideo(_currentVideoIndex);
    _preloadNextVideo();
  }

  void _onVideoProgress() {
    if (!mounted ||
        _currentController == null ||
        _hasTriggeredChange ||
        _isChangingVideo) {
      return;
    }

    if (_videoStartTime != null) {
      final timeSinceStart = DateTime.now().difference(_videoStartTime!);
      if (timeSinceStart.inMilliseconds < 1000) {
        return;
      }
    }

    final position = _currentController!.value.position;
    final duration = _currentController!.value.duration;

    if (duration.inMilliseconds > 0) {
      final timeLeft = duration.inMilliseconds - position.inMilliseconds;

      if (timeLeft <= 500 && position.inMilliseconds >= 2000) {
        _currentController!.removeListener(_onVideoProgress);
        _hasTriggeredChange = true;
        _transitionToNextVideo();
      }
    }
  }

  Future<void> _loadCurrentVideo(int index) async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(_videoUrls[index]),
      );

      await controller.initialize();
      controller.setVolume(0);

      if (!mounted) {
        controller.dispose();
        return;
      }

      final oldController = _currentController;
      oldController?.removeListener(_onVideoProgress);

      setState(() {
        _currentController = controller;
        _hasTriggeredChange = false;
      });

      _currentController!.addListener(_onVideoProgress);
      await _currentController!.play();
      _videoStartTime = DateTime.now();

      Future.delayed(const Duration(seconds: 1), () {
        oldController?.dispose();
      });
    } catch (e) {
      // Video transition errors are silently ignored
    }
  }

  Future<void> _preloadNextVideo() async {
    if (_nextController != null) return;

    final nextIndex = (_currentVideoIndex + 1) % _videoUrls.length;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(_videoUrls[nextIndex]),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      controller.setVolume(0);

      if (mounted) {
        _nextController = controller;
      } else {
        controller.dispose();
      }
    } catch (e) {
      // Video preload errors are silently ignored
    }
  }

  Future<void> _transitionToNextVideo() async {
    if (_isChangingVideo || _nextController == null) return;

    _isChangingVideo = true;

    try {
      await _nextController!.play();

      int attempts = 0;
      while (attempts < 10 && _nextController != null) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_nextController!.value.isPlaying) break;
        attempts++;
      }

      if (!mounted) return;

      final oldController = _currentController;
      oldController?.removeListener(_onVideoProgress);

      setState(() {
        _currentController = _nextController;
        _nextController = null;
      });

      _currentVideoIndex = (_currentVideoIndex + 1) % _videoUrls.length;

      Future.delayed(const Duration(seconds: 1), () {
        oldController?.dispose();
      });

      int playAttempts = 0;
      while (playAttempts < 10 && _currentController != null) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_currentController!.value.isPlaying) break;
        playAttempts++;
      }

      if (mounted && _currentController != null) {
        _currentController!.addListener(_onVideoProgress);
        _hasTriggeredChange = false;
        _videoStartTime = DateTime.now();
      }

      await _preloadNextVideo();
    } finally {
      _isChangingVideo = false;
    }
  }

  @override
  void dispose() {
    _currentController?.removeListener(_onVideoProgress);
    _currentController?.dispose();
    _nextController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentController == null ||
        !_currentController!.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF324943).withValues(alpha: 0.3),
              const Color(0xFF241913),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _currentController!.value.size.width,
          height: _currentController!.value.size.height,
          child: VideoPlayer(_currentController!),
        ),
      ),
    );
  }
}
