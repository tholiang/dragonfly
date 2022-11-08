//
//  EditModelScheme.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef EditModelScheme_h
#define EditModelScheme_h

#include "Scheme.h"
#include "../UserActions/ModelMoveAction.h"

class EditModelScheme : public Scheme {
private:
    int right_menu_width_ = 300;
    
    Arrow *z_arrow;
    Arrow *x_arrow;
    Arrow *y_arrow;
    // z base, z tip, x base, x tip, y base, y tip
    simd_float2 arrow_projections [6];
    // z, x, y
    int selected_arrow = -1;
    int ARROW_VERTEX_SIZE = 18;
    int ARROW_FACE_SIZE = 22;
    
    int selected_model = -1;
    
    unsigned long wanted_aid = 0;
    
    void CreateControlsModels();
    
    void HandleMouseUp(simd_float2 loc, bool left);
    
    std::pair<int, float> ModelClicked(simd_float2 loc);
    
    bool ClickOnScene(simd_float2 loc);
    
    void HandleSelection(simd_float2 loc);
    
    void ModelEditMenu();
    
    void SetControlsOrigin();
    
    void SetArrowProjections();
    
    void RightMenu();
    void MainWindow();
public:
    EditModelScheme();
    
    ~EditModelScheme();
    void SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf);
    void BuildUI();
    
    void SaveSelectedModelToFile(std::string path);
    
    void HandleMouseMovement(float x, float y, float dx, float dy);
    
    virtual void Update();
};

#endif /* EditModelScheme_h */
