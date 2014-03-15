library MESH;

import 'dart:typed_data';
import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'webgl.dart';

class ColorBin<T>{
  int color;
  List<T> list;
}

class MeshColor{
  double r,g,b,a;
  MeshColor( this.r, this.g, this.b, this.a );
  void draw( Canvas canvas ) => canvas.setColor( r, g, b );
  
  operator ==(MeshColor other){
    return r == other.r && g == other.g && b == other.b && a == other.a;
  }
  int get hashCode{
    int result = 17;
    result = 37 * result + (r*255).toInt();
    result = 37 * result + (g*255).toInt();
    result = 37 * result + (b*255).toInt();
    result = 37 * result + (a*255).toInt();
    return result;
  }
}

abstract class MeshPrimitive{
  MeshColor color;
  List<double> vertices = new List<double>();
  Float32List compiled = null;
  
  void draw(Canvas canvas){
    color.draw( canvas );
    if( compiled == null )
      compiled = new Float32List.fromList( vertices );
  }
}

class MeshTriangles extends MeshPrimitive{
  MeshTriangles(MeshColor color){this.color = color;}
  void draw(Canvas canvas){
    super.draw(canvas);
    canvas.draw_triangles(compiled, compiled.length ~/ 3);
  }
}

class MeshLines extends MeshPrimitive{
  MeshLines(MeshColor color){this.color = color;}
  void draw(Canvas canvas){
    super.draw(canvas);
    canvas.draw_lines(compiled, compiled.length ~/ 3);
  }
}

class MeshModel{
  Map<MeshColor,MeshLines> lines = new Map<MeshColor,MeshLines>();
  Map<MeshColor,MeshTriangles> triangles = new Map<MeshColor,MeshTriangles>();
  
  void draw(Canvas canvas){
    lines.values.forEach((f) => f.draw(canvas));
    triangles.values.forEach((f) => f.draw(canvas));
  }
  
  void offset( double dx, double dy, double dz ){
    //TODO: we need a way to reuse these functions
    lines.values.forEach( (f){
      for( int i=0; i<f.vertices.length ~/ 3 * 3; i+=3 ){
        f.vertices[i] -= dx;
        f.vertices[i+1] -= dy;
        f.vertices[i+2] -= dz;
      }
    });
    triangles.values.forEach( (f){
      for( int i=0; i<f.vertices.length ~/ 3 * 3; i+=3 ){
        f.vertices[i] -= dx;
        f.vertices[i+1] -= dy;
        f.vertices[i+2] -= dz;
      }
    });
  }
  
  double center(){
    double min_x = double.MAX_FINITE, min_y = min_x, min_z = min_y;
    double max_x = -double.MAX_FINITE, max_y = max_x, max_z = max_y;

    //NOTE: We could do it for Lines as well, but it isn't really nessasary
    triangles.values.forEach((f){
      for( int i=0; i<f.vertices.length ~/ 3 * 3; i+=3 ){
        min_x = min( min_x, f.vertices[i] );
        min_y = min( min_y, f.vertices[i+1] );
        min_z = min( min_z, f.vertices[i+2] );
        max_x = max( max_x, f.vertices[i] );
        max_y = max( max_y, f.vertices[i+1] );
        max_z = max( max_z, f.vertices[i+2] );
      }
    });
    
    print( "Min: $min_x, $min_y, $min_z" );
    print( "Max: $max_x, $max_y, $max_z" );
    offset( (max_x-min_x)/2+min_x, (max_y-min_y)/2+min_y, (max_z-min_z)/2+min_z );
    return min( min_z, min( min_y, min_x ) );
  }
  
  List<double> move( List<double> data, Matrix4 offset ){
    for(int i=0; i<data.length ~/ 3 * 3; i+=3){
      Matrix4 pos = new Matrix4.identity().translate( data[i], data[i+1], data[i+2]);
      Vector3 new_pos = offset.clone().multiply(pos).getTranslation();
      data[i] = new_pos.x;
      data[i+1] = new_pos.y;
      data[i+2] = new_pos.z;
    }
    return data;
  }

  void add_triangle( Float32List vertices, Matrix4 offset, double r, double g, double b ){
    MeshColor color = new MeshColor( r, g, b, 1.0 );
    List<double> data = move( vertices.toList(), offset );
    MeshTriangles tri = triangles.putIfAbsent(color, () => new MeshTriangles(color));
    tri.vertices.addAll(data);
    tri.compiled = null;
  }
  void add_lines( Float32List vertices, Matrix4 offset, double r, double g, double b ){
    MeshColor color = new MeshColor( r, g, b, 1.0 );
    List<double> data = move( vertices.toList(), offset );
    MeshLines line = lines.putIfAbsent(color, () => new MeshLines(color));
    line.vertices.addAll(data);
    line.compiled = null;
  }
}