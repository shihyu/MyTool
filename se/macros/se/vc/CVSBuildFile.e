////////////////////////////////////////////////////////////////////////////////////
// Copyright 2013 SlickEdit Inc. 
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
#include "rc.sh"
#require "IBuildFile.e"
#import "stdprocs.e"
#import "saveload.e"
#import "stdcmds.e"
#import "listbox.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class CVSBuildFile : IBuildOriginalFile {

   int buildOriginalFile(_str localFilename,int scriptWID) {
      status := _open_temp_view(localFilename,auto localFileWID,auto origWID);
      if ( status ) {
         return status;
      }
      origFileEncoding := p_encoding;
      origFileUTF8 := p_UTF8;
      scriptWID.top();
      createOptions := "";
      if ( p_newline=="\n" ) {
         createOptions = "+TU";
      } else if ( p_newline=="\r" ) {
         createOptions = "+TM";
      } else if (p_newline=="\n\r") {
         createOptions = "+TD";
      }
      _create_temp_view(auto builtFileWID,createOptions);
      p_UTF8 = origFileUTF8;
      p_encoding = origFileEncoding;
      p_window_id = origWID;
      lastMatchLine := 1;
      for ( ;; ) {
         if ( processNextChange(scriptWID,lastMatchLine,localFileWID,builtFileWID) ) break;
      }

      if ( lastMatchLine<localFileWID.p_Noflines ) {
         markid := _alloc_selection();
         p_window_id = localFileWID;
         p_line=lastMatchLine;
         _select_line(markid);
         bottom();
         _select_line(markid);
         p_window_id = builtFileWID;
         bottom();
         _copy_to_cursor(markid);
         _deselect(markid);
      }
      builtFileWID.p_modify = false;
      p_window_id = localFileWID;

      _delete_temp_view(localFileWID);
      p_window_id = origWID;
      return builtFileWID;
   }

   private int processNextChange(int scriptWID,int &lastMatchLine,int localFileWID,int builtFileWID) {
      p_window_id=scriptWID;
      if ( p_line==1 ) down(5);
      get_line(auto scriptLine);
      p := pos('a|c|d',scriptLine,1,'r');
      if ( !p ) {
         return 1;
      }

      commandChar := substr(scriptLine,p,1);
      preInfo := substr(scriptLine,1,p-1);
      postInfo := substr(scriptLine,p+1);
      status := 0;
      switch ( commandChar ) {
      case 'a':
         {
            lineNum := (int)preInfo;
            range := postInfo;

            if ( processAdd(localFileWID,builtFileWID,scriptWID,lastMatchLine,lineNum,range) ) status =  1;
         }
         break;
      case 'c':
         {
            range1 := preInfo;
            range2 := postInfo;
            if ( processChange(localFileWID,builtFileWID,scriptWID,lastMatchLine,range1,range2) ) status = 1;
         }
         break;
      case 'd':
         {
            range := preInfo;
            lineNum := (int)postInfo;
            if ( processDelete(localFileWID,builtFileWID,scriptWID,lastMatchLine,lineNum,range) ) status = 1;
         }
         break;
      }
      return status;
   }

   private int processAdd(int localFileWID,int builtFileWID,int scriptWID,int &lastMatchLine,int lineNum,_str range) {
      status := 0;
      origWID := p_window_id;
      do {
         parse range with auto startLineStr ',' auto endLineStr ;
         startLine := (int)startLineStr;
         endLine := -1;
         if ( endLineStr == "" ) {
         } else {
            endLine = (int) endLineStr;
         }


         // Copy the last section that matched
         if ( lastMatchLine<startLine ) {
            markid := _alloc_selection();
            p_window_id = localFileWID;
            p_line=lastMatchLine;
            _select_line(markid);
            if ( startLine!=lastMatchLine+1 ) {
               p_line=startLine-1;
               _select_line(markid);
            }
            p_window_id = builtFileWID;
            bottom();
            _copy_to_cursor(markid);
            _deselect(markid);
            _free_selection(markid);
         }

         p_window_id = scriptWID;
         if ( endLine!=-1 ) {
            if ( down((endLine-startLine)+1) ) {
               status = 1;
               break;
            }
         } else {
            down();
         }
         
         if ( endLine==-1 ) {
            lastMatchLine = startLine +1;
         } else {
            lastMatchLine = endLine +1;
         }
         p_window_id = scriptWID;
         if ( down() ) {
            status = 1;
            break;
         }
      } while (false);
      p_window_id = origWID;
      return status;
   }

   private int processDelete(int localFileWID,int builtFileWID,int scriptWID,int &lastMatchLine,int lineNum,_str range) {
      origWID := p_window_id;
      status := 0;
      do {
         parse range with auto startLineStr ',' auto endLineStr ;
         startLine := (int)startLineStr;
         endLine := -1;
         if ( endLineStr == "" ) {
         } else {
            endLine = (int) endLineStr;
         }
         markid := _alloc_selection();
         if ( lastMatchLine<startLine ) {
            p_window_id = localFileWID;
            p_line=lastMatchLine;
            _select_line(markid);
            if ( startLine!=lastMatchLine+1 ) {
               p_line=startLine-1;
               _select_line(markid);
            }
            p_window_id = builtFileWID;
            bottom();
            _copy_to_cursor(markid);
            _deselect(markid);
         }

         p_window_id = scriptWID;
         if ( down() ) {
            status = 1;
            break;
         }
         _select_line(markid);
         if ( endLine!=-1 ) {
            down((endLine-startLine));
            _select_line(markid);
         }
         p_window_id = builtFileWID;
         bottom();
         _copy_to_cursor(markid);

         _begin_select(markid);
         block_markid := _alloc_selection();
         begin_line();
         _select_block(block_markid);
         _end_select(markid);
         begin_line();
         right();
         _select_block(block_markid);
         _delete_selection(block_markid);

         _free_selection(block_markid);
         _free_selection(markid);

         p_window_id = origWID;
         lastMatchLine = startLine;
         p_window_id = scriptWID;
         if ( down() ) {
            status = 1;
            break;
         }
      } while (false);
      p_window_id = origWID;
      return status;
   }

   private int processChange(int localFileWID,int builtFileWID,int scriptWID,int &lastMatchLine,_str range1,_str range2) {
      status := 0;
      origWID := p_window_id;
      do {
         parse range1 with auto startLine1Str ',' auto endLine1Str ;
         parse range2 with auto startLine2Str ',' auto endLine2Str ;
         startLine1 := (int)startLine1Str;
         endLine1 := -1;
         startLine2 := (int)startLine2Str;
         endLine2 := -1;
         if ( endLine1Str != "" ) {
            endLine1 = (int)endLine1Str;
         }
         if ( endLine2Str != "" ) {
            endLine2 = (int)endLine2Str;
         }

         markid := _alloc_selection();

         if ( lastMatchLine<startLine2 ) {
            p_window_id = localFileWID;
            p_line=lastMatchLine;
            _select_line(markid);
            if ( startLine2!=lastMatchLine+1 ) {
               p_line=startLine2-1;
               _select_line(markid);
            }
            p_window_id = builtFileWID;
            bottom();
            _copy_to_cursor(markid);
            _deselect(markid);
         }

         p_window_id = scriptWID;
         if ( down() ) {
            status = 1;
            break;
         }
         _select_line(markid);
         if ( endLine1!=-1 ) {
            if ( down((endLine1-startLine1)) ) {
               status = 1;
               break;
            }
            _select_line(markid);
         }
         p_window_id = builtFileWID;
         bottom();
         _copy_to_cursor(markid);

         _begin_select(markid);
         block_markid := _alloc_selection();
         begin_line();
         _select_block(block_markid);
         _end_select(markid);
         begin_line();
         right();
         _select_block(block_markid);
         _delete_selection(block_markid);

         _free_selection(markid);
         
         p_window_id = origWID;
         if ( endLine1==-1 ) {
            lastMatchLine = startLine2 +1;
         } else {
            lastMatchLine = endLine2 +1;
         }
         p_window_id = scriptWID;

         // Move past other stuff
         if ( down((endLine2-startLine2)+1+2) ){
            // These are the +2 added in above
            //down();  // Move on to "---"
            //down();  // Move past
            status = 1;
            break;
         }
      } while (false);
      p_window_id = origWID;
      return status;
   }
};
