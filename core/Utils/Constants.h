//
//  Constants.h
//  dragonfly
//
//  Created by Thomas Liang on 12/8/24.
//

#ifndef Constants_h
#define Constants_h

// panel buffer consts
const unsigned long PNL_NUM_OUTBUFS = 20;

const unsigned long PNL_CAMERA_OUTBUF_IDX = 0;
const unsigned long PNL_LIGHT_OUTBUF_IDX = 1;
const unsigned long PNL_SCFACE_OUTBUF_IDX = 2;
const unsigned long PNL_SCEDGE_OUTBUF_IDX = 3;
const unsigned long PNL_SCNODE_OUTBUF_IDX = 4;
const unsigned long PNL_SCNODEMODELID_OUTBUF_IDX = 5;
const unsigned long PNL_SCNODEVERTEXLNK_OUTBUF_IDX = 6;
const unsigned long PNL_SCMODELTRANS_OUTBUF_IDX = 7;
const unsigned long PNL_SCSLICEDOT_OUTBUF_IDX = 8;
const unsigned long PNL_SCSLICELINE_OUTBUF_IDX = 9;
const unsigned long PNL_SCENESLICEATTR_OUTBUF_IDX = 10;
const unsigned long PNL_CTFACE_OUTBUF_IDX = 11;
const unsigned long PNL_CTNODE_OUTBUF_IDX = 12;
const unsigned long PNL_CTNODEMODELID_OUTBUF_IDX = 13;
const unsigned long PNL_CTNODEVERTEXLNK_OUTBUF_IDX = 14;
const unsigned long PNL_CTMODELTRANS_OUTBUF_IDX = 15;
const unsigned long PNL_UIFACE_OUTBUF_IDX = 16;
const unsigned long PNL_UIVERTEX_OUTBUF_IDX = 17;
const unsigned long PNL_UIELEMID_OUTBUF_IDX = 18;
const unsigned long PNL_UITRANS_OUTBUF_IDX = 19;


const unsigned long PNL_NUM_INBUFS = 5;

const unsigned long PNL_COMPKEYIDX_INBUF_IDX = 0;
const unsigned long PNL_COMPCOMPVERTEX_INBUF_IDX = 1;
const unsigned long PNL_COMPCOMPFACE_INBUF_IDX = 2;
const unsigned long PNL_COMPMODELVERTEX_INBUF_IDX = 3;
const unsigned long PNL_COMPMODELNODE_INBUF_IDX = 4;

#endif /* Constants_h */
