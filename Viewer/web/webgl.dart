library GRAPHICS;

import 'dart:html';
import 'dart:typed_data';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'ldraw.dart';

class Canvas{
  CanvasElement canvas;
  RenderingContext gl;
  
  UniformLocation uPMatrix;
  UniformLocation uMVMatrix;
  int aVertexPosition;
  double test = 0.0;
  
  Program shaderProgram;
  
  LDrawFile file;
  
  Canvas( String canvas_selector ){
    canvas = querySelector( canvas_selector );

    //Initialize WebGL
    gl = canvas.getContext3d();
    if( gl == null ){
      print( "No context :\\" );
      //TODO: throw exception
      return;
    }

    //Vertex Array Object?
    Buffer vertexBuffer = gl.createBuffer();
    gl.bindBuffer( ARRAY_BUFFER, vertexBuffer );
    
    gl.clearColor( 0.0, 0.0, 0.0, 1.0 );
    //TODO: check if transparency works
    gl.enable( DEPTH_TEST );
    gl.clear( COLOR_BUFFER_BIT );
    
    
    //Shader program
    String vsSource = """
        attribute vec3 aVertexPosition;
        attribute vec4 aVertexColor;
        
        uniform mat4 uMVMatrix;
        uniform mat4 uPMatrix;
        
        void main(void) {
        gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
        }
      """;

    // fragment shader source code. uColor is our variable that we'll
    // use to animate color
    String fsSource = """
        precision mediump float;
        
        void main(void) {
          gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);;
        }
      """;
    Program shaderProgram = create_program( vsSource, fsSource );
    
    
    //View transformation
    uPMatrix = gl.getUniformLocation( shaderProgram, "uPMatrix" );
    uMVMatrix = gl.getUniformLocation( shaderProgram, "uMVMatrix" );

    //Position attribute
    aVertexPosition = gl.getAttribLocation( shaderProgram, "aVertexPosition" );
    gl.enableVertexAttribArray( aVertexPosition );
    
    window.requestAnimationFrame((num time) => update(time));
  }
  
  void update(num time){
    //Init
    gl.viewport( 0,0, canvas.width, canvas.height );
    gl.clear( COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT );
    
    test += 0.05;
    
    //Perspective
    Matrix4 pMatrix = makePerspectiveMatrix( radians(45.0), canvas.width / canvas.height, 0.1, 100.0 );
    Float32List tmpList = new Float32List(16);
    pMatrix.copyIntoArray( tmpList );
    gl.uniformMatrix4fv( uPMatrix, false, tmpList );
    
    
/*
    move( -1.5, 0.0, -7.0, 0.0, test, 0.0 );
    draw_triangle(
         0.0,  1.0,  0.0,
         -1.0, -1.0,  0.0,
         1.0, -1.0,  0.0
       );

    move( 1.5, 0.0, -7.0, test, 0.0, test );
    draw_triangle(
        0.0,  1.0,  0.0,
        -1.0, -1.0,  0.0,
        1.0, -1.0,  0.0
      );
*/
    if( file != null ){
      Matrix4 offset = new Matrix4.identity();
      offset.translate(1.0, -2.0, -70.0);
      offset.rotateX(test);
      offset.rotateY(test*0.5);
      file.draw( this, offset );
    }
    
    window.requestAnimationFrame((num time) => update(time));
  }
  
  void move( Matrix4 mvMatrix ){
    Float32List tmpList = new Float32List(16);
    mvMatrix.copyIntoArray( tmpList );
    gl.uniformMatrix4fv( uMVMatrix, false, tmpList );
  }
  void draw_triangle(
                     double x1, double y1, double z1,
                     double x2, double y2, double z2,
                     double x3, double y3, double z3
                     ){
    Float32List vertices = new Float32List.fromList([
                                                     x1, y1, z1,
                                                     x2, y2, z2,
                                                     x3, y3, z3
                                                     ]);

    gl.bufferDataTyped( ARRAY_BUFFER, vertices, STATIC_DRAW );
    gl.vertexAttribPointer( aVertexPosition, 3, FLOAT, false, 0, 0 );
    gl.drawArrays( TRIANGLES, 0, 3 );
  }
  void draw_quad(
                     double x1, double y1, double z1,
                     double x2, double y2, double z2,
                     double x3, double y3, double z3,
                     double x4, double y4, double z4
                     ){
    Float32List vertices = new Float32List.fromList([
                                                     x1, y1, z1,
                                                     x2, y2, z2,
                                                     x3, y3, z3,
                                                     x4, y4, z4,
                                                     ]);
    draw_triangle(x1, y1, z1, x2, y2, z2, x3, y3, z3);
    draw_triangle(x1, y1, z1, x4, y4, z4, x3, y3, z3);
  }
  

  Shader create_shader( int type, String source ){
    Shader shader = gl.createShader( type );
    gl.shaderSource( shader, source );
    gl.compileShader( shader );
    if( !gl.getShaderParameter( shader, COMPILE_STATUS ) )
      print( gl.getShaderInfoLog( shader ) );
    return shader;
  }

  Program create_program( String vsSource, String fsSource ){
    Program program = gl.createProgram();
    gl.attachShader( program, create_shader( VERTEX_SHADER, vsSource ) );
    gl.attachShader( program, create_shader( FRAGMENT_SHADER, fsSource ) );
    gl.linkProgram( program );
    gl.useProgram( program );
    
    if( !gl.getProgramParameter( program, LINK_STATUS ) )
      print( gl.getProgramInfoLog( program ) );
    
    return program;
  }
}