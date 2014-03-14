import 'dart:html';
import 'dart:async';

import 'ldraw.dart';
import 'webgl.dart';

class LDrawWidget{
  Canvas canvas;
  
  LDrawWidget( Element div ){
    canvas = new Canvas( div.querySelector("canvas") );
    String filename = div.dataset["file"];
    print( filename );
    HttpRequest.getString( filename )
      .then(load);
  }
  
  void load(String content){
    LDrawFile file = new LDrawFile();
    file.content = new LDrawFileContent();
    file.content.init(content);
    Timer timer = new Timer( const Duration(seconds:5), (){ canvas.load_ldraw(file); });
  }
}

void main() {
  List<LDrawWidget> list = new List<LDrawWidget>();
  querySelectorAll(".webldraw").forEach( (div){
    print( "test" );
    list.add( new LDrawWidget( div ) );
  });
}

