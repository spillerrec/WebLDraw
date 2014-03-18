part of ldraw;

class LDrawWidget{
  Element container;
  Canvas canvas;
  bool active = false;
  
  LDrawWidget( this.container ){
    canvas = new Canvas( container.querySelector("canvas") );
    String filename = container.dataset["file"];
    LDrawLoader loader = new LDrawLoader( filename, this );

    canvas.canvas.onMouseEnter.listen( (t){ active=true; } );
    canvas.canvas.onMouseLeave.listen( (t){ active=false; } );
    window.onKeyPress.listen( (KeyboardEvent key ){
      if( active && key.keyCode == 102 )
        canvas.canvas.requestFullscreen();
    } );
    
    createProgressBar();
  }
  
  void show( LDrawFile file ){
    canvas.load_ldraw( file );
    removeProgressBar();
  }
  
  Element bar;
  Element bar_text;
  void createProgressBar(){
    container.style.width = "${canvas.canvas.width}px";
    container.style.position = 'relative';
    
    bar = new Element.div();
    bar.attributes['class'] = 'progress';
    bar.style.backgroundColor = 'green';
    
    bar_text = new Element.p();
    bar_text.appendText("");
    bar_text.style.textAlign = 'center';
    bar_text.style.width = '100%';
    
    centerElement( bar );
    centerElement( bar_text );
    container.append( bar );
    container.append( bar_text );
  }
  
  void centerElement( Element em ){
    em.style.position = 'absolute';
    em.style.top = '45%';
    em.style.height = '10%';
  }
  
  void update( int current, int max ){
    bar.style.width = "${current / max * 100}%";
    bar_text.text = "Loading files: $current / $max";
  }
  
  void removeProgressBar(){
    bar.remove();
    bar_text.remove();
  }
}