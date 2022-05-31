//
//  Arrow.m
//  dragonfly
//
//  Created by Thomas Liang on 3/5/22.
//

#import <Foundation/Foundation.h>
#include "Arrow.h"

Arrow::Arrow(uint32 mid) : Model(mid) {
    color = simd_make_float4(1, 0, 0, 0); // default red
    MakeArrow();
}

Arrow::Arrow(uint32 mid, simd_float4 c) : Model(mid), color(c) {
    MakeArrow();
}

void Arrow::MakeArrow() {
    // base
    MakeVertex(-0.005, -0.005, -1);
    MakeVertex(0.005, -0.005, -1);
    MakeVertex(-0.005, 0.005, -1);
    MakeVertex(0.005, 0.005, -1);
    MakeVertex(-0.005, -0.005, 1);
    MakeVertex(0.005, -0.005, 1);
    MakeVertex(-0.005, 0.005, 1);
    MakeVertex(0.005, 0.005, 1);
    
    MakeFace(1, 0, 4, color);
    MakeFace(4, 5, 1, color);
    
    MakeFace(2, 0, 4, color);
    MakeFace(2, 6, 4, color);
    
    MakeFace(3, 2, 6, color);
    MakeFace(3, 7, 6, color);
    
    MakeFace(3, 1, 5, color);
    MakeFace(5, 7, 3, color);
    
    MakeFace(5, 4, 6, color);
    MakeFace(5, 7, 6, color);
    
    // bottom of pointy part 1
    MakeVertex(-0.05, -0.05, 1);
    MakeVertex(-0.05, 0.05, 1);
    MakeVertex(0.05, -0.05, 1);
    MakeVertex(0.05, 0.05, 1);
    
    MakeFace(8, 9, 10, color);
    MakeFace(9, 10, 11, color);
    
    // pointy part 1
    MakeVertex(0, 0, 1.1);
    
    MakeFace(8, 9, 12, color);
    MakeFace(9, 10, 12, color);
    MakeFace(10, 11, 12, color);
    MakeFace(9, 11, 12, color);
    
    // bottom of pointy part 2
    MakeVertex(-0.05, -0.05, -1);
    MakeVertex(-0.05, 0.05, -1);
    MakeVertex(0.05, -0.05, -1);
    MakeVertex(0.05, 0.05, -1);
    
    MakeFace(13, 14, 15, color);
    MakeFace(14, 15, 16, color);
    
    // pointy part 2
    MakeVertex(0, 0, -1.1);
    
    MakeFace(13, 14, 17, color);
    MakeFace(14, 15, 17, color);
    MakeFace(15, 16, 17, color);
    MakeFace(14, 16, 17, color);
}
