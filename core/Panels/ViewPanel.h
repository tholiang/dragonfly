// Panel just for viewing a scene

#ifndef ViewPanel_h
#define ViewPanel_h

#include "Panel.h"

class ViewPanel : public Panel {
private:
    Camera *camera_;
    bool lighting_enabled_ = false;

    void HandleCameraMovement(float fps);

    // inherited
    void HandleInput(float fps);
    void InitOutBuffers();
    void InitInBuffers();
    void InitExtraBuffers();
public:
    ViewPanel() = delete;
    ViewPanel(vec_float4 borders, Scene *scene);
    ~ViewPanel();

    void Update(float fps);

    void SetCamera(Camera *c);
    void EnableLighting(bool enabled);
};

#endif /* ViewPanel_h */
