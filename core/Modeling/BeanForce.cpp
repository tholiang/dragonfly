#include "BeanForce.h"

using namespace DragonflyUtils;

BeanForce::BeanForce() {
}

BeanForce::~BeanForce() {
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

bool BeanForce::Contains(vec_float3 point) {
    // assume axis is (0,0,1)
    // assume zero angle is (1,0,0)

    // project point onto vector
    float z = point.z;
    float r = sqrt(pow(point.x, 2) + pow(point.y, 2));
    float a = AngleBetween(vec_make_float3(1,0,0), point);

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
