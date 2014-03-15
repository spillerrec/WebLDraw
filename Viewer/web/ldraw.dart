library LDRAW;

import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import 'MeshModel.dart';
import 'LDrawLoader.dart';

class LDrawColor{
  int r, g, b; //Main color
  int er, eg, eb; //Edge color
  int alpha = 255;
  //Not supported:
  //Luminance
  //Materials
  
  LDrawColor( this.r, this.g, this.b, this.er, this.eg, this.eb, [this.alpha=255] );
}
class LDrawColorIndex{
  //TODO: this makes new colors work for the entire file, we only want it for the remaining of the file!
  Map<int,LDrawColor> colors = new Map<int,LDrawColor>();
  LDrawColorIndex(){
    colors = new Map<int,LDrawColor>();
  }
  
  LDrawColorIndex combine( LDrawColorIndex parent ){
    LDrawColorIndex combined = new LDrawColorIndex();
    combined.colors.addAll(parent.colors);
    combined.colors.addAll(colors);
    return combined;
  }
  
  LDrawColor lookUp( int index ){
    if( colors.containsKey( index ) )
      return colors[index];
    else
      return colors[0]; //Note: black must be defined
      //TODO: throw exception instead?
  }
  
  LDrawColorIndex.officialColors(){
    colors = {
        00: new LDrawColor( 0x00, 0x00, 0x00, 0x3F, 0x47, 0x4C )
      , 04: new LDrawColor( 0xC9, 0x1A, 0x09, 0xD5, 0x1A, 0x09 )
      , 07: new LDrawColor( 0x9B, 0xA1, 0x9D, 0x75, 0x7B, 0x7C )
      , 39: new LDrawColor( 0xC1, 0xDF, 0xF0, 0x85, 0xA3, 0xB4, 64 )
      };
  }
}

class LDrawColorId{
  int code = 16;
  LDrawColorId();
  LDrawColorId.parse( String part ){
    code = int.parse( part );
    //TODO: support rgb definition
  }
}

class LDrawContext{
  LDrawColorIndex index = new LDrawColorIndex.officialColors();
  Matrix4 offset = new Matrix4.identity();
  LDrawColor color;
  
  LDrawContext(){
    color = index.lookUp(0);
  }
  LDrawContext.subpart( LDrawContext context, this.color, this.offset ){
    index = context.index;
  }
  LDrawContext.subfile( LDrawContext context, LDrawColorIndex index ){
    offset = context.offset;
    color = context.color;
    this.index = index.combine( context.index );
  }
  
  LDrawColor lookUp( LDrawColorId color_id ){
    if( color_id.code == 16 || color_id.code == 24 )
      return color;
    else
      return index.lookUp( color_id.code );
  }
}

class LDrawFileContent extends LDrawPrimitive{
  LDrawColorIndex color_index = new LDrawColorIndex();
  List<LDrawPrimitive> primitives = new List<LDrawPrimitive>();

