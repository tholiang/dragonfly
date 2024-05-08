//
//  Utils.cpp
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#include "Utils.h"



bool DragonflyUtils::InIntVector(std::vector<int> &vec, int a) {
    for (int i = 0; i < vec.size(); i++) {
        if (vec[i] == a) {
            return true;
        }
    }
    return false;
}

bool DragonflyUtils::isInt( std::string str ) {
    std::istringstream iss(str);
    int i;
    iss >> std::noskipws >> i; // noskipws considers leading whitespace invalid
    // Check the entire string was consumed and if either failbit or badbit is set
    return iss.eof() && !iss.fail();
}

bool DragonflyUtils::isFloat( std::string str ) {
    std::istringstream iss(str);
    float f;
    iss >> std::noskipws >> f; // noskipws considers leading whitespace invalid
    // Check the entire string was consumed and if either failbit or badbit is set
    return iss.eof() && !iss.fail();
}

bool DragonflyUtils::isUnsignedLong( std::string str ) {
    std::istringstream iss(str);
    unsigned long ul;
    iss >> std::noskipws >> ul; // noskipws considers leading whitespace invalid
    // Check the entire string was consumed and if either failbit or badbit is set
    return iss.eof() && !iss.fail();
}

std::vector<float> DragonflyUtils::splitStringToFloats (std::string str) {
    std::vector<float> ret;
    
    std::string curr = "";
    for (int i = 0; i < str.size(); i++) {
        if (str[i] == ' ') {
            ret.push_back(std::stof(curr));
            curr = "";
        } else {
            curr += str[i];
        }
    }
    
    ret.push_back(std::stof(curr));
    
    return ret;
}

vector_float3 DragonflyUtils::TriAvg (vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    float x = (p1.x + p2.x + p3.x)/3;
    float y = (p1.y + p2.y + p3.y)/3;
    float z = (p1.z + p2.z + p3.z)/3;
    
    return vector_make_float3(x, y, z);
}

vector_float3 DragonflyUtils::BiAvg (vector_float3 p1, vector_float3 p2) {
    float x = (p1.x + p2.x)/2;
    float y = (p1.y + p2.y)/2;
    float z = (p1.z + p2.z)/2;
    
    return vector_make_float3(x, y, z);
}

