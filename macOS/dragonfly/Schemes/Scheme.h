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

#include "../Utils/Utils.h"
#include "../Utils/Basis.h"

#include "../Modeling/Model.h"
#include "../Modeling/Scene.h"
#include "../Modeling/Arrow.h"
#include "../Modeling/Rotator.h"

#include "../UI/UIElement.h"

#include "../UserActions/UserAction.h"

class SchemeController;

using namespace DragonflyUtils;

enum SchemeType {
    EditModel,
    EditFEV,
    EditNode,
    EditSlice
};

struct UIElementUniforms {
    simd_int3 position;
    simd_float3 up;
    simd_float3 right;
};

struct VertexRenderUniforms {
    float screen_ratio = 1280.0/720.0;
    int num_selected_vertices = 0;
    std::vector<int> selected_vertices;
};

struct NodeRenderUniforms {
    float screen_ratio = 1280.0/720.0;
    int selected_node;
};

struct UIRenderUniforms {
    int screen_width;
    int screen_height;
};

struct KeyPresses {
    bool w = false;
    bool a = false;
    bool s = false;
    bool d = false;
    bool space = false;
    bool shift = false;
    bool option = false;
    bool control = false;
    bool command = false;
};

struct ShouldRender {
    bool faces = true;
    bool edges = false;
    bool vertices = false;
    bool nodes = false;
    bool slices = false;
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
    
    SchemeController *controller_;
    
    // for creating empty buffers in compute pipeline - calculate with CalculateNum____() and get with Num______()
    unsigned long scene_vertex_length_;
    unsigned long scene_face_length_;
    unsigned long scene_node_length_;
    unsigned long scene_dot_length_;
    unsigned long scene_line_length_;
    
    unsigned long controls_vertex_length_;
    unsigned long controls_face_length_;
    unsigned long controls_node_length_;
    
    unsigned long ui_vertex_length_;
    unsigned long ui_face_length_;
    
    // given by compute pipeline with SetBufferContents() - used in handling clicks
    Vertex * scene_models_vertices_;
    Vertex * scene_models_projected_vertices_;
    Face * scene_models_faces_;
    
    Node * scene_models_nodes_;
    Vertex * scene_models_projected_nodes_;
    
    Vertex * control_models_vertices_;
    Vertex * control_models_projected_vertices_;
    Face * control_models_faces_;
    float curr_control_scale = 1;
    
    Vertex * scene_slice_plate_vertices_;
    
    Vertex * ui_elements_vertices_;
    UIFace * ui_elements_faces_;
    
    // actual model data for controls models (arrows, etc)
    std::vector<Model *> controls_models_;
    std::vector<ModelUniforms> controls_model_uniforms_;
    std::vector<Basis> controls_model_default_bases_;
    
    std::vector<UIElement *> ui_elements_;
    std::vector<UIElementUniforms> ui_element_uniforms_;
    
    // where to put the controls models - usually whatever is being edited
    Basis controls_basis_;
    
    // what the renderer should show
    ShouldRender should_render;
    
    float fps = 0;
    
    // beginning of the scheme UI - after menu bar
    simd_int2 UI_start_;
    
    // last click location
    simd_float2 click_loc_;
    // current mouse location
    simd_float2 mouse_loc_;
    
    float x_sens_ = 0.1;
    float y_sens_ = 0.1;
    
    bool input_enabled = true;
    bool lighting_enabled = false;
    
    bool left_mouse_down_ = false;
    bool right_mouse_down_ = false;
    
    // contains data on whether certain keys are currently being pressed
    KeyPresses keypresses_;
    
    float clear_color[4] = {0.45f, 0.55f, 0.60f, 1.00f};
    
    int prev_width = 1080;
    int prev_height = 700;
    int window_width_ = 1080;
    int window_height_ = 700;
    float aspect_ratio_ = 1080/700;
    
    bool show_UI = true;
    
    // for renderer - also contains list of selected vertices
    VertexRenderUniforms vertex_render_uniforms;
    
    // for renderer - also contains the selected node
    NodeRenderUniforms node_render_uniforms_;
    
    UIRenderUniforms ui_render_uniforms_;
    
