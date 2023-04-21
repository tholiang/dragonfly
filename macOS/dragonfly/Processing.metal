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

typedef simd_float3 Vertex;
typedef simd_float2 Dot;

struct Basis {
    simd_float3 pos;
    // angles
    simd_float3 x;
    simd_float3 y;
    simd_float3 z;
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
    
    bool normal_reversed;
    simd_float3 lighting_offset; // if there were a light source directly in front of the face, this is the rotation to get to its brightest orientation
    float shading_multiplier;
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

struct VertexOut {
    vector_float4 pos [[position]];
    vector_float4 color;
};

struct ModelUniforms {
    vector_float3 rotate_origin;
    Basis b;
};

struct Uniforms {
    unsigned int numFaces;
    unsigned int selectedFace;
};

struct VertexRenderUniforms {
    float screen_ratio;
    int num_selected_vertices;
};

struct NodeRenderUniforms {
    float screen_ratio;
    int selected_node;
};

struct SliceAttributes {
    float width;
    float height;
};

struct Line {
    unsigned int did[2];
};

/*struct EdgeRenderUniforms {
    vector_int2 selected_edge;
};*/

//convert a 3d point to a pixel (vertex) value
vector_float3 PointToPixel (vector_float3 point, constant Camera &camera)  {
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
        return vector_float3(screenX, screenY, -proj.w/render_dist);
    }
    
    return vector_float3(screenX, screenY, proj.w/render_dist);
}

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

