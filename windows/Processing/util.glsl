// constants
float pi = 3.14159265358979;
float render_dist = 50;

// structs
struct vector_float2 {
    float x;
    float y;
};

struct vector_float3 {
    float x;
    float y;
    float z;
};

struct vector_float4 {
    float x;
    float y;
    float z;
    float w;
};

struct vector_int2 {
    int x;
    int y;
};

struct vector_int3 {
    int x;
    int y;
    int z;
};

struct vector_int4 {
    int x;
    int y;
    int z;
    int w;
};

struct WindowAttributes {
    unsigned int width;
    unsigned int height;
};

struct CompiledBufferKeyIndices {
    unsigned int compiled_vertex_size;
    unsigned int compiled_vertex_scene_start;
    unsigned int compiled_vertex_control_start;
    unsigned int compiled_vertex_dot_start;
    unsigned int compiled_vertex_node_circle_start;
    unsigned int compiled_vertex_vertex_square_start;
    unsigned int compiled_vertex_dot_square_start;
    unsigned int compiled_vertex_slice_plate_start;
    unsigned int compiled_vertex_ui_start;
    
    unsigned int compiled_face_size;
    unsigned int compiled_face_scene_start;
    unsigned int compiled_face_control_start;
    unsigned int compiled_face_node_circle_start;
    unsigned int compiled_face_vertex_square_start;
    unsigned int compiled_face_dot_square_start;
    unsigned int compiled_face_slice_plate_start;
    unsigned int compiled_face_ui_start;
    
    unsigned int compiled_edge_size;
    unsigned int compiled_edge_scene_start;
    unsigned int compiled_edge_line_start;
};

struct Basis {
    vector_float3 pos;
    // angles
    vector_float3 x;
    vector_float3 y;
    vector_float3 z;
};

struct Camera {
    vector_float3 pos;
    vector_float3 vector;
    vector_float3 upVector;
    vector_float2 FOV;
};

struct Face {
    unsigned int vertices[3];
    vector_float4 color;
    
    unsigned int normal_reversed;
    vector_float3 lighting_offset; // if there were a light source directly in front of the face, this is the rotation to get to its brightest orientation
    float shading_multiplier;
};

struct UIElementTransform {
    vector_int3 position;
    vector_float3 up;
    vector_float3 right;
};

struct Node {
    int locked_to;
    Basis b;
};

struct NodeVertexLink {
    int nid;
    vector_float3 vector;
    float weight;
};

struct ModelTransform {
    vector_float3 rotate_origin;
    Basis b;
};

struct SliceAttributes {
    float width;
    float height;
};

struct SimpleLight {
    Basis b;
    float max_intensity;
    vector_float4 color;
    vector_float3 distance_falloff;
    vector_float3 angle_falloff;
};

// ---HELPER FUNCTIONS---
vector_float2 vector_make_float2(float x, float y) {
	vector_float2 ret;
	ret.x = x;
	ret.y = y;
	return ret;
}

vector_float3 vector_make_float3(float x, float y, float z) {
	vector_float3 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	return ret;
}

vector_float4 vector_make_float4(float x, float y, float z, int w) {
	vector_float4 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	ret.w = w;
	return ret;
}

vector_int2 vector_make_int2(int x, int y) {
	vector_int2 ret;
	ret.x = x;
	ret.y = y;
	return ret;
}

vector_int3 vector_make_int3(int x, int y, int z) {
	vector_int3 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	return ret;
}

vector_int4 vector_make_int4(int x, int y, int z, int w) {
	vector_int4 ret;
	ret.x = x;
	ret.y = y;
	ret.z = z;
	ret.w = w;
	return ret;
}

// add two 3D vectors
vector_float3 AddVectors(vector_float3 v1, vector_float3 v2) {
    vector_float3 ret;
    ret.x = v1.x + v2.x;
    ret.y = v1.y + v2.y;
    ret.z = v1.z + v2.z;
    return ret;
}

vector_float3 SubtractVectors(vector_float3 v1, vector_float3 v2) {
    vector_float3 ret;
    ret.x = v1.x - v2.x;
    ret.y = v1.y - v2.y;
    ret.z = v1.z - v2.z;
    return ret;
}

