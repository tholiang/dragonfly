//
//  Scene.mm
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#import <Foundation/Foundation.h>
#include "Scene.h"

Model * Scene::GetModel(unsigned long mid) {
    if (mid >= models.size()) {
        return NULL;
    }
    
    return models[mid];
}

ModelUniforms * Scene::GetModelUniforms(unsigned long mid) {
    if (mid >= model_uniforms.size()) {
        return NULL;
    }
    
    return &model_uniforms[mid];
}

simd_float3 Scene::GetModelPosition(unsigned long mid) {
    if (mid >= model_uniforms.size()) {
        return NULL;
    }
    
    return model_uniforms[mid].position;
}

simd_float3 Scene::GetModelAngle(unsigned long mid) {
    if (mid >= model_uniforms.size()) {
        return NULL;
    }
    
    return model_uniforms[mid].angle;
}

void Scene::MoveModelBy(unsigned int mid, float dx, float dy, float dz) {
    ModelUniforms * mu = GetModelUniforms(mid);
    
    if (mu == NULL) {
        return;
    }
    
    mu->position.x += dx;
    mu->position.y += dy;
    mu->position.z += dz;
}

void Scene::RotateModelBy(unsigned int mid, float dx, float dy, float dz) {
    ModelUniforms * mu = GetModelUniforms(mid);
    
    if (mu == NULL) {
        return;
    }
    
    mu->angle.x += dx;
    mu->angle.y += dy;
    mu->angle.z += dz;
}

void Scene::MoveModelTo(unsigned int mid, float x, float y, float z) {
    ModelUniforms * mu = GetModelUniforms(mid);
    
    if (mu == NULL) {
        return;
    }
    
    mu->position.x = x;
    mu->position.y = y;
    mu->position.z = z;
}

void Scene::RotateModelTo(unsigned int mid, float x, float y, float z) {
    ModelUniforms * mu = GetModelUniforms(mid);
    
    if (mu == NULL) {
        return;
    }
    
    mu->angle.x = x;
    mu->angle.y = y;
    mu->angle.z = z;
}

unsigned long Scene::NumModels() {
    return models.size();
}

std::vector<Model *> * Scene::GetModels() {
    return &models;
}
std::vector<ModelUniforms> * Scene::GetAllModelUniforms() {
    return &model_uniforms;
}
