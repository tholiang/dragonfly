//
//  VertexMoveAction.h
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#ifndef FaceAddVertexAction_h
#define FaceAddVertexAction_h

#include "UserAction.h"
#include "../Modeling/Model.h"

class FaceAddVertexAction : public UserAction {
public:
    FaceAddVertexAction(Model *m, int vid, int fid);
    virtual void BeginRecording();
    virtual void EndRecording();
    virtual void Do();
    virtual void Undo();
    virtual ~FaceAddVertexAction();
private:
    Model *model_;
    int vid_;
    int fid_;
    int original_vertices_[3];
    int new_fid1_;
    int new_fid2_;
};

#endif /* FaceAddVertexAction_h */
