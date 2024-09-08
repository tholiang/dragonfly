#ifndef ForceField_h
#define ForceField_h

#include "Utils/Basis.h"
#include "Force.h"

using namespace DragonflyUtils;

/*
Binary tree structure
- Leaf: Force
- Internal: binary operation
*/

enum FFType {
LEAF, AND, OR, XOR
};

class ForceField {
public:
    ForceField(Force *f, Basis b);
    ForceField(FFType t, ForceField *left, ForceField *right, Basis b);
    ~ForceField();

    FFType GetType();
    bool Contains(vec_float3 p);
private:
    // list of pairs of Basis to force
    Basis basis_;

    FFType type_;
    Force *f_ = NULL;
    ForceField *l_ = NULL;
    ForceField *r_ = NULL;
};

#endif /* ForceField_h */