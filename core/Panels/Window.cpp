#include "Window.h"

Window::Window(WindowAttributes attr) : attr_(attr) {
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        dirty_compiled_panel_buffers_[i] = false;
        compiled_panel_buffers_[i] = NULL;
    }

    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        compute_buffers_[i] = NULL;
    }
}

Window::~Window() {

}

void Window::Update() {
    PrepareBuffers();
}

vec_float2 Window::TranslatePixel(vec_float2 p) {
    p.x = (p.x / attr_.screen_width)*2 - 1;
    p.y = -((p.y / attr_.screen_height)*2 - 1);
    return p;
}

void Window::UpdateAttributes(WindowAttributes attr) {
    attr_ = attr;
}

WindowAttributes Window::GetAttributes() {
    return attr_;
}

void Window::HandleKeyPresses(int key, bool down) {
    switch (key) {
        case 119:
            keys_.w = down;
            break;
        case 97:
            keys_.a = down;
            break;
        case 115:
            keys_.s = down;
            break;
        case 100:
            keys_.d = down;
            break;
        case 32:
            keys_.space = down;
            break;
        case 122:
            // z
            // TODO
            // if (keys_.command && down) Undo();
            break;
        case 1073742049:
            keys_.shift = down;
            break;
        case 1073742048:
            keys_.control = down;
            break;
        case 1073742054:
            keys_.option = down;
            break;
        case 1073742055:
            keys_.command = down;
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
    mouse_.location.x = x / attr_.screen_width;
    mouse_.location.y = y / attr_.screen_height;
    mouse_.movement.x = dx / attr_.screen_width;
    mouse_.movement.y = dy / attr_.screen_height;
}

void Window::MakeViewWindow(Scene *scene) {
    ViewPanel view_panel = ViewPanel(vec_make_float4(0, 0, 1, 1), scene);
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
    return &panels_[i];
}

void Window::PrepareBuffers() {
    // if the number of panels have changed, regenerate everything
    bool regen_all = panel_info_buffer_ == NULL || panel_info_buffer_->size != panels_.size();
    if (regen_all) {
        if (panel_info_buffer_ != NULL) { free(panel_info_buffer_); }
        unsigned long data_size = panels_.size() * sizeof(PanelInfoBuffer);
        panel_info_buffer_ = (Buffer *) calloc(sizeof(BufferHeader) + data_size, 1);
        panel_info_buffer_->size = data_size;
        panel_info_buffer_->capacity = data_size;
        dirty_panel_info_buffer_ = true;
    }

    // set some info buffer stuff
    for (int j = 0; j < panels_.size(); j++) {
        PanelInfoBuffer *info_buf = (PanelInfoBuffer *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelInfoBuffer));
        info_buf->borders = panels_[j].GetBorders();
        info_buf->compiled_key_indices = panels_[j].GetCompiledBufferKeyIndices();
    }


    /* PANEL OUT BUFFERS */
    // get out buffers for all panels
    std::vector<Buffer **> panel_out_buffers;
    for (int j = 0; j < panels_.size(); j++) { panel_out_buffers.push_back(panels_[j].GetOutBuffers()); }
    
    // compile the panel out buffers
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        unsigned long total_size = 0;
        unsigned long total_capacity = 0;
        bool reorg = false;
        for (int j = 0; j < panels_.size(); j++) {
            // set panel info start idx (to what it will be)
            PanelInfoBuffer *info_buf = (PanelInfoBuffer *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelInfoBuffer));
            if (info_buf->panel_buffer_starts[i] != total_capacity) { // if start it off - then some buffer capacities were changed
                info_buf->panel_buffer_starts[i] = total_capacity;
                reorg = true;
            }

            BufferHeader header = *((BufferHeader *) panel_out_buffers[j][i]);
            total_size += header.size;
            total_capacity += header.capacity;
            info_buf->panel_buffer_headers[i] = header;
        }

        // regenerate compiled buffer if needed
        bool regen = regen_all || compiled_panel_buffers_[i] == NULL || total_capacity != compiled_panel_buffers_[i]->capacity;
        if (regen) {
            if (compiled_panel_buffers_[i] != NULL) { free(compiled_panel_buffers_[i]); }
            compiled_panel_buffers_[i] = (Buffer *) malloc(sizeof(BufferHeader) + total_capacity);
            compiled_panel_buffers_[i]->capacity = total_capacity;
        }
        compiled_panel_buffers_[i]->size = total_size;

        // fix data
        for (int j = 0; j < panels_.size(); j++) {
            PanelInfoBuffer *info_buf = (PanelInfoBuffer *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelInfoBuffer));
            if (reorg || regen || panels_[j].IsBufferDirty(i)) {
                void *panel_buffer_start = compiled_panel_buffers_[i]+info_buf->panel_buffer_starts[i];
                char *panel_out_buffer_data = ((char *) panel_out_buffers[j][i]) + sizeof(BufferHeader);
                memcpy(panel_buffer_start, (void *) panel_out_buffer_data, panel_out_buffers[j][i]->capacity);

                panels_[j].CleanBuffer(i);
                dirty_compiled_panel_buffers_[j] = true;
            }
        }
    }


    /* COMPUTE BUFFERS */
    // get (unset) in buffers for panel
    std::vector<Buffer **> panel_in_buffers;
    for (int j = 0; j < panels_.size(); j++) { panel_in_buffers.push_back(panels_[j].GetInBuffers(true)); }

    // compile the compute (out) buffers
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        // similar to above except we just always set the contained data since we don't change that much
        unsigned long total_size = 0;
        unsigned long total_capacity = 0;
        for (int j = 0; j < panels_.size(); j++) {
            PanelInfoBuffer *info_buf = (PanelInfoBuffer *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelInfoBuffer));
            info_buf->compute_buffer_starts[j] = total_size;

            BufferHeader header = *((BufferHeader *) panel_in_buffers[j][i]);
            total_size += header.size;
            total_capacity += header.capacity;
            info_buf->compute_buffer_headers[i] = header;
        }

        // regenerate compiled buffer if needed
        if (regen_all || compute_buffers_[i] == NULL || total_capacity != compute_buffers_[i]->capacity) {
            if (compute_buffers_[i] != NULL) { free(compute_buffers_[i]); }
            compute_buffers_[i] = (Buffer *) malloc(sizeof(BufferHeader) + total_capacity);
            compute_buffers_[i]->capacity = total_capacity;
        }
        compute_buffers_[i]->size = total_size;
    }
}

bool Window::IsPanelInfoBufferDirty() {
    return dirty_panel_info_buffer_;
}

void Window::CleanPanelInfoBuffer() {
    dirty_panel_info_buffer_ = false;
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

unsigned long *Window::GetCompiledPanelBufferSizes() {
    return compiled_panel_buffer_sizes_;
}

unsigned long *Window::GetCompiledPanelBufferCapacities() {
    return compiled_panel_buffer_capacities_;
}

Buffer **Window::GetCompiledPanelBuffers() {
    return compiled_panel_buffers_;
}

unsigned long *Window::GetComputeBufferCapacities() {
    return compute_buffer_capacities_;
}

Buffer **Window::GetComputeBuffers() {
    return compute_buffers_;
}
