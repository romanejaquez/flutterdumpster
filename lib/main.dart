import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayer/audioplayer.dart';

void main() => runApp(MaterialApp(home: SplashPage(), debugShowCheckedModeBanner: false));

class Utils {
  static const Color mainColor = Color.fromRGBO(0, 106, 156, 1.0);
  static const Color accentBlue = Color.fromRGBO(63, 179, 237, 1.0);
  static const Color darkGray = Colors.black87;

  static List<Genre> genres;
}

class SplashPage extends StatelessWidget {

  Future<List<Genre>> getInfo() async{

    var genres = List<Genre>();
    var url = "http://streaming.drcoderz.com/files.php";

    var response = await http.get(url);
    List responseJSON = jsonDecode(response.body.toString());
    genres = createGenreList(responseJSON);

    return genres;
  }

  List<Genre> createGenreList(List data) {
    var jsonGenres = List<Genre>();

    for(var i = 0; i < data.length; i++) {
      var jsonGenre = data[i];
      var jsonSongs = jsonGenre["Songs"];

      var songModels = List<Song>();
      for(var s = 0; s < jsonSongs.length; s++) {
        var singleSong = jsonSongs[s];
        songModels.add(
          Song(
            id: singleSong["Id"],
            name: singleSong["Name"],
            path: singleSong["Path"],
            duration: singleSong["Duration"],
            index: s
          )
        );
      }

      jsonGenres.add(
        Genre(genreName: jsonGenre["FolderName"],
        songs: songModels)
      );
    }

    return jsonGenres;
  }

  Future<List<Genre>> getInfoFromFile() async {
    var file = await rootBundle.loadString('assets/json.json');
    List responseJSON = jsonDecode(file.toString());
    var genres = createGenreList(responseJSON);

    Utils.genres = genres;
    return genres;
  }

  
  @override
  Widget build(BuildContext context) {

    Timer.run(() {
      new Timer(new Duration(days: 0, hours: 0, minutes: 0, seconds: 2, microseconds: 0, milliseconds: 0), () {
        
        getInfoFromFile().then((items) => 
          Navigator.push(context, 
          MaterialPageRoute(
            builder: (context) => HomePage()))
        );

      });
    });

    return new Scaffold(
      backgroundColor: Utils.mainColor,
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/dumpster_icon_logo2_white.png', width: 200.0, height: 150.0, fit: BoxFit.contain),
            Padding(padding: EdgeInsets.only(top: 40.0),
            child: new CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color.fromARGB(255, 255, 255, 255)),
                strokeWidth: 5.0
                ),)
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

enum PlayerState {
  playing,
  paused,
  stopped
}

class HomePageState extends State<HomePage> {
  Genre selectedGenre;
  Song selectedSong;
  AudioPlayer player;
  PlayerState playerState;
  Color selectedColor = Colors.transparent;

  HomePageState() {
    player = new AudioPlayer();
    playerState = PlayerState.paused;
    selectedGenre = Utils.genres[0];
    selectedSong = selectedGenre.songs[0];
  }

  Future<void> togglePlay() async {

    if (playerState == PlayerState.playing) {
      await player.pause();
      setState(() {
         playerState = PlayerState.paused;     
      });
    }
    else {
      await player.play(selectedSong.path.replaceAll(' ', '%20'));
      setState(() {
        playerState = PlayerState.playing;
      });
    }
  }

