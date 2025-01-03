//
//  Scene.cpp
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#include <unistd.h>
#include "Scene.h"

#include "../Utils/Wrap.h"

bool in_sphere(vec_float3 p) {
    return dist3to3(p, vec_make_float3(0, 0, 0)) < 5;
}

bool in_cube(vec_float3 p) {
    return (p.x > 3 || p.y > 3 || p.z > 3) || (p.x < -3 || p.y < -3 || p.z < -3);
}

float dec_line(float x) {
    return 1-(x*x);
}
float flat_line(float x) {
    return 1;
}

Scene::Scene() {
    CreateNewModel();
    
    /*PointLight pl;
    Basis lightb;
    lightb.pos.x = -5;
    lightb.pos.z = 5;
    pl.SetColor(vec_make_float4(1,0,0,1));
    AddLight(pl, lightb);
    
    PointLight pl2;
    Basis lightb2;
    lightb2.pos.x = 5;
    lightb2.pos.z = 5;
    pl2.SetColor(vec_make_float4(0,1,0,1));
    AddLight(pl2, lightb2);

    BeanForce *bf = new BeanForce();
    bf->AddGuideline(0, dec_line);
    ForceField *leaf = new ForceField(bf, Basis());
    BeanForce *bf2 = new BeanForce();
    bf2->AddGuideline(M_PI, flat_line);
    Basis b;
    b.z = vec_make_float3(0,0,-1);
    ForceField *leaf2 = new ForceField(bf2, b);

    ForceField *ff = new ForceField(FFType::AND, leaf, leaf2, Basis());

    using std::placeholders::_1;
    std::function<bool(vec_float3)> in_ff = std::bind(&ForceField::Contains, ff, _1);
    Model m = *Wrap(0, 0, 0.5, 0.05, 0.4, false, in_ff);
    ModelTransform new_uniform;
    new_uniform.b = Basis();
    new_uniform.rotate_origin = vec_make_float3(0, 0, 0);
    AddModel(m, new_uniform);*/
}

Scene::~Scene() {
}

