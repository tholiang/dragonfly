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
Vertex GetStandardVertexFromDot(Slice *s, ModelUniforms *mu, int i);

void BuildSliceOnModel(Model *m, ModelUniforms *mu, Slice *s, ModelUniforms *su, int lastslicestart);
std::vector<int> LinesAcross(Slice *a, ModelUniforms *au, ModelUniforms *bu);
std::vector<int> LowerDotsOnLinesAcross(Slice *a, ModelUniforms *au, ModelUniforms *bu);
std::vector<simd_float3> CrossedPointsOnLinesAcross(Slice *a, ModelUniforms *au, ModelUniforms *bu);
std::pair<int,int> GetNextMergeDots(std::pair<int, int> curr, bool up, Slice *a, Slice *b, ModelUniforms *au, ModelUniforms *bu);
void MoveToMerge(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, std::pair<int, int> bdots);
void JoinSlices(Model *m, ModelUniforms *mu, Slice *a, Slice *b, ModelUniforms *au, ModelUniforms *bu, float merge_threshold);

int GetNextDot(Slice *s, int cur, int last);
float DotDist(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, int adot, int bdot);
std::pair<std::vector<int>, float> MatchSlicesFrom(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, int a1, int a2, int b1, int b2);
// return minimized matching from a to b and its distance for when |a| = |b|
// adots[ret[i]] = matched bdot idx
std::vector<int> MatchEqualSlices(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu);
void BridgeEqualSlices(Model *m, ModelUniforms *mu, Slice *a, Slice *b, ModelUniforms *au, ModelUniforms *bu);

/* TODO later
// return minimized matching from a to b and its distance for when |a| > |b| and can skip dots in a
std::vector<int> MatchSlicesWithSkip(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, int numskips);
// return (dots skipped, score)
std::pair<std::vector<int>, float> GetBestSkipMatch(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, int alast, int acur, int blast, int bcur, int astart, int numskips);

// return minimized matching from a to b and its distance for when |a| < |b| and can add dots to a
std::vector<int> MatchSlicesWithAdd(Slice *a, ModelUniforms *au, Slice *b, ModelUniforms *bu, int numadds);

std::vector<int> GetBestAddMatch(std::vector<Dot> adots, std::vector<Line> alines, ModelUniforms *au, Slice *b, ModelUniforms *bu, int a1, int a2, int b1, int b2);
 */
}

#endif /* JoinSlices_h */
