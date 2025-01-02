// Panel just for viewing a scene

#ifndef ViewPanel_h
#define ViewPanel_h

#include "Panel.h"

class ViewPanel : public Panel {
private:
    Camera *camera_;
    bool lighting_enabled_ = false;
    float fps = 0.0;

    void HandleCameraMovement();

    // inherited
    void HandleInput();
    void InitOutBuffers();
    void InitExtraBuffers();
public:
    ViewPanel() = delete;
    ViewPanel(vec_float4 borders, Scene *scene);
    ~ViewPanel();

    void Update();

    void SetCamera(Camera *c);
    void EnableLighting(bool enabled);
};

#endif /* ViewPanel_h */
