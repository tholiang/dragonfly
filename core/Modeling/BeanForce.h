#ifndef BeanForce_h
#define BeanForce_h

#include <stdio.h>
#include <vector>
#include <functional>
#include "Utils/Vec.h"
#include "Utils/Utils.h"
using namespace Vec;
#include "ForceField.h"

// a guideline function is a 2D function that returns a y given an x
typedef std::function<float(float)> Guideline;

class BeanForce : public ForceField {
public:
    BeanForce();
    void SetAxisAndZero(vec_float3 a, vec_float3 z);
    void AddGuideline(float angle, Guideline guideline);

    virtual bool Contains(vec_float3 point, vec_float3 origin);
private:
    vec_float3 axis_; // from origin
    vec_float3 zero_angle_; // ortho to axis - what "0" in an angle represents
    std::vector<std::pair<float, Guideline>> guidelines_; // angle and function
};

#endif /* BeanForce_h */