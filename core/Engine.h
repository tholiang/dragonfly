//
//  Engine.h
//  dragonfly
//
//  Created by Thomas Liang on 3/9/24.
//

#ifndef Engine_h
#define Engine_h

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <filesystem>
#include <sys/stat.h>
#include <sys/types.h>
#include <math.h>

#include "imgui.h"
#include "Utils/Vec.h"
using namespace Vec;
#include "imfilebrowser.h"

#include "Schemes/SchemeController.h"

#include "Schemes/Scheme.h"
#include "Schemes/EditModelScheme.h"
#include "Schemes/EditFEVScheme.h"
#include "Schemes/EditNodeScheme.h"

#include "Pipelines/ComputePipeline.h"
#include "Pipelines/RenderPipeline.h"

class Engine {
protected:
    std::string project_path = "/";

    // ui variables
    int menu_bar_height = 20;
    bool using_menu_bar = false;
    
    int window_id;

    int scene_window_start_x = 0;
    int scene_window_start_y = 19;
    int window_width = 1080;
    int window_height = 700;

    bool show_main_window = true;
    
    // rendering
    ComputePipeline *compute_pipeline;
    RenderPipeline *render_pipeline;

    float fps = 0;
    
    // scheme and scene
    Camera *camera;
    SchemeController *scheme_controller;
    Scheme *scheme;
    Scene *scene;
    
    virtual int SetPipelines() = 0; // varies for graphics implementations
    virtual int HandleInputEvents() = 0; // varies for input implementations

    // send to scheme
    void HandleKeyboardEvents(int key, bool down);
    void HandleMouseClick(vector_float2 loc, int button, bool down);
    void HandleMouseMovement(float x, float y, float dx, float dy);
public:
    Engine();
    virtual ~Engine();
    virtual int init();
    void run();
};

#endif /* Engine_h */
