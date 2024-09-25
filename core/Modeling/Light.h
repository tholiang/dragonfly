#ifndef Light_h
#define Light_h
#include <stdio.h>
#include <vector>
#include <string>
#include <stdint.h>
#include <cmath>

#include "Utils/Vec.h"
using namespace Vec;
#include <fstream>

#include "../Utils/Utils.h"
#include "../Utils/Basis.h"

using namespace DragonflyUtils;
using namespace Vec;

typedef Vec::vec_float3 Vertex;

class Light {
private:
Basis b;
vec_float4 color;
float intensity;
};

#endif // Light_h