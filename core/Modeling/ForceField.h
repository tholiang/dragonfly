//
//  ForceField.h
//  dragonfly
//
//  Created by Thomas Liang on 5/16/24.
//

#ifndef ForceField_h
#define ForceField_h

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

#include "Model.h"

using namespace DragonflyUtils;

class ForceField {
private:
    
    bool in_model(vec_float3 point);
public:
};

#endif /* ForceField_h */
