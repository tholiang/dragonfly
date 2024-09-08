#ifndef BeanForce_h
#define BeanForce_h

#include <stdio.h>
#include <unistd.h>
#include <vector>
#include <functional>
#include "Utils/Vec.h"
#include "Utils/Utils.h"
using namespace Vec;
#include "Force.h"

// a guideline function is a 2D function that returns a y given an x
typedef std::function<float(float)> Guideline;

class BeanForce : public Force {
public:
    BeanForce();
    void AddGuideline(float angle, Guideline guideline);

    // assume the point is in the force's basis
    virtual bool Contains(vec_float3 point);
private:
    std::vector<std::pair<float, Guideline>> guidelines_; // angle and function
};

#endif /* BeanForce_h */