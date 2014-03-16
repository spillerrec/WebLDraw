import 'dart:html';

import 'package:WebLDraw/ldrawlib.dart';

void main() {
  HttpRequest.getString( 'ldraw/LDConfig.ldr' ).then( (content){
    LDrawFileContent color_file = new LDrawFileContent();
    color_file.init( content, null );
    
    color_file.color_index.colors.forEach( (int code, LDrawColor color){
      print( "$code: new LDrawColor( ${color.r}, ${color.g}, ${color.b}, ${color.er}, ${color.eg}, ${color.eb}, ${color.alpha} )," );
    } );
  } );
}