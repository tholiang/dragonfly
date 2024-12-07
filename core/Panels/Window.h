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
};

#endif /* Window_h */