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