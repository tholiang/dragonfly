#include "ForceField.h"

ForceField::ForceField(Force *f, Basis b) : f_(f), basis_(b) {
    type_ = FFType::LEAF;
}

ForceField::ForceField(FFType t, ForceField *left, ForceField *right, Basis b) : type_(t), l_(left), r_(right), basis_(b) {
    assert(t != FFType::LEAF);
}

ForceField::~ForceField() {
    if (f_ != NULL) { delete f_; }
    if (l_ != NULL) { delete l_; }
    if (r_ != NULL) { delete r_; }
}

FFType ForceField::GetType() {
    return type_;
}

bool ForceField::Contains(vec_float3 p) {
    if (type_ == FFType::LEAF) {
        assert(f_ != NULL);
        return f_->Contains(TranslatePointToStandard(&basis_, p));
    }

    assert(l_ != NULL);
    assert(r_ != NULL);
    bool l_res = l_->Contains(p);
    bool r_res = r_->Contains(p);

    if (type_ == FFType::AND) {
        return l_res && r_res;
    } else if (type_ == FFType::OR) {
        return l_res || r_res;
    } else if (type_ == FFType::XOR) {
        return l_res != r_res;
    }
}