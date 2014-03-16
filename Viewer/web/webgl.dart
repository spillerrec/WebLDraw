library GRAPHICS;

import 'dart:html';
import 'dart:typed_data';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'ldraw.dart';
import 'MeshModel.dart';

class Canvas{
  CanvasElement canvas;
  RenderingContext gl;
  
  UniformLocation uPMatrix;
  UniformLocation uMVMatrix;
  int aVertexPosition;
  UniformLocation aColor;
  
  Program shaderProgram;
  
  Buffer vertexBuffer;
  
  MeshModel meshes = new MeshModel();
  bool draw = false;
  
  void load_ldraw( LDrawFile file ){
    file.to_mesh( meshes, new LDrawContext() );
    zoom = meshes.center()*3; //TODO: fix random constant
    //TODO: cleanup memory
    requestUpdate();
  }
  
  bool mouse_active = false;
  double speed = 0.01, zoomSpeed = 0.1;
  Point old_pos = new Point( -1.0, -1.0 );
  double offset_x = radians(180.0+15), offset_y = radians(-45.0), zoom = 0.0;
  void mouseHandler( MouseEvent event ){
    switch( event.type ){
      case "mouseup": mouse_active = false; break;
      case "mousedown": mouse_active = true; break;
      case "mousemove":
          if( old_pos.x < 0 )
            old_pos = event.screen;
          if( mouse_active ){
            offset_y += (event.screen.x - old_pos.x)*speed;
            offset_x += (event.screen.y - old_pos.y)*speed;
            requestUpdate();
          }
          old_pos = event.screen;
        break;
    }
  }
  void wheelHandler( WheelEvent event ){
    event.preventDefault();
    zoom += event.wheelDeltaY * zoomSpeed;
    //TODO: we want wheelDeltaY, but it appears to be broken in dart2js
  }
  
  Canvas( CanvasElement canvas ){
    this.canvas = canvas;
    canvas.onMouseDown.listen( mouseHandler );
    window.onMouseUp.listen( mouseHandler );
    canvas.onMouseWheel.listen( wheelHandler );
    window.onMouseMove.listen( mouseHandler );

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
    
    gl.enable( BLEND );
    gl.blendFunc( SRC_ALPHA, ONE_MINUS_SRC_ALPHA );
    
    window.requestAnimationFrame( (num time) => update() );
  }
  
  void update(){
    if( draw ){
      //Init
      gl.viewport( 0,0, canvas.width, canvas.height );
      gl.clear( COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT );
      
      //Perspective
      Matrix4 pMatrix = makePerspectiveMatrix( radians(45.0), canvas.width / canvas.height, 0.1, -zoom + 1000 );
      Float32List tmpList = new Float32List(16);
      pMatrix.copyIntoArray( tmpList );
      gl.uniformMatrix4fv( uPMatrix, false, tmpList );
      
      //Set rotation/zoom
      Matrix4 offset = new Matrix4.identity();
      offset.translate( 0.0, 0.0, zoom );
      offset.rotateX( offset_x );
      offset.rotateY( offset_y );
      move( offset );
      meshes.draw(this);
      
      draw = false;
    }
    
    window.requestAnimationFrame( (num time) => update() );
  }
  
  void requestUpdate( [bool animate=false] ){
    this.draw = true;
  }
  
  void move( Matrix4 mvMatrix ){
    Float32List tmpList = new Float32List(16);
    mvMatrix.copyIntoArray( tmpList );
    gl.uniformMatrix4fv( uMVMatrix, false, tmpList );
  }
  
  double old_r = 0.0, old_g = 0.0, old_b = 0.0, old_a = 0.0;
  void setColor( double r, double g, double b, double a ){
    if( old_r != r || old_g != g || old_b != b || old_a != a ){
      old_r = r; old_g = g; old_b = b; old_a = a;
      gl.uniform4f( aColor, r, g, b, a );
    }
  }

  
  void draw_lines( Float32List vertices, int amount ){
    gl.bufferDataTyped( ARRAY_BUFFER, vertices, STATIC_DRAW );
    gl.vertexAttribPointer( aVertexPosition, 3, FLOAT, false, 0, 0 );
    gl.drawArrays( LINES, 0, amount );
  }
  void draw_triangles( Float32List vertices, int amount ){
    gl.bufferDataTyped( ARRAY_BUFFER, vertices, STATIC_DRAW );
    gl.vertexAttribPointer( aVertexPosition, 3, FLOAT, false, 0, 0 );
    gl.drawArrays( TRIANGLES, 0, amount );
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