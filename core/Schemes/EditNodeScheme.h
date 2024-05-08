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
    int bottom_menu_height_ = 200;
    
    bool render_rightclick_popup_ = false;
    vector_float2 rightclick_popup_loc_;
    vector_float2 rightclick_popup_size_;
    bool rightclick_popup_clicked_ = false;
    
    Arrow *z_arrow;
    Arrow *x_arrow;
    Arrow *y_arrow;
    
    Rotator *z_rotator;
    Rotator *x_rotator;
    Rotator *y_rotator;
    // z base, z tip, x base, x tip, y base, y tip
    vector_float2 arrow_projections [6];
    vector_float2 rotator_projections [6];
    // z, x, y
    int selected_arrow = -1;
    int selected_rotator = -1;
    int ARROW_VERTEX_SIZE = 10;
    int ARROW_FACE_SIZE = 12;
    int ROTATOR_VERTEX_SIZE = 20;
    int ROTATOR_FACE_SIZE = 8;
    
    int selected_model_ = -1;
    
    int selected_ui_elem = -1;
    int selected_key = -1;
    std::vector<int> clickable_ui;
    int key_ui_start = 5;
    
    int wanted_aid = -1;
    float wanted_time = 0;
    bool anim_paused = true;
    
    std::string angle_input_x = "0";
    std::string angle_input_y = "0";
    std::string angle_input_z = "0";
    
    std::string scale_input_x = "1";
    std::string scale_input_y = "1";
    std::string scale_input_z = "1";
    
    void GenerateCustomUI();
    void UpdateCustomUI();
    void SetNewAnimations(int aid);
    void UpdateTimeKey();
    
    void CreateControlsModels();
    
    std::pair<std::pair<int, int>, float> NodeClicked(vector_float2 loc);
    
    float GetTimeFromLocation(vector_float2 loc);
    
    bool ClickOnScene(vector_float2 loc);
    
    void HandleSelection(vector_float2 loc);
    
    void SetControlsBasis();
    
    void SetArrowProjections();
    
    void RightClickPopup();
    
    void BottomMenu();
    void RightMenu();
    void NodeEditMenu();
    void AnimationMenu();
    
    void MainWindow();
public:
    void BuildUI();
    void SetBufferContents(CompiledBufferKeyIndices *cki, Vertex *ccv, Face *ccf, Vertex *cmv, Node *cmn);
    
    void HandleMouseMovement(float x, float y, float dx, float dy);
    
    void HandleMouseDown(vector_float2 loc, bool left);
    void HandleMouseUp(vector_float2 loc, bool left);
    
    EditNodeScheme();
    ~EditNodeScheme();
    
    virtual void Update();
};

#endif /* EditNodeScheme_h */