void Scene::GetFromFolder(std::string path) {
    for (int i = models.size()-1; i >= 0; i--) {
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
            
            ModelTransform mu;
//            mu.position.x = vals[0];
//            mu.position.y = vals[1];
//            mu.position.z = vals[2];
//
//            mu.rotate_origin.x = vals[3];
//            mu.rotate_origin.y = vals[4];
//            mu.rotate_origin.z = vals[5];
//
//            mu.angle.x = vals[6];
//            mu.angle.y = vals[7];
//            mu.angle.z = vals[8];
            
            model_uniforms.push_back(mu);
            
            Model m;
            m.FromFile(path+"/Models/"+model_file);
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
    
    return &models[mid];
}

ModelTransform * Scene::GetModelUniforms(unsigned long mid) {
    if (mid >= model_uniforms.size()) {
        return NULL;
    }
    
    return &model_uniforms[mid];
}

Slice * Scene::GetSlice(unsigned long sid) {
    if (sid >= slices.size()) {
        return NULL;
    }
    
    return &slices[sid];
}

ModelTransform * Scene::GetSliceUniforms(unsigned long sid) {
    if (sid >= slice_uniforms.size()) {
        return NULL;
    }
    
    return &slice_uniforms[sid];
}

Light *Scene::GetLight(unsigned long lid) {
    if (lid >= lights.size()) {
        return NULL;
    }
    
    return &lights[lid];
}

Basis *Scene::GetLightBasis(unsigned long lid) {
    if (lid >= lights.size()) {
        return NULL;
    }
    
    return &light_bases[lid];
}

vec_float3 Scene::GetModelPosition(unsigned long mid) {
    if (mid >= model_uniforms.size()) {
        return vec_make_float3(0,0,0);
    }
    
    return model_uniforms[mid].b.pos;
}

Basis *Scene::GetModelBasis(unsigned long mid) {
    if (mid >= model_uniforms.size()) {
        return NULL;
    }
    
    return &model_uniforms[mid].b;
}

//vec_float3 Scene::GetModelAngle(unsigned long mid) {
//    if (mid >= model_uniforms.size()) {
//        return NULL;
//    }
//
//    return model_uniforms[mid].angle;
//}

vec_float3 Scene::GetSlicePosition(unsigned long sid) {
    if (sid >= slice_uniforms.size()) {
        return vec_make_float3(0,0,0);
    }
    
    return slice_uniforms[sid].b.pos;
}

//vec_float3 Scene::GetSliceAngle(unsigned long sid) {
//    if (sid >= slice_uniforms.size()) {
//        return NULL;
//    }
//    
//    return slice_uniforms[sid].angle;
//}

void Scene::MoveModelBy(unsigned int mid, float dx, float dy, float dz) {
    if (mid < model_uniforms.size()) {
        ModelTransform * mu = GetModelUniforms(mid);
        
        if (mu == NULL) {
            return;
        }
        
        mu->b.pos.x += dx;
        mu->b.pos.y += dy;
        mu->b.pos.z += dz;
        
        mu->rotate_origin.x += dx;
        mu->rotate_origin.y += dy;
        mu->rotate_origin.z += dz;
    }
}

void Scene::RotateModelBy(unsigned int mid, float dx, float dy, float dz) {
    if (mid < model_uniforms.size()) {
        ModelTransform * mu = GetModelUniforms(mid);

        if (mu == NULL) {
            return;
        }

//        mu->angle.x += dx;
//        mu->angle.y += dy;
//        mu->angle.z += dz;
        
        RotateBasisOnX(&mu->b, dx);
        RotateBasisOnY(&mu->b, dy);
        RotateBasisOnZ(&mu->b, dz);
    }
}

void Scene::MoveModelTo(unsigned int mid, float x, float y, float z) {
    if (mid < model_uniforms.size()) {
        ModelTransform * mu = GetModelUniforms(mid);
        
        if (mu == NULL) {
            return;
        }
        
        mu->rotate_origin.x += x - mu->b.pos.x;
        mu->rotate_origin.y += y - mu->b.pos.y;
        mu->rotate_origin.z += z - mu->b.pos.z;
        
        mu->b.pos.x = x;
        mu->b.pos.y = y;
        mu->b.pos.z = z;
    }
}

//void Scene::RotateModelTo(unsigned int mid, float x, float y, float z) {
//    if (mid < model_uniforms.size()) {
//        ModelUniforms * mu = GetModelUniforms(mid);
//
//        if (mu == NULL) {
//            return;
//        }
//
//        mu->angle.x = x;
//        mu->angle.y = y;
//        mu->angle.z = z;
//    }
//}

void Scene::MoveSliceBy(unsigned int sid, float dx, float dy, float dz) {
    if (sid < slice_uniforms.size()) {
        ModelTransform * mu = GetSliceUniforms(sid);
        
        if (mu == NULL) {
            return;
        }
        
        mu->b.pos.x += dx;
        mu->b.pos.y += dy;
        mu->b.pos.z += dz;
        
        mu->rotate_origin.x += dx;
        mu->rotate_origin.y += dy;
        mu->rotate_origin.z += dz;
    }
}

void Scene::RotateSliceBy(unsigned int sid, float dx, float dy, float dz) {
    if (sid < slice_uniforms.size()) {
        ModelTransform * mu = GetSliceUniforms(sid);
        
        if (mu == NULL) {
            return;
        }
        
        RotateBasisOnX(&mu->b, dx);
        RotateBasisOnY(&mu->b, dy);
        RotateBasisOnZ(&mu->b, dz);
    }
}

void Scene::MoveSliceTo(unsigned int sid, float x, float y, float z) {
    if (sid < slice_uniforms.size()) {
        ModelTransform * mu = GetSliceUniforms(sid);
        
        if (mu == NULL) {
            return;
        }
        
        mu->rotate_origin.x += x - mu->b.pos.x;
        mu->rotate_origin.y += y - mu->b.pos.y;
        mu->rotate_origin.z += z - mu->b.pos.z;
        
        mu->b.pos.x = x;
        mu->b.pos.y = y;
        mu->b.pos.z = z;
    }
}

//void Scene::RotateSliceTo(unsigned int sid, float x, float y, float z) {
//    if (sid < slice_uniforms.size()) {
//        ModelUniforms * mu = GetSliceUniforms(sid);
//        
//        if (mu == NULL) {
//            return;
//        }
//        
//        mu->angle.x = x;
//        mu->angle.y = y;
//        mu->angle.z = z;
//    }
//}

void Scene::MoveLightBy(unsigned int lid, float dx, float dy, float dz) {
    if (lid < light_bases.size()) {
        Basis *b = GetLightBasis(lid);
        
        if (b == NULL) {
            return;
        }
        
        b->pos.x += dx;
        b->pos.y += dy;
        b->pos.z += dz;
    }
}

void Scene::RotateLightBy(unsigned int lid, float dx, float dy, float dz) {
    if (lid < light_bases.size()) {
        Basis *b = GetLightBasis(lid);
        
        if (b == NULL) {
            return;
        }
        
        RotateBasisOnX(b, dx);
        RotateBasisOnY(b, dy);
        RotateBasisOnZ(b, dz);
    }
}

void Scene::MoveLightTo(unsigned int lid, float x, float y, float z) {
    if (lid < light_bases.size()) {
        Basis *b = GetLightBasis(lid);
        
        if (b == NULL) {
            return;
        }
        
        b->pos.x = x;
        b->pos.y = y;
        b->pos.z = z;
    }
}

void Scene::CreateNewModel() {
    Model m;
//    m.MakeCube();
    m.MakeVertex(0, 0, 0);
    m.MakeVertex(1, 1, 0);
    m.MakeVertex(0, 1, 1);
    m.MakeFace(0, 1, 2, vec_make_float4(1, 0, 0, 1));
    models.push_back(m);
    ModelTransform new_uniform;
    new_uniform.b = Basis();
    new_uniform.rotate_origin = vec_make_float3(0, 0, 0);
    
    model_uniforms.push_back(new_uniform);
}

void Scene::NewModelFromFile(std::string path) {
    Model m;
    m.FromFile(path);
    models.push_back(m);
    ModelTransform new_uniform;
    new_uniform.b = Basis();
    new_uniform.rotate_origin = vec_make_float3(0, 0, 0);
    
    model_uniforms.push_back(new_uniform);
}

void Scene::NewModelFromPointData(std::string path) {
    PointData *pd = PointDataFromFile(path);
    Model m = *ModelFromPointData(pd);
    delete pd;
    models.push_back(m);
    ModelTransform new_uniform;
    new_uniform.b = Basis();
    new_uniform.rotate_origin = vec_make_float3(0, 0, 0);
    
    model_uniforms.push_back(new_uniform);
}

void Scene::AddModel(Model m, ModelTransform mu) {
    models.push_back(m);
    model_uniforms.push_back(mu);
}

void Scene::AddSlice(Slice s) {
    slices.push_back(s);
    
    ModelTransform new_uniform;
    new_uniform.b = Basis();
    new_uniform.rotate_origin = vec_make_float3(0, 0, 0);
    
    slice_uniforms.push_back(new_uniform);
}

void Scene::AddLight(Light l, Basis b) {
    lights.push_back(l);
    light_bases.push_back(b);
}

void Scene::RemoveModel(unsigned long mid) {
    if (mid < models.size()) {
        models.erase(models.begin() + mid);
        model_uniforms.erase(model_uniforms.begin() + mid);
    }
}

void Scene::RemoveSlice(unsigned long sid) {
    if (sid < slices.size()) {
        slices.erase(slices.begin() + sid);
        slice_uniforms.erase(slice_uniforms.begin() + sid);
    }
}

void Scene::RemoveLight(unsigned long lid) {
    if (lid < lights.size()) {
        lights.erase(lights.begin() + lid);
        light_bases.erase(light_bases.begin() + lid);
    }
}

unsigned long Scene::NumModels() {
    return models.size();
}

unsigned long Scene::NumSlices() {
    return slices.size();
}

unsigned long Scene::NumLights() {
    return lights.size();
}

std::vector<Model> * Scene::GetModels() {
    return &models;
}
std::vector<ModelTransform> * Scene::GetAllModelUniforms() {
    return &model_uniforms;
}

std::vector<Slice> * Scene::GetSlices() {
    return &slices;
}
std::vector<ModelTransform> * Scene::GetAllSliceUniforms() {
    return &slice_uniforms;
}
/*std::vector<SliceAttributes> Scene::GetAllSliceAttributes() {
    std::vector<SliceAttributes> attr;
    for (int i = 0; i < slices.size(); i++) {
        attr.push_back(slices[i]->GetAttributes());
    }
    return attr;
}*/

std::vector<Light> *Scene::GetLights() {
    return &lights;
}

std::vector<SimpleLight> Scene::GetSimpleLights() {
    std::vector<SimpleLight> ret;
    for (int i = 0; i < lights.size(); i++) {
        ret.push_back(lights[i].ToSimpleLight(light_bases[i]));
    }
    
    return ret;
}

std::vector<Basis> *Scene::GetLightBases() {
    return &light_bases;
}

std::string Scene::GetName() {
    return name_;
}

void Scene::SetName(std::string name) {
    name_ = name;
}

void Scene::SaveToFolder(std::string path) {
    #ifdef _WIN64 || _WIN32
    if(mkdir(path.c_str()) == -1) {
        rmdir(path.c_str());
        mkdir(path.c_str());
    }
    
    if(mkdir((path+"/Models").c_str()) == -1) {
        rmdir((path+"/Models").c_str());
        mkdir((path+"/Models").c_str());
    }

    #else
    if(mkdir(path.c_str(), 0777) == -1) {
        rmdir(path.c_str());
        mkdir(path.c_str(), 0777);
    }
    
    if(mkdir((path+"/Models").c_str(), 0777) == -1) {
        rmdir((path+"/Models").c_str());
        mkdir((path+"/Models").c_str(), 0777);
    }
    #endif
    
    std::ofstream myfile;
    myfile.open ((path+"/uniforms.lair").c_str());
    
    for (int i = 3; i < model_uniforms.size(); i++) {
        models.at(i).SaveToFile(path+"/Models/");
        
        ModelTransform mu = model_uniforms.at(i);
        myfile << models.at(i).GetName() << ".drgn ";
//        myfile << mu.position.x << " " << mu.position.y << " " << mu.position.z << " ";
//        myfile << mu.rotate_origin.x << " " << mu.rotate_origin.y << " " << mu.rotate_origin.z << " ";
//        myfile << mu.angle.x << " " << mu.angle.y << " " << mu.angle.z << std::endl;
    }
    
    myfile.close();
}
