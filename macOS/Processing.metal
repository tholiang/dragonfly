// TODO: CHANGE vec_ TYPES


//
//  Processing.metal
//  dragonfly
//
//  Created by Thomas Liang on 5/27/21.
//

#include <metal_stdlib>
using namespace metal;

constant float pi = 3.14159265358979;
constant float render_dist = 50;

struct vec_float2 {
    float x;
    float y;
};

struct vec_float3 {
    float x;
    float y;
    float z;
};

struct vec_float4 {
    float x;
    float y;
    float z;
    float w;
};

struct vec_int2 {
    int x;
    int y;
};

struct vec_int3 {
    int x;
    int y;
    int z;
};

struct vec_int4 {
    int x;
    int y;
    int z;
    int w;
};

typedef vec_float3 Vertex;
typedef vec_int3 UIVertex;
typedef vec_float2 Dot;

struct WindowAttributes {
    unsigned int width = 1280;
    unsigned int height = 720;
};

struct CompiledBufferKeyIndices {
    unsigned int compiled_vertex_size = 0;
    unsigned int compiled_vertex_scene_start = 0;
    unsigned int compiled_vertex_control_start = 0;
    unsigned int compiled_vertex_dot_start = 0;
    unsigned int compiled_vertex_node_circle_start = 0;
    unsigned int compiled_vertex_vertex_square_start = 0;
    unsigned int compiled_vertex_dot_square_start = 0;
    unsigned int compiled_vertex_slice_plate_start = 0;
    unsigned int compiled_vertex_ui_start = 0;
    
    unsigned int compiled_face_size = 0;
    unsigned int compiled_face_scene_start = 0;
    unsigned int compiled_face_control_start = 0;
    unsigned int compiled_face_node_circle_start = 0;
    unsigned int compiled_face_vertex_square_start = 0;
    unsigned int compiled_face_dot_square_start = 0;
    unsigned int compiled_face_slice_plate_start = 0;
    unsigned int compiled_face_ui_start = 0;
    
    unsigned int compiled_edge_size = 0;
    unsigned int compiled_edge_scene_start = 0;
    unsigned int compiled_edge_line_start = 0;
};

struct Basis {
    vec_float3 pos;
    // angles
    vec_float3 x;
    vec_float3 y;
    vec_float3 z;
};

struct Camera {
    vec_float3 pos;
    vec_float3 vector;
    vec_float3 upVector;
    vec_float2 FOV;
};

struct Face {
    unsigned int vertices[3];
    vec_float4 color;
    
    bool normal_reversed;
    vec_float3 lighting_offset; // if there were a light source directly in front of the face, this is the rotation to get to its brightest orientation
    float shading_multiplier;
};

struct UIElementTransform {
    vec_int3 position;
    vec_float3 up;
    vec_float3 right;
};

struct Node {
    int locked_to;
    Basis b;
};

struct NodeVertexLink {
    int nid;
    vec_float3 vector;
    float weight;
};

struct VertexOut {
    vector_float4 pos [[position]];
    vector_float4 color;
};

struct ModelTransform {
    vec_float3 rotate_origin;
    Basis b;
};

struct SliceAttributes {
    float width;
    float height;
};

// ---HELPER FUNCTIONS---
// vec
vec_float2 vec_make_float2(float x, float y) {
    vec_float2 ret;
    ret.x = x;
    ret.y = y;
    return ret;
}

vec_float3 vec_make_float3(float x, float y, float z) {
    vec_float3 ret;
    ret.x = x;
    ret.y = y;
    ret.z = z;
    return ret;
}

vec_float4 vec_make_float4(float x, float y, float z, int w) {
    vec_float4 ret;
    ret.x = x;
    ret.y = y;
    ret.z = z;
    ret.w = w;
    return ret;
}

vec_int2 vec_make_int2(int x, int y) {
    vec_int2 ret;
    ret.x = x;
    ret.y = y;
    return ret;
}

vec_int3 vec_make_int3(int x, int y, int z) {
    vec_int3 ret;
    ret.x = x;
    ret.y = y;
    ret.z = z;
    return ret;
}

vec_int4 vec_make_int4(int x, int y, int z, int w) {
    vec_int4 ret;
    ret.x = x;
    ret.y = y;
    ret.z = z;
    ret.w = w;
    return ret;
}

// add two 3D vectors
vec_float3 AddVectors(vec_float3 v1, vec_float3 v2) {
    vec_float3 ret;
    ret.x = v1.x + v2.x;
    ret.y = v1.y + v2.y;
    ret.z = v1.z + v2.z;
    return ret;
}

