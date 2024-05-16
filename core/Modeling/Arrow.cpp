//
//  Arrow.cpp
//  dragonfly
//
//  Created by Thomas Liang on 3/5/22.
//

#include "Arrow.h"

Arrow::Arrow() {
    name_ = "arrow";
    color = vec_make_float4(1, 0, 0, 0); // default red
    MakeArrow();
}

Arrow::Arrow(vec_float4 c) : color(c) {
    MakeArrow();
}

void Arrow::MakeArrow() {
    // bottom of pointy part 1
    MakeVertex(-0.05, -0.05, 1);
    MakeVertex(-0.05, 0.05, 1);
    MakeVertex(0.05, -0.05, 1);
    MakeVertex(0.05, 0.05, 1);
    
    MakeFace(0, 1, 2, color);
    MakeFace(1, 2, 3, color);
    
    // pointy part 1
    MakeVertex(0, 0, 1.1);
    
    MakeFace(0, 1, 4, color);
    MakeFace(1, 2, 4, color);
    MakeFace(2, 3, 4, color);
    MakeFace(1, 3, 4, color);
    
    // bottom of pointy part 2
    MakeVertex(-0.05, -0.05, -1);
    MakeVertex(-0.05, 0.05, -1);
    MakeVertex(0.05, -0.05, -1);
    MakeVertex(0.05, 0.05, -1);
    
    MakeFace(5, 6, 7, color);
    MakeFace(6, 7, 8, color);
    
    // pointy part 2
    MakeVertex(0, 0, -1.1);
    
    MakeFace(5, 6, 9, color);
    MakeFace(6, 7, 9, color);
    MakeFace(7, 8, 9, color);
    MakeFace(6, 8, 9, color);
}
