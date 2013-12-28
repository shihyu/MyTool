////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#import "WWTSLine.e"
#import "WWTSFile.e"
#import "backtag.e"
#import "cvsquery.e"
#require "IWWTSIdentifier.e"
#include "markers.sh"
#include "WWTS.sh"
#import "sc/editor/TempEditor.e"
#import "varedit.e"
#import "wkspace.e"
#import "stdprocs.e"
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
class WWTSRelativeAgeIdentifier : IWWTSIdentifier {

   // This is temp until we get real display stuff
   private int m_bmIndex = -1;
   private _str m_curDate = "";
   private int m_defaultIndex = -1;
   private int m_daysSince1980 = 0;
   private INT_DATE_RANGE m_rangeList[];

   WWTSRelativeAgeIdentifier(int bmIndex = _pic_file_d) {
      setInternalDate();
      m_bmIndex = bmIndex;
   }

   ~WWTSRelativeAgeIdentifier() {
   }

   private void setInternalDate() {
      curDate := _date();
      if ( m_curDate != curDate ) {
         m_curDate = curDate;
         parse m_curDate with auto month '/' auto day '/' auto year;
         imonth := (int) month;
         iday   := (int) day;
         iyear  := (int) year;
         m_daysSince1980 = _days_since_ny1980(imonth,iday,iyear);
      }
   }

   private void findDefaultIndex() {
      m_defaultIndex = -1;
      len := m_rangeList._length();
      for ( i:=0;i<len;++i ) {
         if ( !m_rangeList[i].ageInDays ){
            m_defaultIndex = i;break;
         }
      }
   }

   public void addAge(int ageInDays,int fgcolor,int bgcolor,_str description) {
      INT_DATE_RANGE range;
      range.ageInDays = ageInDays;
      range.fgcolor = fgcolor;
      range.bgcolor = bgcolor;
      range.description = description;

      len := m_rangeList._length();
      if ( !len ) {
         m_rangeList[0] = range;
      }else if ( range.ageInDays < m_rangeList[0].ageInDays ) {
         ShiftArrayUp(m_rangeList,0);
         m_rangeList[0] = range;
      }else if ( range.ageInDays > m_rangeList[len-1].ageInDays ) {
         m_rangeList[m_rangeList._length()] = range;
      }else{
         for ( i:=1;i<len-1;++i ) {
            if ( range.ageInDays > m_rangeList[i-1].ageInDays &&
                 range.ageInDays < m_rangeList[i].ageInDays ) {
               ShiftArrayUp(m_rangeList,i);
               m_rangeList[i] = range;
            }
         }
      }
   }

   void deleteAllRanges() {
      m_rangeList = null;
   }

   public void getRangeList(INT_DATE_RANGE (&rangeList)[]) {
      rangeList = m_rangeList;
   }

   public void setRangeList(INT_DATE_RANGE (&rangeList)[]) {
      m_rangeList = rangeList;
      findDefaultIndex();
   }

   public _str getType() {
      return "relativeage";
   }

   public boolean isMatch(WWTSFile *pFile,WWTSLine *pLineInfo,typeless &lineData=null) {
      if ( m_defaultIndex<0 ) findDefaultIndex();
      lineData = null;
      setInternalDate();

      match := false;

      lineMonth := (int)pLineInfo->getCaption("%m");
      lineDay  := (int)pLineInfo->getCaption("%d");
      lineYear  := (int)pLineInfo->getCaption("%y");
      lineDate := _days_since_ny1980(lineMonth,lineDay,lineYear);

      curOldest := 0;
      len := m_rangeList._length();

      lineAge := m_daysSince1980 - lineDate;

      for ( i:=0;i<len;++i ) {
         if ( i==m_defaultIndex ) {
            continue;
         }
         if ( lineAge < m_rangeList[i].ageInDays ) {
            lineData = i;
            match = true;
            break;
         }
      }

      if ( !match ) {
         if ( m_defaultIndex>-1 ) {
            match = true;
            lineData = m_defaultIndex;
         }
      }

      return match;
   }

   public int displayLine(WWTSFile *pFileInfo,int localLineNumber,int fileWID,int markerType,typeless &lineData=null) {
      origWID := p_window_id;
      status := 0;
      do {
         filename := pFileInfo->getFilename();
         status = pFileInfo->getLineInfo(localLineNumber,auto pLineInfo);
         if ( status ) break;

         if ( status ) break;
         p_window_id = fileWID;
         p_line = localLineNumber;_begin_line();
         seekPos := _QROffset();

         //caption := pLineInfo->getCaption();
         //if ( lineData!=null ) {
         //   caption = m_rangeList[lineData].description:+" ":+caption;
         //}
         caption := "Version ":+pLineInfo->getVersion():+",":+m_rangeList[lineData].description;

         markerIndex := _StreamMarkerAddB(filename,seekPos,3,1,0,markerType,caption);
         p_window_id = origWID;

         if ( markerIndex>=0 ) {
            if ( lineData!=null ) {
               _StreamMarkerSetStyleColor(markerIndex,m_rangeList[lineData].bgcolor);
            }
            status = markerIndex;
         }

      } while ( false );
      return status;
   }
};
