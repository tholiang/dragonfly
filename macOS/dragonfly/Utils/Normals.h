//
//  GenerateLighting.hpp
//  dragonfly
//
//  Created by Thomas Liang on 1/17/23.
//

#ifndef GenerateLighting_h
#define GenerateLighting_h

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <vector>
#include <utility>
#include <string>
#include <sstream>
#include <simd/SIMD.h>
#include <iostream>

#include "../Modeling/Model.h"
#include "../Modeling/Scene.h"
#include "Utils.h"

namespace DragonflyUtils {
int FaceIntercept(Model *m, simd_float3 start, simd_float3 vector, int avoid);
void FindNormals(Model *m);
void ReverseNormals(Model *m);
}

#endif /* GenerateLighting_h */
