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
#include "Utils/Vec.h"
using namespace Vec;
#include <iostream>

#include "../Modeling/Model.h"
#include "../Modeling/Scene.h"
#include "Utils.h"

namespace DragonflyUtils {
Vertex GetStandardVertexFromDot(Slice *s, ModelTransform *mu, int i);

void BuildSliceOnModel(Model *m, ModelTransform *mu, Slice *s, ModelTransform *su, int lastslicestart);
std::vector<int> LinesAcross(Slice *a, ModelTransform *au, ModelTransform *bu);
std::vector<int> LowerDotsOnLinesAcross(Slice *a, ModelTransform *au, ModelTransform *bu);
std::vector<vector_float3> CrossedPointsOnLinesAcross(Slice *a, ModelTransform *au, ModelTransform *bu);
std::pair<int,int> GetNextMergeDots(std::pair<int, int> curr, bool up, Slice *a, Slice *b, ModelTransform *au, ModelTransform *bu);
void MoveToMerge(Slice *a, ModelTransform *au, Slice *b, ModelTransform *bu, std::pair<int, int> bdots);
void JoinSlices(Model *m, ModelTransform *mu, Slice *a, Slice *b, ModelTransform *au, ModelTransform *bu, float merge_threshold);

int GetNextDot(Slice *s, int cur, int last);
float DotDist(Slice *a, ModelTransform *au, Slice *b, ModelTransform *bu, int adot, int bdot);
std::pair<std::vector<int>, float> MatchSlicesFrom(Slice *a, ModelTransform *au, Slice *b, ModelTransform *bu, int a1, int a2, int b1, int b2);
// return minimized matching from a to b and its distance for when |a| = |b|
// adots[ret[i]] = matched bdot idx
std::vector<int> MatchEqualSlices(Slice *a, ModelTransform *au, Slice *b, ModelTransform *bu);
void BridgeEqualSlices(Model *m, ModelTransform *mu, Slice *a, Slice *b, ModelTransform *au, ModelTransform *bu);

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
