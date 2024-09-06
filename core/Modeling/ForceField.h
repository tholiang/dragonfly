#ifndef ForceField_h
#define ForceField_h

#include <stdio.h>
#include <vector>
#include "Utils/Vec.h"
using namespace Vec;

class ForceField {
public:
    virtual bool Contains(vec_float3 point, vec_float3 origin) = 0;
private:
};

#endif /* ForceField_h */