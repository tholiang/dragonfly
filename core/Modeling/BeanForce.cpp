#include "BeanForce.h"

using namespace DragonflyUtils;

BeanForce::BeanForce() {
    axis_ = vec_make_float3(0,0,1);
    zero_angle_ = vec_make_float3(1,0,0);
}

void BeanForce::SetAxisAndZero(vec_float3 a, vec_float3 z) {
    axis_ = a;
    zero_angle_ = z;
}

void BeanForce::AddGuideline(float angle, Guideline guideline) {
    std::pair<float, Guideline> entry = std::make_pair(angle, guideline);
    
    // sort by angle
    for (int i = 0; i < guidelines_.size(); i++) {
        if (guidelines_[i].first > angle) {
            guidelines_.insert(guidelines_.begin()+i, entry);
            return;
        }
    }
    guidelines_.push_back(entry);
}

bool BeanForce::Contains(vec_float3 point, vec_float3 origin) {
    // project point onto vector
    point = point - origin;

    float z = Projection(point, axis_);
    vec_float3 proj = ScaleVector(axis_, z);
    float r = Magnitude(point - proj);
    float a = AngleBetween(zero_angle_, point);

    // if no guidelines, anything "under" the tip of the axis is in 
    if (guidelines_.size() == 0 || r == 0) {
        return z < 1;
    }

    if (guidelines_.size() == 1) {
        return z < guidelines_[0].second(r);
    }

    // find the last guideline angle < a (note this wraps around) 
    // assume guidelines vector is sorted
    int guide1_idx = guidelines_.size() - 1;
    for (int i = 0; i < guidelines_.size(); i++) {
        if (guidelines_[i].first > a) {
            break;
        }
        guide1_idx = i;
    }

    int guide2_idx = (guide1_idx + 1) % (guidelines_.size());

    // extrapolate z limit based on dist between angles
    float guide1_a = guidelines_[guide1_idx].first;
    float guide2_a = guidelines_[guide2_idx].first;
    float guide_angle_diff = guide2_a - guide1_a;
    if (guide_angle_diff < 0) guide_angle_diff += 2*M_PI;
    float a_diff = a - guide1_a;
    if (a_diff < 0) a_diff += 2*M_PI;
    float a_weight = a_diff / guide_angle_diff;

    float ex_z = a_weight * (guidelines_[guide2_idx].second(r)) + (1 - a_weight) * (guidelines_[guide1_idx].second(r));

    return z < ex_z;
}