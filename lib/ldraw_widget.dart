part of webldraw;

class LDrawHttpLib extends LDrawLib{
	Future<List<int>> load( String url ){
	  return HttpRequest.request( url, responseType: 'arraybuffer' )
	      .then( (request){
	       return new Uint8List.view( request.response );
	      } );
	}
}

class LDrawWidget extends Progress{
	Element container;
	Canvas canvas;
	bool active = false;
	LDrawLoader loader;

	LDrawWidget( this.container ){
		canvas = new Canvas( container.querySelector("canvas") );
		String filename = container.dataset["file"];
		loader = new LDrawLoader( new LDrawHttpLib(), filename, this );

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

	void showWarning( String message ){
		Element warning = new Element.p();
		warning.style.backgroundColor = 'yellow';
		warning.style.textAlign = 'center';
		warning.style.width = '100%';
		warning.style.top = '0';
		warning.style.position = 'absolute';
		warning.style.lineHeight = '2em';

		warning.appendText( message + " (Click to close)" );

		warning.onClick.listen( (t){ warning.remove(); } );

		container.append( warning );
	}

	void centerElement( Element em, [int top=45] ){
		em.style.position = 'absolute';
		em.style.top = '$top%';
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

	@override
	void updated() {
		update( current, total );
		if( current + failed >= total ){
			canvas.load_ldraw( loader.file );
			removeProgressBar();

			if( failed > 0 )
				showWarning( "$failed file(s) not loaded" );
		}
	}
}