// calculate cross product of 3D triangle
vec_float3 cross_product (vec_float3 p1, vec_float3 p2, vec_float3 p3) {
    vec_float3 u = vec_make_float3(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z);
    vec_float3 v = vec_make_float3(p3.x - p1.x, p3.y - p1.y, p3.z - p1.z);
    
    return vec_make_float3(u.y*v.z - u.z*v.y, u.z*v.x - u.x*v.z, u.x*v.y - u.y*v.x);
}

// calculate cross product of 3D vectors
vec_float3 cross_vectors(vec_float3 p1, vec_float3 p2) {
    vec_float3 cross;
    cross.x = p1.y*p2.z - p1.z*p2.y;
    cross.y = -(p1.x*p2.z - p1.z*p2.x);
    cross.z = p1.x*p2.y - p1.y*p2.x;
    return cross;
}

// calculate average of three 3D points
vec_float3 TriAvg (vec_float3 p1, vec_float3 p2, vec_float3 p3) {
    float x = (p1.x + p2.x + p3.x)/3;
    float y = (p1.y + p2.y + p3.y)/3;
    float z = (p1.z + p2.z + p3.z)/3;
    
    return vec_make_float3(x, y, z);
}

// idk what this is tbh
float acos2(vec_float3 v1, vec_float3 v2) {
    float dot = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
    vec_float3 cross = cross_vectors(v1, v2);
    float det = sqrt(pow(cross.x, 2) + pow(cross.y, 2) + pow(cross.z, 2));
    return atan2(det, dot);
}

// calculate angle between 3D vectors
float angle_between (vec_float3 v1, vec_float3 v2) {
    float mag1 = sqrt(pow(v1.x, 2) + pow(v1.y, 2) + pow(v1.z, 2));
    float mag2 = sqrt(pow(v2.x, 2) + pow(v2.y, 2) + pow(v2.z, 2));
    
    return acos((v1.x*v2.x + v1.y*v2.y + v1.z*v2.z) / (mag1 * mag2));
}

// TODO: make this not shit pls
// convert a 3d point to a pixel (vertex) value
vec_float3 PointToPixel (vec_float3 point, constant Camera &camera)  {
    //vector from camera position to object position
    vec_float4 toObject;
    toObject.x = (point.x-camera.pos.x);
    toObject.y = (point.y-camera.pos.y);
    toObject.z = (point.z-camera.pos.z);
    toObject.w = (sqrt(pow(toObject.x, 2)+pow(toObject.y, 2)+pow(toObject.z, 2)));
    
    //project camera vector onto object vector
    float dotProduct = (toObject.x*camera.vector.x)+(toObject.y*camera.vector.y)+(toObject.z*camera.vector.z);
    vec_float4 proj;
    proj.x = dotProduct*camera.vector.x;
    proj.y = dotProduct*camera.vector.y;
    proj.z = dotProduct*camera.vector.z;
    proj.w = sqrt(pow(proj.x, 2)+pow(proj.y, 2)+pow(proj.z, 2));
    
    //subtract projected vector from the object vector to get the "on screen" vector
    vec_float4 distTo;
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
    float angleBetween = atan2(det, dotProductDistToAndCamUp);
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
        return vec_make_float3(screenX, screenY, -proj.w/render_dist);
    }
    
    return vec_make_float3(screenX, screenY, proj.w/render_dist);
}

