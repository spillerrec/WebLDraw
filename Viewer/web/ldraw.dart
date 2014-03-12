library LDRAW;

import 'dart:collection';
import 'dart:html';

import 'package:vector_math/vector_math.dart';

import 'webgl.dart';

class LDrawContext{
  Matrix4 offset;
  double r, g, b; //Main color
  double er, eg, eb; //Secondary color
  
  LDrawContext( Matrix4 offset, double r, double g, double b ){
    this.offset = offset.clone();
    this.r = r;
    this.g = g;
    this.b = b;
    er = 0x33/255;
    eb = 0x33/255;
    eg = 0x33/255;
    //TODO: does Dart have some smart syntax for this?
  }
  
  LDrawContext update_color( int code ){
    LDrawContext sub = new LDrawContext( offset, r,g,b );
    switch( code ){
      case 16: break; //Do nothing, use main color
      case 24: break; //TODO: !
      case 4: sub.r=0xC9/255; sub.g=0x1A/255; sub.b=0x09/255; break; 
      case 0: sub.r=0x00/255; sub.g=0x00/255; sub.b=0x00/255; break; 
      case 7: sub.r=0x9B/255; sub.g=0xA1/255; sub.b=0x9D/255; break; 
    }
    return sub;
  }
}

class LDrawFileContent extends LDrawPrimitive{
  List<LDrawPrimitive> primitives = new List<LDrawPrimitive>();

