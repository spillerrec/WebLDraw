import 'dart:html';

import 'ldraw.dart';
import 'webgl.dart';
import 'LDrawLoader.dart';

class LDrawWidget{
  Canvas canvas;
  bool active = false;
  
  LDrawWidget( Element div ){
    canvas = new Canvas( div.querySelector("canvas") );
    String filename = div.dataset["file"];
    LDrawLoader loader = new LDrawLoader( filename, this );

    canvas.canvas.onMouseEnter.listen( (t){ active=true; } );
    canvas.canvas.onMouseLeave.listen( (t){ active=false; } );
    window.onKeyPress.listen( (KeyboardEvent key ){
      if( active && key.keyCode == 102 )
        canvas.canvas.requestFullscreen();
    } );
  }
  
  void show( LDrawFile file ){
    canvas.load_ldraw( file );
  }
}

void main() {
  querySelectorAll(".webldraw").forEach( (div){
    new LDrawWidget( div );
  });
}

