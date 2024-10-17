#ifndef EditForceFieldScheme_h
#define EditForceFieldScheme_h

#include <stdio.h>

#include "Scheme.h"
#include "../Utils/Utils.h"

class EditForceFieldScheme : public Scheme {
private:
    // ---CLICK HANDLERS---
    // check if a click is on a valid scene selection area
    bool ClickOnScene(vec_float2 loc);
    // handle clicks - pure virtual, completely handled by child classes
    void HandleSelection(vec_float2 loc) = 0;
    // check if click collides with control model
    std::pair<int,float> ControlModelClicked(vec_float2 loc);
    // check if click collides with ui element
    std::pair<int, float> UIElementClicked(vec_float2 loc);

    // ---CONTROL MODELS TRANSFORM FUNCTIONS---
    void SetControlsBasis();
    void MoveControlsModels();
public:
    EditForceFieldScheme();
    ~EditForceFieldScheme();

    void Update();

    // ---DIRECT INPUT HANDLERS---
    void HandleMouseMovement(float x, float y, float dx, float dy);
    void HandleKeyPresses(int key, bool keydown);
    void HandleMouseDown(vec_float2 loc, bool left);
    void HandleMouseUp(vec_float2 loc, bool left);

    // ---RENDERING---
    void BuildUI();
};

#endif /* EditForceFieldScheme_h */
