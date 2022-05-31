//
//  Arrow.h
//  dragonfly
//
//  Created by Thomas Liang on 3/5/22.
//

#ifndef Arrow_h
#define Arrow_h

#include "Model.h"

#include <stdio.h>
#include <vector>
#include <simd/SIMD.h>

class Arrow : public Model {
public:
    Arrow(uint32 mid);
    Arrow(uint32 mid, simd_float4 c);
private:
    void MakeArrow();
    
    simd_float4 color;
};
#endif /* Arrow_h */
