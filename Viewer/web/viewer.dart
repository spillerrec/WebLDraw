import 'dart:html';

import 'ldraw.dart';
import 'webgl.dart';
import 'LDrawLoader.dart';

class LDrawWidget{
  Canvas canvas;
  
  LDrawWidget( Element div ){
    canvas = new Canvas( div.querySelector("canvas") );
    String filename = div.dataset["file"];
    LDrawLoader loader = new LDrawLoader( filename, this );
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

