#include "Window.h"

Window::Window(vec_int2 size) : size_(size) {
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        dirty_compiled_panel_buffers_[i] = false;
        compiled_panel_buffer_capacities_[i] = 0;
        compiled_panel_buffers_[i] = NULL;
    }
}

Window::~Window() {

}

vec_float2 Window::TranslatePixel(vec_float2 p) {
    p.x = (p.x / size_.x)*2 - 1;
    p.y = -((p.y / size_.y)*2 - 1);
    return p;
}

void Window::UpdateSize(vec_int2 size) {
    size_ = size;
}

void Window::HandleKeyPresses(int key, bool down) {
    switch (key) {
        case 119:
            keys_.w = keydown;
            break;
        case 97:
            keys_.a = keydown;
            break;
        case 115:
            keys_.s = keydown;
            break;
        case 100:
            keys_.d = keydown;
            break;
        case 32:
            keys_.space = keydown;
            break;
        case 122:
            // z
            // TODO
            // if (keys_.command && keydown) Undo();
            break;
        case 1073742049:
            keys_.shift = keydown;
            break;
        case 1073742048:
            keys_.control = keydown;
            break;
        case 1073742054:
            keys_.option = keydown;
            break;
        case 1073742055:
            keys_.command = keydown;
            break;
        default:
            break;
    }
}

void Window::HandleMouseClick(vec_float2 loc, bool left, bool down) {
    if (left) {
        mouse_.left = down;
    } else {
        mouse_.right = down;
    }
}

void Window::HandleMouseMovement(float x, float y, float dx, float dy) {
    mouse_.location.x = x / size_.x;
    mouse_.location.y = y / size_.y;
    mouse_.movement.x = dx / size_.x;
    mouse_.movement.y = dy / size_.y;
}

void Window::MakeViewWindow(Scene *scene) {
    Panel view_panel = ViewPanel(vec_make_float4(0, 0, 1, 1), scene);
    panels_.push_back(view_panel);
}

unsigned int Window::NumPanels() {
    return panels_.size();
}

std::vector<Panel> *Window::GetPanels() {
    return &panels_;
}

Panel *Window::GetPanel(unsigned int i) {
    assert(i < panels_.size());
    return &panels[i];
}

void Window::CompilePanelBuffers() {
    // get out buffers for all panels
    std::vector<Buffer **> panel_out_buffers;
    for (int j = 0; j < panels_.size(); j++) { panel_out_buffers.push_back(panels_[j].GetOutBuffers()); }

    // if the number of panels have changed, regenerate everything
    bool regen_all = panel_info_buffer_ == NULL || panel_info_buffer_->size() != panels_.size();
    if (regen_all) {
        if (panel_info_buffer_ != NULL) { free(panel_info_buffer_); }
        panel_info_buffer_ = (Buffer *) malloc(sizeof(Buffer) + (panels_.size() * sizeof(PanelInfoBuffer)));
    }

    // set panel info borders (just always do this)
    for (int j = 0; j < panels_.size(); j++) {
        PanelInfoBuffer *info_buf = (PanelInfoBuffer *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelInfoBuffer));
        info_buf->borders = panels_[j].GetBorders();
    }
    
    // compile the panel buffers
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        unsigned long total_capacity = 0;
        bool reorg = false;
        for (int j = 0; j < panels_.size(); j++) {
            // set panel info start idx (to what it will be)
            PanelInfoBuffer *info_buf = (PanelInfoBuffer *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelInfoBuffer));
            if (info_buf->buffer_starts[i] != total_capacity) { // if start it off - then some buffer capacities were changed
                info_buf->buffer_starts[i] = total_capacity;
                reorg = true;
            }

            total_capacity += TotalBufferSize(panel_out_buffers[j][i]);
        }

        // regenerate compiled buffer if needed
        bool regen = regen_all || total_capacity != panel_buffer_capacities_[i];
        if (regen) {
            if (compiled_panel_buffers_[i] != NULL) { free(compiled_panel_buffers_[i]); }
            compiled_panel_buffers_[i] = malloc(total_capacity);
            compiled_panel_buffer_capacities_[i] = total_capacity;
        }

        // fix data
        for (int j = 0; j < panels_.size(); j++) {
            PanelInfoBuffer *info_buf = (PanelInfoBuffer *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelInfoBuffer));
            if (reorg || regen || panels_[j].IsBufferDirty(i)) {
                void *panel_buffer_start = compiled_panel_buffers_[i]+info_buf->buffer_starts[i];
                Buffer *panel_out_buffer = panel_out_buffers[j][i]
                memcpy(panel_buffer_start, (void *) panel_out_buffer, TotalBufferSize(panel_out_buffer));

                panels_[j].CleanBuffer(i);
                dirty_compiled_panel_buffers_[j] = true;
            }
        }
    }
}

Buffer *Window::GetPanelInfoBuffer() {
    return panel_info_buffer_;
}

bool Window::IsCompiledPanelBufferDirty(unsigned long buf) {
    assert(buf < PNL_NUM_OUTBUFS);
    return dirty_compiled_panel_buffers_[buf];
}

void Window::CleanCompiledPanelBuffer(unsigned long buf) {
    assert(buf < PNL_NUM_OUTBUFS);
    dirty_compiled_panel_buffers_[buf] = false;
}

void **Window::GetCompiledPanelBuffers() {
    return compiled_panel_buffers_;
}