//
//  Project2D.hpp
//  dragonfly
//
//  Created by Thomas Liang on 12/18/22.
//

#ifndef Project2D_h
#define Project2D_h

#include <vector>
#include <utility>
#include <string>
#include <sstream>
#include "Utils/Vec.h"
using namespace Vec;
#include <iostream>

#include "Utils.h"
#include "../Modeling/Model.h"

namespace DragonflyUtils {
struct PointData {
    std::vector<vec_float2> points;
    std::vector<std::vector<int>> edges; // index i contains the indices of vertices the vertex at index i is connected to
    int dim = 0;
};
PointData *PointDataFromFile(std::string path);
std::vector<vec_int3> FindPointDataTriangles(PointData* pd);
Model *ModelFromPointData(PointData *pd);
}

#endif /* Project2D_h */
