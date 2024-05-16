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
#include <deque>
#include <stdint.h>

#include "Utils/Vec.h"
using namespace Vec;

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
struct CompiledBufferKeyIndices; // from compute pipeline

using namespace DragonflyUtils;

enum SchemeType {
    EditModel,
    EditFEV,
    EditNode,
    EditSlice
};

struct UIElementTransform {
    vec_int3 position;
    vec_float3 up;
    vec_float3 right;
};

struct WindowAttributes {
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
    vec_float3 pos;
    vec_float3 vector;
    vec_float3 up_vector;
    vec_float2 FOV;
};

class Scheme {
protected:
    // ---GENERAL SCHEME VARIABLES---
    SchemeType type;
    Camera *camera_;
    Scene *scene_;
    SchemeController *controller_;
    ShouldRender should_render; // what the renderer should show (node circles, vertex squares, etc.)
    bool lighting_enabled = false;
    
    // ---DISPLAY DATA---
    float fps = 0;
    WindowAttributes window_attributes;
    int prev_width = 1080; // for changes in window size
    int prev_height = 700;
    int window_width_ = 1080;
    int window_height_ = 700;
    float aspect_ratio_ = 1080/700;
    float clear_color[4] = {0.45f, 0.55f, 0.60f, 1.00f}; // background color
    
    // ---DISPLAY FLAGS---
    bool should_reset_empty_buffers = true;  // whether the compute pipeline should reset empty buffers (usually when something is created or deleted)
    bool should_reset_static_buffers = true; // whether the compute pipeline should reset static buffers (usually when a static buffer item is moved - like a vertex)
    
    
    // ---CONTROLS MODELS---
    // actual model data for controls models (arrows, etc)
    std::vector<Model *> controls_models_;
    std::vector<ModelTransform> controls_model_uniforms_;
    std::vector<Basis> controls_model_default_bases_;
    float curr_control_scale = 1; // number to scale control models by - should get larger the farther the camera is from the model
    Basis controls_basis_; // where to put the controls models - usually whatever is being edited
    
    // ---UI ELEMENTS---
    bool show_UI = true;
    std::vector<UIElement *> ui_elements_;
    std::vector<UIElementTransform> ui_element_uniforms_;
    vec_int2 UI_start_; // beginning of the scheme UI - after menu bar
    
    
    // ---INPUT DATA---
    bool input_enabled = true;
    vec_float2 click_loc_; // last click location
    vec_float2 mouse_loc_; // current mouse location
    float x_sens_ = 0.1;
    float y_sens_ = 0.1;
    bool left_mouse_down_ = false;
    bool right_mouse_down_ = false;
    KeyPresses keypresses_; // contains data on whether certain keys are currently being pressed
    std::vector<uint32_t> selected_vertices; // list of selected vertex indices
    int selected_node_ = -1;
    
    // action variables - for undo
    UserAction *current_action = NULL;
    std::deque<UserAction *> past_actions;
    
    
    // ---COUNTS OF VARIOUS SCHEME DATA---
    // for creating empty buffers in compute pipeline - calculate with CalculateNum____() and get with Num______()
    unsigned long scene_vertex_length_ = 0;
    unsigned long scene_face_length_ = 0;
    unsigned long scene_node_length_ = 0;
    unsigned long scene_dot_length_ = 0;
    unsigned long scene_line_length_ = 0;
    unsigned long controls_vertex_length_ = 0;
    unsigned long controls_face_length_ = 0;
    unsigned long controls_node_length_ = 0;
    unsigned long ui_vertex_length_ = 0;
    unsigned long ui_face_length_ = 0;
    
    // ---DATA CALCULATED BY COMPUTE KERNEL--
    // given by compute pipeline with SetBufferContents() - used in handling clicks
    CompiledBufferKeyIndices *computed_key_indices_ = NULL;
    Vertex * computed_compiled_vertices_ = NULL;
    Face * computed_compiled_faces_ = NULL;
    Vertex * computed_model_vertices_ = NULL;
    Node * computed_model_nodes_ = NULL;
    
    
    
    // handle linear transforms of camera from key presses
    virtual void HandleCameraMovement();
    
    // undo last action
    void Undo();
    
    // ---CLICK HANDLERS---
    // check if a click is on a valid scene selection area
    virtual bool ClickOnScene(vec_float2 loc);
    // handle clicks - pure virtual, completely handled by child classes
    virtual void HandleSelection(vec_float2 loc) = 0;
    // check if click collides with control model
    virtual std::pair<int,float> ControlModelClicked(vec_float2 loc);
    // check if click collides with ui element
    virtual std::pair<int, float> UIElementClicked(vec_float2 loc);
    
    // ---CONTROL MODELS TRANSFORM FUNCTIONS---
    virtual void SetControlsBasis();
    virtual void MoveControlsModels();
    
    // ---UI RENDER FUNCTIONS---
    void UpdateUIVars();
    virtual void MainWindow(); // for imgui
    
    void MakeRect(int x, int y, int w, int h, int z, vec_float4 color);
    void MakeIsoTriangle(int x, int y, int w, int h, int z, vec_float4 color);
    
    void ChangeElementLocation(int eid, int x, int y);
    void ChangeRectDim(int eid, int w, int h);
    
    bool DidScreenSizeChange();
    
    // ---COUNTERS---
    // call when something is created or deleted
    void CalculateCounts(); // calls all following functions
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
    
