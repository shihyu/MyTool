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
#require "IWWTSIdentifier.e"
#include "markers.sh"
#import "sc/editor/TempEditor.e"
#import "varedit.e"
#import "stdprocs.e"
#include "WWTS.sh"
#import "math.e"
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
class WWTSUserIdentifier : IWWTSIdentifier {
   private WWTS_USER_INFO m_userTable:[];
   private _str m_description = "";

   // This is temp until we get real display stuff
   private int m_bmIndex = -1;
   //private int m_defaultColor = -1;

   WWTSUserIdentifier(int bmIndex = _pic_file) {
      m_userTable = null;
      m_bmIndex  = bmIndex;
   }
   ~WWTSUserIdentifier() {
   }

   public _str getType() {
      return "user";
   }

   public boolean isMatch(WWTSFile *pFile,WWTSLine *pLineInfo,typeless &lineData=null) {
      // 12:42:47 PM 1/24/2008
      // For this identifier, we will just calculate if we which one we are using
      // in displayLine.  There is a default for cases we didn't find, so always
      return true;
   }

   public int displayLine(WWTSFile *pFileInfo,int localLineNumber,int fileWID,int markerType,typeless &lineData=null) {
      origWID := p_window_id;
      status := 0;
      do {
         filename := pFileInfo->getFilename();
         status = pFileInfo->getLineInfo(localLineNumber,auto pLineInfo);
         if ( status ) break;

         p_window_id = fileWID;
         p_line = localLineNumber;_begin_line();
         if ( _line_length()<3 ) break;
         seekPos := _QROffset();

         userName := pLineInfo->getUserName();
         WWTS_USER_INFO curUserInfo=null;
         if ( m_userTable:[userName]!=null ) {
            curUserInfo = m_userTable:[userName];
         }else{
            curUserInfo = m_userTable:[""];
         }
         caption := userName:+",":+curUserInfo.description;

         markerIndex := _StreamMarkerAddB(filename,seekPos,3,1,0,markerType,caption);

         lineUserName := pLineInfo->getCaption("%u");

         WWTS_USER_INFO lineUserInfo = null;
         if ( m_userTable._indexin(lineUserName) ) {
            // Do this to be sure we don't insert a null item
            lineUserInfo = m_userTable:[lineUserName];
         }

         userIndex := lineUserName;

         if ( lineUserInfo==null ) {
            // Get the default case
            userIndex = "";
            lineUserInfo = m_userTable:[userIndex];
            lineUserInfo.description = "[Default]";
         }

         if ( markerIndex>=0 && lineUserInfo!=null ) {
            _StreamMarkerSetStyleColor(markerIndex,lineUserInfo.bgcolor);
         }

         if ( markerIndex>=0 ) {
            status = markerIndex;
         }
      } while ( false );
      p_window_id = origWID;
      return status;
   }

   public void addUser(_str userName,int fgcolor,int bgcolor,_str description) {
      m_userTable:[userName].fgcolor = fgcolor;
      m_userTable:[userName].bgcolor = bgcolor;
      m_userTable:[userName].description = description;
   }

   public void getUserTable(WWTS_USER_INFO (&userTable):[]) {
      userTable = m_userTable;
   }

   public void deleteUser(_str userName) {
      //m_userTable:[userName] = null;
      m_userTable._deleteel(userName);
   }

   public void deleteAllUsers() {
      m_userTable = null;
   }
};
