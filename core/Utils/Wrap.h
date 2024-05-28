//
//  Wrap.h
//  dragonfly
//
//  Created by Thomas Liang on 5/16/24.
//

#ifndef Wrap_h
#define Wrap_h

#include <stdlib.h>
#include <vector>
#include <queue>
#include <utility>
#include <string>
#include <sstream>
#include "Utils/Vec.h"
using namespace Vec;
#include <functional>
#include <iostream>

#include "Utils.h"
#include "../Modeling/Model.h"
#include "../Modeling/ForceField.h"

namespace DragonflyUtils {
// get a random number around a desired float value
float float_randomizer(float d, float r);
// get any (unit) vector normal to a given vector
vec_float3 get_a_normal(vec_float3 v);
// find any point on the surface of the model
vec_float3 find_wrap_start(float step, std::function<bool(vec_float3)> in_model);
// search for a surface point by rotating a vector around an origin in a given direction
// return angle needed to rotate to that point, if > 2pi nothing found
std::pair<vec_float3, float> find_surface(vec_float3 origin, vec_float3 vector, vec_float3 dir, float step, float starting_angle, std::function<bool(vec_float3)> in_model);
// check if point is within separation distance from a vertex on the model, and return vertex id if so
std::vector<int> near_vertices(Model *m, vec_float3 point, float sep);
// return if a given point is in a face
bool point_in_face(Model *m, vec_float3 point, float sep);
bool face_overlaps(Model *m, vec_float3 v1, vec_float3 v2, vec_float3 v3, float sep, std::vector<int> ignore_vids);
Model *Wrap(float a_r, float l_r, float l_d, float step, float sep, bool should_simplify, std::function<bool(vec_float3)> in_model);
};

#endif /* Wrap_h */
