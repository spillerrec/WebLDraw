library GRAPHICS;

import 'dart:html';
import 'dart:typed_data';
import 'dart:web_gl';

class Canvas{
  CanvasElement canvas;
  RenderingContext gl;
  
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
    gl.viewport( 0,0, canvas.width, canvas.height );
  }
  
  void update(){
    Buffer vertexBuffer = gl.createBuffer();
    gl.bindBuffer(ARRAY_BUFFER, vertexBuffer);
    
    Float32List vertices = new Float32List.fromList([
                                                     0.0,  1.0,  0.0,
                                                     -1.0, -1.0,  0.0,
                                                     1.0, -1.0,  0.0
                                                     ]);

    gl.bufferDataTyped(ARRAY_BUFFER, vertices, STATIC_DRAW);
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
  

    gl.clear( COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT );
    
    Program shaderProgram = create_program( vsSource, fsSource );
  
    gl.bindBuffer( ARRAY_BUFFER, vertexBuffer );
    int vertexPos = gl.getAttribLocation( shaderProgram, "aVertexPosition" );
    gl.enableVertexAttribArray( vertexPos );
    gl.vertexAttribPointer( vertexPos, 3, FLOAT, false, 0, 0 );
    gl.drawArrays( TRIANGLES, 0, 3);
    
    var uPMatrix = gl.getUniformLocation(shaderProgram, "uPMatrix");
    var uMVMatrix = gl.getUniformLocation(shaderProgram, "uMVMatrix");
  
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