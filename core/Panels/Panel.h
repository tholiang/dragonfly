#ifndef Panel_h
#define Panel_h

#include <stdio.h>
#include <vector>
#include <string>
#include <sstream>
#include <deque>
#include <stdint.h>

#include <iostream>

#include "../Utils/Buffers.h"
#include "../Utils/Misc.h"
#include "../Utils/Vec.h"
#include "../Modeling/Scene.h"

using namespace DragonflyUtils;
using namespace Vec;

// each subclass should have a type - for easier casting
enum PanelType {
    View
};

// what to render - faces, vertices, ui...
struct PanelElements {
    bool faces = false;
    bool edges = false;
    bool vertices = false;
    bool controls = false;
    bool ui = false; // not including imgui
};

// all possible buffers to send to the gpu pipeline
struct PanelOutBuffers {
    Buffer *camera = NULL;

    Buffer *scene_lights = NULL;

    Buffer *scene_faces = NULL;
    Buffer *scene_edges = NULL;
    Buffer *scene_nodes = NULL;
    Buffer *scene_node_model_ids = NULL;
    Buffer *scene_node_vertex_links = NULL;
    Buffer *scene_model_transforms = NULL;

    Buffer *scene_slice_dots = NULL;
    Buffer *scene_slice_lines = NULL;
    Buffer *scene_slice_attributes = NULL;
    Buffer *scene_slice_transforms = NULL;
    
    Buffer *control_faces = NULL;
    Buffer *control_nodes = NULL;
    Buffer *control_node_model_ids = NULL;
    Buffer *control_node_vertex_links = NULL;
    Buffer *control_model_transforms = NULL;

    Buffer *ui_faces = NULL;
    Buffer *ui_vertices = NULL;
    Buffer *ui_element_ids = NULL;
    Buffer *ui_transforms = NULL;
};

// what buffers are wanted from the gpu pipeline
struct PanelWantedBuffers {
    bool computed_key_indices = false;
    bool computed_compiled_vertices = false;
    bool computed_compiled_faces = false;
    bool computed_model_vertices = false;
    bool computed_model_nodes = false;
};

// all possible buffers to take in from the gpu pipeline
struct PanelInBuffers {
    Buffer *computed_key_indices = NULL;
    Buffer *computed_compiled_vertices = NULL;
    Buffer *computed_compiled_faces = NULL;
    Buffer *computed_model_vertices = NULL;
    Buffer *computed_model_nodes = NULL;
};

class Panel {
protected:
    // data
    Scene *scene_;

    vec_float4 borders_; // panel rectangle relative to window (center, size)
    PanelType type_;
    PanelElements elements_;
    PanelOutBuffers out_buffers_;
    PanelWantedBuffers wanted_buffers_;
    PanelInBuffers in_buffers_;

    // input
    Mouse mouse_;
    Keys keys_;

    // flags
    // TODO: remove the need for these
    bool should_reset_empty_buffers = true;  // whether the compute pipeline should reset empty buffers (usually when something is created or deleted)
    bool should_reset_static_buffers = true; // whether the compute pipeline should reset static buffers (usually when a static buffer item is moved - like a vertex)

    virtual void HandleInput() = 0;
    virtual void PrepareOutBuffers() = 0;
public:
    Panel() = 0;
    // child classes should initialize type and wanted buffers here
    Panel(vec_float4 borders, Scene *scene);
    ~Panel();
    virtual void Update();

    void SetScene(Scene *s);

    vec_float4 GetBorders();
    PanelType GetType();
    PanelElements GetElements();
    PanelOutBuffers GetOutBuffers();
    PanelWantedBuffers GetWantedBuffers();
    void SetPanelInBuffers(PanelInBuffers b);

    void SetInputData(Mouse m, Keys k);

    // TODO: remove the need for these
    void SetResetEmptyBuffers(bool set);
    void SetResetStaticBuffers(bool set);
    
    bool ShouldResetEmptyBuffers();
    bool ShouldResetStaticBuffers();
};

#endif /* Panel_h */