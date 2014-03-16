library LDRAW_LOADER;

import 'dart:html';

import 'ldraw.dart';
import 'viewer.dart';

class LDrawLoader{
  static Map<String,LDrawFileContent> cache = new Map<String,LDrawFileContent>();
  
  int files_loaded = 0;
  int files_failed = 0;
  int files_needed = 0;
  int total_file_size = 0;
  
  LDrawFile file;
  LDrawWidget viewer;
  
  LDrawLoader( String filename, [this.viewer=null] ){
    file = new LDrawFile( filename );
    load_file( file, true );
  }
  
  void load_file( LDrawFile load, [bool local=false] ){
    String filename = load.name;
    if( cache.containsKey( filename ) )
      load.content = cache[filename];
    else{
      load.content = new LDrawFileContent();
      cache[filename] = load.content;
      files_needed++;

      List<String> names = [ "ldraw/parts/" + filename, "ldraw/p/" + filename, "ldraw/models/" + filename ];
      if( local )
        names.insert( 0, filename );
      load_ldraw_list( names, filename );
    }
  }

  void load_ldraw_list( List<String> names, String name ){
    String try_load = names.removeAt(0);
    HttpRequest.getString( try_load )
    .then( (content){
      cache[name].init( content, this );
      total_file_size += content.length;
      files_loaded++;
      update_progress();
    } )
    .catchError( (onError){
      if( names.length > 0 )
        load_ldraw_list( names, name );
      else{
        print( "Could not retrive file: " + name + " :\\" );
        files_failed++;
        update_progress();
      }
    } );
  }
  
  void update_progress(){
    if( files_loaded + files_failed >= files_needed && viewer != null )
      viewer.show( file );
    //TODO: show progress
  }
}