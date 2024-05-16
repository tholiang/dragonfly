//
//  Slice.h
//  dragonfly
//
//  Created by Thomas Liang on 2/5/23.
//

#ifndef Slice_h
#define Slice_h

#include <stdio.h>
#include <vector>
#include <string>
#include <stdint.h>

#include "Utils/Vec.h"
using namespace Vec;
#include <fstream>

#include "../Utils/Utils.h"

typedef vec_float2 Dot;

struct SliceAttributes {
    float width;
    float height;
};

struct Line {
    uint32_t d1;
    uint32_t d2;
};

class Slice {
private:
    std::vector<Dot *> dots;
    std::vector<Line *> lines;
    
    SliceAttributes attr;
public:
    Slice();
    ~Slice();
    
    void SetWidth(float w);
    void SetHeight(float h);
    
    float GetWidth();
    float GetHeight();
    
    SliceAttributes GetAttributes();
    
    unsigned MakeDot(float x, float y);
    unsigned MakeLine(int d1, int d2);
    
    void AddDotToLine(int lid);
    
    void MoveDotBy(int did, float dx, float dy);
    void MoveDotTo(int did, float x, float y);
    
    void RemoveDot(int did);
    void RemoveLine(int lid);
    
    void RemoveDotAndMergeLines(int did);
    
    Dot *GetDot(unsigned long did);
    Line *GetLine(unsigned long lid);
    
    std::vector<Dot*> &GetDots();
    std::vector<Line*> &GetLines();
    
    unsigned long NumDots();
    unsigned long NumLines();
};

#endif /* Slice_h */
