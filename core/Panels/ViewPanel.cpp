#include "ViewPanel.h"

ViewPanel::ViewPanel(vec_float4 borders, Scene *scene) : Panel(borders, scene) {
    type_ = PanelType::View;

    cmaera_ = new Camera();
}

ViewPanel::~ViewPanel() {
    
}

void ViewPanel::Update() {
    Panel::Update();
}

void ViewPanel::HandleInput() {
    HandleCameraMovement();
}

void ViewPanel::PrepareOutBuffers() {
    out_buffers_.camera->size = sizeof(Camera);
    out_buffers_.camera->data = camera_;

    out_buffers_.scene_lights->size = scene_->NumLights() * sizeof(Light);
    out_buffers_.scene_lights->data = scene_->
}

void ViewPanel::SetCamera(Camera *c) {
    if (camera_ != NULL) { delete camera_; }
    camera_ = c;
}

void ViewPanel::EnableLighting(bool enabled) {
    lighting_enabled_ = enabled;
}

void ViewPanel::HandleCameraMovement() {
    // KEYS
    // find unit vector of xy camera vector
    float magnitude = sqrt(pow(camera_->vector.x, 2)+pow(camera_->vector.y, 2));
    float unit_x = camera_->vector.x/magnitude;
    float unit_y = camera_->vector.y/magnitude;
    
    if (keys_.w) {
        camera_->pos.x += (3.0/fps)*unit_x;
        camera_->pos.y += (3.0/fps)*unit_y;
    }
    if (keys_.a) {
        camera_->pos.y -= (3.0/fps)*unit_x;
        camera_->pos.x += (3.0/fps)*unit_y;
    }
    if (keys_.s) {
        camera_->pos.x -= (3.0/fps)*unit_x;
        camera_->pos.y -= (3.0/fps)*unit_y;
    }
    if (keys_.d) {
        camera_->pos.y += (3.0/fps)*unit_x;
        camera_->pos.x -= (3.0/fps)*unit_y;
    }
    if (keys_.space) {
        camera_->pos.z += (3.0/fps);
    }
    if (keys_.option) {
        camera_->pos.z -= (3.0/fps);
    }

    // MOUSE
    if (keys_.control) {
        //get current camera angles (phi is horizontal and theta is vertical)
        //get the new change based on the amount the mouse moved
        float curr_phi = atan2(camera_->vector.y, camera_->vector.x);
        float phi_change = 0.1*mouse_.movement.x*(M_PI/180); // TODO: change arbitrary sensitivity (0.1)
        
        float curr_theta = acos(camera_->vector.z);
        float theta_change = 0.1*mouse_.movement.y*(M_PI/180);
        
        //get new phi and theta angles
        float new_phi = curr_phi + phi_change;
        float new_theta = curr_theta + theta_change;
        //set the camera "pointing" vector to spherical -> cartesian
        camera_->vector.x = sin(new_theta)*cos(new_phi);
        camera_->vector.y = sin(new_theta)*sin(new_phi);
        camera_->vector.z = cos(new_theta);
        //set the camera perpendicular "up" vector the same way but adding pi/2 to theta
        camera_->up_vector.x = sin(new_theta-M_PI_2)*cos(new_phi);
        camera_->up_vector.y = sin(new_theta-M_PI_2)*sin(new_phi);
        camera_->up_vector.z = cos(new_theta-M_PI_2);
    }
}