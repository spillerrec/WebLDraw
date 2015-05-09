import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:lzma/lzma.dart' as LZMA;

import 'package:webldraw/ldrawlib.dart';

/* Converts an ordinary LDraw file into a MPD file containing all
 * LDraw files it depends on. For archiving, or reducing HTTP requests
 * when sending over the network. (Do compress it however!)
 */

class LDrawFileLib extends LDrawLib{
	Future<List<int>> load( String url ) => new File( url ).readAsBytes();
}

LDrawLoader loader;
void main( List<String> args ){
	if( args.length > 0 )
		loader = new LDrawLoader( new LDrawFileLib(), args[0], new Combiner( args[0] ) );
	else
		print( "Supply the filename to convert as an argument" );
	}

class Combiner extends Progress{
	String name;
	Combiner( String path ){
		int pos = path.indexOf(".");
		name = pos < 0 ? path : path.substring( 0, pos );
	}

	@override
	void updated() {
		if( current + failed == total ){
			//Add all the dependent files to the loaded file (except for itself)
			LDrawLoader.cache.remove( loader.file.name );
			loader.file.content.files.addAll( LDrawLoader.cache );

			//Write to file
      var output = new File('$name.full.mpd.lzma');
      //var output = new File('$name.full.mpd').openWrite();
      //output.write( loader.file.content.asLDraw() );
      //output.close();
			
			var lzmaOutput = new LZMA.OutStream();
			LZMA.compress(
			    new LZMA.InStream(UTF8.encoder.convert(loader.file.content.asLDraw()))
			, lzmaOutput);
			
			output.writeAsBytesSync(lzmaOutput.data);
		}
	}
}