  void draw( Canvas canvas, LDrawContext context ){
    primitives.forEach( (x) => x.draw( canvas, context ) );
  }
  void init(String content){
    try{
    List<String> lines = content.split("\n");
    lines.removeWhere((test)=>test.isEmpty);
    lines.forEach((line){
      List<String> parts = line.trim().split(" ");
      parts.removeWhere((test)=>test.isEmpty); //Note: could mess up file names if they contain spaces 
      
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
    load_ldraw( sub, filepath );
    primitives.add(sub);
  }
  void parse_line(List<String> parts){
    assert(parts.length >= 7);
    LDrawLine line = new LDrawLine();
    line.color = int.parse( parts[0] );
    line.x1 = double.parse( parts[1] );
    line.y1 = double.parse( parts[2] );
    line.z1 = double.parse( parts[3] );
    line.x2 = double.parse( parts[4] );
    line.y2 = double.parse( parts[5] );
    line.z2 = double.parse( parts[6] );
    primitives.add(line);
  }
  void parse_triangle(List<String> parts){
    assert(parts.length >= 10);
    LDrawTriangle tri = new LDrawTriangle();
    tri.color = int.parse( parts[0] );
    tri.x1 = double.parse( parts[1] );
    tri.y1 = double.parse( parts[2] );
    tri.z1 = double.parse( parts[3] );
    tri.x2 = double.parse( parts[4] );
    tri.y2 = double.parse( parts[5] );
    tri.z2 = double.parse( parts[6] );
    tri.x3 = double.parse( parts[7] );
    tri.y3 = double.parse( parts[8] );
    tri.z3 = double.parse( parts[9] );
    primitives.add(tri);
  }
  void parse_quad(List<String> parts){
    assert(parts.length >= 13);
    LDrawQuad quad = new LDrawQuad();
    quad.color = int.parse( parts[0] );
    quad.x1 = double.parse( parts[1] );
    quad.y1 = double.parse( parts[2] );
    quad.z1 = double.parse( parts[3] );
    quad.x2 = double.parse( parts[4] );
    quad.y2 = double.parse( parts[5] );
    quad.z2 = double.parse( parts[6] );
    quad.x3 = double.parse( parts[7] );
    quad.y3 = double.parse( parts[8] );
    quad.z3 = double.parse( parts[9] );
    quad.x4 = double.parse( parts[10] );
    quad.y4 = double.parse( parts[11] );
    quad.z4 = double.parse( parts[12] );
    primitives.add(quad);
  }
  void parse_optional(List<String> parts){
    assert(parts.length >= 13);
    LDrawOptional opt = new LDrawOptional();
    opt.color = int.parse( parts[0] );
    opt.x1 = double.parse( parts[1] );
    opt.y1 = double.parse( parts[2] );
    opt.z1 = double.parse( parts[3] );
    opt.x2 = double.parse( parts[4] );
    opt.y2 = double.parse( parts[5] );
    opt.z2 = double.parse( parts[6] );
    opt.x3 = double.parse( parts[7] );
    opt.y3 = double.parse( parts[8] );
    opt.z3 = double.parse( parts[9] );
    opt.x4 = double.parse( parts[10] );
    opt.y4 = double.parse( parts[11] );
    opt.z4 = double.parse( parts[12] );
    primitives.add(opt);
  }

  void debug(int indent){
    String spaces = "";
    for(int i=0; i<indent; i++)
      spaces += "  ";
    print( spaces + "Content" );
    primitives.forEach((f){
      f.debug(indent+1);
    });
  }
}

class LDrawFile extends LDrawPrimitive{
  int color = 16;
  double x = 0.0, y = 0.0, z = 0.0;
  double a = 1.0, b = 0.0, c = 0.0;
  double d = 0.0, e = 1.0, f = 0.0;
  double g = 0.0, h = 0.0, i = 1.0;
  LDrawFileContent content;

  void debug(int indent){
    String spaces = "";
    for(int i=0; i<indent; i++)
      spaces += "  ";
    if( content != null ){
      print( spaces + "File" );
      content.debug(indent+1);
    }
    else
      print( spaces + "File, no content" );
  }

  void draw( Canvas canvas, LDrawContext context ){
    Matrix4 pos = new Matrix4(a, d, g, 0.0, b, e, h, 0.0, c, f, i, 0.0, x, y, z, 1.0);
    pos = context.offset.clone().multiply(pos);
    content.draw(canvas, new LDrawContext( pos, context.r, context.g, context.b ).update_color(color) );
  }
}

class LDrawLine extends LDrawPrimitive{
  int color = 16;
  double x1 = 0.0, y1 = 0.0, z1 = 0.0;
  double x2 = 0.0, y2 = 0.0, z2 = 0.0;
  
  void debug(int indent){
    String spaces = "";
    for(int i=0; i<indent; i++)
      spaces += "  ";
    print( spaces + "Line" );
  }

  void draw( Canvas canvas, LDrawContext context ){
    LDrawContext con = context.update_color(color);
    canvas.move(context.offset);
    canvas.draw_line(x1, y1, z1, x2, y2, z2, con.er, con.eg, con.eb);
  }
}

class LDrawTriangle extends LDrawPrimitive{
  int color = 16;
  double x1 = 0.0, y1 = 0.0, z1 = 0.0;
  double x2 = 0.0, y2 = 0.0, z2 = 0.0;
  double x3 = 0.0, y3 = 0.0, z3 = 0.0;

  void debug(int indent){
    String spaces = "";
    for(int i=0; i<indent; i++)
      spaces += "  ";
    print( spaces + "Triangle" );
  }

  void draw( Canvas canvas, LDrawContext context ){
    LDrawContext con = context.update_color(color);
    canvas.move(context.offset);
    canvas.draw_triangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, con.r, con.g, con.b);
  }
}

class LDrawQuad extends LDrawPrimitive{
  int color = 16;
  double x1 = 0.0, y1 = 0.0, z1 = 0.0;
  double x2 = 0.0, y2 = 0.0, z2 = 0.0;
  double x3 = 0.0, y3 = 0.0, z3 = 0.0;
  double x4 = 0.0, y4 = 0.0, z4 = 0.0;
  
  void debug(int indent){
    String spaces = "";
    for(int i=0; i<indent; i++)
      spaces += "  ";
    print( spaces + "Quad" );
  }

  void draw( Canvas canvas, LDrawContext context ){
    LDrawContext con = context.update_color(color);
    canvas.move(context.offset);
    canvas.draw_quad(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, con.r, con.g, con.b);
  }
}

class LDrawOptional extends LDrawPrimitive{
  int color = 16;
  double x1 = 0.0, y1 = 0.0, z1 = 0.0;
  double x2 = 0.0, y2 = 0.0, z2 = 0.0;
  double x3 = 0.0, y3 = 0.0, z3 = 0.0;
  double x4 = 0.0, y4 = 0.0, z4 = 0.0;
  
  void debug(int indent){
    String spaces = "";
    for(int i=0; i<indent; i++)
      spaces += "  ";
    print( spaces + "Optional" );
  }
}

abstract class LDrawPrimitive{
  void draw( Canvas canvas, LDrawContext context ){ }//TODO: make it abstract
  
  void debug(int indent);
}

void load_ldraw( LDrawFile file, String name ){
  if( cache[name] != null ){
    file.content = cache[name];
    return;
  }
  
  loading++;
  List<String> names = new List<String>();
  cache[name] = new LDrawFileContent();
  file.content = cache[name];
  //names.add( name );
  names.add( "ldraw/parts/" + name );
  names.add( "ldraw/p/" + name );
  //names.add( "ldraw/models/" + name );
  load_ldraw_list( names, name );
}

Map<String,LDrawFileContent> cache = new HashMap<String,LDrawFileContent>();
int loading = 0;

void load_ldraw_list( List<String> names, String name ){
  String try_load = names.removeAt(0);
  HttpRequest.getString( try_load )
  .then((content){
    cache[name].init(content);
    loading--;
  })
  .catchError((onError){
    if( names.length > 0 )
      load_ldraw_list( names, name );
    else{
      print( "Could not retrive file: " + name + " :\\" );
      loading--;
    }
  });
}