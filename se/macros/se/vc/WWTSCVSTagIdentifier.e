////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////

#pragma option(pedantic,on)
#region Imports
#include "markers.sh"
#include "WWTS.sh"
#require "WWTSLine.e"
#require "WWTSFile.e"
#require "IWWTSIdentifier.e"
#require "sc/editor/TempEditor.e"
#require "VersionMap.e"
#import "backtag.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

/**
 * Class used to display items that match a certain list of
 * users
 */
class WWTSCVSTagIdentifier : IWWTSIdentifier {
   private VersionMap m_map:[];
   private TAG_IDENTIFIER_VERSION_INFO m_rangeList[];

   // This is temp until we get real display stuff
   private int m_bmIndex = -1;
   private int m_defaultIndex = -1;

   WWTSCVSTagIdentifier (int bmIndex = _pic_file) {
      m_bmIndex  = bmIndex;
   }

   ~WWTSCVSTagIdentifier() {
   }

   _str getType() {
      return "cvstag";
   }

   
   private void findDefaultIndex() {
      len := m_rangeList._length();
      for ( i:=0;i<len;++i ) {
         if ( m_rangeList[i].startTag =="" && m_rangeList[i].endTag =="" ) {
            m_defaultIndex = i;break;
         }
      }
   }

   void addRange(_str startTag,_str endTag,int fgcolor,int bgcolor,_str description) {
      len := m_rangeList._length();
      TAG_IDENTIFIER_VERSION_INFO temp;
      temp.startTag         = startTag;
      temp.endTag           = endTag;
      temp.description      = description;
      temp.fgcolor          = fgcolor;
      temp.bgcolor          = bgcolor;
      m_rangeList[len] = temp;

      findDefaultIndex();
   }

   void deleteAllRanges() {
      m_rangeList = null;
   }

   void getRangeList(TAG_IDENTIFIER_VERSION_INFO (&rangeList)[]) {
      rangeList = m_rangeList;
   }

   void setRangeList(TAG_IDENTIFIER_VERSION_INFO (&rangeList)[]) {
       m_rangeList = rangeList;
       findDefaultIndex();
   }

   static private _str getBranchFromVersionNumber(_str versionString) {
      branchString := "";
      lp := lastpos('.',versionString);
      if ( lp>1 ) {
         branchString = substr(versionString,1,lp-1);
      }
      return branchString;
   }

   static private _str stripBranchFromVersionNumber(_str versionString) {
      strippedVersionString := "";
      lp := lastpos('.',versionString);
      if ( lp>0 ) {
         strippedVersionString = substr(versionString,lp+1);
      }
      return strippedVersionString;
   }

   bool isMatch(WWTSFile *pFile,WWTSLine *pLine,typeless &lineData=null) {
      _str filename = pFile->getFilename();
      displayThisLine := false;

      for ( i:=0;i<m_rangeList._length();++i ) {
         pCur := &m_rangeList[i];
         //if ( !file_eq(pCur->curFilename,filename) ) {
         //   pCur->curFilename = pFile->getFilename();
         //   //calculateStartEnd();
         //}
         if ( m_map:[filename]==null ) {
            VersionMap temp;
            m_map:[filename] = temp;
            map := pFile->getLabelMap();
            m_map:[filename].setVersionMap( map );
         }
   
         do {
   
            if ( pCur->startTag == "" && pCur->endTag == "" ) {
               displayThisLine = true; break;
            }

            if ( (pCur->startVersion=="" && pCur->startTag!="") ||
                 (pCur->endVersion=="" && pCur->endTag!="") ||
                 (pCur->startVersion==null && pCur->startTag!=null) ||
                 (pCur->endVersion==null && pCur->endTag!=null) 
                 ) {
               calculateStartEnd(pFile,pCur);
            }
   
            if ( pCur->startVersion == null ) {
               //say('WWTSCVSTagIdentifier.isMatch out 1');
               break;
            }
            // Take start version number  x.y.z
            // x.y is start branch, z is start version number
            // 
            // For current line, be sure branch matches, then grab 
            // the version and be sure that is >= z from above.
   
            curVersion := pLine->getVersion();
            curBranch := getBranchFromVersionNumber(curVersion);
            curStrippedVersion := stripBranchFromVersionNumber(curVersion);
   
            // If a start point was specified, and that branch number 
            // does not match current line branch number
            if ( pCur->startBranch != curBranch && pCur->startBranch!="" ) {
               //say('WWTSCVSTagIdentifier.isMatch out 10');
               break;
            }
   
            // If a start point was specified, and that branch number 
            // does not match current line branch number
            if ( pCur->endBranch != curBranch && pCur->endBranch!="" ) break;
   
            //say('WWTSCVSTagIdentifier.isMatch curStrippedVersion='curStrippedVersion' pCur->strippedStartVersion='pCur->strippedStartVersion' pCur->strippedEndVersion='pCur->strippedEndVersion);
            newestOK := pCur->endTag=="" || curStrippedVersion <= pCur->strippedEndVersion;
            oldestOK := pCur->startTag=="" || curStrippedVersion>=pCur->strippedStartVersion;
            displayThisLine = newestOK && oldestOK;
         } while ( false );
         if ( displayThisLine ) {
            lineData = i;
            break;
         }
      }
      if ( !displayThisLine && m_defaultIndex>-1 ) {
         displayThisLine = true;
         lineData = m_defaultIndex;
      }
      return displayThisLine;
   }