simd_float3 TranslatePointToStandard(Basis b, simd_float3 point) {
    simd_float3 ret;
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

simd_float3 RotatePointToStandard(Basis b, simd_float3 point) {
    simd_float3 ret;
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

simd_float3 AddVectors(simd_float3 v1, simd_float3 v2) {
    simd_float3 ret;
    ret.x = v1.x + v2.x;
    ret.y = v1.y + v2.y;
    ret.z = v1.z + v2.z;
}

vector_float3 cross_product (vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    vector_float3 u = vector_float3(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z);
    vector_float3 v = vector_float3(p3.x - p1.x, p3.y - p1.y, p3.z - p1.z);
    
    return vector_float3(u.y*v.z - u.z*v.y, u.z*v.x - u.x*v.z, u.x*v.y - u.y*v.x);
}

vector_float3 cross_vectors(vector_float3 p1, vector_float3 p2) {
    vector_float3 cross;
    cross.x = p1.y*p2.z - p1.z*p2.y;
    cross.y = -(p1.x*p2.z - p1.z*p2.x);
    cross.z = p1.x*p2.y - p1.y*p2.x;
    return cross;
}

vector_float3 TriAvg (vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    float x = (p1.x + p2.x + p3.x)/3;
    float y = (p1.y + p2.y + p3.y)/3;
    float z = (p1.z + p2.z + p3.z)/3;
    
    return vector_float3(x, y, z);
}

float acos2(vector_float3 v1, vector_float3 v2) {
    float dot = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
    simd_float3 cross = cross_vectors(v1, v2);
    float det = sqrt(pow(cross.x, 2) + pow(cross.y, 2) + pow(cross.z, 2));
    return atan2(det, dot);
}

float angle_between (vector_float3 v1, vector_float3 v2) {
    float mag1 = sqrt(pow(v1.x, 2) + pow(v1.y, 2) + pow(v1.z, 2));
    float mag2 = sqrt(pow(v2.x, 2) + pow(v2.y, 2) + pow(v2.z, 2));
    
    return acos((v1.x*v2.x + v1.y*v2.y + v1.z*v2.z) / (mag1 * mag2));
}

kernel void ResetVertices (device Vertex *vertices [[buffer(0)]], unsigned int vid [[thread_position_in_grid]]) {
    vertices[vid] = vector_float3(0,0,0);
}

kernel void CalculateModelNodeTransforms(device Node *nodes [[buffer(0)]], unsigned int vid [[thread_position_in_grid]], const constant unsigned int *modelIDs [[buffer(1)]], const constant ModelUniforms *uniforms [[buffer(2)]]) {
    ModelUniforms uniform = uniforms[modelIDs[vid]];
//    vector_float3 offset_node = nodes[vid].b.pos;
//    offset_node.x += uniform.b.pos.x;
//    offset_node.y += uniform.b.pos.y;
//    offset_node.z += uniform.b.pos.z;
//    nodes[vid].pos = RotateAround(offset_node, uniform.rotate_origin, uniform.angle);
    nodes[vid].b.pos = TranslatePointToStandard(uniform.b, nodes[vid].b.pos);
    nodes[vid].b.x = RotatePointToStandard(uniform.b, nodes[vid].b.x);
    nodes[vid].b.y = RotatePointToStandard(uniform.b, nodes[vid].b.y);
    nodes[vid].b.z = RotatePointToStandard(uniform.b, nodes[vid].b.z);
    
//    nodes[vid].angle.x += uniform.angle.x;
//    nodes[vid].angle.y += uniform.angle.y;
//    nodes[vid].angle.z += uniform.angle.z;
}

kernel void CalculateVertices(device Vertex *vertices [[buffer(0)]], const constant NodeVertexLink *nvlinks [[buffer(1)]], unsigned int vid [[thread_position_in_grid]], const constant Node *nodes [[buffer(2)]]) {
    Vertex v = vector_float3(0,0,0);
    
    NodeVertexLink link1 = nvlinks[vid*2];
    NodeVertexLink link2 = nvlinks[vid*2 + 1];
    
    if (link1.nid != -1) {
        Node n = nodes[link1.nid];
        
//        Vertex desired1 = vector_float3(n.pos.x + link1.vector.x, n.pos.y + link1.vector.y, n.pos.z + link1.vector.z);
//        desired1 = RotateAround(desired1, n.pos, n.angle);
        Vertex desired1 = TranslatePointToStandard(n.b, link1.vector);
        
        v.x += link1.weight*desired1.x;
        v.y += link1.weight*desired1.y;
        v.z += link1.weight*desired1.z;
    }
    
    if (link2.nid != -1) {
        Node n = nodes[link2.nid];
        
//        Vertex desired2 = vector_float3(n.pos.x + link2.vector.x, n.pos.y + link2.vector.y, n.pos.z + link2.vector.z);
//        desired2 = RotateAround(desired2, n.pos, n.angle);
        Vertex desired2 = TranslatePointToStandard(n.b, link2.vector);
        
        v.x += link2.weight*desired2.x;
        v.y += link2.weight*desired2.y;
        v.z += link2.weight*desired2.z;
    }
    
    vertices[vid] = v;
}

kernel void CalculateProjectedVertices(device vector_float3 *output [[buffer(0)]], const constant Vertex *vertices [[buffer(1)]], unsigned int vid [[thread_position_in_grid]], constant Camera &camera [[buffer(2)]]) {
    output[vid] = PointToPixel(vertices[vid], camera);
}

kernel void CalculateProjectedNodes(device vector_float3 *output [[buffer(0)]], device Node *nodes [[buffer(1)]], unsigned int vid [[thread_position_in_grid]], constant Camera &camera [[buffer(2)]]) {
    output[vid] = PointToPixel(nodes[vid].b.pos, camera);
}

kernel void CalculateFaceLighting(device Face *output [[buffer(0)]], const constant Face *faces[[buffer(1)]], const constant Vertex *vertices [[buffer(2)]], const constant Vertex *light[[buffer(3)]], unsigned int fid[[thread_position_in_grid]]) {
    Face f = faces[fid];
    vector_float3 f_norm = cross_product(vertices[f.vertices[0]], vertices[f.vertices[1]], vertices[f.vertices[2]]);
    if (f.normal_reversed) {
        f_norm.x *= -1;
        f_norm.y *= -1;
        f_norm.z *= -1;
    }
    Vertex center = TriAvg(vertices[f.vertices[0]], vertices[f.vertices[1]], vertices[f.vertices[2]]);
    vector_float3 vec_to = vector_float3(light->x - center.x, light->y - center.y, light->z - center.z);
    float ang = abs(acos2(f_norm, vec_to));
    f.color.x /= ang * f.shading_multiplier;
    f.color.y /= ang * f.shading_multiplier;
    f.color.z /= ang * f.shading_multiplier;
    
    output[fid] = f;
}

kernel void CalculateScaledDots(device Vertex *output [[buffer(0)]], const constant Dot *dots[[buffer(1)]], const constant SliceAttributes *attr[[buffer(2)]], const constant VertexRenderUniforms *uniforms [[buffer(3)]], const constant simd_float4 *edit_window [[buffer(4)]], unsigned int did [[thread_position_in_grid]]) {
    float scale = attr->height / 2;
    if (attr->height < attr->width) {
        scale = attr->width / 2;
    }
    float eratio = edit_window->z / edit_window->w * uniforms->screen_ratio;
    if (eratio < 1) {
        output[did].x = dots[did].x / scale;
        output[did].y = eratio * dots[did].y / scale;
    } else {
        output[did].x = (dots[did].x / scale) / eratio;
        output[did].y =  dots[did].y / scale;
    }
    output[did].z = 0.5;
    
    output[did].x *= edit_window->z;
    output[did].y *= edit_window->w;
    output[did].x += edit_window->x;
    output[did].y += edit_window->y;
}

kernel void CalculateProjectedDots(device Vertex *output [[buffer(0)]], const constant Dot *dots[[buffer(1)]], const constant ModelUniforms *model_uniforms[[buffer(2)]], const constant int *dot_slice_links[[buffer(3)]], const constant SliceAttributes *attr[[buffer(4)]], const constant VertexRenderUniforms *uniforms [[buffer(5)]], constant Camera &camera [[buffer(6)]], unsigned int did [[thread_position_in_grid]]) {
    Dot d = dots[did];
    Vertex dot3d;
    dot3d.x = d.x;
    dot3d.y = d.y;
    dot3d.z = 0;
    
    int sid = dot_slice_links[did];
    dot3d = TranslatePointToStandard(model_uniforms[sid].b, dot3d);
    
    output[did] = PointToPixel(dot3d, camera);
}

kernel void CalculateSlicePlates (device Vertex *output [[buffer(0)]], const constant ModelUniforms *model_uniforms[[buffer(1)]], const constant SliceAttributes *attr[[buffer(2)]], constant Camera &camera [[buffer(3)]], unsigned int vid [[thread_position_in_grid]]) {
    unsigned int sid = vid/6;
    unsigned int svid = vid%6;
    
    Vertex v;
    SliceAttributes sa = attr[sid];
    
    if (svid == 0 || svid == 3) {
        v.x = sa.width/2;
        v.y = sa.height/2;
    } else if (svid == 1) {
        v.x = sa.width/2;
        v.y = -sa.height/2;
    } else if (svid == 4) {
        v.x = -sa.width/2;
        v.y = sa.height/2;
    } else {
        v.x = -sa.width/2;
        v.y = -sa.height/2;
    }
    
    v.z = 0;
    
    v = TranslatePointToStandard(model_uniforms[sid].b, v);
    v = PointToPixel(v, camera);
    v.z += 0.01;
    
    output[vid] = v;
}

vertex VertexOut SuperDefaultVertexShader (const constant vector_float3 *vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]]) {
    vector_float3 currentVertex = vertex_array[vid];
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    output.color = vector_float4(1, 1, 1, 1);
    return output;
}

