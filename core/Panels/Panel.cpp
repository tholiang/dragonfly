#include "Panel.h"

Panel::Panel(vec_float4 borders, Scene *scene) : borders_(borders), scene_(scene) {
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        dirty_buffers_[i] = true;
        out_buffers_[i] = NULL;
    }
    for (int i = 0; i < PNL_NUM_INBUFS; i++) {
        wanted_buffers_[i] = false;
        in_buffers_[i] = NULL;
    }
}

Panel::~Panel() {

}

void Panel::Update() {
    HandleInput();
}

void Panel::SetScene(Scene *s) {
    scene_ = s;
}

vec_float4 Panel::GetBorders() { return borders_; }
PanelType Panel::GetType() { return type_; }
PanelElements Panel::GetElements() { return elements_; }
bool Panel::IsBufferDirty(unsigned int buf) { return dirty_buffers_[buf]; }
void Panel::CleanBuffer(unsigned int buf) { dirty_buffers_[buf] = false; }
Buffer **Panel::GetOutBuffers() {
    PrepareOutBuffers();
    return out_buffers_;
}
CompiledBufferKeyIndices Panel::GetCompiledBufferKeyIndices() {
    PrepareCompiledBufferKeyIndices();
    return key_indices_;
}
bool Panel::IsBufferWanted(unsigned int buf) { return wanted_buffers_[buf]; }
Buffer **Panel::GetInBuffers(bool realloc) {
    if (realloc) { PrepareInBuffers(); }
    return in_buffers_;
}

void Panel::SetInputData(Mouse m, Keys k) {
    keys_ = k;
    mouse_ = m;

    // set mouse location and movement relative to panel
    mouse_.location.x -= borders_.x;
    mouse_.location.y -= borders_.y;
    mouse_.movement.x *= borders_.z;
    mouse_.movement.y *= borders_.w;
}

void Panel::PrepareInBuffers() {
    
}

void Panel::PrepareCompiledBufferKeyIndices() {

}