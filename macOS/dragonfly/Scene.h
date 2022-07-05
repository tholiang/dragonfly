//
//  Scene.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef Scene_h
#define Scene_h

#include <stdio.h>
#include <vector>
#include <string>

#include <simd/SIMD.h>

#include "Modeling/Model.h"

struct ModelUniforms {
    simd_float3 position;
    simd_float3 rotate_origin;
    simd_float3 angle; // euler angles zyx
};

class Scene {
private:
    std::vector<Model *> models;
    std::vector<ModelUniforms> model_uniforms;
public:
    Model *GetModel(unsigned long mid);
    ModelUniforms *GetModelUniforms(unsigned long mid);
    
    simd_float3 GetModelPosition(unsigned long mid);
    simd_float3 GetModelAngle(unsigned long mid);
    
    void MoveModelBy(unsigned int mid, float dx, float dy, float dz);
    void RotateModelBy(unsigned int mid, float dx, float dy, float dz);
    
    void MoveModelTo(unsigned int mid, float x, float y, float z);
    void RotateModelTo(unsigned int mid, float x, float y, float z);
    
    unsigned long NumModels();
    
    std::vector<Model *> *GetModels();
    std::vector<ModelUniforms> *GetAllModelUniforms();
};

#endif /* Scene_h */
