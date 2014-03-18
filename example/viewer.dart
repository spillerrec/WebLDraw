import 'dart:html';

import 'package:webldraw/ldrawlib.dart';

void main() {
  querySelectorAll(".webldraw").forEach( (div){
    new LDrawWidget( div );
  });
}

