import 'dart:async';
import 'dart:math' as math;

import 'package:cuelume/cuelume.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CuelumeExampleApp());
}

class CuelumeExampleApp extends StatelessWidget {
  const CuelumeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Cuelume example',
      color: _violet,
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
      home: CuelumeExamplePage(),
    );
  }
}

class CuelumeExamplePage extends StatefulWidget {
  const CuelumeExamplePage({super.key});

  @override
  State<CuelumeExamplePage> createState() => _CuelumeExamplePageState();
}

class _CuelumeExamplePageState extends State<CuelumeExamplePage>
    with SingleTickerProviderStateMixin {
  static const _descriptions = <SoundName, _SoundInfo>{
    SoundName.chime: _SoundInfo(
      'Soft ascending bell',
      'Hover / confirm',
      family: 'TONAL',
      energy: 'LOW',
    ),
    SoundName.sparkle: _SoundInfo(
      'Four-note twinkle',
      'Playful accent',
      family: 'ARPEGGIO',
      energy: 'HIGH',
    ),
    SoundName.droplet: _SoundInfo(
      'Falling pitch glide',
      'Dismiss / collapse',
      family: 'GLIDE',
      energy: 'LOW',
    ),
    SoundName.bloom: _SoundInfo(
      'Warm slow swell',
      'Reveal / expand',
      family: 'PAD',
      energy: 'LOW',
    ),
    SoundName.whisper: _SoundInfo(
      'Quiet hush',
      'Tooltip / preview',
      family: 'TEXTURE',
      energy: 'LOW',
    ),
    SoundName.tick: _SoundInfo(
      'Crisp instant tick',
      'Menu / navigation',
      family: 'UI',
      energy: 'HIGH',
    ),
    SoundName.press: _SoundInfo(
      'Muted knock',
      'Pointer down',
      family: 'UI',
      energy: 'MID',
    ),
    SoundName.release: _SoundInfo(
      'Springy tick',
      'Pointer up',
      family: 'UI',
      energy: 'HIGH',
    ),
    SoundName.toggle: _SoundInfo(
      'Mechanical click-clack',
      'Switch / tab',
      family: 'UI',
      energy: 'MID',
    ),
    SoundName.success: _SoundInfo(
      'Warm confirmation',
      'Action complete',
      family: 'CHORD',
      energy: 'MID',
    ),
    SoundName.error: _SoundInfo(
      'Descending refusal',
      'Recoverable error',
      family: 'REFUSAL',
      energy: 'MID',
    ),
    SoundName.page: _SoundInfo(
      'Papery flick',
      'Page / carousel',
      family: 'TEXTURE',
      energy: 'MID',
    ),
    SoundName.loading: _SoundInfo(
      'Rising shimmer',
      'Work starting',
      family: 'MOTION',
      energy: 'MID',
    ),
    SoundName.ready: _SoundInfo(
      'Lock-on resolve',
      'Content ready',
      family: 'RESOLVE',
      energy: 'MID',
    ),
    SoundName.pulse: _SoundInfo(
      'Synthetic chirp',
      'Primary control',
      family: 'SYNTH',
      energy: 'HIGH',
    ),
    SoundName.scan: _SoundInfo(
      'Three-step locator',
      'Secondary control',
      family: 'SEQUENCE',
      energy: 'HIGH',
    ),
    SoundName.arrival: _SoundInfo(
      'Harmonic portal',
      'Route arrival',
      family: 'ARRIVAL',
      energy: 'LOW',
    ),
    SoundName.focus: _SoundInfo(
      'Soft selection ping',
      'Keyboard / focus',
      family: 'FOCUS',
      energy: 'LOW',
    ),
    SoundName.attention: _SoundInfo(
      'Gentle double pulse',
      'Needs attention',
      family: 'NOTICE',
      energy: 'MID',
    ),
    SoundName.notification: _SoundInfo(
      'Bright incoming bell',
      'External event',
      family: 'INBOX',
      energy: 'MID',
    ),
    SoundName.cancel: _SoundInfo(
      'Low descending two-hit',
      'Cancel / undo',
      family: 'CANCEL',
      energy: 'LOW',
    ),
  };

  static const _soundArc = <_CueStep>[
    _CueStep(
      SoundName.loading,
      '01 / PREPARE',
      'Rising shimmer',
      pause: Duration(milliseconds: 260),
    ),
    _CueStep(
      SoundName.ready,
      '02 / RESOLVE',
      'Lock-on resolve',
      pause: Duration(milliseconds: 300),
    ),
    _CueStep(
      SoundName.pulse,
      '03 / ENGAGE',
      'Synthetic chirp',
      pause: Duration(milliseconds: 230),
    ),
    _CueStep(
      SoundName.success,
      '04 / COMPLETE',
      'Warm confirmation',
      pause: Duration(milliseconds: 260),
    ),
  ];

  bool _enabled = true;
  double _volume = 0.7;
  SoundName? _lastPlayed;
  String _status = 'Ready to play';
  int _boundActivations = 0;
  int _sequenceRun = 0;
  bool _isSequencing = false;
  late final AnimationController _ambientController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _ambientController.stop();
    } else {
      _ambientController.repeat();
    }
  }

  @override
  void dispose() {
    _sequenceRun++;
    _ambientController.dispose();
    super.dispose();
  }

  void _play(SoundName sound, {double? volume, String? status}) {
    Cuelume.play(sound, volume: volume);
    setState(() {
      _lastPlayed = sound;
      _status =
          status ??
          (volume == null
              ? 'Played ${sound.name}'
              : 'Played ${sound.name} at ${(volume * 100).round()}%');
    });
  }

  Future<void> _playSoundArc() async {
    final run = ++_sequenceRun;
    setState(() {
      _isSequencing = true;
      _status = 'Sound arc armed / listen for the resolve';
    });
    for (final step in _soundArc) {
      if (!mounted || run != _sequenceRun) return;
      _play(step.sound, status: '${step.phase} · ${step.status}');
      await Future<void>.delayed(step.pause);
    }
    if (!mounted || run != _sequenceRun) return;
    setState(() {
      _isSequencing = false;
      _status = 'Arc complete / four cues, one flow';
    });
  }

  void _setEnabled(bool value) {
    Cuelume.setEnabled(value);
    setState(() {
      _enabled = value;
      _status = value ? 'Sound feedback enabled' : 'Sound feedback muted';
    });
  }

  void _setVolume(double value) {
    Cuelume.setVolume(value);
    setState(() {
      _volume = value;
      _status = 'Volume set to ${(value * 100).round()}%';
    });
  }

  Future<void> _warmup() async {
    setState(() => _status = 'Preparing audio…');
    await Cuelume.warmup();
    if (!mounted) return;
    setState(() => _status = 'Audio backend ready');
  }

  void _onBoundButtonPressed() {
    setState(() {
      _boundActivations++;
      _status = 'Bound button activated ($_boundActivations)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _ink,
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = constraints.maxWidth >= 960 ? 56.0 : 20.0;
                  final contentWidth = constraints.maxWidth - side * 2;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(side, 24, side, 56),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 44),
                      _buildHero(),
                      const SizedBox(height: 24),
                      _buildCueDeck(),
                      const SizedBox(height: 28),
                      _buildControlRow(contentWidth),
                      const SizedBox(height: 42),
                      _buildPaletteHeader(),
                      const SizedBox(height: 16),
                      _buildSoundGrid(contentWidth),
                      const SizedBox(height: 40),
                      _buildFooter(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _LogoMark(),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'CUELUME',
            style: TextStyle(
              color: _paper,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.2,
            ),
          ),
        ),
        if (!compact)
          Text(
            'LIVE AUDIO / ${sounds.length} CUES',
            style: _monoStyle(color: _muted, size: 10, spacing: 1.2),
          ),
        if (!compact) const SizedBox(width: 18),
        _ActionButton(
          label: 'WARM UP',
          leading: '↯',
          compact: true,
          onPressed: _warmup,
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SOUND\nAS SIGNAL', style: _displayStyle(size: 54, color: _paper)),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Text(
            'A small, intentional palette for the moments between tap and response. Synthesized live. No audio files. No generic click tracks.',
            style: const TextStyle(
              color: _muted,
              fontSize: 16,
              height: 1.5,
              letterSpacing: 0.15,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Container(width: 34, height: 2, color: _acid),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: _motionDuration(
                  context,
                  const Duration(milliseconds: 180),
                ),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  _lastPlayed == null
                      ? 'LISTEN TO THE PALETTE'
                      : 'NOW PLAYING / ${_lastPlayed!.name.toUpperCase()}',
                  key: ValueKey(_lastPlayed),
                  style: _monoStyle(color: _acid, size: 10, spacing: 1.3),
                ),
              ),
            ),
          ],
        ),
        if (MediaQuery.sizeOf(context).width >= 740) ...[
          const SizedBox(height: 26),
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) => _SignalVisualizer(
              progress: _ambientController.value,
              active: _lastPlayed != null,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlRow(double width) {
    final controls = [
      _buildPreferencesPanel(),
      _buildBindingPanel(),
      _buildImperativePanel(),
    ];
    final columns = width >= 1180
        ? 3
        : width >= 740
        ? 2
        : 1;
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          controls[0],
          const SizedBox(height: 12),
          controls[1],
          const SizedBox(height: 12),
          controls[2],
        ],
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: controls
          .map(
            (child) => SizedBox(
              width: (width - (columns - 1) * 12) / columns,
              child: child,
            ),
          )
          .toList(),
    );
  }

  Widget _buildCueDeck() {
    final sound = _lastPlayed ?? SoundName.chime;
    final info = _descriptions[sound]!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _lineBright),
        gradient: const LinearGradient(
          colors: [Color(0xFF15152B), Color(0xFF101020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 17),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 580;
            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _violet,
                    border: Border.all(color: _acid),
                  ),
                  child: Text(
                    (sound.index + 1).toString().padLeft(2, '0'),
                    style: _monoStyle(
                      color: _acid,
                      size: 11,
                      spacing: 1,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVE CUE / ${info.family}',
                        style: _monoStyle(color: _acid, size: 9, spacing: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sound.name.toUpperCase(),
                        style: _displayStyle(size: 25, color: _paper),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        info.character,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final tags = Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _CueTag(label: 'USE', value: info.usage),
                _CueTag(label: 'ENERGY', value: info.energy),
                _CueTag(
                  label: 'INDEX',
                  value: '${sound.index + 1}/${sounds.length}',
                ),
              ],
            );
            final replay = _ActionButton(
              label: 'REPLAY CUE',
              leading: '▶',
              compact: true,
              onPressed: () => _play(sound),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(height: 15),
                  tags,
                  const SizedBox(height: 14),
                  replay,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [tags, const SizedBox(height: 12), replay],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreferencesPanel() {
    return _Panel(
      eyebrow: '01 / PREFERENCES',
      title: 'Control the signal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleRow(
            label: 'SOUND FEEDBACK',
            value: _enabled,
            onChanged: _setEnabled,
          ),
          const SizedBox(height: 20),
          Text('MASTER VOLUME', style: _monoStyle(color: _muted, size: 10)),
          const SizedBox(height: 10),
          _VolumeRail(value: _volume, onChanged: _setVolume),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  _status,
                  style: _monoStyle(color: _muted, size: 10),
                ),
              ),
              Text(
                '${(_volume * 100).round().toString().padLeft(3)}%',
                style: _monoStyle(
                  color: _acid,
                  size: 12,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBindingPanel() {
    return _Panel(
      eyebrow: '02 / BINDING',
      title: 'One wrapper, four cues',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CuelumeListener maps pointer phases to sound. Hover is mouse-only and globally throttled.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 17),
          CuelumeListener(
            hover: .custom(SoundName.chime, volume: 0.2),
            press: .custom(SoundName.press, volume: 0.7),
            release: .system(SoundName.release),
            child: _ActionButton(
              label: 'TRY THE BOUND BUTTON',
              leading: '⌁',
              onPressed: Cuelume.wrap(_onBoundButtonPressed, SoundName.toggle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImperativePanel() {
    return _Panel(
      eyebrow: '03 / IMPERATIVE',
      title: 'Call it when it matters',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ActionButton(
            label: _isSequencing ? 'REPLAY ARC' : 'PLAY SOUND ARC',
            leading: '⌁',
            onPressed: _playSoundArc,
          ),
          _ActionButton(
            label: 'SUCCESS',
            leading: '+',
            onPressed: () => _play(SoundName.success),
          ),
          _ActionButton(
            label: 'QUIET 40%',
            leading: '·',
            quiet: true,
            onPressed: () => _play(SoundName.success, volume: 0.4),
          ),
          _ActionButton(
            label: 'ERROR',
            leading: '×',
            quiet: true,
            onPressed: () => _play(SoundName.error),
          ),
          _ActionButton(
            label: 'FOCUS',
            leading: '○',
            quiet: true,
            onPressed: () => _play(SoundName.focus),
          ),
          _ActionButton(
            label: 'ATTENTION',
            leading: '!',
            quiet: true,
            onPressed: () => _play(SoundName.attention),
          ),
          _ActionButton(
            label: 'NOTIFY',
            leading: '✦',
            quiet: true,
            onPressed: () => _play(SoundName.notification),
          ),
          _ActionButton(
            label: 'CANCEL',
            leading: '←',
            quiet: true,
            onPressed: () => _play(SoundName.cancel),
          ),
          _ActionButton(
            label: 'WRAP + CALLBACK',
            leading: '↗',
            quiet: true,
            onPressed: Cuelume.wrap(
              () => setState(() => _status = 'Cuelume.wrap callback ran'),
              SoundName.toggle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteHeader() {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THE PALETTE',
                style: _monoStyle(color: _acid, size: 11, spacing: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a texture',
                style: _displayStyle(size: 30, color: _paper),
              ),
            ],
          ),
        ),
        if (!compact)
          Text(
            'TAP TO PLAY / HOVER TO PREVIEW',
            style: _monoStyle(color: _muted, size: 9, spacing: 1.1),
          ),
      ],
    );
  }

  Widget _buildSoundGrid(double width) {
    final columns = width >= 1180
        ? 4
        : width >= 740
        ? 3
        : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sounds.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: width < 500 ? 1.16 : 1.42,
      ),
      itemBuilder: (context, index) {
        final sound = sounds[index];
        return CuelumeListener(
          hover: SoundSpec.system(sound),
          child: _SoundTile(
            sound: sound,
            info: _descriptions[sound]!,
            selected: sound == _lastPlayed,
            onPressed: () => _play(sound),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) =>
                _Waveform(progress: _ambientController.value),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 18),
          Text(
            'FLUTTER PORT / SYNTHESIZED LIVE',
            style: _monoStyle(color: _muted, size: 9, spacing: 1),
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _panel,
        border: Border.fromBorderSide(BorderSide(color: _line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: _monoStyle(color: _acid, size: 9, spacing: 1.4),
            ),
            const SizedBox(height: 8),
            Text(title, style: _displayStyle(size: 21, color: _paper)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _CueTag extends StatelessWidget {
  const _CueTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x121DFFB2),
        border: Border.all(color: _lineBright),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label  ',
                style: _monoStyle(color: _muted, size: 8, spacing: 0.9),
              ),
              TextSpan(
                text: value.toUpperCase(),
                style: _monoStyle(
                  color: _paper,
                  size: 9,
                  spacing: 0.7,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.leading,
    required this.onPressed,
    this.quiet = false,
    this.compact = false,
  });

  final String label;
  final String leading;
  final VoidCallback onPressed;
  final bool quiet;
  final bool compact;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final duration = _motionDuration(
      context,
      const Duration(milliseconds: 140),
    );
    final active = _hovered || _pressed;
    final background = widget.quiet
        ? (active ? _violet.withValues(alpha: 0.2) : const Color(0x00000000))
        : (active ? _acid : _violet);
    final foreground = widget.quiet
        ? (active ? _acid : _paper)
        : (active ? _ink : _paper);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: duration,
          transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: widget.compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: widget.quiet ? _lineBright : _acid),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.leading,
                style: TextStyle(color: foreground, fontSize: 16, height: 1),
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: _monoStyle(
                  color: foreground,
                  size: 10,
                  spacing: 0.9,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final duration = _motionDuration(
      context,
      const Duration(milliseconds: 140),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Text(
            label,
            style: _monoStyle(
              color: _paper,
              size: 11,
              spacing: 1.1,
              weight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: duration,
            width: 42,
            height: 22,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? _violet : const Color(0xFF202036),
              border: Border.all(color: value ? _acid : _lineBright),
            ),
            child: AnimatedAlign(
              duration: duration,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 14,
                height: 14,
                color: value ? _acid : _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeRail extends StatelessWidget {
  const _VolumeRail({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  void _update(Offset localPosition, double width) {
    onChanged((localPosition.dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _update(details.localPosition, width),
          onHorizontalDragUpdate: (details) =>
              _update(details.localPosition, width),
          child: SizedBox(
            height: 24,
            child: CustomPaint(
              painter: _RailPainter(value),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _SoundTile extends StatefulWidget {
  const _SoundTile({
    required this.sound,
    required this.info,
    required this.selected,
    required this.onPressed,
  });

  final SoundName sound;
  final _SoundInfo info;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_SoundTile> createState() => _SoundTileState();
}

class _SoundTileState extends State<_SoundTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final duration = _motionDuration(
      context,
      const Duration(milliseconds: 150),
    );
    final active = widget.selected || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: active ? _tileActive : _tile,
            border: Border.all(color: active ? _acid : _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.sound.name.toUpperCase(),
                      style: _monoStyle(
                        color: active ? _acid : _paper,
                        size: 12,
                        spacing: 1,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    active ? '●' : '○',
                    style: TextStyle(
                      color: active ? _acid : _muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.info.character,
                style: const TextStyle(
                  color: _paper,
                  fontSize: 13,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 11),
              SizedBox(
                height: 18,
                width: double.infinity,
                child: CustomPaint(
                  painter: _MiniWavePainter(
                    seed: widget.sound.index,
                    active: active,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                widget.info.usage.toUpperCase(),
                style: _monoStyle(color: _muted, size: 9, spacing: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: CustomPaint(painter: _WavePainter(progress)),
    );
  }
}

class _SignalVisualizer extends StatelessWidget {
  const _SignalVisualizer({required this.progress, required this.active});

  final double progress;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      width: double.infinity,
      child: CustomPaint(
        painter: _VisualizerPainter(progress: progress, active: active),
      ),
    );
  }
}

class _SoundInfo {
  const _SoundInfo(
    this.character,
    this.usage, {
    required this.family,
    required this.energy,
  });

  final String character;
  final String usage;
  final String family;
  final String energy;
}

class _CueStep {
  const _CueStep(this.sound, this.phase, this.status, {required this.pause});

  final SoundName sound;
  final String phase;
  final String status;
  final Duration pause;
}

Duration _motionDuration(BuildContext context, Duration duration) {
  return MediaQuery.maybeOf(context)?.disableAnimations == true
      ? Duration.zero
      : duration;
}

TextStyle _monoStyle({
  required Color color,
  required double size,
  double spacing = 0,
  FontWeight weight = FontWeight.w400,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    letterSpacing: spacing,
    fontWeight: weight,
    fontFamily: 'monospace',
  );
}

TextStyle _displayStyle({required double size, required Color color}) {
  return TextStyle(
    color: color,
    fontSize: size,
    height: 0.95,
    letterSpacing: -1.5,
    fontWeight: FontWeight.w900,
  );
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _RailPainter extends CustomPainter {
  const _RailPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    final base = Paint()
      ..color = _lineBright
      ..strokeWidth = 2;
    final active = Paint()
      ..color = _acid
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, center), Offset(size.width, center), base);
    canvas.drawLine(
      Offset(0, center),
      Offset(size.width * value, center),
      active,
    );
    canvas.drawCircle(
      Offset(size.width * value, center),
      6,
      Paint()..color = _acid,
    );
    canvas.drawCircle(
      Offset(size.width * value, center),
      3,
      Paint()..color = _ink,
    );
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _MiniWavePainter extends CustomPainter {
  const _MiniWavePainter({required this.seed, required this.active});

  final int seed;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? _acid : _muted
      ..strokeWidth = active ? 1.8 : 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(0, size.height / 2);
    final cycles = 1.7 + (seed % 4) * 0.55;
    final amplitude = active ? 6.5 : 4.2;
    for (var x = 0.0; x <= size.width; x += 3) {
      final normalized = x / size.width;
      final envelope = math.sin(normalized * math.pi).abs();
      final y =
          size.height / 2 +
          math.sin(normalized * math.pi * cycles * 2 + seed * 0.7) *
              amplitude *
              envelope;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniWavePainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.active != active;
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = _acid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..color = _violet;
    canvas.drawRect(Offset.zero & size, fill);
    final path = Path()
      ..moveTo(4, size.height * .55)
      ..lineTo(9, size.height * .55)
      ..lineTo(12, size.height * .25)
      ..lineTo(16, size.height * .75)
      ..lineTo(20, size.height * .4)
      ..lineTo(24, size.height * .4);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _acid
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(0, size.height / 2);
    for (var x = 0.0; x <= size.width; x += 3) {
      final y =
          size.height / 2 +
          math.sin(x / 7 + progress * math.pi * 2) *
              4 *
              math.sin(x / 31 + progress * math.pi);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _VisualizerPainter extends CustomPainter {
  const _VisualizerPainter({required this.progress, required this.active});

  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height / 2);
    final phase = progress * math.pi * 2;
    final radius = 28 + math.sin(phase) * 3;
    final glow = Paint()
      ..color = _violet.withValues(alpha: active ? 0.28 : 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 15, glow);
    final ring = Paint()
      ..color = _acid.withValues(alpha: active ? 0.85 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius * 0.56, ring..strokeWidth = 2.5);

    final bars = Paint()
      ..color = _acid
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    for (var i = 0; i < SoundName.values.length; i++) {
      final x = size.width * 0.04 + i * size.width * 0.035;
      final pulse = math.sin(phase * 1.4 + i * 0.8).abs();
      final height = 7 + pulse * (active ? 24 : 12);
      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        bars..color = _acid.withValues(alpha: 0.2 + pulse * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.active != active;
}

const _ink = Color(0xFF0C0B18);
const _panel = Color(0xCC151329);
const _tile = Color(0xB317152C);
const _tileActive = Color(0xFF211C46);
const _violet = Color(0xFF6E4BFF);
const _acid = Color(0xFFD7FF55);
const _paper = Color(0xFFF6F3FF);
const _muted = Color(0xFF9892B5);
const _line = Color(0xFF39334F);
const _lineBright = Color(0xFF5B5278);
