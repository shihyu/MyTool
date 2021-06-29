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
#include "slick.sh"
#include "diff.sh"
#include "WWTS.sh"
#import "WWTSLine.e"
#import "stdprocs.e"
#import "varedit.e"
#import "sc/editor/TempEditor.e"
#import "backtag.e"
#import "help.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class WWTSFile {
   private WWTSLine m_fileAnnotations[]; 
   private int m_unannotatedWID;
   private _str m_filename;
   private int m_lastModified=0;
   private INTARRAY m_lineMappingTable;
   private _str m_versionLabelMap:[][];
   private _str m_versionDateMap:[];

   /** 
    * @param annotations Array of line annotations
    * @param bufViewId View Id of buffer that was annotated, need 
    *                  this to compare and properly assign
    *                  annotations to lines
    */
   WWTSFile(_str filename="",WWTSLine (&annotations)[]=null,int unannotatedWID=0,
            _str (&versionLabelMap):[][]=null,_str (&versionDateMap):[]=null) {
      m_filename         = filename;
      m_fileAnnotations  = annotations;
      m_unannotatedWID   = unannotatedWID;
      m_lineMappingTable = null;
      m_versionLabelMap  = versionLabelMap;
      m_versionDateMap   = versionDateMap;
   }

   public _str getFilename() {
      return m_filename;
   }

   /** 
    * @param linenumber real line number, 1..n 
    *  
    * @param lineInfo info for the line specified 
    * 
    * @return int 0 if successful
    */
   public int getLineInfo(int localLineNumber,WWTSLine *(&pLineInfo)) {
      pLineInfo = null;
      status := 0;
      status = getLineMapping(localLineNumber,auto infoLinenumber=-1);
      do {
         if ( infoLinenumber<=0 ) {
            status = 1;break;
         }
         if ( infoLinenumber>=m_fileAnnotations._length() ) {
            pLineInfo=null;
            status = INVALID_ARGUMENT_RC;break;
         }
         pLineInfo = &(m_fileAnnotations[infoLinenumber-1]);
         if ( pLineInfo==null ) {
            pLineInfo=null;
            status = 1;
         }
      } while (false);
      return status;
   }

   public int getUnannotatedWID() {
      return m_unannotatedWID;
   }

   /** 
    * @param fileOnDiskLinenumber line number in the buffer that we
    * are marking up
    * 
    * @param infoLinenumber line number in the table of information
    *                       that we have
    * 
    * @return 0 if successful
    */
   public int getLineMapping(int fileOnDiskLinenumber,int &infoLinenumber) {
      if (!_haveDiff()) {
         popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Diff");
         return VSRC_FEATURE_REQUIRES_PRO_EDITION;
      }
      status := 0;
      infoLinenumber =- 1;
      do {
         if ( m_lastModified!=p_LastModified || m_lineMappingTable==null ) {
            sc.editor.TempEditor tempEditor(m_filename);
            if ( tempEditor.getStatus() ) break;

            DIFF_INFO diffInfo;
            diffInfo.iViewID1 = tempEditor.getWindowID();
            diffInfo.iViewID2 = m_unannotatedWID;
            diffInfo.iOptions = DIFF_NO_BUFFER_SETUP|DIFF_DONT_COMPARE_EOL_CHARS|DIFF_DONT_MATCH_NONMATCHING_LINES;
            diffInfo.iNumDiffOutputs = 0;
            diffInfo.loadOptions = def_load_options;
            diffInfo.iGaugeWID = 0;
            diffInfo.iMaxFastFileSize = def_max_fast_diff_size;
            diffInfo.iSmartDiffLimit = def_smart_diff_limit;
            status=Diff(diffInfo);
            _DiffGetMatchVector(m_lineMappingTable);
            m_lastModified=p_LastModified;
         }
      } while ( false );
      infoLinenumber = m_lineMappingTable[fileOnDiskLinenumber];
      if ( infoLinenumber==null ) {
         infoLinenumber = -1;
      }
      return status;
   }

   /**
    * 
    * @return 0 if successful
    */
   public int getLabelMapping(_str version,STRARRAY &labelList) {
      status := 0;
      labelList = m_versionLabelMap:[version];
      if ( labelList==null ) {
         status = 1;
      }
      return status;
   }

   public STRHASHTABARRAY getLabelMap() {
      return m_versionLabelMap;
   }

   public void getDateMapping(_str version,_str &date) {
      date = "";

      if ( m_versionDateMap:[version] != null ) {
         date = m_versionDateMap:[version];
      }
   }

   public STRHASHTAB getDateMap(_str version) {
      return m_versionDateMap;
   }
};