vertex VertexOut DefaultVertexShader (const constant vector_float3 *vertex_array [[buffer(0)]], const constant Face *face_array[[buffer(1)]], unsigned int vid [[vertex_id]]) {
    Face currentFace = face_array[vid/3];
    vector_float3 currentVertex = vertex_array[currentFace.vertices[vid%3]];
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z, 1);
    output.color = currentFace.color;
    return output;
}

vertex VertexOut VertexEdgeShader (const constant vector_float3 *vertex_array [[buffer(0)]], const constant Face *face_array[[buffer(1)]]/*, const constant EdgeRenderUniforms *uniforms [[buffer(2)]]*/, unsigned int vid [[vertex_id]]) {
    Face currentFace = face_array[vid/4];
    vector_float3 currentVertex = vertex_array[currentFace.vertices[vid%3]];
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z-0.0001, 1);
    output.color = vector_float4(0, 0, 1, 1);
    
    /*if (uniforms->selected_edge.x == currentFace.vertices[vid%3] && uniforms->selected_edge.y == currentFace.vertices[(vid+1)%3]) {
        output.color = vector_float4(1, 0.5, 0, 1);
    }
    
    if (uniforms->selected_edge.y == currentFace.vertices[(vid)%3] && uniforms->selected_edge.x == currentFace.vertices[(vid-1)%3]) {
        output.color = vector_float4(1, 0.5, 0, 1);
    }*/
    return output;
}

vertex VertexOut LineShader (const constant vector_float3 *vertex_array [[buffer(0)]], const constant Line *line_array[[buffer(1)]], unsigned int vid [[vertex_id]]) {
    Line currentLine = line_array[vid/2];
    vector_float3 currentVertex = vertex_array[currentLine.did[vid%2]];
    VertexOut output;
    output.pos = vector_float4(currentVertex.x, currentVertex.y, currentVertex.z-0.0001, 1);
    output.color = vector_float4(0, 0, 1, 1);
    
    return output;
}

