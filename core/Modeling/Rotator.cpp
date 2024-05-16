//
//  Rotator.cpp
//  dragonfly
//
//  Created by Thomas Liang on 4/19/23.
//

#include "Rotator.h"

Rotator::Rotator() {
    name_ = "rotator";
    color = vec_make_float4(1, 0, 0, 0); // default red
    MakeRotator();
}

Rotator::Rotator(vec_float4 c): color(c) {
    MakeRotator();
}

void Rotator::MakeRotator() {
    // top base
    MakeVertex(0, -0.075, 0.95);
    MakeVertex(0, -0.075, 1.05);
    MakeVertex(0, 0.075, 0.95);
    MakeVertex(0, 0.075, 1.05);
    
    MakeFace(0, 1, 2, color);
    MakeFace(1, 2, 3, color);
    
    // top arrow 1
    MakeVertex(0, 0.075, 1.075);
    MakeVertex(0, 0.075, 0.925);
    MakeVertex(0, 0.125, 1);
    
    MakeFace(4, 5, 6, color);
    
    // top arrow 2
    MakeVertex(0, -0.075, 1.075);
    MakeVertex(0, -0.075, 0.925);
    MakeVertex(0, -0.125, 1);
    
    MakeFace(7, 8, 9, color);
    
    // bottom
    MakeVertex(0, -0.075, -1.05);
    MakeVertex(0, -0.075, -0.95);
    MakeVertex(0, 0.075, -1.05);
    MakeVertex(0, 0.075, -0.95);
    
    MakeFace(10, 11, 12, color);
    MakeFace(11, 12, 13, color);
    
    // top arrow 1
    MakeVertex(0, 0.075, -0.925);
    MakeVertex(0, 0.075, -1.075);
    MakeVertex(0, 0.125, -1);
    
    MakeFace(14, 15, 16, color);
    
    // top arrow 2
    MakeVertex(0, -0.075, -0.925);
    MakeVertex(0, -0.075, -1.075);
    MakeVertex(0, -0.125, -1);
    
    MakeFace(17, 18, 19, color);
}
