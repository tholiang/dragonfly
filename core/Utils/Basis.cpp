//
//  Basis.cpp
//  dragonfly
//
//  Created by Thomas Liang on 2/17/23.
//

#include "Basis.h"

void DragonflyUtils::RotateBasisOnX(Basis *b, float angle) {
    // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
    float magx = Magnitude(b->x);
    vector_float3 unitx = vector_make_float3(b->x.x / magx, b->x.y / magx, b->x.z / magx);
    float magy = Magnitude(b->y);
    vector_float3 unity = vector_make_float3(b->y.x / magy, b->y.y / magy, b->y.z / magy);
    float magz = Magnitude(b->z);
    vector_float3 unitz = vector_make_float3(b->z.x / magz, b->z.y / magz, b->z.z / magz);
    
    vector_float3 newY;
    float costh = std::cos(angle);
    newY = ScaleVector(unity, costh);
    float sinth = std::sin(angle);
    newY = AddVectors(newY, ScaleVector(CrossProduct(unitx, unity), sinth));
    float doty = DotProduct(unitx, unity);
    newY = AddVectors(newY, ScaleVector(unitx, doty * (1-costh)));
    
    vector_float3 newZ;
    newZ = ScaleVector(unitz, costh);
    newZ = AddVectors(newZ, ScaleVector(CrossProduct(unitx, unitz), sinth));
    float dotz = DotProduct(unitx, unitz);
    newZ = AddVectors(newZ, ScaleVector(unitx, dotz * (1-costh)));
    
    b->y = vector_make_float3(newY.x * magy, newY.y * magy, newY.z * magy);
    b->z = vector_make_float3(newZ.x * magz, newZ.y * magz, newZ.z * magz);
}

void DragonflyUtils::RotateBasisOnY(Basis *b, float angle) {
    // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
    float magx = Magnitude(b->x);
    vector_float3 unitx = vector_make_float3(b->x.x / magx, b->x.y / magx, b->x.z / magx);
    float magy = Magnitude(b->y);
    vector_float3 unity = vector_make_float3(b->y.x / magy, b->y.y / magy, b->y.z / magy);
    float magz = Magnitude(b->z);
    vector_float3 unitz = vector_make_float3(b->z.x / magz, b->z.y / magz, b->z.z / magz);
    
    vector_float3 newX;
    float costh = std::cos(angle);
    newX = ScaleVector(unitx, costh);
    float sinth = std::sin(angle);
    newX = AddVectors(newX, ScaleVector(CrossProduct(unity, unitx), sinth));
    float dotx = DotProduct(unity, unitx);
    newX = AddVectors(newX, ScaleVector(unity, dotx * (1-costh)));
    
    vector_float3 newZ;
    newZ = ScaleVector(unitz, costh);
    newZ = AddVectors(newZ, ScaleVector(CrossProduct(unity, unitz), sinth));
    float dotz = DotProduct(unity, unitz);
    newZ = AddVectors(newZ, ScaleVector(unity, dotz * (1-costh)));
    
    b->x = vector_make_float3(newX.x * magx, newX.y * magx, newX.z * magx);
    b->z = vector_make_float3(newZ.x * magz, newZ.y * magz, newZ.z * magz);
}

void DragonflyUtils::RotateBasisOnZ(Basis *b, float angle) {
    // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
    float magx = Magnitude(b->x);
    vector_float3 unitx = vector_make_float3(b->x.x / magx, b->x.y / magx, b->x.z / magx);
    float magy = Magnitude(b->y);
    vector_float3 unity = vector_make_float3(b->y.x / magy, b->y.y / magy, b->y.z / magy);
    float magz = Magnitude(b->z);
    vector_float3 unitz = vector_make_float3(b->z.x / magz, b->z.y / magz, b->z.z / magz);
    
    vector_float3 newX;
    float costh = std::cos(angle);
    newX = ScaleVector(unitx, costh);
    float sinth = std::sin(angle);
    newX = AddVectors(newX, ScaleVector(CrossProduct(unitz, unitx), sinth));
    float dotx = DotProduct(unitz, unitx);
    newX = AddVectors(newX, ScaleVector(unitz, dotx * (1-costh)));
    
    vector_float3 newY;
    newY = ScaleVector(unity, costh);
    newY = AddVectors(newY, ScaleVector(CrossProduct(unitz, unity), sinth));
    float doty = DotProduct(unitz, unity);
    newY = AddVectors(newY, ScaleVector(unitz, doty * (1-costh)));
    
    b->x = vector_make_float3(newX.x * magx, newX.y * magx, newX.z * magx);
    b->y = vector_make_float3(newY.x * magy, newY.y * magy, newY.z * magy);
}

vector_float3 DragonflyUtils::TranslatePointToStandard(Basis *b, vector_float3 point) {
    vector_float3 ret;
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

vector_float3 DragonflyUtils::RotatePointToStandard(Basis *b, vector_float3 point) {
    float magx = Magnitude(b->x);
    vector_float3 unitx = vector_make_float3(b->x.x / magx, b->x.y / magx, b->x.z / magx);
    float magy = Magnitude(b->y);
    vector_float3 unity = vector_make_float3(b->y.x / magy, b->y.y / magy, b->y.z / magy);
    float magz = Magnitude(b->z);
    vector_float3 unitz = vector_make_float3(b->z.x / magz, b->z.y / magz, b->z.z / magz);
    
    vector_float3 ret;
    // x component
    ret.x = point.x * unitx.x;
    ret.y = point.x * unitx.y;
    ret.z = point.x * unitx.z;
    // y component
    ret.x += point.y * unity.x;
    ret.y += point.y * unity.y;
    ret.z += point.y * unity.z;
    // z component
    ret.x += point.z * unitz.x;
    ret.y += point.z * unitz.y;
    ret.z += point.z * unitz.z;
    
    return ret;
}

vector_float3 DragonflyUtils::TranslatePointToBasis(Basis *b, vector_float3 point) {
    vector_float3 ret;
    
    vector_float3 tobasis;
    tobasis.x = point.x - b->pos.x;
    tobasis.y = point.y - b->pos.y;
    tobasis.z = point.z - b->pos.z;
    
    ret.x = Projection(tobasis, b->x);
    ret.y = Projection(tobasis, b->y);
    ret.z = Projection(tobasis, b->z);
    
    return ret;
};

vector_float3 DragonflyUtils::RotatePointToBasis(Basis *b, vector_float3 point) {
    float magx = Magnitude(b->x);
    vector_float3 unitx = vector_make_float3(b->x.x / magx, b->x.y / magx, b->x.z / magx);
    float magy = Magnitude(b->y);
    vector_float3 unity = vector_make_float3(b->y.x / magy, b->y.y / magy, b->y.z / magy);
    float magz = Magnitude(b->z);
    vector_float3 unitz = vector_make_float3(b->z.x / magz, b->z.y / magz, b->z.z / magz);
    
    vector_float3 ret;
    
    ret.x = Projection(point, unitx);
    ret.y = Projection(point, unity);
    ret.z = Projection(point, unitz);
    
    return ret;
}

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
