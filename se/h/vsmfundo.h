////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once

#include "vsdecl.h"

  struct VSFILEDATE {
     unsigned short milliseconds;
     unsigned char minutes;
     unsigned char hours;
     unsigned char  day;
     unsigned char  month;
     unsigned short year;
#if VSUNIX
     int dst; // daylight saving time
#endif
  };
EXTERN_C_BEGIN
  void VSAPI vsMFUndoBegin(const char *pszTitle);
  int VSAPI vsMFUndoEnd();
  int VSAPI vsMFUndoBeginStep(const char *pszFilename);
  int VSAPI vsMFUndoEndStep(const char *pszFilename);
  int VSAPI vsMFUndoCancelStep(const char *pszFilename);
  int VSAPI vsMFUndo(int redo=0);
  void VSAPI vsMFUndoSetRedoCount(size_t count);
  int VSAPI vsMFUndoCancel();
  int VSAPI vsMFUndoGetStepCount(int redo=0);
  const char * VSAPI vsMFUndoGetTitle(int redo=0);
  int VSAPI vsMFUndoGetStatus(int redo=0);
  const char *VSAPI vsMFUndoGetStepFilename(int i,int redo);
  void VSAPI vsMFUndoGetStepFileDate(int i,int redo,VSFILEDATE *pLocalFileDate,int CheckCurrent=0);
  int VSAPI vsFileGetDate(const char *pszFilename,VSFILEDATE *pLocalFileDate);
  int VSAPI vsFileCompareDates(VSFILEDATE *pLocalFileDate1,VSFILEDATE *pLocalFileDate2);
  const char *VSAPI vsMFUndoGetStepBackup(int i,int redo=0,int CheckCurrent=0);
  int VSAPI vsMFUndoGetStepStatus(int i,int redo=0);
  size_t VSAPI vsMFUndoGetRedoCount();
  /**
   * Sets an optional callback which allows the caller to perform
   * the copy or just perform some pre-copy operation.
   * 
   * @param pfnCopyFile
   *        The callback function return values are as follows:
   *        <dl compact>
   *        <dt>0<dd>Indicates that the file was copied successfully.
   *        <dt>&lt;0<dd>Indicates that the file copy operation failed.
   *        <dt>1<dd>Indicates that the file still needs to be copied.
   *        </dl>
   *        
   */
  void VSAPI vsMFUndoSetCallbackCopyFile(int (VSAPI *pfnCopyFile)(const char *pszDestFilename,const char *pszSrcFilename));
  void VSAPI vsMFUndoCleanup();
EXTERN_C_END