   private void calculateStartEnd(WWTSFile *pFile,TAG_IDENTIFIER_VERSION_INFO *pCurInfo) {
      //say('calculateStartEnd calculateStartEnd in!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      _str filename = pFile->getFilename();
      pCurInfo->startVersion = "";
      if ( pCurInfo->startTag!="" ) {
         pCurInfo->startVersion = m_map:[filename].getVersion(pCurInfo->startTag);
      }
      if ( pCurInfo->startVersion!=null ) {
   
         pCurInfo->startBranch = "";
         if ( pCurInfo->startTag!="" ) pCurInfo->startBranch = getBranchFromVersionNumber(pCurInfo->startVersion);
   
         pCurInfo->strippedStartVersion = stripBranchFromVersionNumber(pCurInfo->startVersion);
      }

      pCurInfo->endVersion = "";
      if ( pCurInfo->endTag!="" ) {
         pCurInfo->endVersion = m_map:[filename].getVersion(pCurInfo->endTag);
      }
      //say('calculateStartEnd m_endTag='m_endTag);
      //if ( m_endVersion==null ) {
      //   say('calculateStartEnd m_endTag=null');
      //}else{
      //   say('calculateStartEnd m_endTag='m_endTag' m_endVersion='m_endVersion);
      //}
      if ( pCurInfo->endVersion!=null ) {

         pCurInfo->endBranch = "";
         if ( pCurInfo->endTag!="" ) pCurInfo->endBranch = getBranchFromVersionNumber(pCurInfo->endVersion);
   
         pCurInfo->strippedEndVersion = stripBranchFromVersionNumber(pCurInfo->endVersion);
         //say('calculateStartEnd  m_endBranch='m_endBranch' m_strippedEndVersion='m_strippedEndVersion);
      }
   }

   int displayLine(WWTSFile *pFileInfo,int localLineNumber,int fileWID,int markerType,typeless &lineData=null) {
      origWID := p_window_id;
      status := 0;
      do {
         // If for some reason the index was not passed in, we really cannot continue
         if ( lineData==null ) break;

         filename := pFileInfo->getFilename();
         status = pFileInfo->getLineInfo(localLineNumber,auto pLineInfo);
         if ( status ) break;

         if ( status ) break;
         p_window_id = fileWID;
         p_line = localLineNumber;_begin_line();
         seekPos := _QROffset();

         //caption := m_rangeList[lineData].description;
         caption := "Version ":+pLineInfo->getVersion():+",":+m_rangeList[lineData].description;

         markerIndex := _StreamMarkerAddB(filename,seekPos,3,true,0,markerType,caption);
         _StreamMarkerSetStyleColor(markerIndex,m_rangeList[lineData].bgcolor);


         p_window_id = origWID;
         if ( markerIndex>=0 ) {
            status = markerIndex;
         }
         
      } while ( false );
      return status;
   }
}