    // ---INDEX RELATIONS---
    std::pair<int, int> GetModelVertexIdx(int compiled_idx); // take in idx of scene vertex in compiled array and return linked model idx and idx in linked model
    std::pair<int, int> GetModelFaceIdx(int compiled_idx); // take in idx of scene face in compiled array and return linked model idx and idx in linked model
    std::pair<int, int> GetModelNodeIdx(int node_idx); // take in idx of scene node in node array and return linked model idx and idx in linked model
    int GetCompiledVertexIdx(int model_idx, int vertex_idx); // take in idx of model vertex and model idx and return idx in compiled array
    int GetCompiledFaceIdx(int model_idx, int face_idx); // take in idx of model face and model idx and return idx in compiled array
    int GetArrayNodeIdx(int model_idx, int node_idx); // take in idx of model node and model idx and return idx in compiled array
public:
    // ---GENERAL SCHEME FUNCTIONS---
    Scheme(); // constructor
    virtual ~Scheme(); // destructor
    SchemeType GetType();
    virtual void Update(); // update function called every frame
    void SetController(SchemeController *sc);
    void SetCamera(Camera *camera);
    void SetScene(Scene *scene);
    
    // ---SCHEME SETTINGS---
    void EnableInput(bool enabled);
    bool IsInputEnabled();
    void EnableLighting(bool enabled);
    
    // ---DIRECT INPUT HANDLERS---
    virtual void HandleMouseMovement(float x, float y, float dx, float dy);
    virtual void HandleKeyPresses(int key, bool keydown);
    virtual void HandleMouseDown(vec_float2 loc, bool left);
    virtual void HandleMouseUp(vec_float2 loc, bool left);
    
    // ---SCENE EDITORS---
    void CreateNewModel();
    void NewModelFromFile(std::string path);
    void NewModelFromPointData(std::string path);
    void SaveSceneToFolder(std::string path);
    
    // ---RENDERING---
    virtual void BuildUI() = 0;
    
    // ---ENGINE FLAGS---
    void SetResetEmptyBuffers(bool set);
    void SetResetStaticBuffers(bool set);
    
    bool ShouldResetEmptyBuffers();
    bool ShouldResetStaticBuffers();
    
    // ---GETTERS---
    Camera *GetCamera();
    Scene *GetScene();
    bool LightingEnabled();
    WindowAttributes *GetWindowAttributes();
    std::vector<uint32_t> GetSelectedVertices();
    int GetSelectedNode();
    // for EditSliceScheme only
    virtual vec_float4 GetEditWindow();
    
    // functions to get counts for entire scheme - need to call CalculateCounts first for accurate data
    unsigned long NumSceneModels();
    unsigned long NumSceneVertices();
    unsigned long NumSceneFaces();
    unsigned long NumSceneNodes();
    virtual unsigned long NumSceneSlices(); // virtual for EditSliceScheme
    virtual unsigned long NumSceneDots(); // virtual for EditSliceScheme
    virtual unsigned long NumSceneLines(); // virtual for EditSliceScheme
    unsigned long NumControlsModels();
    unsigned long NumControlsVertices();
    unsigned long NumControlsFaces();
    unsigned long NumControlsNodes();
    unsigned long NumUIElements();
    unsigned long NumUIFaces();
    unsigned long NumUIVertices();
    
    bool ShouldRenderFaces();
    bool ShouldRenderEdges();
    bool ShouldRenderVertices();
    bool ShouldRenderNodes();
    bool ShouldRenderSlices();
    
    // ---FOR COMPUTE BUFFERS---
    // setter for compute buffer to set buffer data
    virtual void SetBufferContents(CompiledBufferKeyIndices *cki, Vertex *ccv, Face *ccf, Vertex *cmv, Node *cmn);
    
    // functions to set data in gpu buffers for compute pipeline
    void SetSceneFaceBuffer(Face *buf, unsigned long vertex_start); // start of scene vertices in compiled vertex buffer
    void SetSceneEdgeBuffer(vec_int2 *buf, unsigned long vertex_start); // start of scene vertices in cvb
    void SetSceneNodeBuffer(Node *buf);
    void SetSceneNodeModelIDBuffer(uint32_t *buf, unsigned long model_start); // start of scene models in node model id buffer
    void SetSceneNodeVertexLinkBuffer(NodeVertexLink *buf, unsigned long node_start); // start of scene nodes in node buffer
    void SetSceneModelTransformBuffer(ModelTransform *buf);
    
    void SetControlFaceBuffer(Face *buf, unsigned long vertex_start); // start of control vertices in cvb
    void SetControlNodeBuffer(Node *buf);
    void SetControlNodeModelIDBuffer(uint32_t *buf, unsigned long model_start); // start of control models in node model id buffer
    void SetControlNodeVertexLinkBuffer(NodeVertexLink *buf, unsigned long node_start); // start of control nodes in node buffer
    void SetControlModelTransformBuffer(ModelTransform *buf);
    
    virtual void SetSliceDotBuffer(Dot *buf);
    virtual void SetSliceLineBuffer(vec_int2 *buf, unsigned long dot_start); // start of dots in cvb
    virtual void SetSliceAttributesBuffer(SliceAttributes *buf);
    void SetSliceTransformBuffer(ModelTransform *buf);
    
    void SetUIFaceBuffer(Face *buf, unsigned long vertex_start); // start of ui vertices in cvb
    void SetUIVertexBuffer(UIVertex *buf);
    void SetUIElementIDBuffer(uint32_t *buf);
    void SetUITransformBuffer(UIElementTransform *buf);
};

#endif /* Scheme_hpp */
