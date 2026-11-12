import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/widget/flutter_toast.dart';
import '../controller/ads_controller.dart';
import '../model/ads_model.dart';

// ── YouTube Helpers ──
String? extractYoutubeId(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.host.isEmpty) return null;
  final host = uri.host.toLowerCase();
  String? id;
  if (host == 'youtu.be' || host == 'www.youtu.be') {
    id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else if (host.endsWith('youtube.com') ||
      host.endsWith('youtube-nocookie.com')) {
    if (uri.queryParameters['v'] != null) {
      id = uri.queryParameters['v'];
    } else if (uri.pathSegments.length >= 2 &&
        ['embed', 'shorts', 'live', 'v'].contains(uri.pathSegments.first)) {
      id = uri.pathSegments[1];
    }
  }
  if (id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) return id;
  return null;
}

// ═════════════════════════════════════════════════════════
//  SELF-CONTAINED VIDEO PLAYER  (unchanged)
// ═════════════════════════════════════════════════════════
class _CachedStream {
  final String url;
  final DateTime time;
  _CachedStream(this.url, this.time);
}

class _AdsVideoPlayer extends StatefulWidget {
  final String url;
  final String title;
  final String? thumbnailUrl;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  const _AdsVideoPlayer({
    super.key,
    required this.url,
    required this.title,
    this.thumbnailUrl,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  @override
  State<_AdsVideoPlayer> createState() => _AdsVideoPlayerState();
}

class _AdsVideoPlayerState extends State<_AdsVideoPlayer> {
  static const Color _accent = Colors.white;
  static const List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
  static final Map<String, _CachedStream> _streamCache = {};

  VideoPlayerController? _vc;
  bool _loading = true;
  bool _error = false;
  bool _controlsVisible = true;
  bool _muted = false;
  bool _dragging = false;
  double _dragValue = 0;
  double _doubleTapX = 0;
  int _speedIndex = 1;
  int _token = 0;
  Timer? _hideTimer;

  bool get _isWebYouTube =>
      kIsWeb && extractYoutubeId(widget.url) != null;

  @override
  void initState() {
    super.initState();
    if (_isWebYouTube) {
      _loading = false;
      return;
    }
    _init();
  }

  @override
  void didUpdateWidget(covariant _AdsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url) return;
    if (_isWebYouTube) {
      _loading = false;
      return;
    }
    _init();
  }

  @override
  void dispose() {
    _token++;
    _hideTimer?.cancel();
    _vc?.removeListener(_onTick);
    _vc?.dispose();
    super.dispose();
  }

  Future<String> _resolveUrl(String url, {bool fresh = false}) async {
    final id = extractYoutubeId(url);
    if (id == null) return url;

    final cached = _streamCache[id];
    if (!fresh &&
        cached != null &&
        DateTime.now().difference(cached.time) < const Duration(hours: 2)) {
      return cached.url;
    }

    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient
          .getManifest(id)
          .timeout(const Duration(seconds: 25));

      final streams = manifest.muxed.toList();
      if (streams.isEmpty) throw Exception('No playable stream');

      streams.sort((a, b) =>
          a.videoResolution.height.compareTo(b.videoResolution.height));
      final upTo720 =
      streams.where((s) => s.videoResolution.height <= 720).toList();
      final chosen = upTo720.isNotEmpty ? upTo720.last : streams.first;

      final resolved = chosen.url.toString();
      _streamCache[id] = _CachedStream(resolved, DateTime.now());
      return resolved;
    } finally {
      yt.close();
    }
  }

