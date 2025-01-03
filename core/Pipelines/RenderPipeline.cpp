//
//  RenderPipeline.cpp
//  dragonfly
//
//  Created by Thomas Liang on 3/9/24.
//

#include <stdio.h>
#include "RenderPipeline.h"

RenderPipeline::~RenderPipeline() {
    
}

void RenderPipeline::SetCounts(unsigned long nf, unsigned long ne) {
    num_faces = nf;
    num_edges = ne;
}
