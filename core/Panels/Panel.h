#ifndef Panel_h
#define Panel_h

#include <stdio.h>
#include <vector>
#include <string>
#include <sstream>
#include <deque>
#include <stdint.h>

#include <iostream>

#include "../Utils/Constants.h"
#include "../Utils/Buffers.h"
#include "../Utils/Misc.h"
#include "../Utils/Vec.h"
#include "../Utils/SceneUtils.h"
#include "../Modeling/Scene.h"

using namespace DragonflyUtils;
using namespace Vec;

// each subclass should have a type - for easier casting
enum PanelType {
    View
};

// what to render - faces, vertices, ui...
struct PanelElements {
    bool scene = false;
    bool faces = false; // * if faces, edges, vertices, nodes, or slices are true, then scene must also be true
    bool edges = false;
    bool vertices = false;
    bool nodes = false;
    bool slices = false;
    bool controls = false;
    bool ui = false; // not including imgui
};

class Panel {
protected:
    // data
    Scene *scene_;

    vec_float4 borders_; // panel rectangle relative to window (center, size)
    PanelType type_;
    PanelElements elements_;
    // which out buffers have been modified
    bool dirty_buffers_[PNL_NUM_OUTBUFS];
    // all possible buffers to send to the gpu pipeline
    Buffer *out_buffers_[PNL_NUM_OUTBUFS];
    CompiledBufferKeyIndices compiled_buffer_key_indices_;
    // what buffers are wanted from the gpu pipeline
    bool wanted_buffers_[CPT_NUM_OUTBUFS];
    // all possible buffers to take in from the gpu pipeline
    Buffer *in_buffers_[CPT_NUM_OUTBUFS];

    // input
    Mouse mouse_;
    Keys keys_;

    virtual void HandleInput() = 0;
    // should only write data if needed
    virtual void PrepareOutBuffers() = 0;
    // populate compiled_buffer_key_indices_
    virtual void PrepareCompiledBufferKeyIndices();
    // resize/reallocate if needed
    virtual void PrepareInBuffers();
public:
    Panel() = delete;
    // child classes should initialize type and wanted buffers here
    Panel(vec_float4 borders, Scene *scene);
    ~Panel();
    virtual void Update();

    void SetScene(Scene *s);

    vec_float4 GetBorders();
    PanelType GetType();
    PanelElements GetElements();
    
    bool IsBufferDirty(unsigned int buf);
    void CleanBuffer(unsigned int buf);
    Buffer **GetOutBuffers();
    CompiledBufferKeyIndices GetCompiledBufferKeyIndices();
    bool IsBufferWanted(unsigned int buf);
    Buffer ** GetInBuffers(bool realloc);

    void SetInputData(Mouse m, Keys k);
};

#endif /* Panel_h */
