//
//  VertexMoveAction.cpp
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "EdgeAddVertexAction.h"


EdgeAddVertexAction::EdgeAddVertexAction(Model *m, int vid_new, int vid1, int vid2) : model_(m), vid_new_(vid_new), vid1_(vid1), vid2_(vid2) {
    type_ = "Edge Add Vertex Action";
}

void EdgeAddVertexAction::BeginRecording() {
    fids_ = model_->GetEdgeFaces(vid1_, vid2_);
    original_face_size_ = model_->NumFaces();
    
    recording_ = true;
}

void EdgeAddVertexAction::EndRecording() {
    for (int i = original_face_size_; i < model_->NumFaces(); i++) {
        new_fids_.push_back(i);
    }
    
    recording_ = false;
}

void EdgeAddVertexAction::Do() {
    fids_ = model_->GetEdgeFaces(vid1_, vid2_);
    
    vec_float3 v1 = model_->GetVertex(vid1_);
    vec_float3 v2 = model_->GetVertex(vid2_);
    vec_float3 new_v = DragonflyUtils::BiAvg(v1, v2);
    model_->InsertVertex(new_v.x, new_v.y, new_v.z, vid_new_);
    
    for (std::size_t i = 0; i < fids_.size(); i++) {
        unsigned long fid = fids_[i];
        Face *f = model_->GetFace(fid);
        unsigned long fvid1 = f->vertices[0];
        unsigned long fvid2 = f->vertices[1];
        unsigned long fvid3 = f->vertices[2];
        
        long long other_vid = -1;
        
        if (vid1_ == fvid1) {
            if (vid2_ == fvid2) {
                other_vid = fvid3;
            } else if (vid2_ == fvid3) {
                other_vid = fvid2;
            }
        } else if (vid1_ == fvid2) {
            if (vid2_ == fvid1) {
                other_vid = fvid3;
            } else if (vid2_ == fvid3) {
                other_vid = fvid1;
            }
        } else if (vid1_ == fvid3) {
            if (vid2_ == fvid1) {
                other_vid = fvid2;
            } else if (vid2_ == fvid2) {
                other_vid = fvid1;
            }
        }
        
        if (other_vid != -1) {
            f->vertices[0] = vid1_;
            f->vertices[1] = vid_new_;
            f->vertices[2] = other_vid;
            
            Face *f2 = new Face();
            f2->vertices[0] = vid2_;
            f2->vertices[1] = vid_new_;
            f2->vertices[2] = other_vid;
            f2->color = f->color;
            model_->InsertFace(f2, new_fids_.at(i));
        }
    }
}

void EdgeAddVertexAction::Undo() {
    for (int i = fids_.size()-1; i >= 0; i--) {
        Face *f = model_->GetFace(fids_[i]);
        if (f->vertices[0] == vid_new_) {
            if (f->vertices[1] == vid1_ || f->vertices[2] == vid1_) {
                f->vertices[0] = vid2_;
            } else if (f->vertices[1] == vid2_ || f->vertices[2] == vid2_) {
                f->vertices[0] = vid1_;
            }
        } else if (f->vertices[1] == vid_new_) {
            if (f->vertices[0] == vid1_ || f->vertices[2] == vid1_) {
                f->vertices[1] = vid2_;
            } else if (f->vertices[0] == vid2_ || f->vertices[2] == vid2_) {
                f->vertices[1] = vid1_;
            }
        } else if (f->vertices[2] == vid_new_) {
            if (f->vertices[0] == vid1_ || f->vertices[1] == vid1_) {
                f->vertices[2] = vid2_;
            } else if (f->vertices[0] == vid2_ || f->vertices[1] == vid2_) {
                f->vertices[2] = vid1_;
            }
        }
        
        model_->RemoveFace(new_fids_[i]);
    }
    
    model_->RemoveVertex(vid_new_);
}

EdgeAddVertexAction::~EdgeAddVertexAction () {
    
}
