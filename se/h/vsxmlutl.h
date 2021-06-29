#pragma once
#include "vsdecl.h"

// VSXML
#define VSXML_VALIDATION_SCHEME_WELLFORMEDNESS  0x1
#define VSXML_VALIDATION_SCHEME_VALIDATE        0x2
#define VSXML_VALIDATION_SCHEME_AUTO            VSXML_VALIDATION_SCHEME_WELLFORMEDNESS | VSXML_VALIDATION_SCHEME_VALIDATE

EXTERN_C void VSAPI vsxmlutl_version();
EXTERN_C void VSAPI xerces_version();


EXTERN_C int VSAPI _xml_open(const char *pszFilename,VSHREFVAR hrefStatus,int flags/*, int iEncoding*/);

EXTERN_C int VSAPI _xml_open_from_control(int wid,VSHREFVAR hrefStatus /*,int flags=0,int StartRealSeekPos=0,int EndRealSeekPos= -1*/);

EXTERN_C int VSAPI _xml_close(int iHandle);

EXTERN_C int VSAPI _xml_get_num_errors(int iHandle);

EXTERN_C int VSAPI _xml_get_error_info(int iDocHandle, int errIndex, VSHREFVAR line, VSHREFVAR col, VSHREFVAR fn, VSHREFVAR msg);


EXTERN_C int VSAPI vsXMLOpen(const char *pszFilename,
                             int &status,
                             int OpenFlags, 
                             int iEncoding=2);

EXTERN_C int VSAPI vsXMLGetNumErrors(int iHandle);

EXTERN_C int VSAPI vsXMLGetErrorInfo(int iDocHandle, 
                                     int errIndex, 
                                     int &line, 
                                     int& col, 
                                     char**fn, 
                                     char**msg);

EXTERN_C int VSAPI vsXMLClose(int iHandle);

EXTERN_C int VSAPI vsXMLOpenFromControl(int wid,
                                        int &status,
                                        int flags=0,
                                        int StartRealSeekPos=0,
                                        int EndRealSeekPos=0x7FFFFFFF,
                                        void *preserved=0);


