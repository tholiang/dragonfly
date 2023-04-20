//
//  Arrow.m
//  dragonfly
//
//  Created by Thomas Liang on 3/5/22.
//

#import <Foundation/Foundation.h>
#include "Arrow.h"

Arrow::Arrow(uint32 mid) : Model(mid) {
    name_ = "arrow"+std::to_string(mid);
    color = simd_make_float4(1, 0, 0, 0); // default red
    MakeArrow();
}

Arrow::Arrow(uint32 mid, simd_float4 c) : Model(mid), color(c) {
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
