#ifndef Force_h
#define Force_h

#include <stdio.h>
#include <vector>
#include "Utils/Vec.h"
using namespace Vec;

class Force {
public:
    virtual bool Contains(vec_float3 point) = 0;
private:
};

#endif /* Force_h */