#ifndef MultiScheme_h
#define MultiScheme_h

#include "Scheme.h"
#include "Utils/Vec.h"
using namespace Vec;

class MultiScheme : public Scheme {
protected:
    std::vector<Scheme> schemes_;
    std::vector<vec_float4> panels_; // bounding boxes for each scheme
public:
    MultiScheme();
    virtual ~MultiScheme();
    bool IsMultiScheme();
    
    int NumSchemes();
    std::vector<Scheme> *GetSchemes();
    std::vector<vec_float4> *GetSchemePanelBoxes();
    std::pair<Scheme, vec_float4> GetSchemePanelAt(int i);
}

#endif /* MultiScheme_h */