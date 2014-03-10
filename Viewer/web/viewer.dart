import 'dart:collection';
import 'dart:html';
import 'dart:async';

void main() {
  load_file();
}

void load_file() {
  HttpRequest.getString('6speed.ldr')
  .then(process_ldraw);
}

void process_ldraw(String content){
  querySelector("#sample_text_id").text = content;
  LDrawFile file = new LDrawFile();
  file.init(content);
}

class LDrawFile extends LDrawPrimitive{
  int color = 16;
  double x = 0.0, y = 0.0, z = 0.0;
  double a = 0.0, b = 0.0, c = 0.0;
  double d = 0.0, e = 0.0, f = 0.0;
  double g = 0.0, h = 0.0, i = 0.0;
  List<LDrawPrimitive> primitives = new List<LDrawPrimitive>();
  
  void init(String content){
    try{
    List<String> lines = content.split("\n");
    lines.forEach((line){
      List<String> parts = line.trim().split(" ");
      
      if( parts.length > 0 )
         switch( parts.removeAt(0) ){
           case '0': parse_comment(parts); break;
           case '1': parse_subfile(parts); break;
           case '2': parse_line(parts); break;
           case '3': parse_triangle(parts); break;
           case '4': parse_quad(parts); break;
           case '5': parse_optional(parts); break;
         }
    });
    }
    catch(object){
      print(object);
    }
  }
  
  void parse_comment(List<String> parts){
    if( parts.length > 0 )
      switch( parts[0] ){
        case "STEP": print("step"); break;
        case "ROTATION": print("rotation"); break;
        //default: print("comment");
      }
  }
  
  void parse_subfile(List<String> parts){
    assert(parts.length >= 14);
    LDrawFile sub = new LDrawFile();
    sub.color = int.parse( parts[0] );
    sub.x = double.parse( parts[1] );
    sub.y = double.parse( parts[2] );
    sub.z = double.parse( parts[3] );
    sub.a = double.parse( parts[4] );
    sub.b = double.parse( parts[5] );
    sub.c = double.parse( parts[6] );
    sub.d = double.parse( parts[7] );
    sub.e = double.parse( parts[8] );
    sub.f = double.parse( parts[9] );
    sub.g = double.parse( parts[10] );
    sub.h = double.parse( parts[11] );
    sub.i = double.parse( parts[12] );
    
    String filepath = parts.sublist(13).join(" ").trim();
    //print(filepath);
    load_ldraw( sub, filepath );
    primitives.add(sub);
  }
  void parse_line(List<String> parts){
    
  }
  void parse_triangle(List<String> parts){
    
  }
  void parse_quad(List<String> parts){
    
  }
  void parse_optional(List<String> parts){
    
  }
}

class LDrawPrimitive{
  
}

void load_ldraw( LDrawFile file, String name ){
  if( cache[name] != null ){
    file = cache[name];
    return;
  }
  
  List<String> names = new List<String>();
  cache[name] = file;
  //names.add( name );
  names.add( "ldraw/parts/" + name );
  names.add( "ldraw/p/" + name );
  //names.add( "ldraw/models/" + name );
  load_ldraw_list( file, names, name );
}

Map<String,LDrawFile> cache = new HashMap<String,LDrawFile>();

void load_ldraw_list( LDrawFile file, List<String> names, String name ){
  String try_load = names.removeAt(0);
  HttpRequest.getString( try_load )
  .then((content){
    file.init(content);
  })
  .catchError((onError){
    if( names.length > 0 )
      load_ldraw_list( file, names, name );
    else
      print( "Could not retrive file: " + name + " :\\" );
  });
}

