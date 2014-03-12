import 'dart:html';
import 'dart:async';

import 'ldraw.dart';
import 'webgl.dart';

void main() {
  load_file();
  canvas = new Canvas( "#canvas" );
}
Canvas canvas;

void load_file() {
//  HttpRequest.getString('6speed.ldr')
//  HttpRequest.getString('pin.ldr')
  HttpRequest.getString('colors.ldr')
//  HttpRequest.getString('ldraw/p/axle.dat') //Fails to load!
//  HttpRequest.getString('ldraw/p/peghole2.dat')
  .then(process_ldraw);
}

void process_ldraw(String content){
  LDrawFile file = new LDrawFile();
  file.content = new LDrawFileContent();
  file.content.init(content);
  Timer timer = new Timer( const Duration(seconds:1), () => canvas.file = file);
}



