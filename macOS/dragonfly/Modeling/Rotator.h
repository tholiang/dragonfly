//
//  Rotator.h
//  dragonfly
//
//  Created by Thomas Liang on 4/19/23.
//

#ifndef Rotator_h
#define Rotator_h

#include "Model.h"

#include <stdio.h>
#include <vector>
#include <simd/SIMD.h>

class Rotator : public Model {
public:
    Rotator(uint32_t mid);
    Rotator(uint32_t mid, simd_float4 c);
private:
    void MakeRotator();
    
    simd_float4 color;
};

#endif /* Rotator_h */
