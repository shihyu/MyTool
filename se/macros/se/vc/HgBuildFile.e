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
#require "IBuildFile.e"

// Just for testing
#import "diff.e"

#import "stdprocs.e"
#endregion Imports


/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class HgBuildFile : IBuildOriginalFile {
   int buildOriginalFile(_str localFilename,int scriptWID) {
      status := _open_temp_view(localFilename,auto localFileWID,auto origWID);
      if ( status ) {
         return status;
      }
      createOptions := "";
      if ( p_newline=="\n" ) {
         createOptions = "+TU";
      } else if ( p_newline=="\r" ) {
         createOptions = "+TM";
      } else if (p_newline=="\n\r") {
         createOptions = "+TD";
      }
      origFileEncoding := p_encoding;
      origFileUTF8 := p_UTF8;
      scriptWID.top();
      _create_temp_view(auto builtFileWID,createOptions);
      p_UTF8 = origFileUTF8;
      p_encoding = origFileEncoding;
      p_window_id = scriptWID;
      down(3);
      lastMatchLine := 1;
      for ( i:=0;;++i ) {
         if ( processNextChange(scriptWID,lastMatchLine,localFileWID,builtFileWID,i) ) break;
         if (down()) break;
      }

      // Copy the rest of the file
      p_window_id = localFileWID;
      markid := _alloc_selection();
      p_line = lastMatchLine;
      _select_line(markid);
      bottom();
      _select_line(markid);

      p_window_id = builtFileWID;
      bottom();
      _copy_to_cursor(markid);

      _free_selection(markid);

      p_window_id = origWID;


      builtFileWID.p_modify = false;

      _delete_temp_view(localFileWID);
      p_window_id = origWID;
      return builtFileWID;
   }

   private int processNextChange(int scriptWID,int &lastMatchLine,int localFileWID,int builtFileWID,int numIn) {
      p_window_id=scriptWID;
      if ( p_line==1 ) down(4);
      get_line(auto scriptLine);
      status := 0;
      _str file1LineStr,file1numLinesStr,file2LineStr,file2numLinesStr;
      if ( substr(scriptLine,1,2)!='@@' || substr(scriptLine,length(scriptLine)-2)!='@@' ) return -1;

      parse scriptLine with '@@ -' file1LineStr','file1numLinesStr ' +' file2LineStr','file2numLinesStr ' @@' .;
      int file1LineNum = (int)file1LineStr;
      int file1NumLines = (int)file1numLinesStr;
      int file2LineNum = (int)file2LineStr;
      int file2NumLines = (int)file2numLinesStr;

      copyMatchingSection(scriptWID,lastMatchLine,localFileWID,builtFileWID,file2LineNum);
      copyDifferentSection(scriptWID,lastMatchLine,localFileWID,builtFileWID,file2LineNum,file2NumLines);

      lastMatchLine = (file2LineNum+file2NumLines);

      return status;
   }

   private int copyMatchingSection(int scriptWID,int &lastMatchLine,int localFileWID,int builtFileWID,int newLineNum) {
      if ( lastMatchLine>=newLineNum ) return-1;
      origWID := p_window_id;
      p_window_id = localFileWID;

      markid := _alloc_selection();
      p_line = lastMatchLine;
      _select_line(markid);
      p_line = newLineNum-1;
      _select_line(markid);

      p_window_id = builtFileWID;
      bottom();
      _copy_to_cursor(markid);

      _free_selection(markid);

      p_window_id = origWID;
      return 0;
   }

   private int copyDifferentSection(int scriptWID,int &lastMatchLine,int localFileWID,int builtFileWID,int newLineNum,int numLines) {
      origWID := p_window_id;
      p_window_id = scriptWID;

      for ( i:=0;i<numLines;++i ) {
         down();
         get_line(auto curLine);
         ch := substr(curLine,1,1);
         if ( ch==' ' || ch=='-' ) {
            p_window_id = builtFileWID;
            bottom();
            line := substr(curLine,2);
            insert_line(line);
            p_window_id = scriptWID;
            if ( ch=='-' ) ++numLines;
         }
      }
      p_window_id = origWID;
      return 0;
   }

};
