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
#include "Utils/Vec.h"
using namespace Vec;

class Arrow : public Model {
public:
    Arrow();
    Arrow(vector_float4 c);
private:
    void MakeArrow();
    
    vector_float4 color;
};
#endif /* Arrow_h */
