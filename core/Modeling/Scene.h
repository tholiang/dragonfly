//
//  Scene.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef Scene_h
#define Scene_h

#include <functional>
#include <stdio.h>
#include <vector>
#include <string>

#include "Utils/Vec.h"
using namespace Vec;
#include <filesystem>
#include <sys/stat.h>
#include <sys/types.h>

#include "Model.h"
#include "Slice.h"
#include "BeanForce.h"
#include "ForceField.h"
#include "../Utils/Project2D.h"
#include "../Utils/Basis.h"
#include "../Lights/Light.h"
#include "../Lights/PointLight.h"

using namespace DragonflyUtils;

struct ModelTransform {
    vec_float3 rotate_origin;
    Basis b;
};

class Scene {
private:
    std::vector<Model> models;
    std::vector<ModelTransform> model_uniforms;
    
    std::vector<Slice> slices;
    std::vector<ModelTransform> slice_uniforms;

    std::vector<Light> lights;
    std::vector<Basis> light_bases;
    
    std::string name_;
public:
    Scene();
    ~Scene();
    
    void GetFromFolder(std::string path);
    
    Model *GetModel(unsigned long mid);
    ModelTransform *GetModelUniforms(unsigned long mid);
    
    Slice *GetSlice(unsigned long sid);
    ModelTransform *GetSliceUniforms(unsigned long sid);

    Light *GetLight(unsigned long lid);
    Basis *GetLightBasis(unsigned long lid);
    
    vec_float3 GetModelPosition(unsigned long mid);
    Basis *GetModelBasis(unsigned long mid);
//    vec_float3 GetModelAngle(unsigned long mid);
    
    vec_float3 GetSlicePosition(unsigned long sid);
//    vec_float3 GetSliceAngle(unsigned long sid);
    
    void MoveModelBy(unsigned int mid, float dx, float dy, float dz);
    void RotateModelBy(unsigned int mid, float dx, float dy, float dz);
    
    void MoveModelTo(unsigned int mid, float x, float y, float z);
    //void RotateModelTo(unsigned int mid, float x, float y, float z);
    
    void MoveSliceBy(unsigned int sid, float dx, float dy, float dz);
    void RotateSliceBy(unsigned int sid, float dx, float dy, float dz);
    
    void MoveSliceTo(unsigned int sid, float x, float y, float z);
//    void RotateSliceTo(unsigned int sid, float x, float y, float z);

    void MoveLightBy(unsigned int lid, float dx, float dy, float dz);
    void RotateLightBy(unsigned int lid, float dx, float dy, float dz);
    
    void MoveLightTo(unsigned int lid, float x, float y, float z);
    
    void CreateNewModel();
    void NewModelFromFile(std::string path);
    void NewModelFromPointData(std::string path);
    void AddModel(Model m, ModelTransform mu);
    
    void AddSlice(Slice s);

    void AddLight(Light l, Basis b);
    
    void RemoveModel(unsigned long mid);
    
    void RemoveSlice(unsigned long sid);

    void RemoveLight(unsigned long lid);
    
    unsigned long NumModels();
    unsigned long NumSlices();
    unsigned long NumLights();
    
    std::vector<Model> *GetModels();
    std::vector<ModelTransform> *GetAllModelUniforms();
    
    std::vector<Slice> *GetSlices();
    //std::vector<SliceAttributes> GetAllSliceAttributes();
    std::vector<ModelTransform> *GetAllSliceUniforms();

    std::vector<Light> *GetLights();
    std::vector<SimpleLight> GetSimpleLights();
    std::vector<Basis> *GetLightBases();
    
    std::string GetName();
    void SetName(std::string name);
    void SaveToFolder(std::string path);
};



#endif /* Scene_h */
