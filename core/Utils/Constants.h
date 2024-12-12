//
//  Constants.h
//  dragonfly
//
//  Created by Thomas Liang on 12/8/24.
//

#ifndef Constants_h
#define Constants_h

/* BUFFERS */
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


// compute buffer consts
const unsigned long CPT_NUM_OUTBUFS = 4;

const unsigned long CPT_COMPCOMPVERTEX_OUTBUF_IDX = 0;
const unsigned long CPT_COMPCOMPFACE_OUTBUF_IDX = 1;
const unsigned long CPT_COMPMODELVERTEX_OUTBUF_IDX = 2;
const unsigned long CPT_COMPMODELNODE_OUTBUF_IDX = 3;


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
