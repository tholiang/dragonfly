//
//  RenderPipeline.h
//  dragonfly
//
//  Created by Thomas Liang on 3/9/24.
//

#ifndef RenderPipeline_h
#define RenderPipeline_h

#include <stdio.h>
#include <vector>
#include <string>

#include "Utils/Vec.h"
using namespace Vec;

#include "imgui.h"

class RenderPipeline {
protected:
    int window_width;
    int window_height;
    
    // render variables
    unsigned long num_faces = 0;
    unsigned long num_edges = 0;
public:
    virtual ~RenderPipeline();
    
    void SetCounts(unsigned long nf, unsigned long ne);
    
    virtual int init() = 0;
    
    virtual void SetPipeline() = 0;
    
    virtual void Render() = 0;
};

#endif /* RenderPipeline_h */
