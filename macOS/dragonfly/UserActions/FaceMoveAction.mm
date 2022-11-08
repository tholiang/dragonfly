//
//  VertexMoveAction.m
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "FaceMoveAction.h"

FaceMoveAction::FaceMoveAction(Model *m, int fid) : model_(m), fid_(fid) {
    type_ = "Face Move Action";
}

void FaceMoveAction::BeginRecording() {
    Face *f = model_->GetFace(fid_);
    v1_initial_location_ = model_->GetVertex(f->vertices[0]);

    recording_ = true;
}

void FaceMoveAction::EndRecording() {
    Face *f = model_->GetFace(fid_);
    simd_float3 end = model_->GetVertex(f->vertices[0]);
    movement_vector_.x = end.x - v1_initial_location_.x;
    movement_vector_.y = end.y - v1_initial_location_.y;
    movement_vector_.z = end.z - v1_initial_location_.z;

    recording_ = false;
}

void FaceMoveAction::Do() {
    Face *f = model_->GetFace(fid_);
    
    model_->MoveVertex(f->vertices[0], movement_vector_.x, movement_vector_.y, movement_vector_.z);
    model_->MoveVertex(f->vertices[1], movement_vector_.x, movement_vector_.y, movement_vector_.z);
    model_->MoveVertex(f->vertices[2], movement_vector_.x, movement_vector_.y, movement_vector_.z);
}

void FaceMoveAction::Undo() {
    Face *f = model_->GetFace(fid_);
    
    model_->MoveVertex(f->vertices[0], -movement_vector_.x, -movement_vector_.y, -movement_vector_.z);
    model_->MoveVertex(f->vertices[1], -movement_vector_.x, -movement_vector_.y, -movement_vector_.z);
    model_->MoveVertex(f->vertices[2], -movement_vector_.x, -movement_vector_.y, -movement_vector_.z);
}

FaceMoveAction::~FaceMoveAction () {
    
}
