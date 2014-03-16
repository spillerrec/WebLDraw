import 'dart:html';

import 'package:WebLDraw/ldrawlib.dart';

void main() {
  querySelectorAll(".webldraw").forEach( (div){
    new LDrawWidget( div );
  });
}

