import 'dart:html';

import 'ldraw.dart';
import 'webgl.dart';

void main() {
  load_file();
  
  Canvas canvas = new Canvas( "#canvas" );
}

void load_file() {
  HttpRequest.getString('6speed.ldr')
  .then(process_ldraw);
}

void process_ldraw(String content){
  LDrawFile file = new LDrawFile();
  file.content = new LDrawFileContent();
  //file.content.init(content);
  //Timer timer = new Timer( const Duration(seconds:5), () => file.debug(0));
}



