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
  UniformLocation aColor;
  double test = 0.0;
  
  Program shaderProgram;
  
  Buffer vertexBuffer;
  
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
    vertexBuffer = gl.createBuffer();
    gl.bindBuffer( ARRAY_BUFFER, vertexBuffer );
    
    gl.clearColor( 0.0, 0.0, 0.0, 0.0 );
    //TODO: check if transparency works
    gl.enable( DEPTH_TEST );
    gl.clear( COLOR_BUFFER_BIT );
    
    
    //Shader program
    String vsSource = """
        attribute vec3 aVertexPosition;
        attribute vec4 aVertexColor;
        
        uniform mat4 uMVMatrix;
        uniform mat4 uPMatrix;

        varying vec4 vColor;
        uniform vec4 aColor;
        
        void main(void) {
          gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
          vColor = aColor;
        }
      """;

    // fragment shader source code. uColor is our variable that we'll
    // use to animate color
    String fsSource = """
        precision mediump float;
        
        varying vec4 vColor;
        
        void main(void) {
          gl_FragColor = vColor;;
        }
      """;
    Program shaderProgram = create_program( vsSource, fsSource );
    
    
    //View transformation
    uPMatrix = gl.getUniformLocation( shaderProgram, "uPMatrix" );
    uMVMatrix = gl.getUniformLocation( shaderProgram, "uMVMatrix" );

    //Position attribute
    aVertexPosition = gl.getAttribLocation( shaderProgram, "aVertexPosition" );
    gl.enableVertexAttribArray( aVertexPosition );
    
    aColor = gl.getUniformLocation( shaderProgram, "aColor" );
    
    window.requestAnimationFrame((num time) => update(time));
  }
  
  void update(num time){
    //Init
    gl.viewport( 0,0, canvas.width, canvas.height );
    gl.clear( COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT );
    
    test += 0.05;
    
    //Perspective
    Matrix4 pMatrix = makePerspectiveMatrix( radians(45.0), canvas.width / canvas.height, 0.1, 500.0 );
    Float32List tmpList = new Float32List(16);
    pMatrix.copyIntoArray( tmpList );
    gl.uniformMatrix4fv( uPMatrix, false, tmpList );
    
    if( file != null ){
      Matrix4 offset = new Matrix4.identity();
      offset.translate(1.0, -2.0, -140.0);
      offset.rotateX(test);
      offset.rotateY(test*0.5);
      file.draw( this, new LDrawContext( offset, 0.0, 0.0, 0.0 ) );
    }
    
    window.requestAnimationFrame((num time) => update(time));
  }
  
  void move( Matrix4 mvMatrix ){
    Float32List tmpList = new Float32List(16);
    mvMatrix.copyIntoArray( tmpList );
    gl.uniformMatrix4fv( uMVMatrix, false, tmpList );
  }
  void setColor( double r, double g, double b ) => gl.uniform4f( aColor, r, g, b, 1.0 );

  
  void draw_lines( Float32List vertices, int amount ){
    gl.bufferDataTyped( ARRAY_BUFFER, vertices, STATIC_DRAW );
    gl.vertexAttribPointer( aVertexPosition, 3, FLOAT, false, 0, 0 );
    gl.drawArrays( LINES, 0, amount );
  }
  void draw_triangle_fan( Float32List vertices, int amount ){
    gl.bufferDataTyped( ARRAY_BUFFER, vertices, STATIC_DRAW );
    gl.vertexAttribPointer( aVertexPosition, 3, FLOAT, false, 0, 0 );
    gl.drawArrays( TRIANGLE_FAN, 0, amount );
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