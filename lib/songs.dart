import 'package:meta/meta.dart';

final demoPlaylist = new DemoPlaylist(
  songs: [
    new DemoSong(
      audioUrl: 'http://seifer231.free.fr/03%20musique/03%20autres/Linkin%20Park%20-%20Meteora%20-%2009%20-%20Breaking%20The%20Habit%20-%20Abyss.mp3',
      albumArtUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/6/64/MeteoraLP.jpg/220px-MeteoraLP.jpg',
      songTitle: 'Breaking The Habit',
      artist: 'Linkin Park',
    ),
    new DemoSong(
      audioUrl: 'http://tegos.kz/new/mp3_full/Linkin_Park_-_Castle_Of_Glass.mp3',
      albumArtUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/c/c9/Linkin_Park_-_Living_Things.jpg/220px-Linkin_Park_-_Living_Things.jpg',
      songTitle: 'Castle of Glass',
      artist: 'Linkin Park',
    ),
    new DemoSong(
      audioUrl: 'http://fabricegalinier.free.fr/DOSSIERS/MUSICA/02%20-%20Clocks%20Coldplay%20A%20Rush%20Of%20Blood%20To%20The%20Head.mp3',
      albumArtUrl: 'http://www.coldplay.com/recordings/art_arushofbloodtothehead.jpg',
      songTitle: 'Clocks',
      artist: 'Coldplay',
    ),
    new DemoSong(
      audioUrl: 'https://api.soundcloud.com/tracks/260578593/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P',
      albumArtUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/5/53/Maroon_5_-_V_%28Official_Album_Cover%29.png/220px-Maroon_5_-_V_%28Official_Album_Cover%29.png',
      songTitle: 'Maps',
      artist: 'Maroon 5',
    ),
    new DemoSong(
      audioUrl: 'http://tegos.kz/new/mp3_full/Ed_Sheeran_-_Thinking_Out_Loud.mp3',
      albumArtUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/a/ad/X_cover.png/220px-X_cover.png',
      songTitle: 'Thinking Out Loud',
      artist: 'Ed Sheeran',
    ),
    new DemoSong(
      audioUrl: 'https://talkmuziktv.co/wp-content/uploads/2017/08/Marshmello_ft_Khalid_-_Silence_Talkmuzik.mp3',
      albumArtUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/c/c4/Marshmello_Silence.jpg/220px-Marshmello_Silence.jpg',
      songTitle: 'Silence',
      artist: 'Marshmello Ft. Khalid',
    ),
  ],
);

class DemoPlaylist {

  final List<DemoSong> songs;

  DemoPlaylist({
    @required this.songs,
  });

}

class DemoSong {

  final String audioUrl;
  final String albumArtUrl;
  final String songTitle;
  final String artist;

  DemoSong({
    @required this.audioUrl,
    @required this.albumArtUrl,
    @required this.songTitle,
    @required this.artist,
  });

}