// calculate cross product of 3D triangle
vector_float3 cross_product (vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    vector_float3 u = vector_float3(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z);
    vector_float3 v = vector_float3(p3.x - p1.x, p3.y - p1.y, p3.z - p1.z);
    
    return vector_float3(u.y*v.z - u.z*v.y, u.z*v.x - u.x*v.z, u.x*v.y - u.y*v.x);
}

// calculate cross product of 3D vectors
vector_float3 cross_vectors(vector_float3 p1, vector_float3 p2) {
    vector_float3 cross;
    cross.x = p1.y*p2.z - p1.z*p2.y;
    cross.y = -(p1.x*p2.z - p1.z*p2.x);
    cross.z = p1.x*p2.y - p1.y*p2.x;
    return cross;
}

// calculate projection
float projection (vector_float3 v1, vector_float3 v2) {
    float dot = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
    float mag = sqrt(pow(v2.x, 2) + pow(v2.y, 2) + pow(v2.z, 2));
    return dot / mag;
}

vector_float3 unit_vector(vector_float3 v) {
    float mag = sqrt(pow(v.x, 2) + pow(v.y, 2) + pow(v.z, 2));
    v.x /= mag;
    v.y /= mag;
    v.z /= mag;
    return v;
}

// calculate average of three 3D points
vector_float3 TriAvg (vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    float x = (p1.x + p2.x + p3.x)/3;
    float y = (p1.y + p2.y + p3.y)/3;
    float z = (p1.z + p2.z + p3.z)/3;
    
    return vector_float3(x, y, z);
}

// idk what this is tbh
float acos2(vector_float3 v1, vector_float3 v2) {
    float dot = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
    vector_float3 cross = cross_vectors(v1, v2);
    float det = sqrt(pow(cross.x, 2) + pow(cross.y, 2) + pow(cross.z, 2));
    return atan(det, dot);
}

// calculate angle between 3D vectors
float angle_between (vector_float3 v1, vector_float3 v2) {
    float mag1 = sqrt(pow(v1.x, 2) + pow(v1.y, 2) + pow(v1.z, 2));
    float mag2 = sqrt(pow(v2.x, 2) + pow(v2.y, 2) + pow(v2.z, 2));
    
    return acos((v1.x*v2.x + v1.y*v2.y + v1.z*v2.z) / (mag1 * mag2));
}

// TODO: make this not shit pls
// convert a 3d point to a pixel (vertex) value
vector_float3 PointToPixel (vector_float3 point, Camera camera)  {
    //vector from camera position to object position
    vector_float4 toObject;
    toObject.x = (point.x-camera.pos.x);
    toObject.y = (point.y-camera.pos.y);
    toObject.z = (point.z-camera.pos.z);
    toObject.w = (sqrt(pow(toObject.x, 2)+pow(toObject.y, 2)+pow(toObject.z, 2)));
    
    //project camera vector onto object vector
    float dotProduct = (toObject.x*camera.vector.x)+(toObject.y*camera.vector.y)+(toObject.z*camera.vector.z);
    vector_float4 proj;
    proj.x = dotProduct*camera.vector.x;
    proj.y = dotProduct*camera.vector.y;
    proj.z = dotProduct*camera.vector.z;
    proj.w = sqrt(pow(proj.x, 2)+pow(proj.y, 2)+pow(proj.z, 2));
    
    //subtract projected vector from the object vector to get the "on screen" vector
    vector_float4 distTo;
    distTo.x = toObject.x-proj.x;
    distTo.y = toObject.y-proj.y;
    distTo.z = toObject.z-proj.z;
    distTo.w = sqrt(pow(distTo.x, 2)+pow(distTo.y, 2)+pow(distTo.z, 2));
    
    //angle from vertical on screen - 0 is straight up - counterclockwise
    //use the plane of the camera with normal vector being where the camera is pointing
    //some method to find the angle between 2 vectors in 2pi radians
    //https://stackoverflow.com/questions/14066933/direct-way-of-computing-clockwise-angle-between-2-vectors/16544330#16544330
    
    float dotProductDistToAndCamUp = (distTo.x*camera.upVector.x)+(distTo.y*camera.upVector.y)+(distTo.z*camera.upVector.z);
    float det = (camera.upVector.x*distTo.y*camera.vector.z) + (distTo.x*camera.vector.y*camera.upVector.z) + (camera.vector.x*camera.upVector.y*distTo.z) - (camera.upVector.z*distTo.y*camera.vector.x) - (distTo.z*camera.vector.y*camera.upVector.x) - (camera.vector.z*camera.upVector.y*distTo.x);
    float angleBetween = atan(det, dotProductDistToAndCamUp);
    //TODO: add twist
    angleBetween = angleBetween/*-camera.vector.z*/;
    
    //find dimensions of the "screen rectangle" at the location of the object
    //FOV is the angle of the field of view - the whole screen
    float halfWidth = abs(proj.w*tan(camera.FOV.x/2));
    float halfHeight = abs(proj.w*tan(camera.FOV.y/2));
    
    //screen location of object
    float xLoc = -distTo.w*sin(angleBetween);
    float yLoc = distTo.w*cos(angleBetween);
    
    //get screen coordinates
    float screenX = 0;
    float screenY = 0;
    if (halfWidth != 0 && halfHeight != 0) {
        screenX = (xLoc)/(halfWidth);
        screenY = (yLoc)/(halfHeight);
    }
    
    // if dot product is negative then the vertex is behind
    if (dotProduct < 0) {
        return vector_float3(screenX, screenY, -proj.w/render_dist);
    }
    
    return vector_float3(screenX, screenY, proj.w/render_dist);
}

