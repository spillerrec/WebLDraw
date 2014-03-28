part of ldraw;

abstract class Drawable3D{
	void setColor( int r, int g, int b, int alpha );
	void draw_triangles( Float32List vertices, int amount );
	void draw_lines( Float32List vertices, int amount );
}

List<Float32List> unused = new List<Float32List>();
class DynamicFloat32List{
	Float32List create( int wanted ){
		for( int i=0; i<unused.length; i++ )
			if( unused[i].length >= wanted )
				return unused.removeAt(i);
		return new Float32List( wanted );
	}

	Float32List list;
	int length = 0;
	void addAll( Float32List add, Matrix4 offset ){
		if( list == null ){ //List doesn't exist
			list = create( add.length );
			for( int i=0; i<add.length; i++ )
				list[i] = add[i];
		}
		else{
			int needed = length + add.length;
			if( needed < list.length ){
				//List large enough to contain both
				for( int i=0; i<add.length; i++ )
					list[i+length] = add[i];
			}
			else{
				//List not large enough, need to expand
				Float32List new_list = create( needed*2 );
				for( int i=0; i<length; i++ )
					new_list[i] = list[i];
				for( int i=0; i<add.length; i++ )
					new_list[i+length] = add[i];
				unused.add(list);
				list = new_list;
			}
		}

		for(int i=0; i<add.length ~/ 3 * 3; i+=3){
			/*
			Matrix4 pos = new Matrix4.translationValues( list[length+i], list[length+i+1], list[length+i+2]);
			Vector3 new_pos = offset.clone().multiply(pos).getTranslation();
			list[length+i] = new_pos.x;
			list[length+i+1] = new_pos.y;
			list[length+i+2] = new_pos.z;
			// */
			//* The same code as above, taken from source, and removed reductanct statements
			//Why isn't the optimizer doing this?
			final double m00 = offset.storage[0];
			final double m01 = offset.storage[4];
			final double m02 = offset.storage[8];
			final double m03 = offset.storage[12];
			final double m10 = offset.storage[1];
			final double m11 = offset.storage[5];
			final double m12 = offset.storage[9];
			final double m13 = offset.storage[13];
			final double m20 = offset.storage[2];
			final double m21 = offset.storage[6];
			final double m22 = offset.storage[10];
			final double m23 = offset.storage[14];
			final double n03 = list[length+i];
			final double n13 = list[length+i+1];
			final double n23 = list[length+i+2];
			list[length+i] =  (m00 * n03) + (m01 * n13) + (m02 * n23) + (m03);
			list[length+i+1] =  (m10 * n03) + (m11 * n13) + (m12 * n23) + (m13);
			list[length+i+2] =  (m20 * n03) + (m21 * n13) + (m22 * n23) + (m23);
			// */
		}

		length += add.length;
	}
}

class MeshColor{
	int r,g,b,a;
	MeshColor( this.r, this.g, this.b, this.a );
	void draw( Drawable3D canvas ) => canvas.setColor( r, g, b, a );

	operator ==(MeshColor other){
		return r == other.r && g == other.g && b == other.b && a == other.a;
	}
	int get hashCode{
		int result = 17;
		result = 37 * result + r;
		result = 37 * result + g;
		result = 37 * result + b;
		result = 37 * result + a;
		return result;
	}
}

abstract class MeshPrimitive{
	MeshColor color;
	DynamicFloat32List vertices = new DynamicFloat32List();

	void draw(Drawable3D canvas){
		color.draw( canvas );
	}
}

class MeshTriangles extends MeshPrimitive{
	MeshTriangles(MeshColor color){this.color = color;}
	void draw(Drawable3D canvas){
		super.draw(canvas);
		canvas.draw_triangles(vertices.list, vertices.length ~/ 3);
	}
}

class MeshLines extends MeshPrimitive{
	MeshLines(MeshColor color){this.color = color;}
	void draw(Drawable3D canvas){
		super.draw(canvas);
		canvas.draw_lines(vertices.list, vertices.length ~/ 3);
	}
}

class MeshModel{
	Map<MeshColor,MeshLines> lines = new Map<MeshColor,MeshLines>();
	Map<MeshColor,MeshTriangles> triangles = new Map<MeshColor,MeshTriangles>();

	void draw(Drawable3D canvas){
		lines.values.forEach((f) => f.draw(canvas));
		triangles.values.forEach((f) => f.draw(canvas));
	}

	void offset( double dx, double dy, double dz ){
		//TODO: we need a way to reuse these functions
		lines.values.forEach( (f){
				for( int i=0; i<f.vertices.length ~/ 3 * 3; i+=3 ){
					f.vertices.list[i] -= dx;
					f.vertices.list[i+1] -= dy;
					f.vertices.list[i+2] -= dz;
				}
			} );
		triangles.values.forEach( (f){
				for( int i=0; i<f.vertices.length ~/ 3 * 3; i+=3 ){
					f.vertices.list[i] -= dx;
					f.vertices.list[i+1] -= dy;
					f.vertices.list[i+2] -= dz;
				}
			} );
	}

	double center(){
		double min_x = double.MAX_FINITE, min_y = min_x, min_z = min_y;
		double max_x = -double.MAX_FINITE, max_y = max_x, max_z = max_y;

		//NOTE: We could do it for Lines as well, but it isn't really nessasary
		triangles.values.forEach((f){
				for( int i=0; i<f.vertices.length ~/ 3 * 3; i+=3 ){
					/*
					min_x = math.min( min_x, f.vertices.list[i] );
					min_y = math.min( min_y, f.vertices.list[i+1] );
					min_z = math.min( min_z, f.vertices.list[i+2] );
					max_x = math.max( max_x, f.vertices.list[i] );
					max_y = math.max( max_y, f.vertices.list[i+1] );
					max_z = math.max( max_z, f.vertices.list[i+2] );
					// */
					//* This is getting stupid...
					min_x = min_x < f.vertices.list[i] ? min_x : f.vertices.list[i];
					min_y = min_y < f.vertices.list[i+1] ? min_y : f.vertices.list[i+1];
					min_z = min_z < f.vertices.list[i+2] ? min_z : f.vertices.list[i+2];
					max_x = max_x > f.vertices.list[i] ? max_x : f.vertices.list[i];
					max_y = max_y > f.vertices.list[i+1] ? max_y : f.vertices.list[i+1];
					max_z = max_z > f.vertices.list[i+2] ? max_z : f.vertices.list[i+2];
					// */
				}
			} );

		offset( (max_x-min_x)/2+min_x, (max_y-min_y)/2+min_y, (max_z-min_z)/2+min_z );
		return math.min( min_z, math.min( min_y, min_x ) );
	}

	MeshTriangles last_tri;
	void add_triangle( Float32List vertices, Matrix4 offset, int r, int g, int b, int a ){
		MeshColor color = new MeshColor( r, g, b, a );
		if( last_tri == null || !(last_tri.color == color) )
			last_tri = triangles.putIfAbsent( color, () => new MeshTriangles(color) );
		last_tri.vertices.addAll( vertices, offset );
	}
	MeshLines last_line;
	void add_lines( Float32List vertices, Matrix4 offset, int r, int g, int b, int a ){
		MeshColor color = new MeshColor( r, g, b, a );
		if( last_line == null || !(last_line.color == color) )
			last_line = lines.putIfAbsent( color, () => new MeshLines(color) );
		last_line.vertices.addAll( vertices, offset );
	}
}