//
//  Constants.h
//  dragonfly
//
//  Created by Thomas Liang on 12/8/24.
//

#ifndef Constants_h
#define Constants_h

/* BUFFERS */
enum BufferStorageMode {
    Shared,
    Managed
};

// panel buffer consts
const unsigned long PNL_NUM_OUTBUFS = 17;

const unsigned long PNL_CAMERA_OUTBUF_IDX = 0;
const unsigned long PNL_LIGHT_OUTBUF_IDX = 1;
const unsigned long PNL_FACE_OUTBUF_IDX = 2;
const unsigned long PNL_EDGE_OUTBUF_IDX = 3;
const unsigned long PNL_NODE_OUTBUF_IDX = 4;
const unsigned long PNL_NODEMODELID_OUTBUF_IDX = 5;
const unsigned long PNL_NODEVERTEXLNK_OUTBUF_IDX = 6;
const unsigned long PNL_MODELTRANS_OUTBUF_IDX = 7;
const unsigned long PNL_SLICEDOT_OUTBUF_IDX = 8;
const unsigned long PNL_SLICELINE_OUTBUF_IDX = 9;
const unsigned long PNL_SLICEATTR_OUTBUF_IDX = 10;
const unsigned long PNL_SLICETRANS_OUTBUF_IDX = 11;
const unsigned long PNL_DOTSLICEID_OUTBUF_IDX = 12;
const unsigned long PNL_UIFACE_OUTBUF_IDX = 13;
const unsigned long PNL_UIVERTEX_OUTBUF_IDX = 14;
const unsigned long PNL_UIELEMID_OUTBUF_IDX = 15;
const unsigned long PNL_UITRANS_OUTBUF_IDX = 16;

// TODO
const BufferStorageMode PNL_OUTBUF_STORAGE_MODES[PNL_NUM_OUTBUFS] = {
    Shared, /* camera (0) */
    Managed, /* light (1) */
    Managed, /* face (2) */
    Managed, /* edge (3) */
    Managed, /* node (4) */
    Managed, /* node model id (5) */
    Managed, /* node vertex link (6) */
    Managed, /* model transform (7) */
    Managed, /* slice dot (8) */
    Managed, /* slice line (9) */
    Managed, /* slice attribute (10) */
    Managed, /* slice transform (11) */
    Managed, /* dot slice id (12) */
    Managed, /* ui face (13) */
    Managed, /* ui vertex (14) */
    Managed, /* ui element id (15) */
    Managed, /* ui transform (16) */
};


// compute buffer consts
const unsigned long CPT_NUM_OUTBUFS = 4;

const unsigned long CPT_COMPCOMPVERTEX_OUTBUF_IDX = 0;
const unsigned long CPT_COMPCOMPFACE_OUTBUF_IDX = 1;
const unsigned long CPT_COMPMODELVERTEX_OUTBUF_IDX = 2;
const unsigned long CPT_COMPMODELNODE_OUTBUF_IDX = 3;

// TODO
const BufferStorageMode CPT_OUTBUF_STORAGE_MODES[CPT_NUM_OUTBUFS] = {
    Managed, /* compiled computed vertex (0) */
    Managed, /* compiled computed face (1) */
    Managed, /* computed model vertex (2) */
    Managed, /* computed model node (3) */
};


// compiled buffer key indices
const unsigned long CBKI_NUM_KEYS = 20;
const unsigned long CBKI_V_SIZE_IDX = 0;
const unsigned long CBKI_V_SCENE_START_IDX = 1;
const unsigned long CBKI_V_CONTROL_START_IDX = 2;
const unsigned long CBKI_V_DOT_START_IDX = 3;
const unsigned long CBKI_V_NCIRCLE_START_IDX = 4;
const unsigned long CBKI_V_VSQUARE_START_IDX = 5;
const unsigned long CBKI_V_DSQUARE_START_IDX = 6;
const unsigned long CBKI_V_SPLATE_START_IDX = 7;
const unsigned long CBKI_V_UI_START_IDX = 8;

const unsigned long CBKI_F_SIZE_IDX = 9;
const unsigned long CBKI_F_SCENE_START_IDX = 10;
const unsigned long CBKI_F_CONTROL_START_IDX = 11;
const unsigned long CBKI_F_NCIRCLE_START_IDX = 12;
const unsigned long CBKI_F_VSQUARE_START_IDX = 13;
const unsigned long CBKI_F_DSQUARE_START_IDX = 14;
const unsigned long CBKI_F_SPLATE_START_IDX = 15;
const unsigned long CBKI_F_UI_START_IDX = 16;

const unsigned long CBKI_E_SIZE_IDX = 17;
const unsigned long CBKI_E_SCENE_START_IDX = 18;
const unsigned long CBKI_E_LINE_START_IDX = 19;


/* RENDERING VALUES */
const unsigned int NUM_VERTEX_SQUARE_VERTICES = 4;
const unsigned int NUM_NODE_CIRLCE_VERTICES = 9;
const unsigned int NUM_SLICE_PLATE_VERTICES = 4;
const unsigned int NUM_VERTEX_SQUARE_FACES = 2;
const unsigned int NUM_NODE_CIRLCE_FACES = 8;
const unsigned int NUM_SLICE_PLATE_FACES = 2;


/* COMPUTE KERNELS */
const unsigned int CPT_NUM_KERNELS = 10;

const unsigned int CPT_TRANSFORMS_KRN_IDX = 0;
const unsigned int CPT_VERTEX_KRN_IDX = 1;
const unsigned int CPT_PROJ_VERTEX_KRN_IDX = 2;
const unsigned int CPT_VERTEX_SQR_KRN_IDX = 3;
const unsigned int CPT_PROJ_NODE_KRN_IDX = 4;
const unsigned int CPT_LIGHTING_KRN_IDX = 5;
const unsigned int CPT_SCALED_DOT_KRN_IDX = 6;
const unsigned int CPT_PROJ_DOT_KRN_IDX = 7;
const unsigned int CPT_SLICE_PLATE_KRN_IDX = 8;
const unsigned int CPT_UI_VERTEX_KRN_IDX = 9;

#endif /* Constants_h */