    // whether the compute pipeline should reset empty buffers (usually when something is created or deleted)
    bool should_reset_empty_buffers = true;
    // whether the compute pipeline should reset static buffers (usually when a static buffer item is moved - like a vertex)
    bool should_reset_static_buffers = true;
    
    // action variables - for undo
    UserAction *current_action = NULL;
    std::deque<UserAction *> past_actions;
    
    virtual void HandleCameraMovement();
    
    virtual void HandleSelection(simd_float2 loc) = 0;
    virtual bool ClickOnScene(simd_float2 loc);
    
    virtual std::pair<int,float> ControlModelClicked(simd_float2 loc);
    
    virtual void SetControlsBasis();
    virtual void MoveControlsModels();
    
    void UpdateUIVars();
    
    virtual void MainWindow();
    
    // call all following calculate functions - usually when something is created or deleted
    void CalculateCounts();
    
    void CalculateNumSceneVertices();
    void CalculateNumSceneFaces();
    void CalculateNumSceneNodes();
    virtual void CalculateNumSceneDots();
    virtual void CalculateNumSceneLines();
    void CalculateNumControlsVertices();
    void CalculateNumControlsFaces();
    void CalculateNumControlsNodes();
    void CalculateNumUIVertices();
    void CalculateNumUIFaces();
    
    void MakeRect(int x, int y, int w, int h, int z, simd_float4 color);
    void MakeIsoTriangle(int x, int y, int w, int h, int z, simd_float4 color);
    
    void ChangeElementLocation(int eid, int x, int y);
    void ChangeRectDim(int eid, int w, int h);
    
    bool DidScreenSizeChange();
    
    void Undo();
public:
    Scheme();
    
    SchemeType GetType();
    
    void SetController(SchemeController *sc);
    
    void SetCamera(Camera *camera);
    void SetScene(Scene *scene);
    
    virtual void SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf, Vertex *ssp, Vertex *uiv, UIFace *uif);
    
    Camera *GetCamera();
    Scene *GetScene();
    virtual std::vector<Model *> *GetModels();
    virtual std::vector<ModelUniforms> *GetModelUniforms();
    virtual std::vector<Slice *> *GetSlices();
    virtual std::vector<SliceAttributes> GetSliceAttributes();
    virtual std::vector<ModelUniforms> *GetSliceUniforms();
    std::vector<Model *> *GetControlsModels();
    std::vector<ModelUniforms> *GetControlsModelUniforms();
    std::vector<UIElement *> *GetUIElements();
    std::vector<UIElementUniforms> *GetUIElementUniforms();
    
    void EnableInput(bool enabled);
    bool IsInputEnabled();
    
    void EnableLighting(bool enabled);
    
    virtual void HandleMouseMovement(float x, float y, float dx, float dy);
    virtual void HandleKeyPresses(int key, bool keydown);
    virtual void HandleMouseDown(simd_float2 loc, bool left);
    virtual void HandleMouseUp(simd_float2 loc, bool left);
    
    void CreateNewModel();
    void NewModelFromFile(std::string path);
    void NewModelFromPointData(std::string path);
    
    virtual void BuildUI() = 0;
    
    VertexRenderUniforms *GetVertexRenderUniforms();
    NodeRenderUniforms *GetNodeRenderUniforms();
    UIRenderUniforms *GetUIRenderUniforms();
    
    void SaveSceneToFolder(std::string path);
    
    void SetResetEmptyBuffers(bool set);
    void SetResetStaticBuffers(bool set);
    
    bool ShouldResetEmptyBuffers();
    bool ShouldResetStaticBuffers();
    
    bool LightingEnabled();
    
    unsigned long NumSceneVertices();
    unsigned long NumSceneFaces();
    unsigned long NumSceneNodes();
    virtual unsigned long NumSceneDots();
    virtual unsigned long NumSceneLines();
    unsigned long NumControlsVertices();
    unsigned long NumControlsFaces();
    unsigned long NumControlsNodes();
    unsigned long NumUIFaces();
    unsigned long NumUIVertices();
    
    bool ShouldRenderFaces();
    bool ShouldRenderEdges();
    bool ShouldRenderVertices();
    bool ShouldRenderNodes();
    bool ShouldRenderSlices();
    
    virtual void Update();
    
    virtual simd_float4 GetEditWindow();
    
    virtual ~Scheme();
};

#endif /* Scheme_hpp */