// rotate a point around a point
vec_float3 RotateAround (vec_float3 point, vec_float3 origin, vec_float3 angle) {
    vec_float3 vec;
    vec.x = point.x-origin.x;
    vec.y = point.y-origin.y;
    vec.z = point.z-origin.z;
    
    vec_float3 newvec;
    
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
vec_float3 TranslatePointToStandard(Basis b, vec_float3 point) {
    vec_float3 ret;
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

// rotate point from given basis to standard basis (ignore basis translation offset)
vec_float3 RotatePointToStandard(Basis b, vec_float3 point) {
    vec_float3 ret;
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


// transform list of model (scene + control) nodes in Model Space to World Space
// operate per node
kernel void CalculateModelNodeTransforms(
    device Node *nodes [[buffer(0)]],
    const constant unsigned int *modelIDs [[buffer(1)]],
    const constant ModelTransform *uniforms [[buffer(2)]],
    unsigned int nid [[thread_position_in_grid]]
) {
    ModelTransform uniform = uniforms[modelIDs[nid]];
    nodes[nid].b.pos = TranslatePointToStandard(uniform.b, nodes[nid].b.pos);
    nodes[nid].b.x = RotatePointToStandard(uniform.b, nodes[nid].b.x);
    nodes[nid].b.y = RotatePointToStandard(uniform.b, nodes[nid].b.y);
    nodes[nid].b.z = RotatePointToStandard(uniform.b, nodes[nid].b.z);
}

// calculate model (scene + control) vertices in world space from node data and node vertex link data
// operate per output vertex - two nvlinks for each output vertex
kernel void CalculateVertices(
    device Vertex *vertices [[buffer(0)]],
    const constant NodeVertexLink *nvlinks [[buffer(1)]],
    const constant Node *nodes [[buffer(2)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    Vertex v = vec_make_float3(0,0,0);
    
    NodeVertexLink link1 = nvlinks[vid*2];
    NodeVertexLink link2 = nvlinks[vid*2 + 1];
    
    if (link1.nid != -1) {
        Node n = nodes[link1.nid];
        Vertex desired1 = TranslatePointToStandard(n.b, link1.vector);
        
        v.x += link1.weight*desired1.x;
        v.y += link1.weight*desired1.y;
        v.z += link1.weight*desired1.z;
    }
    
    if (link2.nid != -1) {
        Node n = nodes[link2.nid];
        Vertex desired2 = TranslatePointToStandard(n.b, link2.vector);
        
        v.x += link2.weight*desired2.x;
        v.y += link2.weight*desired2.y;
        v.z += link2.weight*desired2.z;
    }
    
    vertices[vid] = v;
}

// calculate projected vertices from model (scene + control) vertices
// operate per input/output vertex
kernel void CalculateProjectedVertices(
    device Vertex *compiled_vertices [[buffer(0)]],
    const constant Vertex *vertices [[buffer(1)]],
    constant Camera &camera [[buffer(2)]],
    const constant CompiledBufferKeyIndices *key_indices [[buffer(3)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    // calculate projected vertices and place into compiled buffer
    compiled_vertices[vid+key_indices->compiled_vertex_scene_start] = PointToPixel(vertices[vid], camera);
}

// calculate vertex squares from scene model projected vertices
// operate per projected vertex - output 4 vertices for each input vertex
kernel void CalculateVertexSquares(
    device Vertex *compiled_vertices [[buffer(0)]],
    device Face *compiled_faces [[buffer(1)]],
    const constant CompiledBufferKeyIndices *key_indices [[buffer(2)]],
    const constant WindowAttributes *window_attributes [[buffer(3)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    // get current projected vertex
    vec_float3 currentVertex = compiled_vertices[key_indices->compiled_vertex_scene_start+vid];
    
    // find index of the start of the 4 corner indices
    unsigned int square_vertex_start_index = key_indices->compiled_vertex_vertex_square_start+(vid*4);
    float screen_ratio = (float) window_attributes->height / window_attributes->width;
    
    // add to compiled vertices
    compiled_vertices[square_vertex_start_index+0] = vec_make_float3(currentVertex.x-0.007, currentVertex.y - 0.007/screen_ratio, currentVertex.z-0.01);
    compiled_vertices[square_vertex_start_index+1] = vec_make_float3(currentVertex.x-0.007, currentVertex.y + 0.007/screen_ratio, currentVertex.z-0.01);
    compiled_vertices[square_vertex_start_index+2] = vec_make_float3(currentVertex.x+0.007, currentVertex.y - 0.007/screen_ratio, currentVertex.z-0.01);
    compiled_vertices[square_vertex_start_index+3] = vec_make_float3(currentVertex.x+0.007, currentVertex.y + 0.007/screen_ratio, currentVertex.z-0.01);
    
    // add to compiled faces
    unsigned int square_face_start_index = key_indices->compiled_face_vertex_square_start+(vid*2);
    
    Face f1;
    f1.color = vec_make_float4(0,1,0,1);
    f1.vertices[0] = square_vertex_start_index+0;
    f1.vertices[1] = square_vertex_start_index+1;
    f1.vertices[2] = square_vertex_start_index+2;
    compiled_faces[square_face_start_index+0] = f1;

    Face f2;
    f2.color = vec_make_float4(0,1,0,1);
    f2.vertices[0] = square_vertex_start_index+1;
    f2.vertices[1] = square_vertex_start_index+2;
    f2.vertices[2] = square_vertex_start_index+3;
    compiled_faces[square_face_start_index+1] = f2;
}

// operate per dot
// output both scaled dot value and corner values to compiled vertex
kernel void CalculateScaledDots(
    device Vertex *compiled_vertices [[buffer(0)]],
    device Face *compiled_faces [[buffer(1)]],
    const constant Dot *dots[[buffer(2)]],
    const constant SliceAttributes *attr[[buffer(3)]],
    const constant WindowAttributes *window_attr[[buffer(4)]],
    const constant vec_float4 *edit_window [[buffer(5)]],
    const constant CompiledBufferKeyIndices *key_indices[[buffer(6)]],
    unsigned int did [[thread_position_in_grid]]
) {
    float scale = attr->height / 2;
    if (attr->height < attr->width) {
        scale = attr->width / 2;
    }
    
    // set dot in cvb
    float screen_ratio = (float) window_attr->height / window_attr->width;
    float eratio = edit_window->z / edit_window->w * screen_ratio;
    unsigned long cvb_dot_idx = key_indices->compiled_vertex_dot_start + did;
    Vertex scaled_dot;
    if (eratio < 1) {
        scaled_dot.x = dots[did].x / scale;
        scaled_dot.y = eratio * dots[did].y / scale;
    } else {
        scaled_dot.x = (dots[did].x / scale) / eratio;
        scaled_dot.y =  dots[did].y / scale;
    }
    scaled_dot.z = 0.5;
    
    scaled_dot.x *= edit_window->z;
    scaled_dot.y *= edit_window->w;
    scaled_dot.x += edit_window->x;
    scaled_dot.y += edit_window->y;
    compiled_vertices[cvb_dot_idx] = scaled_dot;
    
    
    // set (4) dot square corners in cvb
    unsigned long cvb_dot_corner_idx = key_indices->compiled_vertex_dot_square_start + did*4;
    compiled_vertices[cvb_dot_corner_idx+0] = vec_make_float3(scaled_dot.x-0.007, scaled_dot.y-0.007 * screen_ratio, scaled_dot.z-0.01);
    compiled_vertices[cvb_dot_corner_idx+1] = vec_make_float3(scaled_dot.x-0.007, scaled_dot.y+0.007 * screen_ratio, scaled_dot.z-0.01);
    compiled_vertices[cvb_dot_corner_idx+2] = vec_make_float3(scaled_dot.x+0.007, scaled_dot.y-0.007 * screen_ratio, scaled_dot.z-0.01);
    compiled_vertices[cvb_dot_corner_idx+3] = vec_make_float3(scaled_dot.x+0.007, scaled_dot.y+0.007 * screen_ratio, scaled_dot.z-0.01);
    
    // set (2) dot square faces in cfb
    unsigned long cfb_dot_square_idx = key_indices->compiled_face_dot_square_start + did*2;
    Face f1;
    f1.color = vec_make_float4(0, 1, 0, 1);
    f1.vertices[0] = cvb_dot_corner_idx+0;
    f1.vertices[1] = cvb_dot_corner_idx+1;
    f1.vertices[2] = cvb_dot_corner_idx+2;
    compiled_faces[cfb_dot_square_idx+0] = f1;
    
    Face f2;
    f2.color = vec_make_float4(0, 1, 0, 1);
    f2.vertices[0] = cvb_dot_corner_idx+1;
    f2.vertices[1] = cvb_dot_corner_idx+2;
    f2.vertices[2] = cvb_dot_corner_idx+3;
    compiled_faces[cfb_dot_square_idx+1] = f2;
    
    // TODO: SET SPECIAL COLOR FOR SELECTED DOTS
}

// operate per dot
// output both projected dot value and corner values to compiled vertex
kernel void CalculateProjectedDots(
    device Vertex *compiled_vertices [[buffer(0)]],
    device Face *compiled_faces [[buffer(1)]],
    const constant Dot *dots[[buffer(2)]],
    const constant ModelTransform *slice_transforms[[buffer(3)]],
    constant Camera &camera [[buffer(4)]],
    const constant unsigned int *dot_slice_ids[[buffer(5)]],
    const constant WindowAttributes *window_attr [[buffer(6)]],
    const constant CompiledBufferKeyIndices *key_indices [[buffer(7)]],
    unsigned int did [[thread_position_in_grid]]
) {
    // project dot to vertex
    Dot d = dots[did];
    Vertex dot3d; // need to make intermediate vertex to call function
    dot3d.x = d.x;
    dot3d.y = d.y;
    dot3d.z = 0;
    
    int sid = dot_slice_ids[did];
    dot3d = TranslatePointToStandard(slice_transforms[sid].b, dot3d);
    
    // set dot in cvb
    unsigned long cvb_dot_idx = key_indices->compiled_vertex_dot_start + did;
    Vertex proj_dot;
    
    proj_dot = PointToPixel(dot3d, camera);
    proj_dot.z -= 0.01;
    compiled_vertices[cvb_dot_idx] = proj_dot;
    
    // set (4) dot square corners in cvb
    float screen_ratio = (float) window_attr->height / window_attr->width;
    unsigned long cvb_dot_corner_idx = key_indices->compiled_vertex_dot_square_start + did*4;
    compiled_vertices[cvb_dot_corner_idx+0] = vec_make_float3(proj_dot.x-0.007, proj_dot.y-0.007 * screen_ratio, proj_dot.z-0.01);
    compiled_vertices[cvb_dot_corner_idx+1] = vec_make_float3(proj_dot.x-0.007, proj_dot.y+0.007 * screen_ratio, proj_dot.z-0.01);
    compiled_vertices[cvb_dot_corner_idx+2] = vec_make_float3(proj_dot.x+0.007, proj_dot.y-0.007 * screen_ratio, proj_dot.z-0.01);
    compiled_vertices[cvb_dot_corner_idx+3] = vec_make_float3(proj_dot.x+0.007, proj_dot.y+0.007 * screen_ratio, proj_dot.z-0.01);
    
    // set (2) dot square faces in cfb
    unsigned long cfb_dot_square_idx = key_indices->compiled_face_dot_square_start + did*2;
    Face f1;
    f1.color = vec_make_float4(0, 1, 0, 1);
    f1.vertices[0] = cvb_dot_corner_idx+0;
    f1.vertices[1] = cvb_dot_corner_idx+1;
    f1.vertices[2] = cvb_dot_corner_idx+2;
    compiled_faces[cfb_dot_square_idx+0] = f1;
    
    Face f2;
    f2.color = vec_make_float4(0, 1, 0, 1);
    f2.vertices[0] = cvb_dot_corner_idx+1;
    f2.vertices[1] = cvb_dot_corner_idx+2;
    f2.vertices[2] = cvb_dot_corner_idx+3;
    compiled_faces[cfb_dot_square_idx+1] = f2;
}

// operate per node
// output projected node circle vertices and faces
kernel void CalculateProjectedNodes(
    device Vertex *compiled_vertices [[buffer(0)]],
    device Face *compiled_faces [[buffer(1)]],
    const constant Node *nodes [[buffer(2)]],
    constant Camera &camera [[buffer(3)]],
    const constant WindowAttributes *window_attr [[buffer(4)]],
    const constant CompiledBufferKeyIndices *key_indices [[buffer(5)]],
    unsigned int nid [[thread_position_in_grid]]
) {
    float screen_ratio = (float) window_attr->height / window_attr->width;
    
    // get projected node vertex
    Vertex proj_node_center = PointToPixel(nodes[nid].b.pos, camera);
    
    // add circle vertices to cvb abd faces to cfb
    unsigned long cvb_node_circle_idx = key_indices->compiled_vertex_node_circle_start+nid*9;
    unsigned long cfb_node_circle_idx = key_indices->compiled_face_node_circle_start+nid*8;
    
    // center
    compiled_vertices[cvb_node_circle_idx+0] = proj_node_center;
    
    // circle vertices and faces
    for (int i = 0; i < 8; i++) {
        // make radius smaller the farther away
        float radius = 1/(500*proj_node_center.z);
        // get angle from index
        float angle = i*pi/4;
        
        // calculate value (with trig) and add to cvb
        compiled_vertices[cvb_node_circle_idx+1+i] = vec_make_float3(proj_node_center.x + radius * cos(angle), proj_node_center.y + (radius * sin(angle) / screen_ratio), proj_node_center.z+0.05);
        
        // add face to cfb
        Face f;
        f.color = vec_make_float4(0.8, 0.8, 0.9, 1);
        f.vertices[0] = cvb_node_circle_idx; // center
        f.vertices[1] = cvb_node_circle_idx+1+i; // just added vertex
        f.vertices[2] = cvb_node_circle_idx+(1+(1+i)%8); // next vertex (or first added if at the end)
        compiled_faces[cfb_node_circle_idx+i] = f;
    }
}

// operate per face (of scene models only)
// output lit faces into compiled face buffer
kernel void CalculateFaceLighting(
   device Face *compiled_faces [[buffer(0)]],
   const constant Face *faces[[buffer(1)]],
   const constant Vertex *vertices [[buffer(2)]],
   const constant Vertex *light[[buffer(3)]],
   const constant CompiledBufferKeyIndices *key_indices[[buffer(4)]],
   unsigned int fid[[thread_position_in_grid]]
) {
    // get scene face and calculate normal
    Face f = faces[fid];
    vec_float3 f_norm = cross_product(vertices[f.vertices[0]], vertices[f.vertices[1]], vertices[f.vertices[2]]);
    if (f.normal_reversed) {
        f_norm.x *= -1;
        f_norm.y *= -1;
        f_norm.z *= -1;
    }
    
    // get angle between normal and light
    Vertex center = TriAvg(vertices[f.vertices[0]], vertices[f.vertices[1]], vertices[f.vertices[2]]);
    vec_float3 vec_to = vec_make_float3(light->x - center.x, light->y - center.y, light->z - center.z);
    float ang = abs(acos2(f_norm, vec_to));
    // make darker the larger the angle - considering the shading multiplier
    f.color.x /= ang * f.shading_multiplier;
    f.color.y /= ang * f.shading_multiplier;
    f.color.z /= ang * f.shading_multiplier;
    
    // set face in compiled face buffer
    unsigned long cfb_scene_face_idx = key_indices->compiled_face_scene_start+fid;
    compiled_faces[cfb_scene_face_idx] = f;
}

// operate per slice
// output (4) corner vertices to compiled vertex buffer and (2) plate faces to compiled face buffer
kernel void CalculateSlicePlates (
    device Vertex *compiled_vertices [[buffer(0)]],
    device Face *compiled_faces [[buffer(1)]],
    const constant ModelTransform *slice_transforms[[buffer(2)]],
    const constant SliceAttributes *attr[[buffer(3)]],
    constant Camera &camera [[buffer(4)]],
    const constant CompiledBufferKeyIndices *key_indices[[buffer(5)]],
    unsigned int sid [[thread_position_in_grid]]
) {
    // get slice attributes and transform
    SliceAttributes sa = attr[sid];
    ModelTransform st = slice_transforms[sid];
    
    // calculate vertices in slice space
    Vertex v1 = vec_make_float3(sa.width/2, sa.height/2, 0);
    Vertex v2 = vec_make_float3(sa.width/2, -sa.height/2, 0);
    Vertex v3 = vec_make_float3(-sa.width/2, sa.height/2, 0);
    Vertex v4 = vec_make_float3(-sa.width/2, -sa.height/2, 0);
    
    // translate to world space from slice transform
    v1 = TranslatePointToStandard(st.b, v1);
    v2 = TranslatePointToStandard(st.b, v2);
    v3 = TranslatePointToStandard(st.b, v3);
    v4 = TranslatePointToStandard(st.b, v4);
    
    // project vertices
    v1 = PointToPixel(v1, camera);
    v1.z += 0.1;
    v2 = PointToPixel(v2, camera);
    v2.z += 0.1;
    v3 = PointToPixel(v3, camera);
    v3.z += 0.1;
    v4 = PointToPixel(v4, camera);
    v4.z += 0.1;
    
    // add vertices to cvb
    unsigned long cvb_slice_plate_idx = key_indices->compiled_vertex_slice_plate_start+sid*4;
    compiled_vertices[cvb_slice_plate_idx+0] = v1;
    compiled_vertices[cvb_slice_plate_idx+1] = v2;
    compiled_vertices[cvb_slice_plate_idx+2] = v3;
    compiled_vertices[cvb_slice_plate_idx+3] = v4;
    
    // add faces to cfb
    unsigned long cfb_slice_plate_idx = key_indices->compiled_face_slice_plate_start+sid*2;
    Face f1;
    f1.color = vec_make_float4(0.7, 0.7, 0.7, 1);
    f1.vertices[0] = cvb_slice_plate_idx+0;
    f1.vertices[1] = cvb_slice_plate_idx+1;
    f1.vertices[2] = cvb_slice_plate_idx+2;
    compiled_faces[cfb_slice_plate_idx+0] = f1;
    
    Face f2;
    f2.color = vec_make_float4(0.7, 0.7, 0.7, 1);
    f2.vertices[0] = cvb_slice_plate_idx+1;
    f2.vertices[1] = cvb_slice_plate_idx+2;
    f2.vertices[2] = cvb_slice_plate_idx+3;
    compiled_faces[cfb_slice_plate_idx+1] = f2;
}

// operate per ui vertex
// output converted and scaled vertex to compiled vertex buffer
kernel void CalculateUIVertices (
    device Vertex *compiled_vertices [[buffer(0)]],
    const constant UIVertex *ui_vertices[[buffer(1)]],
    const constant unsigned int *element_ids[[buffer(2)]],
    const constant UIElementTransform *element_transforms[[buffer(3)]],
    const constant WindowAttributes *window_attr[[buffer(4)]],
    const constant CompiledBufferKeyIndices *key_indices[[buffer(5)]],
    unsigned int vid [[thread_position_in_grid]]
) {
    // get ui vertex
    UIVertex v = ui_vertices[vid];
    // get transform
    UIElementTransform et = element_transforms[element_ids[vid]];
    // create vertex and set to start of element transform space (in world space)
    Vertex ret;
    ret.x = et.position.x;
    ret.y = et.position.y;
    ret.z = 0.01+float(et.position.z + v.z)/100;
    
    // transform to vertex location (account for rotated element with right and up vectors)
    ret.x += et.right.x * v.x + et.up.x * v.y;
    ret.y += et.right.y * v.x + et.up.y * v.y;

    // convert to screen coords
    ret.x /= window_attr->width/2;
    ret.y /= window_attr->height/2;
    
    // set in compiled vertex buffer
    unsigned long cvb_ui_start = key_indices->compiled_vertex_ui_start+vid;
    compiled_vertices[vid] = ret;
}

// vertex shader with set color (white)
// takes 3D vertex and outputs location exactly
vertex VertexOut SuperDefaultVertexShader (
    const constant vec_float3 *vertex_array [[buffer(0)]],
    unsigned int vid [[vertex_id]]
) {
    vec_float3 currentVertex = vertex_array[vid];
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    output.color = vector_float4(1, 1, 1, 1);
    return output;
}

// default vertex shader for faces
// operates per each vertex index given in every face
// outputs vertex location exactly and with face color
vertex VertexOut DefaultFaceShader (
    const constant vec_float3 *vertex_array [[buffer(0)]],
    const constant Face *face_array[[buffer(1)]],
    unsigned int vid [[vertex_id]]
) {
    // get current face - 3 vertices per face
    Face currentFace = face_array[vid/3];
    // get current vertex in face
    vec_float3 currentVertex = vertex_array[currentFace.vertices[vid%3]];
    
    // make and return output vertex
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    output.color = vector_float4(currentFace.color.x, currentFace.color.y, currentFace.color.z, currentFace.color.w);
    output.pos.z += 0.1;
    return output;
}

// default vertex shader for edges with set color (blue)
// operates per face * 4 - need 4 vertices for the 3 edges in a face
// outputs vertex location exactly
vertex VertexOut SuperDefaultEdgeShader (
     const constant vec_float3 *vertex_array [[buffer(0)]],
     const constant vec_int2 *edge_array[[buffer(1)]],
     unsigned int vid [[vertex_id]]
 ) {
     // get current edge - 2 vertices to each edge
     vec_int2 current_edge = edge_array[vid/2];
     
     // get vertex and output
     Vertex currentVertex;
     if (vid % 2 == 0) currentVertex = vertex_array[current_edge.x];
     else currentVertex = vertex_array[current_edge.y];
     VertexOut output;
     output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z+0.099, 1);
     output.color = vector_float4(0, 0, 1, 1);
     return output;
}

// fragment shader - return interpolated color exactly
fragment vector_float4 FragmentShader(
    VertexOut interpolated [[stage_in]]
) {
    return interpolated.color;
}


// UNUSED
/*vertex VertexOut UIVertexShader (const constant vec_float3 *vertex_array [[buffer(0)]], const constant UIFace *face_array[[buffer(1)]], unsigned int vid [[vertex_id]]) {
    UIFace currentFace = face_array[vid/3];
    vec_float3 currentVertex = vertex_array[currentFace.vertices[vid%3]];
    VertexOut output;
    output.pos = vec_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    output.color = currentFace.color;
    return output;
}

vertex VertexOut LineShader (const constant vec_float3 *vertex_array [[buffer(0)]], const constant Line *line_array[[buffer(1)]], unsigned int vid [[vertex_id]]) {
    Line currentLine = line_array[vid/2];
    vec_float3 currentVertex = vertex_array[currentLine.did[vid%2]];
    VertexOut output;
    output.pos = vec_float4(currentVertex.x, currentVertex.y, currentVertex.z-0.0001, 1);
    output.color = vec_float4(0, 0, 1, 1);
    
    output.pos.z += 0.1;
    return output;
}

vertex VertexOut VertexPointShader (const constant vec_float3 *vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]], const constant VertexRenderUniforms *uniforms [[buffer(1)]], const constant int *selected_vertices [[buffer(2)]]) {
    vec_float3 currentVertex = vertex_array[vid/4];
    VertexOut output;
    if (vid % 4 == 0) {
        output.pos = vec_float4(currentVertex.x-0.007, currentVertex.y-0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else if (vid % 4 == 1) {
        output.pos = vec_float4(currentVertex.x-0.007, currentVertex.y+0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else if (vid % 4 == 2) {
        output.pos = vec_float4(currentVertex.x+0.007, currentVertex.y-0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else {
        output.pos = vec_float4(currentVertex.x+0.007, currentVertex.y+0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    }
    
    bool is_selected = false;
    for (int i = 0; i < uniforms->num_selected_vertices; i++) {
        if (vid/4 == selected_vertices[i]) {
            output.color = vec_float4(1, 0.5, 0, 1);
            is_selected = true;
            break;
        }
    }
    if (!is_selected) {
        output.color = vec_float4(0, 1, 0, 1);
    }
    output.pos.z += 0.1;
    return output;
}

vertex VertexOut DotShader (const constant vec_float3 *vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]], const constant VertexRenderUniforms *uniforms [[buffer(1)]]) {
    vec_float3 currentVertex = vertex_array[vid/4];
    VertexOut output;
    if (vid % 4 == 0) {
        output.pos = vec_float4(currentVertex.x-0.007, currentVertex.y-0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else if (vid % 4 == 1) {
        output.pos = vec_float4(currentVertex.x-0.007, currentVertex.y+0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else if (vid % 4 == 2) {
        output.pos = vec_float4(currentVertex.x+0.007, currentVertex.y-0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else {
        output.pos = vec_float4(currentVertex.x+0.007, currentVertex.y+0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    }
    
    output.color = vec_float4(0, 1, 0, 1);
    output.pos.z += 0.1;
    return output;
}

vertex VertexOut NodeShader (const constant Vertex *node_array [[buffer(0)]], unsigned int vid [[vertex_id]], const constant NodeRenderUniforms *uniforms [[buffer(1)]]) {
    // 20 side "circle"
    Vertex currentNode = node_array[vid/40];
    VertexOut output;
    
    int angle_idx = vid % 40;
    int type_idx = vid % 4;
    
    float radius = (1/currentNode.z) / 500;
    float angle;
    
    if (type_idx == 0) {
        angle = (float) (angle_idx) * pi / 20;
    } else if (type_idx == 1) {
        angle = 0;
        radius = 0;
    } else {
        angle = (float) (angle_idx+1) * pi / 20;
    }
    
    output.pos = vec_float4(currentNode.x + radius * cos(angle), currentNode.y + (radius * sin(angle) * uniforms->screen_ratio), currentNode.z-0.01, 1);
    
    if (vid/40 == uniforms->selected_node) {
        output.color = vec_float4(1, 0.5, 0, 1);
    } else {
        output.color = vec_float4(0.8, 0.8, 0.9, 1);
    }
    
    output.pos.z += 0.1;
    return output;
}

kernel void ResetVertices (device Vertex *vertices [[buffer(0)]], unsigned int vid [[thread_position_in_grid]]) {
    vertices[vid] = vec_float3(0,0,0);
}

float sign (vec_float2 p1, vec_float3 p2, vec_float3 p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

float dist (vec_float2 p1, vec_float3 p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
}

float WeightedZ (vec_float2 click, vec_float3 p1, vec_float3 p2, vec_float3 p3) {
    float dist1 = dist(click, p1);
    float dist2 = dist(click, p2);
    float dist3 = dist(click, p3);
    
    float total_dist = dist1 + dist2 + dist3;
    float weightedZ = p1.z*(dist1/total_dist);
    weightedZ += p2.z*(dist2/total_dist);
    weightedZ += p3.z*(dist3/total_dist);
    return weightedZ;
}

kernel void FaceClicked(device int &clickedIdx [[buffer(0)]], device float &minZ [[buffer(1)]], unsigned int fid [[thread_position_in_grid]], constant vec_float2 &clickLoc [[buffer(2)]], const constant vec_float3 *vertices [[buffer(3)]], device Face *face_array[[buffer(4)]]) {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    Face face = face_array[fid];
    vec_float3 v1 = vertices[face.vertices[0]];
    vec_float3 v2 = vertices[face.vertices[1]];
    vec_float3 v3 = vertices[face.vertices[2]];

    d1 = sign(clickLoc, v1, v2);
    d2 = sign(clickLoc, v2, v3);
    d3 = sign(clickLoc, v3, v1);

    has_neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    has_pos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    if (!(has_neg && has_pos)) {
        float z = WeightedZ(clickLoc, v1, v2, v3);
        if (minZ == -1) {
            minZ = z;
            clickedIdx = fid;
        } else if (z < minZ) {
            minZ = z;
            clickedIdx = fid;
        }
    }
}*/

/*vertex VertexOut ProjectionCalculationVertexShader (const constant vec_float3 *vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]], const constant vec_float4 *color_array [[buffer(1)]], constant Camera &camera [[buffer(2)]]) {
    vec_float3 currentVertex = vertex_array[vid];
    VertexOut output;
    
    vec_float3 pixel = PointToPixel(currentVertex, camera);
    
    output.pos = vec_float4(pixel.x, pixel.y, pixel.z, 1.0);
    
    output.color = color_array[vid/4];
    
    return output;
}*/
