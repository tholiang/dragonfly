//
//  Basis.hpp
//  dragonfly
//
//  Created by Thomas Liang on 2/17/23.
//

#ifndef Basis_h
#define Basis_h

#include <stdio.h>
#include <vector>
#include <utility>
#include <string>
#include <sstream>
#include "Utils/Vec.h"
using namespace Vec;
#include <iostream>
#include <fstream>
#include <cmath>

#include "Utils.h"

namespace DragonflyUtils {
struct Basis {
    vec_float3 pos;
    // angles
    vec_float3 x;
    vec_float3 y;
    vec_float3 z;
    Basis() {
        pos = vec_make_float3(0,0,0);
        x = vec_make_float3(1,0,0);
        y = vec_make_float3(0,1,0);
        z = vec_make_float3(0,0,1);
    }
};
void RotateBasisOnX(Basis *b, float angle);
void RotateBasisOnY(Basis *b, float angle);
void RotateBasisOnZ(Basis *b, float angle);
vec_float3 TranslatePointToStandard(Basis *b, vec_float3 point);
vec_float3 RotatePointToStandard(Basis *b, vec_float3 point);
vec_float3 TranslatePointToBasis(Basis *b, vec_float3 point);
vec_float3 RotatePointToBasis(Basis *b, vec_float3 point);
Basis TranslateBasis(Basis *b, Basis *onto);
void BasisToFile(std::ofstream &file, Basis *b);
Basis BasisFromFile(std::ifstream &file);
}


#endif /* Basis_h */
