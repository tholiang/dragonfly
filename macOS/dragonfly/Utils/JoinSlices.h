//
//  JoinSlices.h
//  dragonfly
//
//  Created by Thomas Liang on 3/19/23.
//

#ifndef JoinSlices_h
#define JoinSlices_h

#include <stdio.h>
#include <vector>
#include <utility>
#include <string>
#include <sstream>
#include <simd/SIMD.h>
#include <iostream>

#include "../Modeling/Model.h"
#include "../Modeling/Scene.h"
#include "Utils.h"

namespace DragonflyUtils {
void BuildSliceOnModel(Model *m, ModelUniforms *mu, Slice *s, ModelUniforms *su, int lastslicestart);
std::vector<int> LinesAcross(Slice *a, ModelUniforms *au, ModelUniforms *bu);
std::vector<int> LowerDotsOnLinesAcross(Slice *a, ModelUniforms *au, ModelUniforms *bu);
std::vector<simd_float3> CrossedPointsOnLinesAcross(Slice *a, ModelUniforms *au, ModelUniforms *bu);
std::pair<int,int> GetNextMergeDots(std::pair<int, int> curr, bool up, Slice *a, Slice *b, ModelUniforms *au, ModelUniforms *bu);
void MoveToMerge(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, std::pair<int, int> bdots);
void JoinSlices(Model *m, ModelUniforms *mu, Slice *a, Slice *b, ModelUniforms *au, ModelUniforms *bu, float merge_threshold);
}

#endif /* JoinSlices_h */
