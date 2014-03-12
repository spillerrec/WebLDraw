library GRAPHICS;

import 'dart:html';
import 'dart:typed_data';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

class Canvas{
  CanvasElement canvas;
  RenderingContext gl;
  
  UniformLocation uPMatrix;
  UniformLocation uMVMatrix;
  int aVertexPosition;
  
  Program shaderProgram;
  
  Canvas( String canvas_selector ){
    canvas = querySelector( canvas_selector );

    //Initialize WebGL
    gl = canvas.getContext3d();
    if( gl == null ){
      print( "No context :\\" );
      //TODO: throw exception
      return;
    }
    
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
  }
  
  void update(){
    gl.viewport( 0,0, canvas.width, canvas.height );
    Matrix4 pMatrix = makePerspectiveMatrix( radians(45.0), canvas.width / canvas.height, 0.1, 100.0 );
    Matrix4 mvMatrix = new Matrix4.identity();
    mvMatrix.translate( -1.5, 0.0, -7.0 );
    
    Buffer vertexBuffer = gl.createBuffer();
    gl.bindBuffer( ARRAY_BUFFER, vertexBuffer );
    
    Float32List vertices = new Float32List.fromList([
                                                     0.0,  1.0,  0.0,
                                                     -1.0, -1.0,  0.0,
                                                     1.0, -1.0,  0.0
                                                     ]);

    gl.bufferDataTyped(ARRAY_BUFFER, vertices, STATIC_DRAW);
    
  

    gl.clear( COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT );
    
  
    gl.vertexAttribPointer( aVertexPosition, 3, FLOAT, false, 0, 0 );
    
    
    Float32List tmpList = new Float32List(16);
    pMatrix.copyIntoArray( tmpList );
    gl.uniformMatrix4fv( uPMatrix, false, tmpList );
    mvMatrix.copyIntoArray( tmpList );
    gl.uniformMatrix4fv( uMVMatrix, false, tmpList );
    
    gl.drawArrays( TRIANGLES, 0, 3);

  
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