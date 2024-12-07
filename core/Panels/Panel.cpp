#include "Panel.h"

Panel::Panel(vec_float4 borders, Scene *scene) : borders_(borders), scene_(scene) {

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
PanelOutBuffers Panel::GetOutBuffers() { 
    PrepareOutBuffers();
    return out_buffers_;
}
PanelWantedBuffers Panel::GetWantedBuffers() { return wanted_buffers_; }
void Panel::SetPanelInBuffers(PanelInBuffers b) { in_buffers_ = b; }

void Panel::SetInputData(Mouse m, Keys k) {
    keys_ = k;
    mouse_ = m;

    // set mouse location and movement relative to panel
    mouse_.location.x -= borders_.x;
    mouse_.location.y -= borders_.y;
    mouse_.movement.x *= borders_.z;
    mouse_.movement.y *= borders_.w;
}

void Panel::SetResetEmptyBuffers(bool set) { should_reset_empty_buffers = set; }
void Panel::SetResetStaticBuffers(bool set) { should_reset_static_buffers = set; }

bool Panel::ShouldResetEmptyBuffers() { return should_reset_empty_buffers; }
bool Panel::ShouldResetStaticBuffers() { return should_reset_static_buffers; }