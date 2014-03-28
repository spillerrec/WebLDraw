import 'dart:html';

import 'package:webldraw/webldraw.dart';

void main() {
	querySelectorAll(".webldraw").forEach( (div){
		new LDrawWidget( div );
	});
}

