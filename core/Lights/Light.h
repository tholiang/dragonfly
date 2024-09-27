#ifndef Light_h
#define Light_h
#include <stdio.h>
#include <vector>
#include <string>
#include <stdint.h>
#include <cmath>
#include <functional>

#include "Utils/Vec.h"
using namespace Vec;
#include <fstream>

#include "../Utils/Utils.h"
#include "../Utils/Basis.h"

using namespace DragonflyUtils;
using namespace Vec;

typedef Vec::vec_float3 Vertex;

struct SimpleLight {
    Basis b;
    float max_intensity;
    vec_float4 color;
    vec_float3 distance_falloff;
    vec_float3 angle_falloff;
};

struct LightUnit {
    vec_float3 dir;
    vec_float4 color;
    float intensity;
};

class Light {
public:
    virtual SimpleLight ToSimpleLight(Basis b);
    LightUnit GetIntensity(vec_float3 p);
protected:
    bool simple_convertible_ = false;
    std::function<LightUnit(vec_float3)> intensity_field_;
};

#endif // Light_h