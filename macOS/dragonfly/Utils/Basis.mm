//
//  Basis.mm
//  dragonfly
//
//  Created by Thomas Liang on 2/17/23.
//

#include "Basis.h"

void DragonflyUtils::RotateBasisOnX(Basis *b, float angle) {
    // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
    
    simd_float3 newY;
    float costh = cos(angle);
    newY = ScaleVector(b->y, costh);
    float sinth = sin(angle);
    newY = AddVectors(newY, ScaleVector(CrossProduct(b->x, b->y), sinth));
    float doty = DotProduct(b->x, b->y);
    newY = AddVectors(newY, ScaleVector(b->x, doty * (1-costh)));
    
    simd_float3 newZ;
    newZ = ScaleVector(b->z, costh);
    newZ = AddVectors(newZ, ScaleVector(CrossProduct(b->x, b->z), sinth));
    float dotz = DotProduct(b->x, b->z);
    newZ = AddVectors(newZ, ScaleVector(b->x, dotz * (1-costh)));
    
    b->y = newY;
    b->z = newZ;
}

void DragonflyUtils::RotateBasisOnY(Basis *b, float angle) {
    simd_float3 newX;
    float costh = cos(angle);
    newX = ScaleVector(b->x, costh);
    float sinth = sin(angle);
    newX = AddVectors(newX, ScaleVector(CrossProduct(b->y, b->x), sinth));
    float dotx = DotProduct(b->y, b->x);
    newX = AddVectors(newX, ScaleVector(b->y, dotx * (1-costh)));
    
    simd_float3 newZ;
    newZ = ScaleVector(b->z, costh);
    newZ = AddVectors(newZ, ScaleVector(CrossProduct(b->y, b->z), sinth));
    float dotz = DotProduct(b->y, b->z);
    newZ = AddVectors(newZ, ScaleVector(b->y, dotz * (1-costh)));
    
    b->x = newX;
    b->z = newZ;
}

void DragonflyUtils::RotateBasisOnZ(Basis *b, float angle) {
    simd_float3 newX;
    float costh = cos(angle);
    newX = ScaleVector(b->x, costh);
    float sinth = sin(angle);
    newX = AddVectors(newX, ScaleVector(CrossProduct(b->z, b->x), sinth));
    float dotx = DotProduct(b->z, b->x);
    newX = AddVectors(newX, ScaleVector(b->z, dotx * (1-costh)));
    
    simd_float3 newY;
    newY = ScaleVector(b->y, costh);
    newY = AddVectors(newY, ScaleVector(CrossProduct(b->z, b->y), sinth));
    float doty = DotProduct(b->z, b->y);
    newY = AddVectors(newY, ScaleVector(b->z, doty * (1-costh)));
    
    b->x = newX;
    b->y = newY;
}

simd_float3 DragonflyUtils::TranslatePointToStandard(Basis *b, simd_float3 point) {
    simd_float3 ret;
    // x component
    ret.x = point.x * b->x.x;
    ret.y = point.x * b->x.y;
    ret.z = point.x * b->x.z;
    // y component
    ret.x += point.y * b->y.x;
    ret.y += point.y * b->y.y;
    ret.z += point.y * b->y.z;
    // z component
    ret.x += point.z * b->z.x;
    ret.y += point.z * b->z.y;
    ret.z += point.z * b->z.z;
    
    ret.x += b->pos.x;
    ret.y += b->pos.y;
    ret.z += b->pos.z;
    
    return ret;
}

simd_float3 DragonflyUtils::RotatePointToStandard(Basis *b, simd_float3 point) {
    simd_float3 ret;
    // x component
    ret.x = point.x * b->x.x;
    ret.y = point.x * b->x.y;
    ret.z = point.x * b->x.z;
    // y component
    ret.x += point.y * b->y.x;
    ret.y += point.y * b->y.y;
    ret.z += point.y * b->y.z;
    // z component
    ret.x += point.z * b->z.x;
    ret.y += point.z * b->z.y;
    ret.z += point.z * b->z.z;
    
    return ret;
}

simd_float3 DragonflyUtils::TranslatePointToBasis(Basis *b, simd_float3 point) {
    simd_float3 ret;
    
    simd_float3 tobasis;
    tobasis.x = point.x - b->pos.x;
    tobasis.y = point.y - b->pos.y;
    tobasis.z = point.z - b->pos.z;
    
    ret.x = Projection(tobasis, b->x);
    ret.y = Projection(tobasis, b->y);
    ret.z = Projection(tobasis, b->z);
    
    return ret;
};

DragonflyUtils::Basis DragonflyUtils::TranslateBasis(Basis *b, Basis *onto) {
    Basis newb;
    newb.pos = TranslatePointToStandard(onto, b->pos);
    newb.x = RotatePointToStandard(onto, b->x);
    newb.y = RotatePointToStandard(onto, b->y);
    newb.z = RotatePointToStandard(onto, b->z);
    
    return newb;
}


void DragonflyUtils::BasisToFile(std::ofstream &file, Basis *b) {
    file << b->pos.x << " " << b->pos.y << " " << b->pos.z << std::endl;
    file << b->x.x << " " << b->x.y << " " << b->x.z << std::endl;
    file << b->y.x << " " << b->y.y << " " << b->y.z << std::endl;
    file << b->z.x << " " << b->z.y << " " << b->z.z << std::endl;
}

DragonflyUtils::Basis DragonflyUtils::BasisFromFile(std::ifstream &file) {
    Basis b;
    
    std::string line;
    getline(file, line);
    float x,y,z;
    sscanf(line.c_str(), "%f %f %f", &x, &y, &z);
    b.pos.x = x;
    b.pos.y = y;
    b.pos.z = z;
    
    getline(file, line);
    sscanf(line.c_str(), "%f %f %f", &x, &y, &z);
    b.x.x = x;
    b.x.y = y;
    b.x.z = z;
    
    getline(file, line);
    sscanf(line.c_str(), "%f %f %f", &x, &y, &z);
    b.y.x = x;
    b.y.y = y;
    b.y.z = z;
    
    getline(file, line);
    sscanf(line.c_str(), "%f %f %f", &x, &y, &z);
    b.z.x = x;
    b.z.y = y;
    b.z.z = z;
    
    return b;
}
