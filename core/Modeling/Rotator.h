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
#include "Utils/Vec.h"
using namespace Vec;

class Rotator : public Model {
public:
    Rotator();
    Rotator(vec_float4 c);
private:
    void MakeRotator();
    
    vec_float4 color;
};

#endif /* Rotator_h */
