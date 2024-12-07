// Panel just for viewing a scene

#ifndef ViewPanel_h
#define ViewPanel_h

#include "Panel.h"

class ViewPanel : public Panel {
private:
    Camera *camera_;
    bool lighting_enabled_ = false;

    void HandleCameraMovement();

    // inherited
    void HandleInput();
    void PrepareOutBuffers();
public:
    ViewPanel() = 0;
    ViewPanel(vec_float4 borders, Scene *scene);
    ~ViewPanel();

    void Update();

    void SetCamera(Camera *c);
    void EnableLighting(bool enabled);
}

#endif /* ViewPanel_h */