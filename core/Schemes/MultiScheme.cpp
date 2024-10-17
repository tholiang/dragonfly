#include "MultiScheme.h"

MultiScheme::MultiScheme() {

}

MultiScheme::~MultiScheme() {

}

bool MultiScheme::IsMultiScheme() {
    return true;
}

int MultiScheme::NumSchemes() {
    return schemes_.size();
}

std::vector<Scheme> *MultiScheme::GetSchemes() {
    return &schemes_;
}

std::vector<vec_float4> *MultiScheme::GetSchemePanelBoxes() {
    return &panels_;
}

std::pair<Scheme, vec_float4> MultiScheme::GetSchemePanelAt(int i) {
    return std::make_pair(schemes_[i], panels_[i]);
}