  Future<void> _init({bool fresh = false}) async {
    final token = ++_token;
    final old = _vc;
    old?.removeListener(_onTick);

    _hideTimer?.cancel();
    setState(() {
      _vc = null;
      _loading = true;
      _error = false;
      _controlsVisible = true;
      _dragging = false;
      _speedIndex = 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());

    try {
      final resolved = await _resolveUrl(widget.url, fresh: fresh);

      final c = VideoPlayerController.networkUrl(
        Uri.parse(resolved),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await c.initialize();

      if (!mounted || token != _token) {
        await c.dispose();
        return;
      }

      c.setLooping(false);
      c.setVolume(_muted ? 0 : 1);
      c.addListener(_onTick);

      setState(() {
        _vc = c;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || token != _token) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _onTick() {
    if (!mounted) return;
    final c = _vc;
    if (c != null && c.value.hasError && !_error) {
      setState(() => _error = true);
      return;
    }
    setState(() {});
  }

  bool _isEnded(VideoPlayerValue v) =>
      v.isInitialized &&
          v.duration > Duration.zero &&
          v.position >= v.duration - const Duration(milliseconds: 300) &&
          !v.isPlaying;

  void _scheduleHide() {
    _hideTimer?.cancel();
    final c = _vc;
    if (c == null || !c.value.isPlaying || _dragging) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _togglePlay() {
    final c = _vc;
    if (c == null) return;
    final v = c.value;
    if (_isEnded(v)) {
      c.seekTo(Duration.zero);
      c.play();
    } else if (v.isPlaying) {
      c.pause();
      _hideTimer?.cancel();
    } else {
      c.play();
    }
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _seekBy(Duration offset) {
    final c = _vc;
    if (c == null) return;
    final total = c.value.duration;
    var target = c.value.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > total) target = total;
    c.seekTo(target);
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _toggleMute() {
    final c = _vc;
    if (c == null) return;
    setState(() => _muted = !_muted);
    c.setVolume(_muted ? 0 : 1);
    _scheduleHide();
  }

  void _cycleSpeed() {
    final c = _vc;
    if (c == null) return;
    _speedIndex = (_speedIndex + 1) % _speeds.length;
    c.setPlaybackSpeed(_speeds[_speedIndex]);
    setState(() {});
    _scheduleHide();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    }
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isWebYouTube) {
      return _WebYoutubePlayer(
        key: ValueKey(extractYoutubeId(widget.url)),
        videoId: extractYoutubeId(widget.url)!,
        isFullscreen: widget.isFullscreen,
        onToggleFullscreen: widget.onToggleFullscreen,
      );
    }
    return ColoredBox(color: Colors.black, child: _buildBody());
  }

  Widget _buildBody() {
    if (_error) return _buildError();
    final c = _vc;
    if (_loading || c == null || !c.value.isInitialized) {
      return _buildLoadingCover();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
        ),
        _buildOverlay(c),
      ],
    );
  }

  Widget _fullscreenBackButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: IconButton(
          onPressed: widget.onToggleFullscreen,
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildLoadingCover() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
          Image.network(
            widget.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          )
        else
          Container(color: Colors.black),
        Container(
          color: Colors.black.withOpacity(0.4),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        if (widget.isFullscreen) _fullscreenBackButton(),
      ],
    );
  }

  Widget _buildError() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 34),
                const SizedBox(height: 6),
                const Text(
                  'Could not play this video.\nCheck the link or your internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _init(fresh: true),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.isFullscreen) _fullscreenBackButton(),
      ],
    );
  }

  Widget _buildOverlay(VideoPlayerController c) {
    final v = c.value;
    final show = _controlsVisible || !v.isPlaying || _isEnded(v);

    return LayoutBuilder(
      builder: (context, cons) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          onDoubleTapDown: (d) => _doubleTapX = d.localPosition.dx,
          onDoubleTap: () => _seekBy(
            Duration(seconds: _doubleTapX < cons.maxWidth / 2 ? -10 : 10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (v.isBuffering)
                const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                        color: _accent, strokeWidth: 3),
                  ),
                ),
              IgnorePointer(
                ignoring: !show,
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _buildControls(c),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(VideoPlayerController c) {
    final v = c.value;
    final fs = widget.isFullscreen;
    final ended = _isEnded(v);

    final totalMs = v.duration.inMilliseconds > 0
        ? v.duration.inMilliseconds.toDouble()
        : 1.0;
    final posMs =
    (_dragging ? _dragValue : v.position.inMilliseconds.toDouble())
        .clamp(0.0, totalMs)
        .toDouble();
    final bufMs = v.buffered.isNotEmpty
        ? v.buffered.last.end.inMilliseconds.toDouble().clamp(0.0, totalMs)
        : 0.0;
    final shownPos = Duration(milliseconds: posMs.round());

    final content = Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(fs ? 4 : 12, 4, 4, 0),
          child: Row(
            children: [
              if (fs)
                IconButton(
                  onPressed: widget.onToggleFullscreen,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
              Expanded(
                child: fs
                    ? Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleButton(Icons.replay_10_rounded, 30,
                    () => _seekBy(const Duration(seconds: -10))),
            const SizedBox(width: 24),
            if (!v.isBuffering)
              _circleButton(
                ended
                    ? Icons.replay_rounded
                    : (v.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
                40,
                _togglePlay,
                filled: true,
              )
            else
              const SizedBox(width: 64, height: 64),
            const SizedBox(width: 24),
            _circleButton(Icons.forward_10_rounded, 30,
                    () => _seekBy(const Duration(seconds: 10))),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
          child: Row(
            children: [
              Text(
                '${_fmt(shownPos)} / ${_fmt(v.duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: _accent,
                    inactiveTrackColor: Colors.white24,
                    secondaryActiveTrackColor: Colors.white54,
                    thumbColor: _accent,
                  ),
                  child: Slider(
                    min: 0,
                    max: totalMs,
                    value: posMs,
                    secondaryTrackValue: bufMs,
                    onChangeStart: (val) {
                      _hideTimer?.cancel();
                      setState(() {
                        _dragging = true;
                        _dragValue = val;
                      });
                    },
                    onChanged: (val) => setState(() => _dragValue = val),
                    onChangeEnd: (val) {
                      c.seekTo(Duration(milliseconds: val.round()));
                      setState(() => _dragging = false);
                      _scheduleHide();
                    },
                  ),
                ),
              ),
              InkWell(
                onTap: _cycleSpeed,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Text(
                    '${_speeds[_speedIndex]}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onToggleFullscreen,
                icon: Icon(
                  fs
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return fs ? SafeArea(child: content) : content;
  }

  Widget _circleButton(IconData icon, double size, VoidCallback onTap,
      {bool filled = false}) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(filled ? 12 : 8),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}

class _WebYoutubePlayer extends StatefulWidget {
  final String videoId;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  const _WebYoutubePlayer({
    super.key,
    required this.videoId,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  @override
  State<_WebYoutubePlayer> createState() => _WebYoutubePlayerState();
}

class _WebYoutubePlayerState extends State<_WebYoutubePlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        YoutubePlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
        ),
        if (widget.isFullscreen)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: widget.onToggleFullscreen,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════
//  ADS CARD
// ═════════════════════════════════════════════════════════
class AdsCard extends StatefulWidget {
  const AdsCard({super.key});

  @override
  State<AdsCard> createState() => _AdsCardState();
}

class _AdsCardState extends State<AdsCard> {
  final AdsController controller = Get.find<AdsController>();

  bool isEditing = false;
  bool isAdding = false;
  bool _isFullscreen = false;

  bool _isHome = false;

  Uint8List? _imageBytes;
  String? _imageName;

  final _titleCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _searchQuery = '';
  int? _filterYear;
  int? _filterMonth;
  DateTime? _filterDate;

  final List<int> _years = [2023, 2024, 2025, 2026];
  final List<Map<String, dynamic>> _months = const [
    {"id": 1, "name": "Jan"}, {"id": 2, "name": "Feb"}, {"id": 3, "name": "Mar"},
    {"id": 4, "name": "Apr"}, {"id": 5, "name": "May"}, {"id": 6, "name": "Jun"},
    {"id": 7, "name": "Jul"}, {"id": 8, "name": "Aug"}, {"id": 9, "name": "Sep"},
    {"id": 10, "name": "Oct"}, {"id": 11, "name": "Nov"}, {"id": 12, "name": "Dec"},
  ];

  final GlobalKey _playerKey = GlobalKey();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _videoUrlCtrl.dispose();
    _searchCtrl.dispose();
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _setFullscreen(bool value) async {
    if (value == _isFullscreen) return;
    setState(() => _isFullscreen = value);

    if (value) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _pickImage() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.single;
      setState(() {
        _imageName = f.name;
        _imageBytes = f.bytes;
      });
    } catch (e) {
      FlutterToast.error('Could not pick image: $e');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColor.primary,
            onPrimary: Colors.white,
            onSurface: AppColor.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _filterDate = picked;
        _filterYear = null;
        _filterMonth = null;
      });
    }
  }

  void _resetState() {
    if (_isFullscreen) _setFullscreen(false);
    controller.clearSelectedAd();
    setState(() {
      isEditing = false;
      isAdding = false;
      _isHome = false;
      _imageBytes = null;
      _imageName = null;
      _titleCtrl.clear();
      _videoUrlCtrl.clear();
    });
  }

  void _selectAd(AdsModel ad) {
    setState(() {
      isEditing = false;
      isAdding = false;
    });
    controller.fetchAdDetail(ad.id);
  }

  void _openAddForm() {
    if (_isFullscreen) _setFullscreen(false);
    controller.clearSelectedAd();
    setState(() {
      isAdding = true;
      isEditing = false;
      _isHome = false;
      _imageBytes = null;
      _imageName = null;
      _titleCtrl.clear();
      _videoUrlCtrl.clear();
    });
  }

  void _openEditForm(AdsModel ad) {
    if (_isFullscreen) _setFullscreen(false);
    setState(() {
      isAdding = false;
      isEditing = true;
      _isHome = ad.isHome;
      _imageBytes = null;
      _imageName = null;
      _titleCtrl.text = ad.title;
      _videoUrlCtrl.text = ad.videoUrl ?? '';
    });
  }

  Future<void> _saveForm() async {
    final title = _titleCtrl.text.trim();
    final videoUrl = _videoUrlCtrl.text.trim();

    if (title.isEmpty) {
      FlutterToast.error('Please enter a title');
      return;
    }

    final ad = controller.selectedAd.value;
    final hasExistingImage = isEditing &&
        (ad?.hasImage ?? false) &&
        _imageBytes == null;
    final hasNewImage = _imageBytes != null;
    final hasVideo = videoUrl.isNotEmpty;

    if (!hasExistingImage && !hasNewImage && !hasVideo) {
      FlutterToast.error('Add an image or a video URL');
      return;
    }

    bool ok;
    if (isAdding) {
      ok = await controller.createAd(
        title: title,
        videoUrl: hasVideo ? videoUrl : null,
        isHome: _isHome,
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      if (ok && controller.ads.isNotEmpty) _selectAd(controller.ads.first);
    } else if (isEditing && ad != null) {
      ok = await controller.updateAd(
        id: ad.id,
        title: title,
        videoUrl: videoUrl.isEmpty ? null : videoUrl,
        isHome: _isHome,
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
    } else {
      ok = false;
    }

    if (ok) {
      setState(() {
        isAdding = false;
        isEditing = false;
        _isHome = false;
        _imageBytes = null;
        _imageName = null;
        _titleCtrl.clear();
        _videoUrlCtrl.clear();
      });
    }
  }

  Future<void> _deleteAd(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (_isFullscreen) _setFullscreen(false);
    await controller.deleteAd(id);
    if (controller.selectedAd.value == null) _resetState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen && controller.selectedAd.value != null) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _buildPlayerWidget(controller.selectedAd.value!),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 20, color: AppColor.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'Manage Ads',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textDark),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openAddForm,
                icon: const Icon(Icons.add),
                label: const Text('Create Ad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildListPanel()),
                const SizedBox(width: 24),
                SizedBox(width: 420, child: _buildRightPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListPanel() {
    return Obx(() {
      final all = controller.ads;
      final filtered = all.where((ad) {
        final title = ad.title.toLowerCase();
        final videoUrl = (ad.videoUrl ?? '').toLowerCase();
        final q = _searchQuery.toLowerCase();
        final matchesSearch = title.contains(q) || videoUrl.contains(q);

        bool matchesDate = true;
        if (_filterDate != null) {
          matchesDate = DateUtils.isSameDay(ad.createdAt, _filterDate);
        } else if (_filterMonth != null) {
          matchesDate = ad.createdAt.month == _filterMonth &&
              (_filterYear == null || ad.createdAt.year == _filterYear);
        } else if (_filterYear != null) {
          matchesDate = ad.createdAt.year == _filterYear;
        }
        return matchesSearch && matchesDate;
      }).toList();

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.surface),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search ads...',
                      hintStyle: const TextStyle(
                          fontSize: 14, color: AppColor.textGrey),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColor.primary, size: 20),
                      filled: true,
                      fillColor: AppColor.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 18, color: AppColor.textGrey),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildYearDropdown()),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMonthDropdown()),
                      const SizedBox(width: 8),
                      Expanded(child: _buildDatePicker()),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetchAds(),
                child: _buildListBody(filtered),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildListBody(List<AdsModel> filtered) {
    if (controller.isLoading.value && controller.ads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.ads.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.campaign_outlined,
              size: 50, color: AppColor.textGrey.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Center(
            child: Text('No ads yet. Tap "Create Ad" to add one.',
                style: TextStyle(color: AppColor.textGrey)),
          ),
        ],
      );
    }
    if (filtered.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.search_off,
              size: 50, color: AppColor.textGrey.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Center(
            child: Text('No results found',
                style: TextStyle(color: AppColor.textGrey)),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final ad = filtered[i];
        final isSelected = controller.selectedAd.value?.id == ad.id &&
            !isEditing &&
            !isAdding;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColor.primary : AppColor.surface,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectAd(ad),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildThumbnail(ad),
                        if (ad.hasVideo)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 20),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ad.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ad.isHome) ...[
                              const SizedBox(width: 8),
                              _homeBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 12, color: AppColor.textGrey),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(ad.createdAt),
                              style: const TextStyle(
                                  color: AppColor.textGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.blue, size: 20),
                        onPressed: () => _openEditForm(ad),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: AppColor.error, size: 20),
                        onPressed: () => _deleteAd(ad.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _homeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_rounded, size: 11, color: Colors.green),
          SizedBox(width: 3),
          Text(
            'HOME',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(AdsModel ad) {
    if (ad.hasImage) {
      return Image.network(
        ad.image!,
        width: 80,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbPlaceholder(),
      );
    }
    return _thumbPlaceholder();
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 80,
      height: 60,
      color: AppColor.surface,
      child: const Icon(Icons.image_outlined,
          color: AppColor.textGrey, size: 24),
    );
  }

  Widget _buildYearDropdown() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _filterYear != null
            ? AppColor.primary.withOpacity(0.1)
            : AppColor.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _filterYear != null ? AppColor.primary : Colors.transparent,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          hint: const Text('Year',
              style: TextStyle(fontSize: 13, color: AppColor.textGrey)),
          value: _filterYear,
          icon: const Icon(Icons.arrow_drop_down, color: AppColor.primary),
          items: _years
              .map((y) => DropdownMenuItem(
            value: y,
            child: Text(y.toString(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ))
              .toList(),
          onChanged: (v) => setState(() {
            _filterYear = v;
            _filterDate = null;
          }),
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _filterMonth != null
            ? AppColor.primary.withOpacity(0.1)
            : AppColor.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
          _filterMonth != null ? AppColor.primary : Colors.transparent,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          hint: const Text('Month',
              style: TextStyle(fontSize: 13, color: AppColor.textGrey)),
          value: _filterMonth,
          icon: const Icon(Icons.arrow_drop_down, color: AppColor.primary),
          items: _months
              .map((m) => DropdownMenuItem(
            value: m['id'] as int,
            child: Text(m['name'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ))
              .toList(),
          onChanged: (v) => setState(() {
            _filterMonth = v;
            _filterDate = null;
          }),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _filterDate != null
              ? AppColor.primary.withOpacity(0.1)
              : AppColor.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
            _filterDate != null ? AppColor.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month,
              color:
              _filterDate != null ? AppColor.primary : AppColor.textGrey,
              size: 18,
            ),
            if (_filterDate != null) ...[
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM').format(_filterDate!),
                style: const TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _filterDate = null),
                child: const Icon(Icons.close,
                    size: 14, color: AppColor.primary),
              ),
            ] else ...[
              const SizedBox(width: 4),
              const Text('Date',
                  style: TextStyle(
                      fontSize: 13, color: AppColor.textGrey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Obx(() {
      final ad = controller.selectedAd.value;
      if (controller.isDetailLoading.value) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.surface),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (!isAdding && !isEditing && ad == null) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.surface),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined,
                    size: 60, color: AppColor.textGrey.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('Select an ad to view details',
                    style: TextStyle(color: AppColor.textGrey, fontSize: 15)),
              ],
            ),
          ),
        );
      }
      if (isAdding || isEditing) return _buildForm();
      return _buildView(ad!);
    });
  }

  Widget _buildForm() {
    final isEdit = isEditing && controller.selectedAd.value != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.surface, width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdding ? 'Create New Ad' : 'Edit Ad',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Ad Title *',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Summer Donation Drive',
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Banner Image',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildImagePreview(isEdit),
              ),
            ),
            if (_imageName != null) ...[
              const SizedBox(height: 6),
              Text(
                _imageName!,
                style: const TextStyle(
                    fontSize: 11, color: AppColor.textGrey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            const Text('Video URL (MP4 or YouTube)',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _videoUrlCtrl,
              decoration: InputDecoration(
                hintText: 'https://...mp4 or YouTube link',
                filled: true,
                fillColor: AppColor.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildIsHomeToggle(),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _resetState,
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColor.textGrey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Obx(() {
                    final busy = controller.isMutating.value;
                    return ElevatedButton(
                      onPressed: busy ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: busy
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                          : Text(
                        isAdding ? 'SAVE' : 'UPDATE',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIsHomeToggle() {
    return InkWell(
      onTap: () => setState(() => _isHome = !_isHome),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: _isHome
              ? Colors.green.withOpacity(0.08)
              : AppColor.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isHome ? Colors.green : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isHome ? Icons.home_rounded : Icons.home_outlined,
              color: _isHome ? Colors.green : AppColor.textGrey,
              size: 22,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Show on Home Screen',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Display this ad on the NGO home screen',
                    style: TextStyle(fontSize: 11, color: AppColor.textGrey),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isHome,
              activeColor: Colors.green,
              onChanged: (v) => setState(() => _isHome = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool isEdit) {
    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_imageBytes!,
            fit: BoxFit.cover, width: double.infinity, height: 120),
      );
    }
    final ad = controller.selectedAd.value;
    if (isEdit && (ad?.hasImage ?? false)) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              ad!.image!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 120,
              errorBuilder: (_, __, ___) => _emptyImagePreview(),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Tap to replace',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ],
      );
    }
    return _emptyImagePreview();
  }

  Widget _emptyImagePreview() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 32, color: AppColor.textGrey),
          SizedBox(height: 4),
          Text('Tap to browse image',
              style: TextStyle(fontSize: 12, color: AppColor.textGrey)),
        ],
      ),
    );
  }

  Widget _buildView(AdsModel ad) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.surface, width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: _resetState,
                icon: const Icon(Icons.close, color: AppColor.textGrey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildVideoSection(ad),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ad.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: AppColor.textGrey),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd MMM yyyy').format(ad.createdAt),
                          style: const TextStyle(
                              color: AppColor.textGrey, fontSize: 13)),
                      if (ad.isHome) ...[
                        const SizedBox(width: 16),
                        _homeBadge(),
                      ],
                    ],
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openEditForm(ad),
                      icon: const Icon(Icons.edit,
                          color: AppColor.primary),
                      label: const Text('Edit Ad',
                          style: TextStyle(color: AppColor.primary)),
                      style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColor.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(AdsModel ad) {
    if (_isFullscreen && ad.hasVideo) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ad.hasImage)
                Image.network(
                  ad.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColor.surface),
                )
              else
                Container(color: AppColor.surface),
              if (!ad.hasVideo)
                const SizedBox.shrink()
              else
                _buildPlayerWidget(ad),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerWidget(AdsModel ad) {
    return _AdsVideoPlayer(
      key: _playerKey,
      url: ad.videoUrl!,
      title: ad.title,
      thumbnailUrl: ad.image,
      isFullscreen: _isFullscreen,
      onToggleFullscreen: () => _setFullscreen(!_isFullscreen),
    );
  }
}