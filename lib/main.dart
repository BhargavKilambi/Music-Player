import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_player/songs.dart';
import 'package:music_player/theme.dart';
import 'package:fluttery/gestures.dart';
import 'package:fluttery_audio/fluttery_audio.dart';

void main() {
  SystemChrome
      .setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(new MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new AudioPlaylist(
      playlist: demoPlaylist.songs.map((DemoSong song) {
        return song.audioUrl;
      }).toList(growable: false),
      child: new Scaffold(
        appBar: new AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          leading: new IconButton(
            icon: new Icon(
              Icons.arrow_back_ios,
            ),
            color: const Color(0xFFDDDDDD),
            onPressed: () {},
          ),
          title: new Text(''),
          actions: <Widget>[
            new IconButton(
              icon: new Icon(
                Icons.menu,
              ),
              color: const Color(0xFFDDDDDD),
              onPressed: () {},
            ),
          ],
        ),
        body: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //seek bar
            new Expanded(
              child: new AudioPlaylistComponent(
                playlistBuilder:
                    (BuildContext context, Playlist playlist, Widget child) {
                  String albumArtUrl =
                      demoPlaylist.songs[playlist.activeIndex].albumArtUrl;
                  return new AudioSeekRadioBar(
                    albumArtUrl: albumArtUrl,
                  );
                },
              ),
            ),

            //visual
            new Container(
              width: double.infinity,
              height: 125.0,
              child: new Visualizer(
                builder: (BuildContext context, List<int> fft) {
                  return new CustomPaint(
                    painter: new VisualizerPainter(
                      fft: fft,
                      height: 125.0,
                      color: accentColor,
                    ),
                    child: new Container(),
                  );
                },
              ),
            ),
            //title
            new BottomController(),
          ],
        ),
      ),
    );
  }
}

class VisualizerPainter extends CustomPainter {
  final List<int> fft;
  final double height;
  final Color color;
  final Paint wavePaint;

