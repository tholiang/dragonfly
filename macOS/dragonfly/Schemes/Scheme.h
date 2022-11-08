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
#include <sstream>

#include <simd/SIMD.h>

#include <iostream>

#include "imgui.h"

#include "../Utils.h"

#include "../Modeling/Model.h"
#include "../Modeling/Scene.h"
#include "../Modeling/Arrow.h"

#include "../UserActions/UserAction.h"

enum SchemeType {
    EditModel,
    EditFEV,
    EditNode
};

struct VertexRenderUniforms {
    float screen_ratio = 1280.0/720.0;
    vector_int3 selected_vertices;
};

struct NodeRenderUniforms {
    float screen_ratio = 1280.0/720.0;
    int selected_node;
};

struct KeyPresses {
    bool w = false;
    bool a = false;
    bool s = false;
    bool d = false;
    bool space = false;
    bool shift = false;
    bool control = false;
    bool command = false;
};

struct ShouldRender {
    bool faces = true;
    bool edges = false;
    bool vertices = false;
    bool nodes = false;
};

struct Camera {
    simd_float3 pos;
    simd_float3 vector;
    simd_float3 up_vector;
    simd_float2 FOV;
};

class Scheme {
protected:
    SchemeType type;
    
    Camera *camera_;
    
    Scene *scene_;
    unsigned long scene_vertex_length_;
    unsigned long scene_face_length_;
    unsigned long scene_node_length_;
    Vertex * scene_models_vertices_;
    Vertex * scene_models_projected_vertices_;
    Face * scene_models_faces_;
    
    Node * scene_models_nodes_;
    Vertex * scene_models_projected_nodes_;
    
    std::vector<Model *> controls_models_;
    std::vector<ModelUniforms> controls_model_uniforms_;
    unsigned long controls_vertex_length_;
    unsigned long controls_face_length_;
    unsigned long controls_node_length_;
    Vertex * control_models_vertices_;
    Vertex * control_models_projected_vertices_;
    Face * control_models_faces_;
    simd_float3 controls_origin_;
    
    ShouldRender should_render;
    
    float fps = 0;
    
    simd_int2 UI_start_;
    
    simd_float2 click_loc_;
    simd_float2 mouse_loc_;
    
    float x_sens_ = 0.1;
    float y_sens_ = 0.1;
    
    bool input_enabled = true;
    
    bool left_mouse_down_ = false;
    bool right_mouse_down_ = false;
    
    KeyPresses keypresses_;
    
    float clear_color[4] = {0.45f, 0.55f, 0.60f, 1.00f};
    
    int window_width_ = 1080;
    int window_height_ = 700;
    float aspect_ratio_ = 1080/700;
    
    bool show_UI = true;
    
    VertexRenderUniforms vertex_render_uniforms;
    
    NodeRenderUniforms node_render_uniforms_;
    
    bool should_reset_empty_buffers = true;
    bool should_reset_static_buffers = true;
    
    // action variables
    UserAction *current_action = NULL;
    std::deque<UserAction *> past_actions;
    
    virtual void HandleCameraMovement();
    
    virtual void HandleSelection(simd_float2 loc) = 0;
    virtual bool ClickOnScene(simd_float2 loc);
    
    virtual std::pair<int,float> ControlModelClicked(simd_float2 loc);
    
    virtual void SetControlsOrigin();
    virtual void MoveControlsModels();
    
    void UpdateUIVars();
    
    virtual void MainWindow();
    
    void CalculateCounts();
    
    void CalculateNumSceneVertices();
    void CalculateNumSceneFaces();
    void CalculateNumSceneNodes();
    void CalculateNumControlsVertices();
    void CalculateNumControlsFaces();
    void CalculateNumControlsNodes();
    
    void Undo();
public:
    Scheme();
    
    SchemeType GetType();
    
    void SetCamera(Camera *camera);
    void SetScene(Scene *scene);
    
    virtual void SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf);
    
    Camera *GetCamera();
    Scene *GetScene();
    std::vector<Model *> *GetControlsModels();
    std::vector<ModelUniforms> *GetControlsModelUniforms();
    
    void EnableInput(bool enabled);
    
    virtual void HandleMouseMovement(float x, float y, float dx, float dy);
    virtual void HandleKeyPresses(int key, bool keydown);
    virtual void HandleMouseDown(simd_float2 loc, bool left);
    virtual void HandleMouseUp(simd_float2 loc, bool left);
    
    void CreateNewModel();
    void NewModelFromFile(std::string path);
    
    virtual void BuildUI() = 0;
    
    VertexRenderUniforms *GetVertexRenderUniforms();
    NodeRenderUniforms *GetNodeRenderUniforms();
    
    void SaveSceneToFolder(std::string path);
    
    void SetResetEmptyBuffers(bool set);
    void SetResetStaticBuffers(bool set);
    
    bool ShouldResetEmptyBuffers();
    bool ShouldResetStaticBuffers();
    
    unsigned long NumSceneVertices();
    unsigned long NumSceneFaces();
    unsigned long NumSceneNodes();
    unsigned long NumControlsVertices();
    unsigned long NumControlsFaces();
    unsigned long NumControlsNodes();
    
    bool ShouldRenderFaces();
    bool ShouldRenderEdges();
    bool ShouldRenderVertices();
    bool ShouldRenderNodes();
    
    virtual void Update();
    
    virtual ~Scheme();
};

#endif /* Scheme_hpp */
