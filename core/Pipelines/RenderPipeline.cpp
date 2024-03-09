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

void RenderPipeline::SetScheme(Scheme *sch) {
    scheme = sch;
}

void RenderPipeline::SetSchemeController(SchemeController *sctr) {
    scheme_controller = sctr;
}
