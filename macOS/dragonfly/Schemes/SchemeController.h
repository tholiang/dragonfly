//
//  SchemeController.h
//  dragonfly
//
//  Created by Thomas Liang on 8/1/22.
//

#ifndef SchemeController_h
#define SchemeController_h

#include "imgui.h"
#include "imgui_impl_sdl.h"
#include "imgui_impl_metal.h"
#include "imfilebrowser.h"

#include "Scheme.h"
#include "EditModelScheme.h"
#include "EditFEVScheme.h"
#include "EditNodeScheme.h"
#include "EditSliceScheme.h"

class SchemeController {
private:
    Scheme *scheme_;
    ImGui::FileBrowser fileDialog;
    
    bool using_menu_bar = false;
    bool saving_model = false;
    bool saving_scene = false;
    bool importing_model = false;
    bool importing_pointdata = false;
    bool importing_scene = false;
    
    void MenuBar();
    void FileDialog();
public:
    SchemeController(Scheme *scheme);
    ~SchemeController();
    
    void BuildUI();
    
    void SetScheme(Scheme *scheme);
    Scheme *GetScheme();
};

#endif /* SchemeController_h */