float DragonflyUtils::sign2D (vector_float2 p1, vector_float2 p2, vector_float2 p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

float DragonflyUtils::sign (vector_float2 p1, vector_float3 p2, vector_float3 p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

float DragonflyUtils::dist2to3 (vector_float2 p1, vector_float3 p2) {
    return std::sqrt(std::pow(p1.x - p2.x, 2) + std::pow(p1.y - p2.y, 2));
}

float DragonflyUtils::dist3to3 (vector_float3 p1, vector_float3 p2) {
    return std::sqrt(std::pow(p1.x - p2.x, 2) + std::pow(p1.y - p2.y, 2) + std::pow(p1.z - p2.z, 2));
}

float DragonflyUtils::acos2(vector_float3 v1, vector_float3 v2) {
    float dot = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
    vector_float3 cross = CrossProduct(v1, v2);
    float det = dist3to3(cross, vector_make_float3(0, 0, 0));
    return std::atan2(det, dot);
}

float DragonflyUtils::WeightedZ (vector_float2 click, vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    float dist1 = dist2to3(click, p1);
    float dist2 = dist2to3(click, p2);
    float dist3 = dist2to3(click, p3);
    
    float total_dist = dist1 + dist2 + dist3;
    float weightedZ = p1.z*(dist1/total_dist);
    weightedZ += p2.z*(dist2/total_dist);
    weightedZ += p3.z*(dist3/total_dist);
    return weightedZ;
}

float DragonflyUtils::Magnitude (vector_float3 v) {
    return std::sqrt(std::pow(v.x, 2) + std::pow(v.y, 2) + std::pow(v.z, 2));
}

vector_float3 DragonflyUtils::CrossProduct (vector_float3 p1, vector_float3 p2) {
    vector_float3 cross;
    cross.x = p1.y*p2.z - p1.z*p2.y;
    cross.y = -(p1.x*p2.z - p1.z*p2.x);
    cross.z = p1.x*p2.y - p1.y*p2.x;
    return cross;
}

float DragonflyUtils::DotProduct (vector_float3 p1, vector_float3 p2) {
    return p1.x * p2.x + p1.y * p2.y + p1.z * p2.z;
}

vector_float3 DragonflyUtils::ScaleVector (vector_float3 v, float k) {
    return vector_make_float3(v.x * k, v.y * k, v.z * k);
}

vector_float3 DragonflyUtils::AddVectors (vector_float3 v1, vector_float3 v2) {
    return vector_make_float3(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
}

float DragonflyUtils::Projection (vector_float3 v1, vector_float3 v2) {
    float dot = DotProduct(v1, v2);
    float mag = Magnitude(v2);
    return dot / mag;
}

vector_float3 DragonflyUtils::GetNormal (vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    vector_float3 u = vector_make_float3(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z);
    vector_float3 v = vector_make_float3(p3.x - p1.x, p3.y - p1.y, p3.z - p1.z);
    
    return vector_make_float3(u.y*v.z - u.z*v.y, u.z*v.x - u.x*v.z, u.x*v.y - u.y*v.x);
}

vector_float4 DragonflyUtils::PlaneEquation(vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    vector_float4 plane;
    
    vector_float3 n = GetNormal(p1, p2, p3);
    plane.x = n.x;
    plane.y = n.y;
    plane.z = n.z;
    plane.w = (p1.x * n.x + p1.y * n.y + p1.z * n.z);
    
    return plane;
}

float DragonflyUtils::LineAndPlane(vector_float3 start, vector_float3 vector, vector_float4 plane) {
    float co = plane.x * vector.x + plane.y * vector.y + plane.z * vector.z;
    float k = plane.w - (plane.x * start.x + plane.y * start.y + plane.z * start.z);
    
    float t = k / co;
    
    return t;
}

float DragonflyUtils::TriangleArea(vector_float3 p1, vector_float3 p2, vector_float3 p3) {
    vector_float3 cross = GetNormal(p1, p2, p3);
    return std::sqrt(std::pow(cross.x, 2) + std::pow(cross.y, 2) + std::pow(cross.z, 2)) / 2;
}

vector_float3 DragonflyUtils::DistancePolynomial(vector_float3 start, vector_float3 vector, vector_float3 origin) {
    start.x -= origin.x;
    start.y -= origin.y;
    start.z -= origin.z;
    vector_float3 x = vector_make_float3(std::pow(vector.x, 2), 2 * start.x * vector.x, std::pow(start.x, 2));
    vector_float3 y = vector_make_float3(std::pow(vector.y, 2), 2 * start.y * vector.y, std::pow(start.y, 2));
    vector_float3 z = vector_make_float3(std::pow(vector.z, 2), 2 * start.z * vector.z, std::pow(start.z, 2));
    
    return vector_make_float3(x.x + y.x + z.x, x.y + y.y + z.y, x.z + y.z + z.z);
}

float DragonflyUtils::QuadraticEquation(vector_float3 coeff) {
    float inner = std::pow(coeff.y, 2) - 4 * coeff.x * coeff.z;
    float t1 = (-coeff.y - std::sqrt(inner)) / (2 * coeff.x);
    float t2 = (-coeff.y + std::sqrt(inner)) / (2 * coeff.x);
    
    if (t1 > t2) {
        return t1;
    }
    
    return t2;
}

/*vector_float3 DragonflyUtils::LinePlaneIntersect (vector_float3 line_origin, vector_float3 line_vector, vector_float3 plane1, vector_float3 plane2, vector_float3 plane3) {
    vector_float3 plane_vec1 = vector_make_float3(plane1.x-plane2.x, plane1.y-plane2.y, plane1.z-plane2.z);
    vector_float3 plane_vec2 = vector_make_float3(plane1.x-plane3.x, plane1.y-plane3.y, plane1.z-plane3.z);
    vector_float3 plane_norm = CrossProduct(plane_vec1, plane_vec2);
    
    float k = -(plane_norm.x*plane1.x + plane_norm.y*plane1.y + plane_norm.z*plane1.z);
    
    //std::cout<<plane_norm.x<<"x + "<<plane_norm.y<<"y + "<<plane_norm.z<<"z + "<<k<<" = 0"<<std::endl;
    
    float intersect_const = k + plane_norm.x*line_origin.x + plane_norm.y*line_origin.y + plane_norm.z*line_origin.z;
    float intersect_coeff = plane_norm.x*line_vector.x + plane_norm.y*line_vector.y + plane_norm.z*line_vector.z;
    
    float distto = -intersect_const/intersect_coeff;
    
    //std::cout<<"t = "<<distto<<std::endl;
    
    vector_float3 intersect = vector_make_float3(distto*line_vector.x + line_origin.x, distto*line_vector.y + line_origin.y, distto*line_vector.z + line_origin.z);
    
    //std::cout<<intersect.x<<" "<<intersect.y<<" "<<intersect.z<<std::endl;
    //std::cout<<distto<<std::endl;
    return intersect;
}

vector_float3 DragonflyUtils::MouseFaceIntercept (vector_float2 &mouse, int fid) {
    Face face = scene_faces.at(fid);
    vector_float3 mouse_angle = vector_make_float3(atan(mouse.x*tan(camera->FOV.x/2)), -atan(mouse.y*tan(camera->FOV.y/2)), 1);
    
    std::cout<<mouse_angle.x<<" "<<mouse_angle.y<<std::endl;
    
    //get current camera angles (phi is vertical and theta is horizontal)
    //get the new change based on the amount the mouse moved
    float cam_phi = std::atan2(camera->vector.y, camera->vector.x);
    
    float cam_theta = acos(camera->vector.z);
    
    //get mouse phi and theta angles
    float new_phi = cam_phi + mouse_angle.x;
    float new_theta = cam_theta + mouse_angle.y;
    
    //find vector
    vector_float3 mouse_vec = vector_make_float3(sin(new_theta)*cos(new_phi), sin(new_theta)*sin(new_phi), cos(new_theta));
    
    //std::cout<<mouse_vec.x<<" "<<mouse_vec.y<<" "<<mouse_vec.z<<std::endl;
    
    //std::cout<<"x: "<<mouse_vec.x<<"t + "<<camera->pos.x<<std::endl;
    //std::cout<<"y: "<<mouse_vec.y<<"t + "<<camera->pos.y<<std::endl;
    //std::cout<<"z: "<<mouse_vec.z<<"t + "<<camera->pos.z<<std::endl;
    
    return LinePlaneIntersect(camera->pos, mouse_vec, scene_vertices.at(face.vertices[0]), scene_vertices.at(face.vertices[1]), scene_vertices.at(face.vertices[2]));
}*/

bool DragonflyUtils::InTriangle2D(vector_float2 point, vector_float2 v1, vector_float2 v2, vector_float2 v3) {
    float d1 = sign2D(point, v1, v2);
    float d2 = sign2D(point, v2, v3);
    float d3 = sign2D(point, v3, v1);

    bool has_neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    bool has_pos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return (!(has_neg && has_pos));
}

bool DragonflyUtils::InTriangle(vector_float2 point, vector_float3 v1, vector_float3 v2, vector_float3 v3) {
    float d1 = sign(point, v1, v2);
    float d2 = sign(point, v2, v3);
    float d3 = sign(point, v3, v1);

    bool has_neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    bool has_pos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return (!(has_neg && has_pos));
}

bool DragonflyUtils::InRectangle(vector_float2 top_left, vector_float2 size, vector_float2 loc) {
    return loc.x >= top_left.x && loc.x < top_left.x+size.x && loc.y >= top_left.y-size.y && loc.y < top_left.y;
}


vector_float3 DragonflyUtils::RotateAround (vector_float3 point, vector_float3 origin, vector_float3 angle) {
    vector_float3 vec;
    vec.x = point.x-origin.x;
    vec.y = point.y-origin.y;
    vec.z = point.z-origin.z;
    
    vector_float3 newvec;
    
    // gimbal locked
    
    // around z axis
    newvec.x = vec.x*std::cos(angle.z)-vec.y*sin(angle.z);
    newvec.y = vec.x*sin(angle.z)+vec.y*std::cos(angle.z);
    
    vec.x = newvec.x;
    vec.y = newvec.y;
    
    // around y axis
    newvec.x = vec.x*std::cos(angle.y)+vec.z*sin(angle.y);
    newvec.z = -vec.x*sin(angle.y)+vec.z*std::cos(angle.y);
    
    vec.x = newvec.x;
    vec.z = newvec.z;
    
    // around x axis
    newvec.y = vec.y*std::cos(angle.x)-vec.z*sin(angle.x);
    newvec.z = vec.y*sin(angle.x)+vec.z*std::cos(angle.x);
    
    vec.y = newvec.y;
    vec.z = newvec.z;
    
    point.x = origin.x+vec.x;
    point.y = origin.y+vec.y;
    point.z = origin.z+vec.z;
    
    return point;
}

float DragonflyUtils::AngleBetween (vector_float3 v1, vector_float3 v2) {
    float mag1 = std::sqrt(std::pow(v1.x, 2) + std::pow(v1.y, 2) + std::pow(v1.z, 2));
    float mag2 = std::sqrt(std::pow(v2.x, 2) + std::pow(v2.y, 2) + std::pow(v2.z, 2));
    
    return std::acos((v1.x*v2.x + v1.y*v2.y + v1.z*v2.z) / (mag1 * mag2));
}

float DragonflyUtils::GetAcute(float angle) {
    if (angle > M_PI_2 && angle <= 3*M_PI_2) {
        angle = angle - M_PI;
    } else if (angle > 3*M_PI_4) {
        angle = M_2_PI - angle;
    }
    
    return angle;
}

std::string DragonflyUtils::TextField(std::string input, std::string name) {
    char buf [128] = "";
    strcpy (buf, input.c_str());
    ImGui::InputText(name.c_str(), buf, IM_ARRAYSIZE(buf));
    
    return std::string(buf);
}
