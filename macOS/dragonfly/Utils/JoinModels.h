//
//  JoinModels.hpp
//  dragonfly
//
//  Created by Thomas Liang on 1/9/23.
//

#ifndef JoinModels_h
#define JoinModels_h

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
// maximum bipartite graph matching
bool bpm(std::vector<std::vector<float>> &graph, int i, std::vector<bool> &seen, std::vector<int> &matches);
int match(std::vector<std::vector<float>> &graph, std::vector<int> &matches);
// minimum vertex cover
void alternate(int i, std::vector<std::vector<float>> &graph, std::vector<bool> &visitedi, std::vector<bool> &visitedj, std::vector<int> &matches);
void koenig(std::vector<std::vector<float>> &graph, std::vector<int> &matches, std::vector<int> &icover, std::vector<int> &jcover);
// O(n^5) implementation - can change to the n^3 one
std::vector<int> Hungarian(std::vector<simd_float3> &A, std::vector<simd_float3> &B);
void JoinModels(Model *A, Model *B, ModelUniforms *muA, ModelUniforms *muB, std::vector<int> &A_pts, std::vector<int> &B_pts);
}

#endif /* JoinModels_h */
