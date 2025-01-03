#ifndef Window_h
#define Window_h

#include "Panel.h"
#include "ViewPanel.h"

struct WindowAttributes {
    int screen_width;
    int screen_height;
};

class Window {
private:
    WindowAttributes attr_;
    std::vector<Panel *> panels_;
    
    // panel to send input to
    unsigned long focused_panel_ = 0;

    Mouse mouse_;
    Keys keys_;

    vec_float2 TranslatePixel(vec_float2 p);

    /* ---BUFFERS--- */
    // buffer of array of PanelBufferInfo objects
    bool dirty_panel_info_buffer_ = false;
    Buffer *panel_info_buffer_ = NULL;

    /* out buffers */
    // compiled buffers across all panels
    // dirtiness per compiled panel buffer - can be made more effecient later
    bool dirty_compiled_panel_buffers_[PNL_NUM_OUTBUFS];
    // note: buffer header size is total number of bytes of actual data in each compiled buffer
    Buffer *compiled_panel_buffers_[PNL_NUM_OUTBUFS]; // each elem: [BufferHeader [panel1 data] [panel2 data] ...]

    /* in buffers */
    bool dirty_compute_buffers_[CPT_NUM_OUTBUFS];
    Buffer *compute_buffers_[CPT_NUM_OUTBUFS]; // similar format as compiled_panel_buffers_
    
    /* counts (num threads) for each kernel */
    unsigned long kernel_counts_[CPT_NUM_KERNELS];

    // call per-frame
    // - update panel_info_buffer_
    // for out buffers - combine all (dirty) panel buffers into panel_buffers_ and also update dirty_buffers_
    // for in buffers - allocate correctly sized compiled buffers for in buffers across panels
    void PrepareBuffers();
    
    // call (from PrepareBuffers) when panel faces and edges have changed
    // copies scene, control, and ui faces + scene edges into the compute compiled face buffer
    // sets offsets for vertex references
    void UpdateComputeCompiledBuffers();
    
    // updates kernel_counts_ from panel
    void UpdateKernelCounts();
public:
    Window() = delete;
    Window(WindowAttributes attr);
    ~Window();

    // call at the start of every frame (before any gpu stuff)
    void Update(float fps);

    void UpdateAttributes(WindowAttributes attr);
    WindowAttributes GetAttributes();

    void HandleKeyPresses(int key, bool down);
    void HandleMouseClick(vec_float2 loc, bool left, bool down);
    void HandleMouseMovement(float x, float y, float dx, float dy);

    void MakeViewWindow(Scene *scene);

    unsigned int NumPanels();
    std::vector<Panel *> *GetPanels();
    Panel *GetPanel(unsigned int i);
    
    bool IsPanelBufferInfoDirty();
    void CleanPanelBufferInfo();
    Buffer *GetPanelBufferInfo();
    bool IsCompiledPanelBufferDirty(unsigned long buf);
    void CleanCompiledPanelBuffer(unsigned long buf);
    Buffer **GetCompiledPanelBuffers();
    bool IsComputeBufferDirty(unsigned long buf);
    void CleanComputeBuffer(unsigned long buf);
    Buffer **GetComputeBuffers();
    unsigned long *GetKernelCounts();
};

#endif /* Window_h */
