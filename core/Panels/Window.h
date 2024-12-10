#ifndef Window_h
#define Window_h

#include "Panel.h"
#include "ViewPanel.h"

class Window {
private:
    vec_int2 size_;
    std::vector<Panel> panels_;

    Mouse mouse_;
    Keys keys_;

    vec_float2 TranslatePixel(vec_float2 p);

    // BUFFERS
    // Buffer of array of PanelBufferInfo objects
    Buffer *panel_info_buffer_ = NULL;
    // dirtiness per compiled panel buffer - can be made more effecient later
    bool dirty_compiled_panel_buffers_[PNL_NUM_OUTBUFS];
    // array of compiled buffers across all panels
    unsigned long compiled_panel_buffer_capacities_[PNL_NUM_OUTBUFS];
    void *compiled_panel_buffers_[PNL_NUM_OUTBUFS]; // [[Buffer, Buffer, Buffer], [Buffer, Buffer, Buffer], ...]

    // call per-frame
    // update panel_info_buffer_
    // combine all (dirty) panel buffers into panel_buffers_ and also update dirty_buffers_
    void CompilePanelBuffers();
public:
    Window() = 0;
    Window(vec_int2 size);
    ~Window();

    void UpdateSize(vec_int2 size);

    void HandleKeyPresses(int key, bool down);
    void HandleMouseClick(vec_float2 loc, bool left, bool down);
    void HandleMouseMovement(float x, float y, float dx, float dy);

    void MakeViewWindow(Scene *scene);

    unsigned int NumPanels();
    std::vector<Panel> *GetPanels();
    Panel *GetPanel(unsigned int i);

    Buffer *GetPanelInfoBuffer();
    bool IsCompiledPanelBufferDirty(unsigned long buf);
    void CleanCompiledPanelBuffer(unsigned long buf);
    void **GetCompiledPanelBuffers();
};

#endif /* Window_h */