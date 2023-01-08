//
//  Utils.m
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#include "Utils.h"


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

simd_float3 DragonflyUtils::TriAvg (simd_float3 p1, simd_float3 p2, simd_float3 p3) {
    float x = (p1.x + p2.x + p3.x)/3;
    float y = (p1.y + p2.y + p3.y)/3;
    float z = (p1.z + p2.z + p3.z)/3;
    
    return simd_make_float3(x, y, z);
}

simd_float3 DragonflyUtils::BiAvg (simd_float3 p1, simd_float3 p2) {
    float x = (p1.x + p2.x)/2;
    float y = (p1.y + p2.y)/2;
    float z = (p1.z + p2.z)/2;
    
    return simd_make_float3(x, y, z);
}

float DragonflyUtils::sign2D (simd_float2 p1, simd_float2 p2, simd_float2 p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

float DragonflyUtils::sign (simd_float2 p1, simd_float3 p2, simd_float3 p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

float DragonflyUtils::dist2to3 (simd_float2 p1, simd_float3 p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
}

float DragonflyUtils::dist3to3 (simd_float3 p1, simd_float3 p2) {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2) + pow(p1.z - p2.z, 2));
}

float DragonflyUtils::WeightedZ (simd_float2 click, simd_float3 p1, simd_float3 p2, simd_float3 p3) {
    float dist1 = dist2to3(click, p1);
    float dist2 = dist2to3(click, p2);
    float dist3 = dist2to3(click, p3);
    
    float total_dist = dist1 + dist2 + dist3;
    float weightedZ = p1.z*(dist1/total_dist);
    weightedZ += p2.z*(dist2/total_dist);
    weightedZ += p3.z*(dist3/total_dist);
    return weightedZ;
}

simd_float3 DragonflyUtils::CrossProduct (simd_float3 p1, simd_float3 p2) {
    simd_float3 cross;
    cross.x = p1.y*p2.z - p1.z*p2.y;
    cross.y = -(p1.x*p2.z - p1.z*p2.x);
    cross.z = p1.x*p2.y - p1.y*p2.x;
    return cross;
}

/*simd_float3 DragonflyUtils::LinePlaneIntersect (simd_float3 line_origin, simd_float3 line_vector, simd_float3 plane1, simd_float3 plane2, simd_float3 plane3) {
    simd_float3 plane_vec1 = simd_make_float3(plane1.x-plane2.x, plane1.y-plane2.y, plane1.z-plane2.z);
    simd_float3 plane_vec2 = simd_make_float3(plane1.x-plane3.x, plane1.y-plane3.y, plane1.z-plane3.z);
    simd_float3 plane_norm = CrossProduct(plane_vec1, plane_vec2);
    
    float k = -(plane_norm.x*plane1.x + plane_norm.y*plane1.y + plane_norm.z*plane1.z);
    
    //std::cout<<plane_norm.x<<"x + "<<plane_norm.y<<"y + "<<plane_norm.z<<"z + "<<k<<" = 0"<<std::endl;
    
    float intersect_const = k + plane_norm.x*line_origin.x + plane_norm.y*line_origin.y + plane_norm.z*line_origin.z;
    float intersect_coeff = plane_norm.x*line_vector.x + plane_norm.y*line_vector.y + plane_norm.z*line_vector.z;
    
    float distto = -intersect_const/intersect_coeff;
    
    //std::cout<<"t = "<<distto<<std::endl;
    
    simd_float3 intersect = simd_make_float3(distto*line_vector.x + line_origin.x, distto*line_vector.y + line_origin.y, distto*line_vector.z + line_origin.z);
    
    //std::cout<<intersect.x<<" "<<intersect.y<<" "<<intersect.z<<std::endl;
    //std::cout<<distto<<std::endl;
    return intersect;
}

simd_float3 DragonflyUtils::MouseFaceIntercept (simd_float2 &mouse, int fid) {
    Face face = scene_faces.at(fid);
    simd_float3 mouse_angle = simd_make_float3(atan(mouse.x*tan(camera->FOV.x/2)), -atan(mouse.y*tan(camera->FOV.y/2)), 1);
    
    std::cout<<mouse_angle.x<<" "<<mouse_angle.y<<std::endl;
    
    //get current camera angles (phi is vertical and theta is horizontal)
    //get the new change based on the amount the mouse moved
    float cam_phi = atan2(camera->vector.y, camera->vector.x);
    
    float cam_theta = acos(camera->vector.z);
    
    //get mouse phi and theta angles
    float new_phi = cam_phi + mouse_angle.x;
    float new_theta = cam_theta + mouse_angle.y;
    
    //find vector
    simd_float3 mouse_vec = simd_make_float3(sin(new_theta)*cos(new_phi), sin(new_theta)*sin(new_phi), cos(new_theta));
    
    //std::cout<<mouse_vec.x<<" "<<mouse_vec.y<<" "<<mouse_vec.z<<std::endl;
    
    //std::cout<<"x: "<<mouse_vec.x<<"t + "<<camera->pos.x<<std::endl;
    //std::cout<<"y: "<<mouse_vec.y<<"t + "<<camera->pos.y<<std::endl;
    //std::cout<<"z: "<<mouse_vec.z<<"t + "<<camera->pos.z<<std::endl;
    
    return LinePlaneIntersect(camera->pos, mouse_vec, scene_vertices.at(face.vertices[0]), scene_vertices.at(face.vertices[1]), scene_vertices.at(face.vertices[2]));
}*/

bool DragonflyUtils::InTriangle2D(vector_float2 point, simd_float2 v1, simd_float2 v2, simd_float2 v3) {
    float d1 = sign2D(point, v1, v2);
    float d2 = sign2D(point, v2, v3);
    float d3 = sign2D(point, v3, v1);

    bool has_neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    bool has_pos = (d1 > 0) || (d2 > 0) || (d3 > 0);

    return (!(has_neg && has_pos));
}

bool DragonflyUtils::InTriangle(vector_float2 point, simd_float3 v1, simd_float3 v2, simd_float3 v3) {
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


simd_float3 DragonflyUtils::RotateAround (simd_float3 point, simd_float3 origin, simd_float3 angle) {
    simd_float3 vec;
    vec.x = point.x-origin.x;
    vec.y = point.y-origin.y;
    vec.z = point.z-origin.z;
    
    simd_float3 newvec;
    
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

std::string DragonflyUtils::TextField(std::string input, std::string name) {
    char buf [128] = "";
    std::strcpy (buf, input.c_str());
    ImGui::InputText(name.c_str(), buf, IM_ARRAYSIZE(buf));
    
    return std::string(buf);
}