// rotate a point around a point
vector_float3 RotateAround (vector_float3 point, vector_float3 origin, vector_float3 angle) {
    vector_float3 vec;
    vec.x = point.x-origin.x;
    vec.y = point.y-origin.y;
    vec.z = point.z-origin.z;
    
    vector_float3 newvec;
    
    // gimbal locked
    
    // around z axis
    newvec.x = vec.x*cos(angle.z)-vec.y*sin(angle.z);
    newvec.y = vec.x*sin(angle.z)+vec.y*cos(angle.z);
    
    vec.x = newvec.x;
    vec.y = newvec.y;
    
    // around y axis
    newvec.x = vec.x*cos(angle.y)+vec.z*sin(angle.y);
    newvec.z = -vec.x*sin(angle.y)+vec.z*cos(angle.y);
    
    vec.x = newvec.x;
    vec.z = newvec.z;
    
    // around x axis
    newvec.y = vec.y*cos(angle.x)-vec.z*sin(angle.x);
    newvec.z = vec.y*sin(angle.x)+vec.z*cos(angle.x);
    
    vec.y = newvec.y;
    vec.z = newvec.z;
    
    point.x = origin.x+vec.x;
    point.y = origin.y+vec.y;
    point.z = origin.z+vec.z;
    
    return point;
}

// translate point from given basis to standard basis
vector_float3 TranslatePointToStandard(Basis b, vector_float3 point) {
    vector_float3 ret;
    // x component
    ret.x = point.x * b.x.x;
    ret.y = point.x * b.x.y;
    ret.z = point.x * b.x.z;
    // y component
    ret.x += point.y * b.y.x;
    ret.y += point.y * b.y.y;
    ret.z += point.y * b.y.z;
    // z component
    ret.x += point.z * b.z.x;
    ret.y += point.z * b.z.y;
    ret.z += point.z * b.z.z;
    
    ret.x += b.pos.x;
    ret.y += b.pos.y;
    ret.z += b.pos.z;
    
    return ret;
}

// translate point from standard basis to given basis
vector_float3 TranslatePointToBasis(Basis b, vector_float3 point) {
    vector_float3 ret;
    
    vector_float3 tobasis;
    tobasis.x = point.x - b.pos.x;
    tobasis.y = point.y - b.pos.y;
    tobasis.z = point.z - b.pos.z;
    
    ret.x = projection(tobasis, b.x);
    ret.y = projection(tobasis, b.y);
    ret.z = projection(tobasis, b.z);
    
    return ret;
};

// rotate point from given basis to standard basis (ignore basis translation offset)
vector_float3 RotatePointToStandard(Basis b, vector_float3 point) {
    vector_float3 ret;
    // x component
    ret.x = point.x * b.x.x;
    ret.y = point.x * b.x.y;
    ret.z = point.x * b.x.z;
    // y component
    ret.x += point.y * b.y.x;
    ret.y += point.y * b.y.y;
    ret.z += point.y * b.y.z;
    // z component
    ret.x += point.z * b.z.x;
    ret.y += point.z * b.z.y;
    ret.z += point.z * b.z.z;
    
    return ret;
}