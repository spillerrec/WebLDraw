part of ldraw;

abstract class LDrawLib{
  String base_dir = "/assets/webldraw/ldraw/";
  Future<String> load( String url );
}

abstract class Progress{
  int current = 0;
  int total = 0;
  int failed = 0;
  void updated();
}

class LDrawLoader{
  static Map<String,LDrawFileContent> cache = new Map<String,LDrawFileContent>();
  
  int total_file_size = 0;
  
  LDrawLib lib;
  LDrawFile file;
  Progress progress;
  
  LDrawLoader( this.lib, String filename, [this.progress=null] ){
    file = new LDrawFile( filename );
    load_file( file, true );
  }
  
  bool containsFolder( String path, String folder ){
    return path.startsWith( folder + "/" );
  }
  
  List<String> standardLibraries( String filename ){
    //Parts last if more than 2 letters ( +3 for ".dat" )
    int letter_count = 0;
    for( int i=0; i<filename.length; i++ )
      if( filename[i].toUpperCase() != filename[i].toLowerCase() )
        letter_count++;
    bool p_first = letter_count > 5;
    
    //Use subfolders as a more precise estimation, if available
    if( containsFolder( filename, 's' ) )
      p_first = false;
    else if( containsFolder( filename, '48' ) || containsFolder( filename, '8' ) )
      p_first = true;
    
    List<String> paths = [
        "assets/webldraw/ldraw/parts/" + filename
      , "assets/webldraw/ldraw/p/" + filename
      , "assets/webldraw/ldraw/models/" + filename
      ];
    
    //Swap 'p/' and 'parts/'
    if( p_first )
      paths.insert( 0, paths.removeAt(1) );
    
    return paths;
  }
  
  void load_file( LDrawFile load, [bool local=false] ){
    String filename = load.name;
    filename = filename.replaceAll( '\\', '/' );
    
    if( cache.containsKey( filename ) )
      load.content = cache[filename];
    else{
      load.content = new LDrawFileContent();
      cache[filename] = load.content;
      progress.total++;

      List<String> names = standardLibraries( filename.toLowerCase() );
      if( local )
        names.insert( 0, filename );
      
      load_ldraw_list( names, filename );
    }
  }

  void load_ldraw_list( List<String> names, String name ){
    String try_load = names.removeAt(0);
    lib.load( try_load )
    .then( (content){
      cache[name].init( content, this );
      total_file_size += content.length;
      progress.current++;
      progress.updated();
    } )
    .catchError( (onError){
      if( names.length > 0 )
        load_ldraw_list( names, name );
      else{
        print( "Could not retrive file: " + name + " :\\" );
        progress.failed++;
        progress.updated();
      }
    } );
  }
}