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
#include <simd/SIMD.h>
#include <iostream>
#include <fstream>

#include "Utils.h"

namespace DragonflyUtils {
struct Basis {
    simd_float3 pos;
    // angles
    simd_float3 x;
    simd_float3 y;
    simd_float3 z;
    Basis() {
        pos = simd_make_float3(0,0,0);
        x = simd_make_float3(1,0,0);
        y = simd_make_float3(0,1,0);
        z = simd_make_float3(0,0,1);
    }
};
void RotateBasisOnX(Basis *b, float angle);
void RotateBasisOnY(Basis *b, float angle);
void RotateBasisOnZ(Basis *b, float angle);
simd_float3 TranslatePointToStandard(Basis *b, simd_float3 point);
simd_float3 RotatePointToStandard(Basis *b, simd_float3 point);
simd_float3 TranslatePointToBasis(Basis *b, simd_float3 point);
Basis TranslateBasis(Basis *b, Basis *onto);
void BasisToFile(std::ofstream &file, Basis *b);
Basis BasisFromFile(std::ifstream &file);
}


#endif /* Basis_h */
