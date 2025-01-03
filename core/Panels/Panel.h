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
#include "../UI/UIElement.h"

using namespace DragonflyUtils;
using namespace Vec;

// each subclass should have a type - for easier casting
enum PanelType {
    View
};

// what to render - faces, vertices, ui...
struct PanelElements {
    bool scene = false;
    bool faces = false;
    bool edges = false;
    bool vertices = false; // squares
    bool nodes = false; // circles
    bool slices = false;
    bool ui = false; // not including imgui
    bool light = false;
};

class Panel {
protected:
    // data
    Scene *scene_ = NULL;

    vec_float4 borders_; // panel rectangle relative to window (offset (x,y), percent of screen (w, h))
    PanelType type_;
    PanelElements elements_;
    // which out buffers have been modified
    bool dirty_buffers_[PNL_NUM_OUTBUFS];
    // all possible buffers to send to the gpu pipeline
    Buffer *out_buffers_[PNL_NUM_OUTBUFS];
    uint64_t compiled_buffer_key_indices_[CBKI_NUM_KEYS];
    // all possible buffers to take in from the gpu pipeline
    Buffer *in_buffers_[CPT_NUM_OUTBUFS];
    // extra buffers to store some face data
    bool dirty_extra_buffers_[PNL_NUM_XBUFS];
    Buffer *extra_buffers_[PNL_NUM_XBUFS];
    
    /* counts (num threads) for each kernel for this panel */
    unsigned long panel_kernel_counts_[CPT_NUM_KERNELS];

    // input
    Mouse mouse_;
    Keys keys_;

    virtual void HandleInput(float fps) = 0;
    // create needed out buffers and set initial data - should only call on init and scene change
    virtual void InitOutBuffers();
    // resize/reallocate if needed
    virtual void InitInBuffers();
    // create needed extra buffers and set initial data - usage same as above
    virtual void InitExtraBuffers();
    // populate compiled_buffer_key_indices_
    virtual void PrepareCompiledBufferKeyIndices();
    // populate kernel counts depending on elements
    virtual void PrepareKernelCounts();
public:
    Panel() = delete;
    // child classes should initialize type and wanted buffers here
    Panel(vec_float4 borders, Scene *scene);
    ~Panel();
    virtual void Update(float fps);

    void SetScene(Scene *s);

    vec_float4 GetBorders();
    PanelType GetType();
    PanelElements GetElements();
    
    bool IsBufferDirty(unsigned int buf);
    void CleanBuffer(unsigned int buf);
    Buffer **GetOutBuffers();
    uint64_t *GetCompiledBufferKeyIndices();
    Buffer **GetInBuffers();
    bool IsXBufferDirty(unsigned int buf);
    void CleanXBuffer(unsigned int buf);
    Buffer **GetXBuffers();
    unsigned long *GetKernelCounts();

    void SetInputData(Mouse m, Keys k);
};

#endif /* Panel_h */
