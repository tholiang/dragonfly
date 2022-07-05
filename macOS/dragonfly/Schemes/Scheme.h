//
//  Scheme.hpp
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef Scheme_h
#define Scheme_h

#include <stdio.h>
#include <vector>
#include <string>

#include <simd/SIMD.h>

#include "../Modeling/Model.h"

struct Camera {
    simd_float3 pos;
    simd_float3 vector;
    simd_float3 up_vector;
    simd_float2 FOV;
};

class Scheme {
private:
    Camera *camera;
    std::vector<Model *> controls_models;
    
    simd_float2 mouse_loc;
public:
    Camera *GetCamera();
    std::vector<Model *> *GetControlsModels();
    
    virtual void HandleMouseMovement(float x, float y, float dx, float dy);
    
    virtual void RenderUI() = 0;
    virtual void HandleClick() = 0;
    virtual void HandleKeyPress(int key) = 0;
};

#endif /* Scheme_hpp */
