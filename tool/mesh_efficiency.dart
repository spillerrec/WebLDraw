import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:webldraw/ldrawlib.dart';

class LDrawFileLib extends LDrawLib{
  Future<String> load( String url ) => new File( url ).readAsString();
}

class Debug extends Progress{
  
  @override
  void updated() {
    if( current == total ){
      MeshModel model = new MeshModel();
      

    Stopwatch watch = new Stopwatch();
    watch.start();
      loader.file.to_mesh( model, new LDrawContext() );
    print( "to_mesh took: ${watch.elapsed}" );
    watch.reset();
      new Float32List( 3244032*10 );
    print( "create took: ${watch.elapsed}" );

      int amount = 0, amount_real = 0;
      
      print( "lines:" );
      model.lines.values.forEach( (f){
        print( f.vertices.length );
        amount += f.vertices.length;
        amount_real += f.vertices.list.length;
      });
      print( "\ntriangles:" );
      model.triangles.values.forEach( (f){
        print( "${f.vertices.length} \t\t\t ${f.vertices.list.length}" );
        amount += f.vertices.length;
        amount_real += f.vertices.list.length;
      });
      
      print( "Needed memory: ${ amount * 4 / 1024 / 1024 } MiB" );
      print( "Used memory: ${ amount_real * 4 / 1024 / 1024 } MiB" );
      print( "unused size: ${unused.length}" );
      unused.forEach((f){
        print( f.length );
      });
    }
  }
}
LDrawLoader loader;
void main(){
  loader = new LDrawLoader( new LDrawFileLib(), "Keywriter.mpd", new Debug() );
}