//
//  Scene.mm
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#import <Foundation/Foundation.h>
#include "Scene.h"

using namespace DragonflyUtils;

Scene::Scene() {
    CreateNewModel();
}

Scene::~Scene() {
    for (int i = 0; i < models.size(); i++) {
        delete models[i];
    }
}

void Scene::GetFromFolder(std::string path) {
    for (int i = models.size()-1; i >= 0; i--) {
        delete models.at(i);
        models.erase(models.begin()+i);
    }
    
    for (int i = model_uniforms.size()-1; i >= 3; i--) {
        model_uniforms.erase(model_uniforms.begin()+i);
    }
    
    std::string line;
    std::ifstream myfile (path+"/uniforms.lair");
    if (myfile.is_open()) {
        int mid = 0;
        
        while ( getline (myfile,line) ) {
            std::string model_file = line.substr(0, line.find(' '));
            line = line.substr(line.find(' ')+1);
            
            std::vector<float> vals = splitStringToFloats(line);
            
            ModelUniforms mu;
            mu.position.x = vals[0];
            mu.position.y = vals[1];
            mu.position.z = vals[2];
            
            mu.rotate_origin.x = vals[3];
            mu.rotate_origin.y = vals[4];
            mu.rotate_origin.z = vals[5];
            
            mu.angle.x = vals[6];
            mu.angle.y = vals[7];
            mu.angle.z = vals[8];
            
            model_uniforms.push_back(mu);
            
            Model *m = new Model(mid);
            m->FromFile(path+"/Models/"+model_file);
            models.push_back(m);
            
            mid++;
        }
        
        myfile.close();
    }
}

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
    
    mu->rotate_origin.x += dx;
    mu->rotate_origin.y += dy;
    mu->rotate_origin.z += dz;
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
    
    mu->rotate_origin.x += x - mu->position.x;
    mu->rotate_origin.y += y - mu->position.y;
    mu->rotate_origin.z += z - mu->position.z;
    
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

void Scene::CreateNewModel() {
    Model *m = new Model(models.size());
    m->MakeCube();
    models.push_back(m);
    ModelUniforms new_uniform;
    new_uniform.position = simd_make_float3(0, 0, 0);
    new_uniform.rotate_origin = simd_make_float3(0, 0, 0);
    new_uniform.angle = simd_make_float3(0, 0, 0);
    
    model_uniforms.push_back(new_uniform);
}

void Scene::NewModelFromFile(std::string path) {
    Model *m = new Model(models.size());
    m->FromFile(path);
    models.push_back(m);
    ModelUniforms new_uniform;
    new_uniform.position = simd_make_float3(0, 0, 0);
    new_uniform.rotate_origin = simd_make_float3(0, 0, 0);
    new_uniform.angle = simd_make_float3(0, 0, 0);
    
    model_uniforms.push_back(new_uniform);
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

std::string Scene::GetName() {
    return name_;
}

void Scene::SetName(std::string name) {
    name_ = name;
}

void Scene::SaveToFolder(std::string path) {
    if(mkdir(path.c_str(), 0777) == -1) {
        rmdir(path.c_str());
        mkdir(path.c_str(), 0777);
    }
    
    if(mkdir((path+"/Models").c_str(), 0777) == -1) {
        rmdir((path+"/Models").c_str());
        mkdir((path+"/Models").c_str(), 0777);
    }
    
    std::ofstream myfile;
    myfile.open ((path+"/uniforms.lair").c_str());
    
    for (int i = 3; i < model_uniforms.size(); i++) {
        models.at(i)->SaveToFile(path+"/Models/");
        
        ModelUniforms mu = model_uniforms.at(i);
        myfile << models.at(i)->GetName() << ".drgn ";
        myfile << mu.position.x << " " << mu.position.y << " " << mu.position.z << " ";
        myfile << mu.rotate_origin.x << " " << mu.rotate_origin.y << " " << mu.rotate_origin.z << " ";
        myfile << mu.angle.x << " " << mu.angle.y << " " << mu.angle.z << std::endl;
    }
    
    myfile.close();
}