  VisualizerPainter({
    this.fft,
    this.height,
    this.color,
  }) : wavePaint = new Paint()
          ..color = color.withOpacity(0.85)
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    _renderWaves(canvas, size);
  }

  void _renderWaves(Canvas canvas, Size size) {
    final histogramLow =
        _createHistogram(fft, 15, 2, ((fft.length) / 4).floor());
    final histogramHigh = _createHistogram(
        fft, 15, (fft.length / 4).ceil(), (fft.length / 2).floor());

    _renderHistogram(canvas, size, histogramLow);
    _renderHistogram(canvas, size, histogramHigh);
  }

  void _renderHistogram(Canvas canvas, Size size, List<int> histogram) {
    if (histogram.length == 0) {
      return;
    }

    final pointsToGraph = histogram.length;
    final widthPerSample = (size.width / (pointsToGraph - 2)).floor();

    final points = new List<double>.filled(pointsToGraph * 4, 0.0);

    for (int i = 0; i < histogram.length - 1; ++i) {
      points[i * 4] = (i * widthPerSample).toDouble();
      points[i * 4 + 1] = size.height - histogram[i].toDouble();

      points[i * 4 + 2] = ((i + 1) * widthPerSample).toDouble();
      points[i * 4 + 3] = size.height - (histogram[i + 1].toDouble());
    }

    Path path = new Path();
    path.moveTo(0.0, size.height);
    path.lineTo(points[0], points[1]);
    for (int i = 2; i < points.length - 4; i += 2) {
      path.cubicTo(points[i - 2] + 10.0, points[i - 1], points[i] - 10.0,
          points[i + 1], points[i], points[i + 1]);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  List<int> _createHistogram(List<int> samples, int bucketCount,
      [int start, int end]) {
    if (start == end) {
      return const [];
    }

    start = start ?? 0;
    end = end ?? samples.length - 1;
    final sampleCount = end - start + 1;

    final samplesPerBucket = (sampleCount / bucketCount).floor();
    if (samplesPerBucket == 0) {
      return const [];
    }

    final actualSampleCount = sampleCount - (sampleCount % samplesPerBucket);
    List<int> histogram = new List<int>.filled(bucketCount, 0);

    // Add up the frequency amounts for each bucket.
    for (int i = start; i <= start + actualSampleCount; ++i) {
      // Ignore the imaginary half of each FFT sample
      if ((i - start) % 2 == 1) {
        continue;
      }

      int bucketIndex = ((i - start) / samplesPerBucket).floor();
      histogram[bucketIndex] += samples[i];
    }

    // Massage the data for visualization
    for (var i = 0; i < histogram.length; ++i) {
      histogram[i] = (histogram[i] / samplesPerBucket).abs().round();
    }

    return histogram;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}

class AudioSeekRadioBar extends StatefulWidget {
  final String albumArtUrl;
  AudioSeekRadioBar({
    this.albumArtUrl,
  });
  @override
  AudioSeekRadioBarState createState() {
    return new AudioSeekRadioBarState();
  }
}

class AudioSeekRadioBarState extends State<AudioSeekRadioBar> {
  double _seekPercent;
  @override
  Widget build(BuildContext context) {
    return new AudioComponent(
      updateMe: [
        WatchableAudioProperties.audioPlayhead,
        WatchableAudioProperties.audioSeeking,
      ],
      playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
        double playbackProgress = 0.0;
        if (player.audioLength != null && player.position != null) {
          playbackProgress = player.position.inMilliseconds /
              player.audioLength.inMilliseconds;
        }
        _seekPercent = player.isSeeking ? _seekPercent : null;
        return new SeekBar(
            progress: playbackProgress,
            seekPercent: _seekPercent,
            onSeekRequested: (double seekPercent) {
              setState(() => _seekPercent = seekPercent);
              final seekMillis =
                  (player.audioLength.inMilliseconds * seekPercent).round();
              player.seek(new Duration(milliseconds: seekMillis));
            },
            child: new Container(
              color: accentColor,
              child: Image.network(
                widget.albumArtUrl,
                fit: BoxFit.cover,
              ),
            ));
      },
    );
  }
}

class SeekBar extends StatefulWidget {
  final double progress;
  final double seekPercent;
  final Function(double) onSeekRequested;
  final Widget child;
  SeekBar({
    this.seekPercent = 0.0,
    this.progress = 0.0,
    this.onSeekRequested,
    this.child,
  });

  @override
  SeekBarState createState() {
    return new SeekBarState();
  }
}

class SeekBarState extends State<SeekBar> {
  double _progress = 0.0;
  PolarCoord _startDragCoords;
  double _startDragPercent;
  double _currentDragPercent;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
  }

  @override
  void didUpdateWidget(SeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _progress = widget.progress;
  }

  void _onDragStart(PolarCoord coord) {
    _startDragCoords = coord;
    _startDragPercent = _progress;
  }

  void _onDragUpdate(PolarCoord coord) {
    final dragAngle = coord.angle - _startDragCoords.angle;
    final dragPercent = dragAngle / (2 * pi);
    setState(
        () => _currentDragPercent = (_startDragPercent + dragPercent) % 1.0);
  }

  void _onDragEnd() {
    if (widget.onSeekRequested != null) {
      widget.onSeekRequested(_currentDragPercent);
    }
    setState(() {
      _currentDragPercent = null;
      _startDragCoords = null;
      _startDragPercent = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double thumbPosition = _progress;
    if (_currentDragPercent != null) {
      thumbPosition = _currentDragPercent;
    } else if (widget.seekPercent != null) {
      thumbPosition = widget.seekPercent;
    }

    return new RadialDragGestureDetector(
      onRadialDragStart: _onDragStart,
      onRadialDragUpdate: _onDragUpdate,
      onRadialDragEnd: _onDragEnd,
      child: new Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: new Center(
          child: new Container(
            width: 200.0,
            height: 200.0,
            child: new RadialSeekBar(
              progressColor: accentColor,
              thumbColor: accentColor,
              progressPercent: _progress,
              thumbPosition: thumbPosition,
              trackColor: Color(0xFFDDDDDD),
              innerPadding: new EdgeInsets.all(8.0),
              trackWidth: 2.0,
              child: new ClipOval(
                clipper: new CircleClipper(),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomController extends StatelessWidget {
  const BottomController({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container(
      width: double.infinity,
      child: new Material(
        color: accentColor,
        shadowColor: const Color(0x44000000),
        child: Padding(
          padding: const EdgeInsets.only(top: 48.0, bottom: 50.0),
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new AudioPlaylistComponent(
                playlistBuilder:
                    (BuildContext context, Playlist playlist, Widget child) {
                  final songTitle =
                      demoPlaylist.songs[playlist.activeIndex].songTitle;
                  final artistTitle =
                      demoPlaylist.songs[playlist.activeIndex].artist;
                  return new RichText(
                    textAlign: TextAlign.center,
                    text: new TextSpan(text: '', children: [
                      new TextSpan(
                          text: songTitle.toUpperCase() + '\n',
                          style: new TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                            height: 1.5,
                          )),
                      new TextSpan(
                          text: artistTitle.toUpperCase() + '\n',
                          style: new TextStyle(
                            color: Colors.white.withOpacity(0.78),
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3.0,
                            height: 1.5,
                          )),
                    ]),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new PrevButton(),
                    new PlayPauseButton(),
                    new NextButton(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new AudioComponent(
      updateMe: [
        WatchableAudioProperties.audioPlayerState,
      ],
      playerBuilder: (BuildContext context, AudioPlayer player, Widget child) {
        IconData icon = Icons.music_note;
        Color buttonColor = lightaccentColor;
        Function onPressed;
        if (player.state == AudioPlayerState.playing) {
          icon = Icons.pause;
          onPressed = player.pause;
          buttonColor = Colors.white;
        } else if (player.state == AudioPlayerState.paused ||
            player.state == AudioPlayerState.completed) {
          icon = Icons.play_arrow;
          onPressed = player.play;
          buttonColor = Colors.white;
        }
        return new RawMaterialButton(
          shape: new CircleBorder(),
          fillColor: buttonColor,
          splashColor: darkaccentColor,
          highlightColor: darkaccentColor.withOpacity(0.5),
          elevation: 10.0,
          highlightElevation: 5.0,
          onPressed: onPressed,
          child: new Padding(
            padding: const EdgeInsets.only(
                top: 20.0, bottom: 20.0, left: 40.0, right: 40.0),
            child: new Icon(
              icon,
              color: accentColor,
            ),
          ),
        );
      },
    );
  }
}

class PrevButton extends StatelessWidget {
  const PrevButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new AudioPlaylistComponent(playlistBuilder:
        (BuildContext context, Playlist playlist, Widget child) {
      return new IconButton(
        splashColor: lightaccentColor,
        highlightColor: Colors.transparent,
        padding: new EdgeInsets.only(right: 20.0, left: 20.0),
        icon: new Icon(
          Icons.skip_previous,
          color: Colors.white,
          size: 25.0,
        ),
        onPressed: playlist.previous,
      );
    });
  }
}

class NextButton extends StatelessWidget {
  const NextButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new AudioPlaylistComponent(playlistBuilder:
        (BuildContext context, Playlist playlist, Widget child) {
      return new IconButton(
        splashColor: lightaccentColor,
        highlightColor: Colors.transparent,
        padding: new EdgeInsets.only(left: 20.0, right: 20.0),
        icon: new Icon(
          Icons.skip_next,
          color: Colors.white,
          size: 25.0,
        ),
        onPressed: playlist.next,
      );
    });
  }
}

class CircleClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return new Rect.fromCircle(
        center: new Offset(size.width / 2, size.height / 2),
        radius: min(size.width, size.height) / 2);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}

class RadialSeekBar extends StatefulWidget {
  final double trackWidth;
  final Color trackColor;
  final double progressWidth;
  final Color progressColor;
  final double progressPercent;
  final double thumbPosition;
  final double thumbSize;
  final Color thumbColor;
  final Widget child;
  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;
  RadialSeekBar(
      {this.trackWidth = 3.0,
      this.trackColor = Colors.grey,
      this.progressWidth = 5.0,
      this.progressColor = accentColor,
      this.thumbSize = 15.0,
      this.progressPercent = 0.0,
      this.thumbPosition = 0.0,
      this.thumbColor = accentColor,
      this.child,
      this.innerPadding = const EdgeInsets.all(0.0),
      this.outerPadding = const EdgeInsets.all(0.0)});
  @override
  _RadialSeekBarState createState() => new _RadialSeekBarState();
}

class _RadialSeekBarState extends State<RadialSeekBar> {
  EdgeInsets _InsetsforPainter() {
    final outerThickness =
        max(widget.trackWidth, max(widget.progressWidth, widget.thumbSize)) / 2;
    return new EdgeInsets.all(outerThickness);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: widget.outerPadding,
      child: new CustomPaint(
        foregroundPainter: new RadialSeekPainter(
            trackWidth: widget.trackWidth,
            trackColor: widget.trackColor,
            progressColor: widget.progressColor,
            progressPercent: widget.progressPercent,
            thumbColor: widget.thumbColor,
            thumbPosition: widget.thumbPosition,
            thumbSize: widget.thumbSize,
            progressWidth: widget.progressWidth),
        child: new Padding(
          padding: _InsetsforPainter() + widget.innerPadding,
          child: widget.child,
        ),
      ),
    );
  }
}

class RadialSeekPainter extends CustomPainter {
  final double trackWidth;
  final Color trackColor;
  final double progressWidth;
  final Color progressColor;
  final double progressPercent;
  final double thumbPosition;
  final double thumbSize;
  final Color thumbColor;
  final Paint trackPaint;
  final Paint progressPaint;
  final Paint thumbPaint;

  RadialSeekPainter({
    @required this.trackWidth,
    @required trackColor,
    @required this.progressWidth,
    @required progressColor,
    @required this.thumbSize,
    @required this.progressPercent,
    @required this.thumbPosition,
    @required thumbColor,
  })  : trackPaint = new Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackWidth,
        progressPaint = new Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = progressWidth
          ..strokeCap = StrokeCap.round,
        thumbPaint = new Paint()
          ..color = thumbColor
          ..style = PaintingStyle.fill;
  @override
  void paint(Canvas canvas, Size size) {
    final outerThickness = max(trackWidth, max(progressWidth, thumbSize));
    Size constrainedSize = new Size(
      size.width - outerThickness,
      size.height - outerThickness,
    );
    final center = new Offset(size.width / 2, size.height / 2);
    final radius = min(constrainedSize.width, constrainedSize.height) / 2;
    //track
    canvas.drawCircle(center, radius, trackPaint);
    //progress
    final progressAngle = 2 * pi * progressPercent;
    canvas.drawArc(new Rect.fromCircle(center: center, radius: radius), -pi / 2,
        progressAngle, false, progressPaint);

    //thumb
    final thumbAngle = 2 * pi * thumbPosition - (pi / 2);
    final thumbX = cos(thumbAngle) * radius;
    final thumbY = sin(thumbAngle) * radius;
    final thumbCenter = new Offset(thumbX, thumbY) + center;
    final thumbRadius = thumbSize / 2;
    canvas.drawCircle(thumbCenter, thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}