  void to_mesh( MeshModel model, LDrawContext context ){
    LDrawContext new_context = new LDrawContext.subfile( context, color_index );
    primitives.forEach( (x) => x.to_mesh( model, new_context ) );
  }
  void init( String content, LDrawLoader loader ){
    try{
    List<String> lines = content.split("\n");
    lines.removeWhere((test)=>test.isEmpty);
    lines.forEach((line){
      List<String> parts = line.trim().split(" ");
      parts.removeWhere((test)=>test.isEmpty); //Note: could mess up file names if they contain spaces 
      
      if( parts.length > 0 )
         switch( parts.removeAt(0) ){
           case '0': parse_comment(parts); break;
           case '1': parse_subfile(parts,loader); break;
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
  
  Float32List from_string_list( List<String> parts, int start, int amount ){
    Float32List list = new Float32List( amount );
    for( int i=0; i<amount; i++ ){
      list[i]=( double.parse( parts[i+start] ) );
    }
    return list;
  }
  
  void parse_comment(List<String> parts){
    if( parts.length > 0 )
      switch( parts[0] ){
        case "STEP": break;
        case "ROTATION": break;
        //default: print("comment");
      }
  }
  
  void parse_subfile( List<String> parts, LDrawLoader loader ){
    assert(parts.length >= 14);
    
    LDrawFile sub = new LDrawFile();
    sub.color = new LDrawColorId.parse( parts[0] );
    double x = double.parse( parts[1] );
    double y = double.parse( parts[2] );
    double z = double.parse( parts[3] );
    double a = double.parse( parts[4] );
    double b = double.parse( parts[5] );
    double c = double.parse( parts[6] );
    double d = double.parse( parts[7] );
    double e = double.parse( parts[8] );
    double f = double.parse( parts[9] );
    double g = double.parse( parts[10] );
    double h = double.parse( parts[11] );
    double i = double.parse( parts[12] );
    sub.pos = new Matrix4( a, d, g, 0.0, b, e, h, 0.0, c, f, i, 0.0, x, y, z, 1.0 );
    
    String filepath = parts.sublist(13).join(" ").trim();
    loader.load_file( sub, filepath );
    primitives.add(sub);
  }
  void parse_line(List<String> parts){
    assert(parts.length >= 7);
    
    LDrawLine line = new LDrawLine();
    line.color = new LDrawColorId.parse( parts[0] );
    line.vertices = from_string_list( parts, 1, 6 );
    
    for(int i=0; i<primitives.length; i++)
      if( primitives[i] is LDrawLine ){
        LDrawLine old_line = primitives[i];
        if( old_line.color == line.color ){
          old_line.vertices = combine( old_line.vertices, line.vertices );
          return;
        }
      }
    
    primitives.add(line);
  }
  void parse_triangle(List<String> parts){
    assert(parts.length >= 10);
    
    LDrawTriangle tri = new LDrawTriangle();
    tri.color = new LDrawColorId.parse( parts[0] );
    tri.vertices = from_string_list( parts, 1, 9 );

    primitives.add(tri);
  }
  void parse_quad(List<String> parts){
    assert(parts.length >= 13);
    
    LDrawTriangle quad = new LDrawTriangle();
    quad.color = new LDrawColorId.parse( parts[0] );
    Float32List arr1 = from_string_list( parts, 1, 9 );
    Float32List arr2 = from_string_list( parts, 1+3, 9 );
    for(int i=0; i<3; i++)
      arr2[i] = arr1[i];
    quad.vertices = combine( arr1, arr2 );
    
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
}
Float32List combine(Float32List arr1, Float32List arr2){
  Float32List arr = new Float32List( arr1.length + arr2.length );
  for(int i=0; i<arr1.length; i++)
    arr[i] = arr1[i];
  for(int i=0; i<arr2.length; i++)
    arr[i+arr1.length] = arr2[i];
  return arr;
}

class LDrawFile extends LDrawPrimitive{
  LDrawColorId color = new LDrawColorId();
  Matrix4 pos = new Matrix4.identity();
  LDrawFileContent content;

  void to_mesh( MeshModel model, LDrawContext context ){
    Matrix4 new_pos = context.offset.clone().multiply(pos);
    content.to_mesh( model, new LDrawContext.subpart( context, context.lookUp(color), new_pos ) );
  }
}

class LDrawLine extends LDrawPrimitive{
  LDrawColorId color;
  Float32List vertices;

  void to_mesh( MeshModel model, LDrawContext context ){
    LDrawColor c = context.lookUp( color );
    model.add_lines( vertices, context.offset, c.er/255, c.eg/255, c.eb/255, c.alpha/255 );
  }
}

class LDrawTriangle extends LDrawPrimitive{
  LDrawColorId color;
  Float32List vertices;

  void to_mesh( MeshModel model, LDrawContext context ){
    LDrawColor c = context.lookUp( color );
    model.add_triangle( vertices, context.offset, c.r/255, c.g/255, c.b/255, c.alpha/255 );
  }
}

class LDrawQuad extends LDrawPrimitive{
  int color = 16;
  Float32List vertices;

  void to_mesh( MeshModel model, LDrawContext context ){
    print( "not implemented" );
  }
}

class LDrawOptional extends LDrawPrimitive{
  int color = 16;
  double x1 = 0.0, y1 = 0.0, z1 = 0.0;
  double x2 = 0.0, y2 = 0.0, z2 = 0.0;
  double x3 = 0.0, y3 = 0.0, z3 = 0.0;
  double x4 = 0.0, y4 = 0.0, z4 = 0.0;
  
}

abstract class LDrawPrimitive{
  void to_mesh( MeshModel model, LDrawContext context ){ }
}