  List<Widget> getAllSongRows() {

    var allSongWidgets = List<Widget>();

    for(var i = 0; i < selectedGenre.songs.length; i++) {
      var song = selectedGenre.songs[i];

      allSongWidgets.add(
        InkWell(
            onTap: () {
              selectedGenre.songs.forEach((s) => s.isSelected = false);
              selectedSong = song;
              selectedSong.isSelected = true;
              togglePlay();
            },
            child: Container(
            color: (song == selectedSong && selectedSong.isSelected ? Utils.accentBlue.withOpacity(0.1) : Colors.transparent),
            padding: EdgeInsets.only(left: 25, top: 20, right: 25, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Text(song.index.toString(), style: TextStyle(color: Utils.accentBlue)),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Utils.accentBlue)
                    ),
                  ),
                  Container(
                    width: 200,
                    child: Text(song.name,
                      softWrap: true,
                      style: TextStyle(color: Colors.white)),
                    ),
                  Text(song.duration.toString(), style: TextStyle(color: Colors.white)),
                  Icon(Icons.file_download, color: Utils.accentBlue)
                ],
              ),
            )
          )  
      );
    }

    return allSongWidgets;
  }

  List<Widget> getGenreMenu() {

    var list = List<Widget>();

    for(var i = 0; i < 10; i++) {
      var genre = Utils.genres[i];

      list.add(
        InkWell(
        onTap: () {},
        child: 
          Padding(
            padding: EdgeInsets.only(top: 5, bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.library_music, color: Colors.white),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(genre.genreName, 
                        style: TextStyle(
                          color: Colors.white
                        )
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Utils.accentBlue)
                  ),
                  child: Text(genre.songs.length.toString(),
                    style: TextStyle(
                      color: Utils.accentBlue
                    )
                  ),
                )
              ],
            ),
          ))
      );
    }

    return list;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          padding: EdgeInsets.all(30),
          color: Utils.darkGray,
          child: Column(
              children: <Widget>[
                Padding(padding: EdgeInsets.only(top: 20, bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Genres", 
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white
                    )),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Utils.accentBlue)
                      ),
                      child: Text('${Utils.genres.length}',
                        style: TextStyle(
                          color: Utils.accentBlue
                        )
                      ),
                    )
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(children: getGenreMenu()),
              )
              ],  //
            ),
          )
      ),
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Utils.mainColor,
        title: Padding(
          padding: EdgeInsets.only(left: 0),
          child: Image.asset('assets/dumpster_icon_justtext.png',
          width: 100.0),),
      ),
      body: Container(
        color: Utils.mainColor,
        child: ClipRRect(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(20.0)),
          child: Container(
            color: Colors.black,
            child: Stack(
              children: <Widget>[
                Align(alignment: Alignment.topCenter,
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                        Icon(Icons.library_music, color: Colors.white),
                        Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: Text(
                          selectedGenre.genreName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0)
                            ),
                        ),
                        Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: Text(
                          '${selectedGenre.songs.length.toString()} songs',
                          style: TextStyle(
                            color: Utils.accentBlue,
                            fontSize: 15)
                            ),
                        )
                      ],
                    )
                  )
                ),
                Positioned(
                  top: 60,
                  left: 0, right: 0,
                  bottom: 130,
                  child: ListView(
                    children: getAllSongRows(),
                  ),
                ),
                Positioned(
                  left: 0, right: 0,
                  bottom: 93,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    color: Colors.white.withOpacity(0.1),
                    child: Text(selectedSong.name,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white)),
                  )),
                Positioned(
                  bottom: 0,
                  left: 0, right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            GestureDetector(
                              onTap: () { 
                                togglePlay(); 
                              },
                              child: Container(
                                width: 44, height: 44,
                                child: Icon(
                                  (playerState == PlayerState.paused 
                                    ? Icons.play_circle_outline : Icons.pause_circle_outline),
                                  color: Colors.white,
                                  size: 44),
                              ),
                            ),
                            Container(
                              child: Icon(Icons.forward_10, color: Colors.white, size: 44),
                            ),
                            Slider(
                              onChanged: (double value) {
                                return value;
                              },
                              min: 0,
                              max: 100,
                              value: 50.0,
                              activeColor: Utils.accentBlue,
                              inactiveColor: Colors.white.withOpacity(0.1),
                            ),
                            Container(
                              child: Icon(Icons.repeat, color: Colors.white, size: 44),
                            ),
                            /*Container(
                              child: Icon(Icons.shuffle, color: Colors.white, size: 44),
                            ),*/
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ));
  }
}

class Genre {
  String genreName;
  List<Song> songs;

  Genre({this.genreName, this.songs});
}

class Song {
  String name;
  String duration;
  String id;
  int index;
  String path;
  bool isSelected = false;

  Song({this.name, this.duration, this.id, this.index, this.path});
}

