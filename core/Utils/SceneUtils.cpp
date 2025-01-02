#include "SceneUtils.h"

unsigned long DragonflyUtils::NumSceneVertices(Scene *s) {
    unsigned long count = 0;
    for (int m = 0; m < s->NumModels(); m++) {
        count += s->GetModel(m)->NumVertices();
    }
    return count;
}

unsigned long DragonflyUtils::NumSceneDots(Scene *s) {
    unsigned long count = 0;
    for (int m = 0; m < s->NumModels(); m++) {
        count += s->GetSlice(m)->NumDots();
    }
    return count;
}

unsigned long DragonflyUtils::NumSceneNodes(Scene *s) {
    unsigned long count = 0;
    for (int m = 0; m < s->NumModels(); m++) {
        count += s->GetModel(m)->NumNodes();
    }
    return count;
}

unsigned long DragonflyUtils::NumSceneFaces(Scene *s) {
    unsigned long count = 0;
    for (int m = 0; m < s->NumModels(); m++) {
        count += s->GetModel(m)->NumFaces();
    }
    return count;
}

unsigned long DragonflyUtils::NumSceneLines(Scene *s) {
    unsigned long count = 0;
    for (int m = 0; m < s->NumModels(); m++) {
        count += s->GetSlice(m)->NumLines();
    }
    return count;
}

std::vector<ModelTransform> DragonflyUtils::GetSceneModelTransforms(Scene *s) {
    return *s->GetAllModelUniforms();
}

std::vector<NodeVertexLink> DragonflyUtils::GetSceneNVLinks(Scene *s) {
    std::vector<NodeVertexLink> ret;
    for (int i = 0; i < s->NumModels(); i++) {
        Model *m = s->GetModel(i);
        for (int j = 0; j < m->NumVertices()*2; j++) {
            ret.push_back(*m->GetNodeVertexLink(j));
        }
    }
    return ret;
}

std::vector<Face> DragonflyUtils::GetSceneFaces(Scene *s) {
    std::vector<Face> ret;
    for (int i = 0; i < s->NumModels(); i++) {
        Model *m = s->GetModel(i);
        for (int j = 0; j < m->NumFaces(); j++) {
            ret.push_back(*m->GetFace(j));
        }
    }
    return ret;
}

std::vector<vec_int2> DragonflyUtils::GetSceneEdges(Scene *s) {
    // TODO: this
    return std::vector<vec_int2>();
}

std::vector<Node> DragonflyUtils::GetSceneNodes(Scene *s) {
    std::vector<Node> ret;
    for (int i = 0; i < s->NumModels(); i++) {
        Model *m = s->GetModel(i);
        for (int j = 0; j < m->NumNodes(); j++) {
            ret.push_back(*m->GetNode(j));
        }
    }
    return ret;
}

std::vector<uint32_t> DragonflyUtils::GetSceneNodeModelIDs(Scene *s) {
    std::vector<uint32_t> ret;
    for (int i = 0; i < s->NumModels(); i++) {
        Model *m = s->GetModel(i);
        for (int j = 0; j < m->NumNodes(); j++) {
            ret.push_back(i);
        }
    }
    return ret;
}