vertex VertexOut VertexPointShader (const constant vector_float3 *vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]], const constant VertexRenderUniforms *uniforms [[buffer(1)]], const constant int *selected_vertices [[buffer(2)]]) {
    vector_float3 currentVertex = vertex_array[vid/4];
    VertexOut output;
    if (vid % 4 == 0) {
        output.pos = vector_float4(currentVertex.x-0.007, currentVertex.y-0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else if (vid % 4 == 1) {
        output.pos = vector_float4(currentVertex.x-0.007, currentVertex.y+0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else if (vid % 4 == 2) {
        output.pos = vector_float4(currentVertex.x+0.007, currentVertex.y-0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else {
        output.pos = vector_float4(currentVertex.x+0.007, currentVertex.y+0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    }
    
    bool is_selected = false;
    for (int i = 0; i < uniforms->num_selected_vertices; i++) {
        if (vid/4 == selected_vertices[i]) {
            output.color = vector_float4(1, 0.5, 0, 1);
            is_selected = true;
            break;
        }
    }
    if (!is_selected) {
        output.color = vector_float4(0, 1, 0, 1);
    }
    return output;
}

vertex VertexOut DotShader (const constant vector_float3 *vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]], const constant VertexRenderUniforms *uniforms [[buffer(1)]]) {
    vector_float3 currentVertex = vertex_array[vid/4];
    VertexOut output;
    if (vid % 4 == 0) {
        output.pos = vector_float4(currentVertex.x-0.007, currentVertex.y-0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else if (vid % 4 == 1) {
        output.pos = vector_float4(currentVertex.x-0.007, currentVertex.y+0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else if (vid % 4 == 2) {
        output.pos = vector_float4(currentVertex.x+0.007, currentVertex.y-0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    } else {
        output.pos = vector_float4(currentVertex.x+0.007, currentVertex.y+0.007 * uniforms->screen_ratio, currentVertex.z-0.001, 1);
    }
    
    output.color = vector_float4(0, 1, 0, 1);
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
    
    output.pos = vector_float4(currentNode.x + radius * cos(angle), currentNode.y + (radius * sin(angle) * uniforms->screen_ratio), currentNode.z-0.01, 1);
    
    if (vid/40 == uniforms->selected_node) {
        output.color = vector_float4(1, 0.5, 0, 1);
    } else {
        output.color = vector_float4(0.8, 0.8, 0.9, 1);
    }
    
    return output;
}

fragment vector_float4 FragmentShader(VertexOut interpolated [[stage_in]]){
    return interpolated.color;
}



// UNUSED
/*float sign (vector_float2 p1, vector_float3 p2, vector_float3 p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

float dist (vector_float2 p1, vector_float3 p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
}

float WeightedZ (vector_float2 click, vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    float dist1 = dist(click, p1);
    float dist2 = dist(click, p2);
    float dist3 = dist(click, p3);
    
    float total_dist = dist1 + dist2 + dist3;
    float weightedZ = p1.z*(dist1/total_dist);
    weightedZ += p2.z*(dist2/total_dist);
    weightedZ += p3.z*(dist3/total_dist);
    return weightedZ;
}

kernel void FaceClicked(device int &clickedIdx [[buffer(0)]], device float &minZ [[buffer(1)]], unsigned int fid [[thread_position_in_grid]], constant vector_float2 &clickLoc [[buffer(2)]], const constant vector_float3 *vertices [[buffer(3)]], device Face *face_array[[buffer(4)]]) {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    Face face = face_array[fid];
    vector_float3 v1 = vertices[face.vertices[0]];
    vector_float3 v2 = vertices[face.vertices[1]];
    vector_float3 v3 = vertices[face.vertices[2]];

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

/*vertex VertexOut ProjectionCalculationVertexShader (const constant vector_float3 *vertex_array [[buffer(0)]], unsigned int vid [[vertex_id]], const constant vector_float4 *color_array [[buffer(1)]], constant Camera &camera [[buffer(2)]]) {
    vector_float3 currentVertex = vertex_array[vid];
    VertexOut output;
    
    vector_float3 pixel = PointToPixel(currentVertex, camera);
    
    output.pos = vector_float4(pixel.x, pixel.y, pixel.z, 1.0);
    
    output.color = color_array[vid/4];
    
    return output;
}*/
