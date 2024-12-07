#include "Window.h"

Window::Window(vec_int2 size) : size_(size) {

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