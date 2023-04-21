//
//  EditNodeScheme.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef EditNodeScheme_h
#define EditNodeScheme_h

#include "Scheme.h"

class EditNodeScheme : public Scheme {
private:
    int right_menu_width_ = 300;
    
    bool render_rightclick_popup_ = false;
    simd_float2 rightclick_popup_loc_;
    simd_float2 rightclick_popup_size_;
    bool rightclick_popup_clicked_ = false;
    
    Arrow *z_arrow;
    Arrow *x_arrow;
    Arrow *y_arrow;
    
    Rotator *z_rotator;
    Rotator *x_rotator;
    Rotator *y_rotator;
    // z base, z tip, x base, x tip, y base, y tip
    simd_float2 arrow_projections [6];
    simd_float2 rotator_projections [6];
    // z, x, y
    int selected_arrow = -1;
    int selected_rotator = -1;
    int ARROW_VERTEX_SIZE = 10;
    int ARROW_FACE_SIZE = 12;
    int ROTATOR_VERTEX_SIZE = 20;
    int ROTATOR_FACE_SIZE = 8;
    
    int selected_node_ = -1;
    int selected_model_ = -1;
    
    unsigned long wanted_aid = 0;
    float wanted_time = 0;
    
    std::string angle_input_x = "0";
    std::string angle_input_y = "0";
    std::string angle_input_z = "0";
    
    std::string scale_input_x = "1";
    std::string scale_input_y = "1";
    std::string scale_input_z = "1";
    
    void GenerateCustomUI();
    
    void CreateControlsModels();
    
    std::pair<std::pair<int, int>, float> NodeClicked(simd_float2 loc);
    
    bool ClickOnScene(simd_float2 loc);
    
    void HandleSelection(simd_float2 loc);
    
    void SetControlsBasis();
    
    void SetArrowProjections();
    
    void RightClickPopup();
    
    void RightMenu();
    void NodeEditMenu();
    
    void MainWindow();
    void UpdateCustomUI();
public:
    void BuildUI();
    void SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf, Vertex *ssp, Vertex *uiv, UIFace *uif);
    
    void HandleMouseMovement(float x, float y, float dx, float dy);
    
    void HandleMouseDown(simd_float2 loc, bool left);
    void HandleMouseUp(simd_float2 loc, bool left);
    
    EditNodeScheme();
    ~EditNodeScheme();
};

#endif /* EditNodeScheme_h */
