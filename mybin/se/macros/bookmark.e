////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#include "tagsdb.sh"
#include "eclipse.sh"
#require "annotations.e"
#import "bind.e"
#import "bookmark.e"
#import "cbrowser.e"
#import "context.e"
#import "eclipse.e"
#import "files.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "pushtag.e"
#import "recmacro.e"
#import "sellist.e"
#import "seltree.e"
#import "stdprocs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "treeview.e"
#import "util.e"
#endregion

/*
  This module provides book marking capabilities.  A bookmark is used to
  remember a location in an active file and attach it to a user supplied
  name or number.

  The maximum number of bookmarks that can be active is dependant on the
  -sv option.  See slick help on invocation.

  bookmark.e last change date 08/14/92

  Changes to bookmark.e as released with 2.2:

   *  A replace option "-R" replaces an existing bookmark without prompting.
      Returns 0 if successful.  1 is returned if bookmark id given could
      not be replaced.
   *  A no menu option "-M" can be used with GOTO-BOOKMARK to prevent a popup
      menu but set a non-zero return code if the mark requested is not
      present.  It can also be used with SET-BOOKMARK to return a non-zero
      value if the bookmark is already set.
   *  Allow for up to unlimited length alpha-numeric bookmarks instead of just
      2 digit.  A user configurable variable "def_bm_max_id" is used to set
      the space reserved for the bookmark id in the bookmark display. Don't
      set this variable to less than a value of 5.
   *  Allow the option and bookmark id to be specified in any order.

  Fixes:

   *  Fix bookmark cancelled on goto bookmark greater then 5 characters

Author(s):  Tom Zartler, AMI, 215 544-0572
            J. Clark Maurer,  SlickEdit Inc.
*/

#define BEEP   0            /* Set to 1 if you want beep on error */
#define MAX_BMDATA_LINE_LEN 200


/**
 * Field width of bookmark id for display.
 * Must be at least 5.
 * 
 * @default 5
 * @categories Configuration_Variables
 */
int def_bm_max_id = 5;    

/**
 * boolean string.  Turn off if you don't want line number displayed.
 * 
 * @categories Configuration_Variables
 */
_str  def_bm_show_line;   
                         

/**
 * Store bookmarks in the workspace history file. The alternate is in the
 * vrestore.slk file.
 * 
 * @default false
 * @categories Configuration_Variables
 */
boolean def_use_workspace_bm = false;

/**
 * Show bitmaps for standard bookmarks.
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_bm_show_picture = true;

/** 
 * Push a bookmark when navigating between search results. 
 *  
 * @default true 
 * @categories Configuration_Variables
 */
boolean def_search_result_push_bookmark = true;

int def_bm_scrollmarkup_color = 0x00FF00;

static boolean gSetBMEnabled;



/** 
 * Relocatable code markers for bookmarks, indexed by the name of the file they 
 * appear in, then by bookmark name. 
 *  
 * Use the following functions to access the relocatable markers.  Accessing the 
 * tables directly can result in putting in bogus entries, which causes stacks 
 * and general misery. 
 */
static RELOC_MARKER bmRELOC_MARKERs:[]:[];

/**
 * Retrieves the number of relocatable markers for this file.
 * 
 * @param filename 
 * 
 * @return int
 */
static int getNumRelocMarkersForFile(_str filename)
{
   // see if we have anything for this file
   if (!bmRELOC_MARKERs._indexin(filename)) {
      return 0;
   }

   // return the size of the table we have
   return bmRELOC_MARKERs:[filename]._length();
}

/**
 * Removes all relocatable markers for the given file.
 * 
 * @param filename 
 */
static void deleteRelocMarkersForFile(_str filename)
{
   // just go ahead and delete the value for this key
   bmRELOC_MARKERs._deleteel(filename);
}

/**
 * Retrieves the relocatable marker for the given file and bookmark name.  If 
 * no such marker exists, null is retrieved and false is returned. 
 *  
 * @param filename         
 * @param bmName 
 * @param marker           where to put the desired marker, this is left as null 
 *                         if nothing is found
 * 
 * @return boolean         true if a marker matched these parameters, false if 
 *                         not
 */
static boolean getRelocMarker(_str filename, _str bmName, RELOC_MARKER &marker)
{
   marker = null;

   // first, check for bookmarks in this file
   if (!bmRELOC_MARKERs._indexin(filename)) return false;

   // now check for a bookmark with this name
   if (!bmRELOC_MARKERs:[filename]._indexin(bmName)) return false;

   // retrieve it and return true
   marker = bmRELOC_MARKERs:[filename]:[bmName];
   return true;
}

/**
 * Saves a relocatable marker.
 *  
 * @param filename 
 * @param bmName 
 * @param marker 
 */
static void addRelocMarker(_str filename, _str bmName, RELOC_MARKER &marker)
{
   // add this to the proper location
   bmRELOC_MARKERs:[filename]:[bmName] = marker;
}

/**
 * Number of milliseconds to attempt to relocate all bookmarks in a file. 
 *  
 * @default 2000 
 * @categories Configuration_Variables 
 */
int def_max_bookmark_relocate_time=2000;


//static _str _bookmark_callback(reason,var result,key);
static _str _goto_bookmark_callback(int reason,var result,_str key)
{
   if (reason==SL_ONINIT) {
      if (!_sellist.p_Noflines) {
         b4.p_enabled=0;
      }
      return ('');
   }
   // Initialize or change selected
   if (reason==SL_ONSELECT) {
      return ('');
   }

   typeless bm_id='';
   if (reason==SL_ONDEFAULT) {  // Enter key
      // Only call for set book mark case
      bm_id=strip(_sellistcombo.p_text);
            // Don't allow ## option
            if (!isbm_valid(bm_id,1)) {
               p_window_id=_sellistcombo;
               _set_sel(1,length(p_text)+1);
               return ('');
            }
            result=bm_id;
      return (1);
   }
   if (reason==SL_ONUSERBUTTON) {
      _str line='';
      int orig_wid=p_window_id;
      switch (key) {
      case 4:  // Delete bookmark
         p_window_id=_sellist;
         line=_lbget_text();
         parse line with bm_id .;
         if ( bm_id == '' ) {
            return ('');
         }
         delete_bookmark(bm_id);
         _lbdelete_item();
         if (!p_line) {
            result='';
            return (1);
         } else {
            line=_lbget_text();
                 parse line with bm_id . ;
                 _sellistcombo.set_command(bm_id,1); //,length(bm_id)+1
                 _lbselect_line();
         }
         return ('');
      }
   }
   if (reason==SL_ONDELKEY) {
      // First find the delete button
      wid := _find_control('ctldelete');
      if (wid) {
         // call the delete button
         wid.call_event(wid,LBUTTON_UP);
      }
   }
   return ('');
}
static _str _set_bookmark_callback(int reason,var result,_str key)
{
   if (reason==SL_ONINIT) {
      ctlreplace._delete_window();
      ctlgoto.p_enabled=0;
      ctldelete.p_enabled=0;
      _sellistok.p_enabled=gSetBMEnabled;
      return ('');
   }
   // Initialize or change selected
   typeless bm_id='';
   typeless tbm_id='';
   _str rest='';
   int orig_wid=0;
   _str line='';
   if (reason==SL_ONSELECT) {
      if (_sellistcombo.p_visible) {
         if (_sellist._lbisline_selected()) {
            ctldelete.p_enabled=1;
            ctlgoto.p_enabled=1;
         } else {
            ctldelete.p_enabled=0;
            ctlgoto.p_enabled=0;
         }
         // DJB 03-23-2007 -- strip leading and trailing
         // spaces and replace the rest with underscores
         // instead of just loosing anything typed after
         // the first space.
         // 
         //parse _sellist._lbget_text() with bm_id rest;
         //parse _sellistcombo.p_text with tbm_id rest;
         bm_id=strip(_sellist._lbget_text());
         bm_id = stranslate(bm_id, '_', ' ');
         tbm_id = strip(_sellistcombo.p_text);
         tbm_id = stranslate(tbm_id, '_', ' ');
         if (pos(tbm_id, bm_id) == 1) {
            _sellistok.p_caption="&Replace";
            //ctlgoto.p_enabled=1;

            if (_sellist._lbisline_selected()) {
               _sellistok.p_default=0;
               ctlgoto.p_default=1;
            }
            _sellistok.p_enabled=gSetBMEnabled;
         } else {
            _sellistok.p_default=1;
            ctlgoto.p_default=0;

            _sellistok.p_enabled=isbm_valid(tbm_id,true) && gSetBMEnabled;
            _sellistok.p_caption="&Add";
            //ctlgoto.p_enabled=0;
         }
         return ('');
      }
      return ('');
   }
   /*if (reason==SL_ONCHANGE) {

   } */
   if (reason==SL_ONDEFAULT) {  // Enter key
      if (ctlgoto.p_default) {
         reason=SL_ONUSERBUTTON;
         key=4;
      } else {
         // Only call for set book mark case
         bm_id=strip(_sellistcombo.p_text);
         // Don't allow ## option
         if (!isbm_valid(bm_id,1)) {
            p_window_id=_sellistcombo;
            _set_sel(1,length(p_text)+1);
            return ('');
         }
         result=bm_id;
         _param1=0;  // Set bookmark
         return (1);
      }
   }
   if (reason==SL_ONUSERBUTTON) {
      orig_wid=p_window_id;
      switch (key) {
      case 1:
         // Only call for set book mark case
         bm_id=strip(_sellistcombo.p_text);
         tbm_id=stranslate(bm_id, '_', ' ');
         // Don't allow ## option
         if (!isbm_valid(tbm_id,1)) {
            p_window_id=_sellistcombo;
            _set_sel(1,length(p_text)+1);
            return ('');
         }
         result=bm_id;
         _param1=0;  // Set bookmark
         return (1);
      case 4:
         line=_sellist._lbget_text();
         parse line with bm_id rest;
         result=bm_id;
         _param1=1;  // Go to bookmark
         return (1);
      case 5:  // Delete bookmark
         p_window_id=_sellist;

         // DJB 01-23-2008 -- strip leading and trailing
         // spaces and replace the rest with underscores
         // instead of just loosing anything typed after
         // the first space.
         // 
         //parse _sellist._lbget_text() with bm_id rest;
         //parse _sellistcombo.p_text with tbm_id rest;
         bm_id = strip(_sellist._lbget_text());
         bm_id = stranslate(bm_id, '_', ' ');
         tbm_id = strip(_sellistcombo.p_text);
         tbm_id = stranslate(tbm_id, '_', ' ');
         if (_sellistcombo.p_visible && pos(tbm_id,bm_id,1,'i')!=1) {
            _message_box(nls('This bookmark does not exist'));
            p_window_id=_sellistcombo;
            _set_sel(1,length(p_text)+1);_set_focus();
            return ('');
         }
         if ( bm_id == '' ) {
            return '';
         }
         bm_id = strip(_sellist._lbget_text());
         parse bm_id with bm_id . ;
         delete_bookmark(bm_id);
         updateBookmarksToolWindow();
         _lbdelete_item();
         if (!p_line) {
            if (_sellistcombo.p_visible) {
               //ctldelete.p_enabled=0;
               //ctlgoto.p_enabled=0;
               _set_bookmark_callback(SL_ONSELECT,result,-1);
               return ('');
            }
            result='';
            return (1);
         } else {
            line=_lbget_text();
                 parse line with bm_id . ;
                 _sellistcombo.set_command(bm_id,1); //,length(bm_id)+1
                 _lbselect_line();
         }
         return ('');
      }
   }else if (reason==SL_ONDELKEY) {
      // First find the delete button
      int wid=_find_control('ctldelete');
      if (wid) {
         // call the delete button
         wid.call_event(wid,LBUTTON_UP);
      }
   }
   return ('');
}
int _restore_bookmark(_str filename, int line_no=0)
{
   if (!(_default_option(VSOPTION_APIFLAGS) &
         (VSAPIFLAG_MDI_WINDOW|VSAPIFLAG_GOTO_BOOKMARK_RESTORES_BY_FILENAME))) {
      return (1);
   }
   if (filename!='') {
      if(isEclipsePlugin()) {
         if(_eclipse_open(0, filename) > 0) {
            _BookmarkRestore();
         }
         return 0;
      }
      int status=edit('+q 'maybe_quote_filename(filename));
      if (status) {
         if (status==NEW_FILE_RC) {
            quit();
            status=FILE_NOT_FOUND_RC;
         }
         if (status==FILE_NOT_FOUND_RC) {
            _message_box(nls("File %s not found",filename));
            return (status);
         }
         _message_box(nls("Error opening %s.  ",filename):+get_message(status));
         return (status);
      } else if (line_no > 0) {
         p_RLine = line_no;
      }
      _BookmarkRestore();
   }
   return (0);
}

struct BookmarkSaveInfo
{
   _str BookmarkName;
   int vsbmflags;
   int RealLineNumber;
   int col;
   long BeginLineROffset;
   _str LineData;
   _str Filename;
   _str DocumentName;
   RELOC_MARKER relocationInfo;
};

static BookmarkSaveInfo eclipseBMSaves[];

_command void eclipse_save_markers() name_info(',')
{
   _SaveBookmarksInFile(eclipseBMSaves, 0, 0, false);
}

_command void eclipse_restore_markers() name_info(',')
{
   _RestoreBookmarksInFile(eclipseBMSaves);
}

/**
 * Save the bookmarks both automatic (pushed) bookmarks and 
 * set bookmarks in the given file, optionally restricting the 
 * bookmarks to a range of lines, and optionally saving relocation 
 * information. 
 * <p> 
 * This function is used to save bookmark information before 
 * we do something that heavily  modifies a buffer, such as 
 * refactoring, beautification, or auto-reload.  It uses the 
 * relocatable marker information to attempt to restore the 
 * bookmarks back to their original line, even if the actual 
 * line number has changed because lines were inserted or deleted.
 * 
 * @param bmSaves       Saved bookmarks           
 * @param startRLine    First line in region to save
 * @param endRLine      Last line in region to save
 * @param relocatable   Save relocation marker information? 
 *  
 * @see _RestoreBookmarksInFile 
 *  
 * @categories Bookmark_Functions 
 */
void _SaveBookmarksInFile(BookmarkSaveInfo (&bmSaves)[],
                          int startRLine=0, int endRLine=0,
                          boolean relocatable=true)
{
   // For each bookmark, save the ones that are in the current
   // file and within the specified region
   bmSaves._makeempty();
   int indices[];
   for ( i:=0; i < _BookmarkQCount(); ++i ) {

      // Get the the data about the bookmarks
      int buf_id=0;
      BookmarkSaveInfo bmInfo;
      _BookmarkGetInfo(i, bmInfo.BookmarkName, 0, bmInfo.vsbmflags, buf_id, 1,
                       bmInfo.RealLineNumber, bmInfo.col, 
                       bmInfo.BeginLineROffset, bmInfo.LineData,
                       bmInfo.Filename, bmInfo.DocumentName);

      // If the specified file does not match
      if (buf_id != p_buf_id || !file_eq(bmInfo.Filename, p_buf_name)) {
         continue;
      }

      // If the bookmark is before the start of the line region
      if (startRLine > 0 && bmInfo.RealLineNumber < startRLine) {
         continue;
      }

      // If the bookmark is after the end of the line region
      if (endRLine > 0 && bmInfo.RealLineNumber > endRLine) {
         continue;
      }

      // Get the relocatable marker info
      if (relocatable) {
         save_pos(auto p);
         p_RLine = bmInfo.RealLineNumber;
         _BuildRelocatableMarker(bmInfo.relocationInfo);
         restore_pos(p);
      } else {
         bmInfo.relocationInfo = null;
      }

      // Save all the information about the breakpoint.
      indices[indices._length()] = i;
      bmSaves[bmSaves._length()] = bmInfo;
   }

   // Now delete all the bookmarks that were saved away
   for (i = indices._length() - 1; i >= 0; --i) {
      _BookmarkRemove(indices[i]);
   }
}

/**
 * Restore saved bookmarks from the current file and relocate them
 * if the bookmark information includes relocation information. 
 * 
 * @param bmSaves          Saved bookmarks 
 * @param adjustLinesBy    Number of lines to adjust start line by
 *  
 * @see _SaveBookmarksInFile 
 * @see _BookmarkAdd 
 *  
 * @categories Bookmark_Functions 
 */
void _RestoreBookmarksInFile(BookmarkSaveInfo (&bmSaves)[], int adjustLinesBy=0)
{
   boolean resetTokens = true;
   save_pos(auto p);
   for (j := 0; j < bmSaves._length(); ++j) {

      // adjust the start line if we were asked to
      if (adjustLinesBy && bmSaves[j].RealLineNumber+adjustLinesBy > 0) {
         bmSaves[j].RealLineNumber += adjustLinesBy;
         if (bmSaves[j].relocationInfo != null) {
            bmSaves[j].relocationInfo.origLineNumber += adjustLinesBy;
         }
      }

      // relocate the marker, presuming the file has changed
      int  origRLine   = bmSaves[j].RealLineNumber;
      if (bmSaves[j].relocationInfo != null) {
         origRLine = _RelocateMarker(bmSaves[j].relocationInfo, resetTokens);
         resetTokens = false;
         if (origRLine < 0) {
            origRLine = bmSaves[j].RealLineNumber;
         }
      }

      // create a mark id for this new bookmark
      markid := _alloc_selection('B');
      p_RLine = origRLine;
      p_col = bmSaves[j].col;
      long origROffset = bmSaves[j].BeginLineROffset;
      if (origRLine != bmSaves[j].RealLineNumber) {
         origROffset = _QROffset();
      }
      _deselect(markid);
      _select_char(markid);

      // now add the bookmark
      _BookmarkAdd(bmSaves[j].BookmarkName, 
                   markid, bmSaves[j].vsbmflags,
                   origRLine, bmSaves[j].col, 
                   origROffset, bmSaves[j].LineData,
                   bmSaves[j].Filename, bmSaves[j].DocumentName);
   }

   updateBookmarksToolWindow(0);
   restore_pos(p);
}

/**
 * Places the cursor at the buffer cursor position stored in the bookmark given 
 * by <i>bookmarkName</i>. 
 * <p>
 * <b>Note</b>: This command no longer supports the + and - options.
 * 
 * @param bookmarkName Name of bookmark on which to place cursor.
 * 
 * @return Zero on success.
 * 
 * @see push_bookmark
 * @see pop_bookmark
 * @see set_bookmark
 * @see toggle_bookmark
 * @see goto_bookmark
 *  
 * @deprecated Use {@link goto_bookmark()}. 
 *  
 * @appliesTo  Edit_Window
 * @categories Bookmark_Functions
 */
_command old_goto_bookmark(_str bookmarkName='') name_info(BOOKMARK_ARG','VSARG2_READ_ONLY)
{
   _macro_delete_line();
   int was_recording=_macro();
   int status = 1;
   _str old_buffer_name='';
   typeless swold_pos;
   typeless swold_buf_id;
   set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
   if (isEclipsePlugin()) {
      int new_wid = eclipse_gotobookmark(bookmarkName);
      if (new_wid > 0) {
       //  p_window_id = new_wid;
         return 0;
      }
      return new_wid;
   }
   // old subtitle nls("Enter=Select Esc=Cancel '='=Prompt ")
   typeless bm_id='';
   typeless mark_id='';
   int vsbmflags=0;
   int buf_id=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str filename='';
   _str DocumentName='';
   _str bm_data = display_bookmarks(
                                    nls('Go to Bookmark'),'goto_bookmark',
                                    0, bookmarkName,
                                    false
                                    );
   if ( bm_data != '' ) {  /* a valid bookmark was selected */
      switch_buffer(old_buffer_name,'',swold_pos,swold_buf_id);
      parse bm_data with bm_id mark_id .;
      status=_BookmarkGetInfo(_BookmarkFind(bm_id),
                              bm_id,mark_id,vsbmflags,buf_id,
                              0,RealLineNumber,col,BeginLineROffset,
                              LineData,filename,DocumentName
                             );
      if (status==TEXT_NOT_SELECTED_RC) {
         status=_restore_bookmark(filename,RealLineNumber);
         if (status) {
            return (status);
         }
      }
      begin_select(mark_id,true,true);
      if (p_window_state=='I') {
         p_window_state='N';
      }
      message(nls("At bookmark '%s'",bm_id));
      status = 0;
      _macro('m',was_recording);
      _macro_call('goto_bookmark', bm_id);
   } else if (bookmarkName=='+' || bookmarkName=='-' ) {
      message(nls('No bookmark available to goto.'));
   }
   return (status);
}

/**
 * This callback is invoked when the new bookmarks dialog box is displayed. 
 * It's primary purpose is to handle the DELETE action. 
 * 
 * @param reason     reason callback was invoked (SL_ON*)
 * @param user_data  user data passed to {@link select_tree}
 * @param info       usually the current tree index in the list
 */
static _str select_bookmark_cb(int reason, typeless user_data, typeless info=null)
{
   switch (reason) {
   case SL_ONDELKEY:
      // get the bookmark ID and remove it from the tree
      if (info <= 0) break;
      bm_id := ctl_tree._TreeGetUserInfo(info);
      ctl_tree._TreeDelete(info);
      // remove the actual bookmark and update tool window
      _BookmarkGetInfo(bm_id, auto bm_name, auto bm_flags);
      if (bm_flags & VSBMFLAG_PUSHED) {
         _BookmarkStackRemove(bm_name);
      }
      _BookmarkRemove(bm_id);
      updateBookmarksToolWindow(0);
      // adjust bookmark id's after removing this one
      index := ctl_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         this_id := (int) ctl_tree._TreeGetUserInfo(index);
         if (this_id > bm_id) {
            ctl_tree._TreeSetUserInfo(index,this_id-1);
         }
         index = ctl_tree._TreeGetNextSiblingIndex(index);
      }
      break;
   case SL_ONINITFIRST:
      // always color the current item (makes delete work better)
      ctl_tree.p_AlwaysColorCurrent=true;
      break;
   }
   return '';
}
/**
 * Display all bookmarks and allow the user to select one. 
 * This dialog also allows you to delete bookmarks, and will 
 * immediately update the Bookmarks tool window. 
 * 
 * @param dialogCaption    Dialog caption 
 * @param pushed_bm        Display pushed bookmarks? 
 *                         Default is to display regular bookmarks. 
 * 
 * @return Returns the bookmark ID of the selected bookmark. 
 *         Returns COMMAND_CANCELLED_RC if the user hits escape.
 *         Returns STRING_NOT_FOUND_RC if there are no bookmarks. 
 */
static int select_bookmark(_str dialogCaption, boolean pushed_bm=false)
{
   // run through list of bookmarks
   _str captions[];
   _str ids[];
   n := _BookmarkQCount();
   for ( i:=0; i<n; ++i ) {
      _BookmarkGetInfo(i, 
                       auto name, 
                       auto markid,
                       auto vsbmflags,
                       auto buf_id,
                       1, // determine line number 
                       auto realLineNumber, 
                       auto col,
                       auto beginLineROffset,
                       auto lineData,
                       auto fileName,
                       auto documentName);

      // check if we are looking for pushed or not pushed bookmarks
      if ( ((vsbmflags & VSBMFLAG_PUSHED)==0) == pushed_bm ) {
         continue;
      }

      // the ID is always the bookmark ID
      ids[ids._length()] = i;

      // the first column is either the bookmark name or it's number
      if (pushed_bm) {
         bm_msg := get_message(VSRC_PUSHED_BOOKMARK_NAME);
         if (bm_msg=='') bm_msg="TAG";
         name = substr(name, length(bm_msg)+1);
      }

      // put together the entire item caption
      captions[captions._length()] = strip(name) "\t" fileName "\t" realLineNumber "\t" lineData;
   }

   // No bookmarks found, OMG!
   if (captions._length() == 0) {
      _message_box("No bookmarks");
      return STRING_NOT_FOUND_RC;
   }

   // Set up column appropriately, needs to sort numerically if
   // it contains the list of pushed bookmarks.
   _str col1Caption = (pushed_bm)? "No." : "Name";
   int  col1Flags   = (pushed_bm)? (TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_AL_RIGHT|TREE_BUTTON_SORT_DESCENDING):0;
   _str helpItem    = (pushed_bm)? "Bookmark Stack dialog" : "Go to Bookmark dialog box";

   // Use the select tree dialog to do the heavy lifting
   result := select_tree(captions, ids, null, null, null, select_bookmark_cb, null, 
                         dialogCaption, SL_SELECTPREFIXMATCH|SL_COLWIDTH|SL_DELETEBUTTON|SL_SIZABLE|SL_XY_WIDTH_HEIGHT,
                         col1Caption:+",File,Line,Data",
                         (col1Flags|TREE_BUTTON_SORT|TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_PUSHBUTTON)',':+
                         (TREE_BUTTON_PUSHED|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_IS_FILENAME)',':+
                         (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_AL_RIGHT)',':+
                         (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_AUTOSIZE),
                         true,
                         helpItem 
                        );

   // Return the result and we are done
   if (result == '' || result == COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }
   return (int) result;
}

/**
 * Navigate to the specified bookmark ID. 
 * Set the name of the bookmark so that the caller 
 * can use it for feedback. 
 * 
 * @param bm_id         bookmark index
 * @param bookmarkName  (reference) set to bookmark name
 * 
 * @return Returns the bookmark ID (bm_id) on 
 *         success. <0 on error.
 */
static int gotoBookmarkId(int bm_id, _str &bookmarkName)
{
   // get all bookmark information, assume bm_id is ok
   _BookmarkGetInfo(bm_id,
                    bookmarkName, 
                    auto markid,
                    auto vsbmflags,
                    auto buf_id,
                    1, // determine line number 
                    auto realLineNumber, 
                    auto col,
                    auto beginLineROffset,
                    auto lineData,
                    auto fileName,
                    auto documentName);

   // for emacs emulation, prepare to switch buffers
   set_switch_buffer_args(auto old_buffer_name, auto swold_pos, auto swold_buf_id);

   // navigate to the bookmark location
   status := _restore_bookmark(fileName,realLineNumber);
   if (!status) {
      begin_select(markid,true,true);
      if (p_window_state=='I') p_window_state='N';
   }

   // for emacs, let it know we switched buffers
   switch_buffer(old_buffer_name,'',swold_pos,swold_buf_id);

   // that's all folks
   message(nls("At bookmark '%s'",bookmarkName));
   if (!status) return bm_id;
   return status;
}

/** 
 * Displays a list of pushed bookmarks allowing you to navigate 
 * to a point higher up your bookmark stack without losing the 
 * existing contents of your bookmark stack. 
 * <p> 
 * The pushed bookmarks are listed from top to bottom, 
 * most recent to oldest. 
 * <p> 
 * When you select a bookmark, you are navigated to the location 
 * of the bookmark, however, your entire bookmark stack remains 
 * intact.  A bookmark is pushed for your previous cursor location. 
 * 
 * @see push_bookmark
 * @see pop_bookmark
 * @see goto_bookmark 
 * 
 * @appliesTo  Edit_Window
 * @categories Bookmark_Functions
 */
_command int bookmark_stack() name_info(','VSARG2_READ_ONLY)
{
   // set up macro recording
   _macro_delete_line();
   was_recording := _macro();

   // let them select a pushed bookmark from the stack
   bm_id := select_bookmark("Bookmark Stack", true);
   if (bm_id < 0) {
      _macro('m',was_recording);
      _macro_call('bookmark_stack');
      return bm_id;
   }

   // push another bookmark an navigate to the selected bookmark
   if (def_search_result_push_bookmark) push_bookmark();
   gotoBookmarkId(bm_id, auto bookmarkName);

   // record what happened
   _macro('m',was_recording);
   _macro_call('push_bookmark');
   _macro_call('goto_bookmark', bookmarkName);
   return 0;
}

/** 
 * Places the cursor at the file and cursor position stored 
 * in the bookmark given by <i>bookmarkName</i>. 
 * <p>
 * <b>Note</b>: This command no longer supports the + and - options.
 * 
 * @param bookmarkName Name of bookmark on which to place cursor.
 * 
 * @return Returns the bookmark ID on success. <0 on error. 
 * 
 * @see set_bookmark
 * @see toggle_bookmark
 * @see old_goto_bookmark 
 * @see bookmark_stack 
 *  
 * @appliesTo  Edit_Window
 * @categories Bookmark_Functions 
 */
_command int goto_bookmark,gb(_str bookmarkName='') name_info(BOOKMARK_ARG','VSARG2_READ_ONLY)
{
   // set up macro recording
   _macro_delete_line();
   was_recording := _macro();

   // do whatever we should do for Eclipse
   if (isEclipsePlugin()) {
      return eclipse_gotobookmark(bookmarkName);
   }

   // translate the bookmark name to a bookmark ID
   bm_id := 0;
   if (bookmarkName == '') {
      // no name given, show dialog
      bm_id = select_bookmark("Go to Bookmark", false);
      if (bm_id < 0) {
         _macro('m',was_recording);
         _macro_call('goto_bookmark');
         return bm_id;
      }
   } else {
      // find to bookmark by name
      bm_id = _BookmarkFind(bookmarkName);
      if (bm_id < 0) {
         // desparate, try pushed bookmarks
         bm_id = _BookmarkFind(bookmarkName,VSBMFLAG_PUSHED);
      }
      // not found, shoot...
      if (bm_id < 0) {
         _message_box(nls("Bookmark '%s' not found",bookmarkName));
         _macro('m',was_recording);
         _macro_call('goto_bookmark');
         return bm_id;
      }
   }

   // only push a bookmark if they selected one from the dialog
   // otherwise, assume that the caller will decide if we should
   // push a bookmark or not.  If we push a bookmark, it may cause
   // the bookmark ID's to get shuffled, so we need to find the
   // bookmark ID again so we go to the right place.
   if (bookmarkName == '') {
      _BookmarkGetInfo(bm_id, bookmarkName); 
      if (def_search_result_push_bookmark) push_bookmark();
      bm_id = _BookmarkFind(bookmarkName);
      if (bm_id < 0) {
         bm_id = _BookmarkFind(bookmarkName,VSBMFLAG_PUSHED);
      }
   }

   // navigate to the bookmark and record the event
   status := gotoBookmarkId(bm_id, bookmarkName);
   _macro('m',was_recording);
   _macro_call('goto_bookmark', bookmarkName);
   return status;
}

/**
 * @return A name for the bookmark at the current location within the file.
 */
_str get_bookmark_name()
{
   _str cur_loc = current_tag(false,false);
   if (cur_loc=='') {
      cur_loc = _strip_filename(p_buf_name,'P');
      cur_loc = stranslate(cur_loc,'_',' ');
   }
   if (cur_loc != '') {
      line := (int)point('L');
      if (line > 0) {
         cur_loc = cur_loc :+ ":" :+ p_RLine;
      }
   }
   return cur_loc;
}

/**
 * This function is used to set a bookmark on the current line.
 * 
 * @param arg1   command line options string of the form:
 *                <pre>option bookmark_name</pre>
 *               where <code>option</code> is:
 *               <ul>
 *               <li><tt>-n</tt> -- Use new smaller dialog to prompt for just bookmark name
 *               <li><tt>-q</tt> -- do not prompt for bookmark name
 *               <li><tt>-r</tt> -- set bookmark without prompting
 *               <li><tt>-m</tt> -- do not set duplicate mark
 *               </ul>
 *               and <code>bookmark_name</code> is the name of the bookmark
 *               to create.
 * 
 * @see push_bookmark
 * @see pop_bookmark
 * @see toggle_bookmark
 * @see goto_bookmark
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Bookmark_Functions
 * 
 */ 
_command set_bookmark,sb(_str arg1='', boolean quiet = false) name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   // Special case for Eclipse. We must use Eclipse bookmark mechanism.
   _str option='';
   if (isEclipsePlugin()) {
      _str bm_name = "";
      if (arg1 != "") {
         _str cmd_option = "";
         parse arg1 with option bm_name .;
         if (bm_name != '') {  /* a bookmark and command option are entered */
            /* expect the option to be first but, if it's not, swap them around */
            if ( pos('-r|-m', option, 1, 'RI')  == 1 ) {  /* option is first */
               cmd_option = upcase(option);
            } else if (pos('-r|-m', bm_name, 1, 'RI') == 1) {  /* option second */
               cmd_option = upcase(bm_name);
               bm_name = option;
            }
         } else {
            bm_name = option;
         }
      }
      if (bm_name != "") {
         bm_name = "Bookmark: '"upcase(bm_name)"'";
         eclipse_addbookmark(bm_name);
         //messageNwait("adding the bookmark1");
      } else {
         //eclipse_gotobookmark();
         //bm_name = "Bookmark: '"get_bookmark_name()"'";
         eclipse_addbookmark(/*bm_name*/);
         //messageNwait("adding the bookmark2");
      }
      return(0);
   }

   _str defaultBookMarkName='';
   int new_dialog_option=pos(' -n ',' 'arg1' ',1,'i');
   int noprompt_option=pos(' -q ',' 'arg1' ',1,'i');
   if (new_dialog_option) {
      // prompt for the bookmark name
      for (;;) {
         _str cur_loc = '';
         if (!_isEditorCtl() && !_no_child_windows()) {
            p_window_id = _mdi.p_child;
         }
         if (_isEditorCtl()) {
            cur_loc = get_bookmark_name();
            if (cur_loc != '' && noprompt_option) {
               arg1 = "-r ":+cur_loc;
               break;
            }
         }
         // DJB 03-23-2007 -- loop until they enter a valid bookmark name
         for (;;) {
            _str result = show('-modal _textbox_form',
                               'Specify bookmark name ', // Form caption
                               TB_RETRIEVE,  //flags
                               '', //use default textbox width
                               '', //Help item.
                               '', //Buttons and captions
                               'bookmarkName', //Retrieve Name
                               'Bookmark:':+cur_loc
                              );
            if ( result=='' ) {
               return(COMMAND_CANCELLED_RC);
            }
            if (!isbm_valid(_param1,true)) {
               _message_box("Bookmark names can not contain spaces or special characters");
               cur_loc = stranslate(_param1, '_', ' ');
               continue;
            }
            break;
         }
         if (_param1!='') {
            arg1 = "-r ":+_param1;
            break;
         }
      }
   } else {
      // Use the old dialog so emulations work better (brief,vcpp - users were complaining).
      // If we improve the bookmark toolbar so that users can do what they were used 
      // to from the keyboard, then maybe we can get rid of the old sellist dialog for this.
      if (arg1=='' || arg1=='-q') {
         _str cur_loc = '';
         boolean done=false;
         if (_isEditorCtl()) {
            cur_loc = get_bookmark_name();
            if (cur_loc != '' && arg1=='-q') {
               arg1 = "-r ":+cur_loc;
               done=true;
            }
         }
         if (!done) {
            defaultBookMarkName=cur_loc;
         }
      }
   }

   _macro_delete_line();
   int was_recording=_macro();
   int status = 1;
   //old subtitle nls("Enter=Replace Esc=Cancel '='=prompt  0-9,A-Z=Rep/Create"),
   //old_buffer_name=p_buf_name;
   boolean dialogResultGoTo=false;
   _str bm_data=display_bookmarks(nls('Bookmarks'),'set_bookmark',
                                  1,arg1,dialogResultGoTo,defaultBookMarkName);
   /**************************************************************************
   * The status of bm_data on return from display_bookmarks:                 *
   *  a. If esc was pressed nothing is returned.                             *
   *  b. If the bookmark selected is not in use only the bm_id is returned.  *
   *  c. If the bookmark is already in use the bm_id and the mark_id         *
   *     reference in the .bookmark buffer are returned.                     *
   *  Note: The bm_id is the alpha-numeric name selected for the bookmark.   *
   *        The mark_id is the mark id assigned by Slick.                    *
   **************************************************************************/
   typeless bm_id='';
   typeless mark_id='';
   typeless line_ref='';
   typeless cmd_option='';
   parse bm_data with bm_id mark_id line_ref cmd_option;
   if (dialogResultGoTo) {
      _macro('m',was_recording);
      return (goto_bookmark(bm_id));
#if 0
      switch_buffer(old_buffer_name);
      begin_select(mark_id);
      message(nls('At Bookmark %s',bm_id));
      status= 0;
      _macro('m',was_recording);
      _macro_call('goto_bookmark', bm_id);
      return (0);
#endif
   }
   if ( bm_id != '' && ! (mark_id != '' && cmd_option :== '-M') ) {
      /* allow a new bm, or a current bm if quiet mode is off, to be set */
      //if (mark_id=="") mark_id = _alloc_selection('B');

      delete_bookmark(bm_id);
      mark_id = _alloc_selection('B');
      _deselect(mark_id);
      _select_char(mark_id);
      int vsbmflags=VSBMFLAG_STANDARD;
      if (def_bm_show_picture) {
         vsbmflags |= VSBMFLAG_SHOWNAME|VSBMFLAG_SHOWPIC;
      }
      _BookmarkAdd(bm_id,mark_id, vsbmflags);
      if (!quiet) {

         // find the correspond key binding for activate_bookmarks
         // or goto-bookmark and display it on the message bar.
         gtkeys := where_is("activate_bookmarks",true);
         parse gtkeys with 'is bound to' gtkeys . ;
         if (gtkeys == "") {
            gtkeys = where_is("goto_bookmark",true);
            parse gtkeys with 'is bound to' gtkeys . ;
         }
         msgkey := "";
         if (gtkeys!="") {
            parse gtkeys with msgkey ',' gtkeys;
            msgkey = stranslate(msgkey, '-', '+');
            msgkey="Press "msgkey" to return to this bookmark later.";
         }

         // inform them that the bookmark has been set
         message(nls('Bookmark %s set.  %s',bm_id,msgkey));
         _macro('m',was_recording);
         _macro_call('set_bookmark', '-r 'bm_id);
         updateBookmarksToolWindow(0);
      }
      status=0;
   } else if ( cmd_option :== '-M' ) {
      if (!quiet) {
         message(nls('Bookmark %s is already set',bm_id));
      }
   }
   return (status);

}

/**
 * Goes to the next bookmark set by one of the commands <b>set_bookmark</b>, 
 * <b>push_bookmark</b>, or <b>push_tag</b>.
 * 
 * @see set_bookmark
 * @see toggle_bookmark
 * @see prev_bookmark
 * @see pb
 * 
 * @return Returns the bookmark ID on success. <0 on error. 
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Bookmark_Functions
 * 
 */
_command int next_bookmark,nb(_str direction='+') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (isEclipsePlugin()) {
      return _eclipse_next_bookmark(p_window_id);
   }
   
   
   int orig_buf_id=p_buf_id;
   int orig_col=p_col;
   typeless orig_BeginLineROffset='';
   parse point() with orig_BeginLineROffset .;
   struct BMINFO {
      long BeginLineROffset;
      int col;
      _str BookmarkName;

      long low_BeginLineROffset;
      int low_col;
      _str low_BookmarkName;
   };
   BMINFO hashtab:[];
   BMINFO found;
   found.BookmarkName="";

   typeless BookmarkName='';
   typeless markid='';
   int vsbmflags=0;
   int buf_id=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str filename='';
   _str DocumentName='';

   // See if there is a bookmark after/before this one in this buffer
   int i=0;
   for (i=0;i<_BookmarkQCount();++i) {
      _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                       buf_id,
                       0,RealLineNumber,col,BeginLineROffset,LineData,
                       filename,DocumentName);
      if (!(vsbmflags & VSBMFLAG_STANDARD)) {
         continue;
      }
      if (hashtab._indexin(buf_id)) {
         BMINFO bminfo;
         bminfo=hashtab:[buf_id];
         if (bminfo.BeginLineROffset<BeginLineROffset ||
             (bminfo.BeginLineROffset==BeginLineROffset && bminfo.col<col)
             ) {
            hashtab:[buf_id].BeginLineROffset=BeginLineROffset;
            hashtab:[buf_id].col=col;
            hashtab:[buf_id].BookmarkName=BookmarkName;
         }
         if (bminfo.low_BeginLineROffset>BeginLineROffset ||
             (bminfo.low_BeginLineROffset==BeginLineROffset && bminfo.low_col>col)
             ) {
            hashtab:[buf_id].low_BeginLineROffset=BeginLineROffset;
            hashtab:[buf_id].low_col=col;
            hashtab:[buf_id].low_BookmarkName=BookmarkName;
         }
      } else {
         hashtab:[buf_id].BeginLineROffset=BeginLineROffset;
         hashtab:[buf_id].col=col;
         hashtab:[buf_id].BookmarkName=BookmarkName;

         hashtab:[buf_id].low_BeginLineROffset=BeginLineROffset;
         hashtab:[buf_id].low_col=col;
         hashtab:[buf_id].low_BookmarkName=BookmarkName;

      }
      if (buf_id==orig_buf_id) {
         if (direction=='+') {
            if (BeginLineROffset>orig_BeginLineROffset ||
                (BeginLineROffset==orig_BeginLineROffset && col>orig_col)
                ) {
               if (found.BookmarkName=="" ||
                   (
                    BeginLineROffset<found.BeginLineROffset ||
                    (BeginLineROffset==found.BeginLineROffset && col<found.col)
                   )

                  ) {
                  found.BeginLineROffset=BeginLineROffset;
                  found.col=col;
                  found.BookmarkName=BookmarkName;
               }
               //messageNwait('found 'BookmarkName' 'BeginLineROffset' 'orig_BeginLineROffset);
            }
         } else {
            if (
                BeginLineROffset<orig_BeginLineROffset ||
                (BeginLineROffset==orig_BeginLineROffset && col<orig_col)

                ) {
               //messageNwait('col='col' 'orig_col);
               if (found.BookmarkName=="" ||
                   (
                    BeginLineROffset>found.BeginLineROffset ||
                    (BeginLineROffset==found.BeginLineROffset && col>found.col)
                   )

                  ) {
                  //message('another');
                  found.BeginLineROffset=BeginLineROffset;
                  found.col=col;
                  found.BookmarkName=BookmarkName;
               }
            }
         }
      }
   }
   BookmarkName=found.BookmarkName;
   if (BookmarkName=="") {
      BookmarkName="";
      if( !def_vcpp_bookmark ) {
         // Look in other buffers for the next/prev bookmark
         for (;;) {
            _next_buffer('rh');
            if (hashtab._indexin(p_buf_id)) {
               break;
            }
            if (p_buf_id==orig_buf_id) {
               break;
            }
         }
      }
      if (hashtab._indexin(p_buf_id)) {
         buf_id=p_buf_id;
         if (direction=='+') {
            BookmarkName=hashtab:[buf_id].low_BookmarkName;
         } else {
            BookmarkName=hashtab:[buf_id].BookmarkName;
         }
#if 0
         if (buf_id==orig_buf_id) {
         } else {
            if (direction=='+') {
               BookmarkName=hashtab:[buf_id].low_BookmarkName;
            } else {
               BookmarkName=hashtab:[buf_id].BookmarkName;
            }
         }
#endif
      }
      p_buf_id=orig_buf_id;
   }
   if (BookmarkName=="") {
      // No next/prev bookmark
      return STRING_NOT_FOUND_RC;
   }
   return goto_bookmark(BookmarkName);
}
/**
 * Goes to the previous bookmark set by one of the commands <b>set_bookmark</b>, 
 * <b>push_bookmark</b>, or <b>push_tag</b>.
 * 
 * @return Returns the bookmark ID on success. <0 on error. 
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Bookmark_Functions
 * 
 */ 
_command int prev_bookmark,pb() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (isEclipsePlugin()) {
      return _eclipse_prev_bookmark(p_window_id);
   }
   return next_bookmark('-');
}

/**
 * Return the bookmark name to use for the given event name.
 * It just peels off the last part of the key combination,
 * stripping away any Ctrl- or Alt- modifiers.  For example:
 * <ul>
 *    <li>A-9   returns '9'
 *    <li>C-S-A returns 'A'
 *    <li>F12   returns 'F12'
 *    <li>S-F12 returns 'F12'
 * </ul>
 * 
 * @see atl_bookmark
 * @see atl_gtbookmark
 */
static _str event_to_bookmark_name(_str event_name)
{
   id := id1 := id2 := "";
   parse event_name with id '-' id1 '-' id2;
   if (id2 != '') return id2;
   if (id1 != '') return id1;
   return id;
}

/**
 * Sets a bookmark identified by a letter or number corresponding 
 * to the key pressed which invoked this command.
 * <p>
 * This command should only be bound to the following groups of 
 * key combinations:
 * <ul>
 *    <li>Alt+<i>0-9</i>
 *    <li>Alt+<i>A-Z</i>
 *    <li>Alt+<i>F1-F12</i>
 *    <li>Ctrl+<i>0-9</i>
 *    <li>Ctrl+<i>A-Z</i>
 *    <li>Ctrl+<i>F1-F12</i>
 *    <li>Ctrl+Alt+<i>0-9</i>
 *    <li>Ctrl+Alt+<i>A-Z</i>
 *    <li>Ctrl+Alt+<i>F1-F12</i>
 *    <li>Shift+<i>F1-F12</i>
 * </ul>
 * 
 * @appliesTo Edit_Window
 * 
 * @see set_bookmark
 * @see toggle_bookmark
 * @see goto_bookmark
 * @see next_bookmark
 * @see prev_bookmark
 * @see alt_gtbookmark
 * @categories Bookmark_Functions
 */
_command void alt_bookmark() name_info(','VSARG2_LASTKEY|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   id := event_to_bookmark_name(event2name(last_event()));
   _macro('m',_macro());
   if (isEclipsePlugin()) {
      eclipse_addbookmark(id);
      return;
   }

   /*Macro Record Stuff is in set_bookmark*/
   status := set_bookmark('-r 'id);

   // find the correspond key binding for alt-gtbookmark
   // and display it on the message bar.
   gtkeys := where_is("alt_gtbookmark",true);
   parse gtkeys with 'is bound to' gtkeys . ;
   while (gtkeys!="") {
      msgkey := "";
      parse gtkeys with msgkey ',' gtkeys;
      msgkey = stranslate(msgkey, '-', '+');
      if (event_to_bookmark_name(msgkey) == id) {
         message("Press "msgkey" to return to this bookmark later.");
         break;
      }
   }
}
/**
 * Goes to bookmark identified by a letter or number corresponding 
 * to the key pressed which invoked this command.
 * <p>
 * This command should only be bound to the following groups of 
 * key combinations:
 * <ul>
 *    <li>Alt+<i>0-9</i>
 *    <li>Alt+<i>A-Z</i>
 *    <li>Alt+<i>F1-F12</i>
 *    <li>Ctrl+<i>0-9</i>
 *    <li>Ctrl+<i>A-Z</i>
 *    <li>Ctrl+<i>F1-F12</i>
 *    <li>Ctrl+Alt+<i>0-9</i>
 *    <li>Ctrl+Alt+<i>A-Z</i>
 *    <li>Ctrl+Alt+<i>F1-F12</i>
 *    <li>Shift+<i>F1-F12</i>
 * </ul>
 * 
 * @return Returns the bookmark ID on success. <0 on error. 
 * 
 * @appliesTo Edit_Window
 * 
 * @see set_bookmark
 * @see toggle_bookmark
 * @see goto_bookmark
 * @see next_bookmark
 * @see prev_bookmark
 * @see alt_bookmark
 * @categories Bookmark_Functions
 */
_command int alt_gtbookmark() name_info(','VSARG2_LASTKEY|VSARG2_EDITORCTL)
{
   _macro('m',_macro());
   id := event_to_bookmark_name(event2name(last_event()));
   return goto_bookmark(id);
   /*Macro Record Stuff is in goto_bookmark*/
}

_command void brief_goto_bookmark() name_info(','VSARG2_LASTKEY|VSARG2_EDITORCTL)
{
   _macro('m',_macro());
   message("Enter alt bookmark label (0-9):");
   key:=get_event('N');
   switch (key) {
   case '0':
      goto_bookmark(key);
      break;
   case '1':
      goto_bookmark(key);
      break;
   case '2':
      goto_bookmark(key);
      break;
   case '3':
      goto_bookmark(key);
      break;
   case '4':
      goto_bookmark(key);
      break;
   case '5':
      goto_bookmark(key);
      break;
   case '6':
      goto_bookmark(key);
      break;
   case '7':
      goto_bookmark(key);
      break;
   case '8':
      goto_bookmark(key);
      break;
   case '9':
      goto_bookmark(key);
      break;
   default:
      message("brief-goto-bookmark must be followed by a valid alt bookmark label."); 
      break;
   }
}
/****************************************************************************
   NOTES:
   1. If called from set_bookmark arg(3) = 1 to allow a selection not active
      in the menu. If called from goto_bookmark arg(3) = 0.
   2. The bookmark id, if present, is passed as arg(4). If it is present
      select one of the conditions below.
    a. If not alphanumeric and not '#', '##', '+' or '-' present the
       bookmark menu.
    b. If called from goto-bookmark:
       1. If the id is '+' or '-' return bm_data for next or prev bookmark
       2. If the id is active return the bm_data.
       3. If the id is not active present the bookmark menu.
          If no menu mode (-m), don't present menu.
    c. If called from set-bookmark:
       1. If the id is '#' or '##' set the next available bookmark.
       2. If the id is active present the bookmark menu with the id selected.
          If replace option (-r), replace without prompting.
          If no menu option (-m), don't replace and return non-zero RC.
       3. If the id is inactive return null bm_data.
   3. Delete inactive bookmark entries and free the associated marks.
   4. Check for a buffer name change while building menu buffer. If a
      change has occurred update the .bookmark buffer.
****************************************************************************/
static _str display_bookmarks(_str title,_str retrieve_name,int doSetBM,_str cmdline,boolean &dialogResultGoTo=0,_str defaultBookMarkName='')
{
   int goto_bm=0;
   int set_bm=0;
   dialogResultGoTo=false;
   if ( doSetBM == 0 ) {
      goto_bm = 1; set_bm = 0;
   } else {
      goto_bm = 0; set_bm = 1;
      gSetBMEnabled=_isEditorCtl();
   }
   _str cmd_option='';
   _str option='';
   _str bm_name='';
   parse cmdline with option bm_name .;
   if ( bm_name != '' ) {  /* a bookmark and command option are entered */
      /* expect the option to be first but, if it's not, swap them around */
      if ( pos('-r|-m', option, 1, 'RI')  == 1 ) {  /* option is first */
         cmd_option = upcase(option);
      } else if ( pos('-r|-m', bm_name, 1, 'RI') == 1 ) {  /* option second */
         cmd_option = upcase(bm_name);
         bm_name = option;
      }
   } else {
      bm_name = option;
   }
   boolean bm_err = !isbm_valid(bm_name, set_bm!=0);
   int view_id=0;
   get_window_id(view_id);    /* remember user's view */
   _str bm_data=''; 
   int max_buf_name_len = 0;
   _str val_bm1='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
   _str active_bm1='';
   _str active_bm2='';
   boolean cancel=false;
   typeless junk;
   int temp_view_id=0;
   int i=0, width=0;
   int status=0;

   typeless bm_id='', bm='';
   typeless mark_id='';
   int flags=0;
   int buf_id=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str Filename='';
   _str DocumentName='';
   _str buf_name='';
   int buf_name_len=0;
   typeless bm_loc=0;
   _str buf_text='';
   typeless tline='';
   typeless a='';
   int hi=0, lo=0;
   int b=0;
   int finished=0;
   int beep_error=0;
   typeless height=0;
   _str buttons='';
   int extra_flags=0;
   int Noflines=0;
   _str help_item='';
   typeless callback;
   int orig_wid=0;
   int wid=0;
   typeless result='';
   typeless selected_bm='';

   for (;;) {
      junk=_create_temp_view(temp_view_id);
      if (junk=='') {
         // Error message already display
         return ('');
      }
      width=76;

      int count=_BookmarkQCount();
      for (i=0;i<count;++i) {
         status=_BookmarkGetInfo(i,bm_id,mark_id,flags,buf_id,0,
                                 RealLineNumber,col,
                                 BeginLineROffset,
                                 LineData,
                                 Filename,
                                 DocumentName
                                );
         //messageNwait('L='RealLineNumber' O='BeginLineROffset);
         if (!(flags &VSBMFLAG_STANDARD)) {
            continue;
         }
         bm=bm_id;
         if (DocumentName!="") {
            Filename=DocumentName;
         }
         buf_name=_build_buf_name2(Filename,buf_id);
         buf_name_len=length(buf_name);
         if ( length(bm) == 1 ) {  /* make lists for auto-bookmark */
            active_bm1 = active_bm1:+bm;
         } else if (length(bm)==2) {
            active_bm2 = active_bm2:+bm;
         }
         if ( max_buf_name_len == 0 ) {
            max_buf_name_len = buf_name_len +1;
         }
         /*if ( buf_name_len != length(buf_name) ) {  /* buffer name len change? */
           //messageNwait('replacing 'buf_name' with ' cur_buf_name'..')
         tline=_right_justify(length(buf_name),4) " "bm_id " "mark_id " "bm_line;
         replace_line trunc_line(tline)
       }*/

         /* Find the bmark line number dynamically because editing can move it */
         bm_loc=RealLineNumber;
         if (RealLineNumber<0) {
            bm_loc='---';
         }
         bm_loc= _right_justify(bm_loc, 5);
         buf_text=' 'buf_name;
         if (length(buf_text)<max_buf_name_len) {
            buf_text=substr(buf_text,1,max_buf_name_len);
         }
         tline=field(bm_id, def_bm_max_id + 4):+
               //_right_justify(buf_name,max_buf_name_len):+
               buf_text:+' ':+
               bm_loc' 'LineData;
         //_lbadd_item(trunc_line(tline))
         _lbadd_item(tline);
         if ( strieq(bm_id,bm_name)) {  /* a match occured on selected bookmark */
            bm_data = bm_id' 'mark_id' .  'cmd_option;
            if ( cmd_option :== '-R' ) {
               break;  /* the mark set will automatically be replaced */
            }
         }
      }

      status = sort_buffer('I');
      clear_message();
      if ( set_bm && pos(bm_name, '##') ) { /* auto mark */
         a = verify(val_bm1, active_bm1);
         if ( bm_name :== '#' && a > 0 ) {  /* found an unused single digit bm */
            bm_name = substr(val_bm1, a, 1);
         } else {
            for (hi=1; hi<=10 ; ++hi ) {
               for (lo=1; lo<=10 ; ++lo ) {
                  bm = substr(val_bm1, hi, 1):+substr(val_bm1, lo, 1);
                  b = 1;
                  for (;;) {
                     a = pos(bm, active_bm2, b);
                     if ( a ) {
                        if ( a % 2 == 0 ) {  /* even address - not a real bookmark */
                           b = a + 1;
                           continue;
                        } else {
                           break;
                        }
                     } else {
                        bm_name = bm; lo = 10; hi = 10;
                        break;
                     }
                  }
               }
            }
         }
      }
      finished = 1;
      if ( set_bm && ! bm_err && bm_data:=='' ) {  /* bm not set yet */
         bm_data =bm_name;
      } else if ( set_bm && pos(cmd_option,'-M -R') ) {
         /* bm set and quiet/rep */

      } else if ( goto_bm && bm_data :!= '' ) {
         /* bm requested found */
         /* just return */

      } else if ( goto_bm && cmd_option :== '-M' ) {  /* no bm and quiet option */
         message(nls('bookmark %s not active.',bm_name));
         /* bypass menu and return */
      } else if ( title :== ''  ) {                   /* auto-save function running */
         /* just bypass menu and return */

      } else {
         /* present the bookmark menu */
         finished = 0;
         beep_error = 0;
         if ( _on_line0() ) {

         } else if ( bm_name :!= '' ) {
            /* pos to selected bm being replaced if set_bm */
            search('^ +:i +'_escape_re_chars(bm_name),'@ri');
            if ( rc ) {
               clear_message();
            }
         }
         beep_error=1;
         if ( set_bm && pos(bm_name, '##') ) {  /* auto bookmark being set */
            bm_name = ''; top();
            message(nls('All bookmarks are in use.'));
         } else if ( bm_name :!= '' ) {
            if ( bm_err ) {
               message(nls("Bookmark '%s' is not valid.",bm_name));
            } else if ( goto_bm ) {
               message(nls('Bookmark %s is not active',bm_name));
            } else if ( set_bm && cmd_option :!= '-R' ) {
               message(nls('Bookmark %s is already active',bm_name));
            } else {
               beep_error = 0;
            }
         }
         if (BEEP && beep_error ) {
            /* send bell char to std out */
            _beep();
         }
         height=p_Noflines;
         if ( height > 10 ) {
            height=10;
         }
         if ( height < 3 ) {
            height=3;
         }
         p_modify=0;
         height = '=':+height; /* leave cursor on active bm if set-bookmark */

         if (set_bm) {
            buttons="&Add,&Go To:ctlgoto,&Delete:ctldelete,&Replace:ctlreplace";
            extra_flags=SL_COMBO|SL_DEFAULTCALLBACK|SL_CLOSEBUTTON|SL_SELECTPREFIXMATCH;
         } else {
            buttons="&Go to Bookmark, &Delete:ctldelete";
            extra_flags=SL_SELECTCLINE|SL_CLOSEBUTTON;
         }
         Noflines=p_Noflines;
         activate_window(view_id);
         if (!set_bm && !Noflines) {
            bm_data = '';
            _message_box('No bookmarks set');
            _delete_temp_view(temp_view_id);
            break;
         }
         // Completion should be added for bookmarks
         if (retrieve_name=='set_bookmark') {
            help_item='Bookmarks dialog box';
            callback=_set_bookmark_callback;
         } else {
            help_item='Go to Bookmark dialog box';
            callback=_goto_bookmark_callback;
         }
         orig_wid=p_window_id;
         wid=show('_sellist_form -showmodal -hidden',
                  title,
                  extra_flags|SL_VIEWID,
                  temp_view_id,
                  buttons,
                  help_item,             // help item name
                  '',        // font
                  callback,  // Call back function
                  '',              // Item separator for list_data
                  retrieve_name,       // Retrieve form name
                  '',               // Combo box. Completion property value.
                  '',
                  defaultBookMarkName
                 );
         if (wid<0) {
            result='';
         } else {
            p_window_id=wid;
            if (set_bm) {
               parse bm_data with bm_id .;
               if (bm_id!='') {
                  _sellistcombo.p_text=bm_id;
                  _sellistcombo._set_sel(1,length(bm_id)+1);
                  _sellist.line_to_bottom();
                  ctlgoto.p_default=0;
                  _sellistok.p_default=1;
               }
            }
            p_visible=1;  /* Make the form visible. */
            result=_modal_wait(wid);
            p_window_id=orig_wid;
            parse result with result .;
            if (result!='') {
               dialogResultGoTo=_param1;
            }
         }
         selected_bm=result;
         cancel= result=='';
         //selected_bm = upcase(selected_bm)
         if ( cancel) {
            bm_data = '';
            // Don't need this message here.
            //message get_message(COMMAND_CANCELLED_RC)
            break;
         } else {
            i=_BookmarkFind(selected_bm);
            if ( i>=0) { /* found bookmark */
               _BookmarkGetInfo(i,selected_bm,mark_id);
               bm_data = selected_bm' 'mark_id' .';
               break;
            } else {
               bm_data = '';
            }
         }
      }
      if ( finished ) {
         _delete_temp_view(temp_view_id);
         break;
      }
      bm_data = '';
      bm_name = selected_bm;
      bm_err = !isbm_valid(bm_name, set_bm!=0);
   }
   // IMPORTANT: Only restore view if user has not selected to edit/cancel the form
   if (!cancel) {
      activate_window(view_id);      /* restore user's view */
   }
   return (bm_data);
}
void _document_renamed_bookmark(int buf_id,_str old_bufname,_str new_bufname,int buf_flags)
{
   _BookmarkRestore();
}
void _buffer_renamed_bookmark(int buf_id,_str old_bufname,_str new_bufname,int buf_flags)
{
   _BookmarkRestore();
}
void _buffer_add_bookmark()
{
   _BookmarkRestore();
   //messageNwait('got here p_buf_name='p_buf_name)
}

void relocateBookmarks ()
{
   // are there any bookmarks for this file?
   if (!getNumRelocMarkersForFile(p_buf_name)) {
      return;
   }
   typeless p;
   save_pos(p);

   BookmarkSaveInfo bmInfos[];
   int deletionList[];
   int rLine;
   int buf_id = 0;
   boolean resetTokens = true;

   int i;
   int existingBMs = _BookmarkQCount();
   double origTime = (double)_time('F');
   // Find bookmarks that need to be relocated.
   for (i = 0; i < existingBMs; ++i) {
      BookmarkSaveInfo bmInfo;
      _BookmarkGetInfo(i, bmInfo.BookmarkName, 0, bmInfo.vsbmflags, buf_id, 1,
                       bmInfo.RealLineNumber, bmInfo.col, 
                       bmInfo.BeginLineROffset, bmInfo.LineData,
                       bmInfo.Filename, bmInfo.DocumentName);
      if (def_cleanup_pushed_bookmarks_on_quit &&
          (bmInfo.vsbmflags & VSBMFLAG_PUSHED)) {
         continue;
      }

      RELOC_MARKER lm;
      if (file_eq(bmInfo.Filename, p_buf_name) && getRelocMarker(p_buf_name, bmInfo.BookmarkName, lm)) {
         rLine = _RelocateMarker(lm, resetTokens);
         resetTokens = false;
         if ((rLine != -1) && (rLine != bmInfo.RealLineNumber)) {
            bmInfo.RealLineNumber = rLine;
            bmInfos[bmInfos._length()] = bmInfo;
            deletionList[deletionList._length()] = i;
         }
      }

      double nowTime = (double)_time('F');
      if ((nowTime - origTime) > def_max_bookmark_relocate_time) {
         break;
      }
   }
   
   // Remove the old bookmarks that need to be relocated.
   i = (deletionList._length()-1);
   for (; i >= 0; --i) {
      _BookmarkRemove(deletionList[i]);
   }

   // Re-add the bookmarks that moved.
   for (i = 0; i < bmInfos._length(); ++i) {
      markid := _alloc_selection('B');
      p_RLine = bmInfos[i].RealLineNumber;
      p_col = bmInfos[i].col;
      _deselect(markid);
      _select_char(markid);
      _BookmarkAdd(bmInfos[i].BookmarkName, 
                   markid, bmInfos[i].vsbmflags,
                   bmInfos[i].RealLineNumber, bmInfos[i].col, 
                   bmInfos[i].BeginLineROffset, bmInfos[i].LineData,
                   bmInfos[i].Filename, bmInfos[i].DocumentName);
   }

   restore_pos(p);
   // Clear out all the relocatable code markers so we don't try to restore them
   // again.
   deleteRelocMarkersForFile(p_buf_name);
}


   
_str bookmark_match(_str name,int find_first)
{
   typeless BookmarkName='';
   typeless markid='';
   int vsbmflags=0;
   int bufid=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str Filename='';
   _str DocumentName='';

   // position from last time we were called
   static int last_i;
   if (find_first) {
      last_i=0;
   }

   // check each bookmark for a prefix match
   int i, n = _BookmarkQCount();
   for (i=last_i; i<n; ++i) {
      _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                       bufid,
                       0,RealLineNumber,col,BeginLineROffset,LineData,
                       Filename,DocumentName);
      if (vsbmflags & VSBMFLAG_STANDARD) {
         if (name=='' || pos(name,BookmarkName)==1) {
            last_i=i+1;
            return BookmarkName;
         }
      }
   }

   // not found
   return '';
}
/**
 * This function is used to toggle setting a bookmark on the current line.
 * 
 * @see push_bookmark
 * @see pop_bookmark
 * @see set_bookmark
 * @see goto_bookmark
 * 
 * @appliesTo Edit_Window
 * @categories Bookmark_Functions
 */ 
_command toggle_bookmark()
{
   typeless BookmarkName='';
   typeless markid='';
   int vsbmflags=0;
   int bufid=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str Filename='';
   _str DocumentName='';

   if (isEclipsePlugin()) {
      if(eclipse_bookmark_exists()){
         eclipse_addbookmark(get_bookmark_name());
      } else {
         eclipse_removebookmark();
      }
      return(0);
   }
   _str bookmarkName = get_bookmark_name();
   int i, n = _BookmarkQCount();
   for (i=0; i<n; ++i) {
      _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                       bufid,
                       0,RealLineNumber,col,BeginLineROffset,LineData,
                       Filename,DocumentName);
      if (vsbmflags & VSBMFLAG_STANDARD && BookmarkName == bookmarkName) {
         delete_bookmark(BookmarkName);
         return(0);
      }
   }
   // if they have a named bookmark on this line, try deleting it
   if (delete_bookmark() == 0) {
      return(0);
   }
   // If the name is not unique, make it more unique
   if (_BookmarkFind(bookmarkName) >= 0) {
      bookmarkName=bookmarkName"<"p_buf_name">";
   }
   // If we got here, then we didn't find the bookmark, so set it
   set_bookmark(bookmarkName);
}
/**
 * Clears all the named bookmarks
 * 
 * @see toggle_bookmark
 * @see set_bookmark
 *
 * @appliesTo Edit_Window
 * @categories Bookmark_Functions
 */
_command clear_bookmarks(_str quiet="") name_info(',')
{
   if (quiet == "") {
      int result=_message_box('Are you sure you want to delete all bookmarks?','',MB_YESNO);
      if (result!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   
   typeless BookmarkName='';
   typeless markid='';
   int vsbmflags=0;
   int bufid=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str Filename='';
   _str DocumentName='';

   int i;
   for (i=_BookmarkQCount()-1; i>=0; --i) {
      _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                       bufid,
                       0,RealLineNumber,col,BeginLineROffset,LineData,
                       Filename,DocumentName);
      if (vsbmflags & VSBMFLAG_STANDARD) {
         _BookmarkRemove(i);
      }
   }
   updateBookmarksToolWindow(0);
}
int _OnUpdate_clear_bookmarks(CMDUI &cmdui,int target_wid,_str command)
{
   /**
    * In the plug-in just return enable here...we don't need to 
    * check _BookmarkGetInfo. 
    */
   if (isEclipsePlugin()) {
      return (MF_ENABLED);
   }
   typeless BookmarkName='';
   typeless markid='';
   int vsbmflags=0;
   int bufid=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str Filename='';
   _str DocumentName='';

   int i, n = _BookmarkQCount();
   for (i=0; i<n; ++i) {
      _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                       bufid,
                       0,RealLineNumber,col,BeginLineROffset,LineData,
                       Filename,DocumentName);
      if (vsbmflags & VSBMFLAG_STANDARD) {
         return (MF_ENABLED);
      }
   }
   return MF_GRAYED;
}
int _OnUpdate_next_bookmark(CMDUI &cmdui,int target_wid,_str command)
{
   if (_no_child_windows()) return MF_GRAYED;
   return _OnUpdate_clear_bookmarks(cmdui,target_wid,command);
}
int _OnUpdate_goto_bookmark(CMDUI &cmdui,int target_wid,_str command)
{
   //if (_no_child_windows()) return MF_GRAYED;
   return _OnUpdate_clear_bookmarks(cmdui,target_wid,command);
}
int _OnUpdate_goto_bookmark_in_tree(CMDUI &cmdui,int target_wid,_str command)
{
   //if (_no_child_windows()) return MF_GRAYED;
   return _OnUpdate_clear_bookmarks(cmdui,target_wid,command);
}
int _OnUpdate_delete_bookmark_from_tree(CMDUI &cmdui,int target_wid,_str command)
{
   //if (_no_child_windows()) return MF_GRAYED;
   return _OnUpdate_clear_bookmarks(cmdui,target_wid,command);
}
int _OnUpdate_prev_bookmark(CMDUI &cmdui,int target_wid,_str command)
{
   if (_no_child_windows()) return MF_GRAYED;
   return _OnUpdate_clear_bookmarks(cmdui,target_wid,command);
}
int _OnUpdate_toggle_bookmark(CMDUI &cmdui,int target_wid,_str command)
{
   return (_no_child_windows())? MF_GRAYED : MF_ENABLED;
}
int _OnUpdate_set_bookmark(CMDUI &cmdui,int target_wid,_str command)
{
   return (_no_child_windows())? MF_GRAYED : MF_ENABLED;
}

#define EMPTY_BOOKMARK_LINE '<**EMPTY_BOOKMARK_LINE**>'

/**
 * Saves and restores bookmarks. If def_use_workspace_bm is set, bookmarks are
 * saved in workspaces' *.vpwhistu files. If it is not, bookmarks are saved in
 * vrestore.slk.
 * 
 * @param option
 * @param info
 * 
 * @return _str
 */
_str _sr_bookmark2(_str option='',_str info='')
{
   typeless vsbmflags=0;
   typeless Nofbookmarks=0;
   int i=0;
   _str line='';

   typeless BookmarkName='';
   typeless markid='';
   typeless bufid=0;
   typeless RealLineNumber=0;
   typeless col=0;
   typeless BeginLineROffset=0;
   typeless LineData='';
   typeless Filename='';
   typeless DocumentName='';

   if ((!def_use_workspace_bm) && //If we're using global bookmarks ...
       (p_buf_name :== "")) { //if p_buf_name is not set, it's not vrestore.slk
      return (0);
   }

   if ( option=='R' || option=='N' ) {
      clear_bookmarks("quiet");
      parse info with Nofbookmarks .;
      // BOOKMARK2 remains for backwards compatiblity, search forward for
      // BOOKMARK3.
      int orig_line = p_line;
      for (i=1; i<=Nofbookmarks ; ++i) {
         down();
      }
      down();
      get_line(line);
      // If BOOKMARK3 isn't present, rewind and use BOOKMARK2.
      if (pos('BOOKMARK3', line) == 0) {
         p_line = orig_line;
         read_BOOKMARK2(Nofbookmarks);
      } else { // If it is present, parse out the number of bookmarks and go.
         parse line with . 'BOOKMARK3: ' Nofbookmarks;
         if ((Nofbookmarks != '') && (isinteger(Nofbookmarks))) {
            read_BOOKMARK3((int)Nofbookmarks);
         }
      }
      updateBookmarksToolWindow(0);
   } else {
      insert_line("");
      int orig_line=p_line;
      Nofbookmarks=0;
      for (i=0;i<_BookmarkQCount();++i) {
         _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                          bufid,
                          0,RealLineNumber,col,BeginLineROffset,LineData,
                          Filename,DocumentName);
         if (!(vsbmflags & VSBMFLAG_STANDARD)) {
            continue;
         }
         ++Nofbookmarks;
         LineData=stranslate(LineData,"",\1);
         LineData=stranslate(LineData,"","\n");
         insert_line(BookmarkName \1 vsbmflags \1 RealLineNumber \1 col \1 BeginLineROffset \1 LineData \1 Filename \1 DocumentName);
      }
      int orig_line2=p_line;
      p_line=orig_line;
      replace_line("BOOKMARK2: "Nofbookmarks);
      p_line=orig_line2;

      // BOOKMARKS3 is for bookmarks with relocatable markers
      insert_line("");
      orig_line=p_line;
      Nofbookmarks=0;
      for (i=0;i<_BookmarkQCount();++i) {
         _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                          bufid,
                          0,RealLineNumber,col,BeginLineROffset,LineData,
                          Filename,DocumentName);
         if (!(vsbmflags & VSBMFLAG_STANDARD)) {
            continue;
         }

         // If the buffer was never closed, we'll need to build relocatable
         // markers now.
         if (!getNumRelocMarkersForFile(Filename)) {
            build_bmRELOC_MARKERs(Filename);
         }

         // see if there was one with this bookmark name
         RELOC_MARKER lm;
         if (!getRelocMarker(Filename, BookmarkName, lm)) {
            continue;
         }
         LineData=stranslate(LineData,"",\1);
         LineData=stranslate(LineData,"","\n");
         insert_line(BookmarkName \1 vsbmflags \1 RealLineNumber \1 col \1 BeginLineROffset \1 LineData \1 Filename \1 DocumentName \1 lm.aboveCount \1 lm.belowCount);
         int j;
         int k;
         _str RMLine;
         for (j = 0; j < lm.aboveCount; ++j) {
            RMLine = '';
            for (k = 0; k < lm.textAbove[j]._length(); ++k) {
               RMLine = RMLine' 'lm.textAbove[j][k];
            }
            RMLine = strip(RMLine);
            if (RMLine == '') RMLine = EMPTY_BOOKMARK_LINE;
            insert_line(RMLine);
         }
         for (j = 0; j < lm.belowCount; ++j) {
            RMLine = '';
            for (k = 0; k < lm.textBelow[j]._length(); ++k) {
               RMLine = RMLine' 'lm.textBelow[j][k];
            }
            RMLine = strip(RMLine);
            if (RMLine == '') RMLine = EMPTY_BOOKMARK_LINE;
            insert_line(RMLine);
         }
         ++Nofbookmarks;
      }
      orig_line2=p_line;
      p_line=orig_line;
      replace_line("BOOKMARK3: "Nofbookmarks);
      p_line=orig_line2;
   }
   return (0);

}

void read_BOOKMARK2 (int Nofbookmarks)
{
   typeless vsbmflags=0;
   int i;
   _str line='';

   typeless BookmarkName='';
   typeless markid='';
   typeless RealLineNumber=0;
   typeless col=0;
   typeless BeginLineROffset=0;
   typeless LineData='';
   typeless Filename='';
   typeless DocumentName='';

   for (i=1; i<=Nofbookmarks ; ++i) {
      down();
      get_line(line);
      parse line with BookmarkName \1 vsbmflags \1 RealLineNumber \1 col \1 BeginLineROffset \1 LineData \1 Filename \1 DocumentName;
      if (def_bm_show_picture) {
         vsbmflags |= (VSBMFLAG_SHOWNAME|VSBMFLAG_SHOWPIC);
      } else {
         vsbmflags &= ~(VSBMFLAG_SHOWNAME|VSBMFLAG_SHOWPIC);
      }

      markid=_alloc_selection('B');
      int temp_view_id;
      int orig_view_id;
      int status = _open_temp_view(Filename,temp_view_id,orig_view_id,'+b');
      if (status) {
         _BookmarkAdd(BookmarkName,markid,vsbmflags,RealLineNumber,col,
                      BeginLineROffset,LineData,Filename,DocumentName);
      } else {
         _str on,value;
         parse def_max_loadall with on value;
         if (RealLineNumber>=0 && !(on && isinteger(value) && BeginLineROffset>value)) {
            p_RLine=RealLineNumber;
         } else {
            _GoToROffset(BeginLineROffset);
         }
         p_col=col;
         _select_char(markid);
         _BookmarkAdd(BookmarkName,markid,vsbmflags);
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
      }
   }
}

void read_BOOKMARK3 (int Nofbookmarks)
{
   typeless vsbmflags=0;
   int i;
   _str line='';

   typeless BookmarkName='';
   typeless markid='';
   typeless RealLineNumber=0;
   typeless col=0;
   typeless BeginLineROffset=0;
   typeless LineData='';
   typeless Filename='';
   typeless DocumentName='';

   for (i=1; i<=Nofbookmarks ; ++i) {
      down();
      get_line(line);
      _str aboveCount = '';
      _str belowCount = '';
      parse line with BookmarkName \1 vsbmflags \1 RealLineNumber \1 col \1 BeginLineROffset \1 LineData \1 Filename \1 DocumentName \1 aboveCount \1 belowCount;
      if (vsbmflags == '') {
         break;
      }
      if (def_bm_show_picture) {
         vsbmflags |= (VSBMFLAG_SHOWNAME|VSBMFLAG_SHOWPIC);
      } else {
         vsbmflags &= ~(VSBMFLAG_SHOWNAME|VSBMFLAG_SHOWPIC);
      }
      if (aboveCount == '') {
         aboveCount = 0;
      }
      if (belowCount == '') {
         belowCount = 0;
      }
      // Starting in v14, if relocatable marker information was saved,
      // read it and relocate the marker.

      if ((aboveCount > 0) || (belowCount > 0)) {
         // Build the relocatable marker
         RELOC_MARKER lm;
         tokenizeLine(LineData, lm.origText);
         lm.aboveCount = (int)aboveCount;
         lm.belowCount = (int)belowCount;
         int j;
         for (j = 0; j < lm.aboveCount; ++j) {
            down();
            _str lineAbove = '';
            get_line(lineAbove);
            if (lineAbove == EMPTY_BOOKMARK_LINE) {
               lineAbove = '';
            } 
            tokenizeLine(lineAbove, lm.textAbove[j]);
         }
         for (j = 0; j < lm.belowCount; ++j) {
            down();        
            _str lineBelow = '';
            get_line(lineBelow);
            if (lineBelow == EMPTY_BOOKMARK_LINE) {
               lineBelow = '';
            }
            tokenizeLine(lineBelow, lm.textBelow[j]);
         }
         lm.origLineNumber = RealLineNumber;
         lm.totalCount = lm.aboveCount + lm.belowCount;
         lm.n = RELOC_MARKER_WINDOW_SIZE;
         lm.sourceFile = Filename;
         addRelocMarker(Filename, BookmarkName, lm);
      }

      int status = -1;
      int temp_view_id;
      int orig_view_id;
      markid=_alloc_selection('B');
      status = _open_temp_view(Filename,temp_view_id,orig_view_id,'+b');
      if (status) {
         _BookmarkAdd(BookmarkName,markid,vsbmflags,RealLineNumber,col,
                      BeginLineROffset,LineData,Filename,DocumentName);
      } else {

         // relocate the bookmark now in the case of the current file
         if (Filename == p_buf_name && (aboveCount > 0 || belowCount > 0)) {
            if (def_cleanup_pushed_bookmarks_on_quit && (vsbmflags & VSBMFLAG_PUSHED)) break;
            
            RELOC_MARKER lm;
            if (getRelocMarker(p_buf_name, BookmarkName, lm)) {
               rLine := _RelocateMarker(lm,true);
            if ((rLine != -1) && (rLine != RealLineNumber)) {
               RealLineNumber = rLine;
               }
            }
         }

         _str on,value;
         parse def_max_loadall with on value;
         if (RealLineNumber>=0 && !(on && isinteger(value) && BeginLineROffset>value)) {
            p_RLine=RealLineNumber;
         } else {
            _GoToROffset(BeginLineROffset);
         }
         p_col=col;
         _select_char(markid);
         _BookmarkAdd(BookmarkName,markid,vsbmflags);
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
      }
   }
}

/*static _str trunc_line(line)
{
   if ( length(line)>MAX_LINE ) {
      line=substr(line,1,MAX_LINE);
   }
   return (line);
} */
static boolean isbm_valid(_str bm,boolean set_bm)
{
   boolean status=0;
   if ( set_bm && pos(bm, '##') ) {
      status=1;
   } else if ( length(bm) == 1 && isalnum(bm) ) {
      status=1;
   } else if ( strip(bm) :!= '' ) {
      /* allow all alphanumerics and some special chars.*/
      if (bm=='+' || bm=='-') {
         return (0);
      }
      //if ( pos('[~A-Za-z0-9_$\-+=@!<>]',bm,1,'r') ) {
      if ( pos('[ \t\0-\32]',bm,1,'r') ) {
         return (status);
      }
      status=1;
   }
   return (status);
}

/**
 * Deletes the currently selected bookmark from the Bookmarks
 * tool window. 
 * 
 * @categories Bookmark_Functions
 */
_command void delete_bookmark_from_tree() name_info(',')
{
   // Is the form visible? 
   int form_wid = _BookmarksFormWid();
   if (!form_wid) {
      return;
   }
   _nocheck _control ctl_bookmarks_tree;
   // Is the tree there?
   if (!form_wid.ctl_bookmarks_tree) {
      return;
   }
   // Call the DEL event
   form_wid.ctl_bookmarks_tree.call_event(form_wid.ctl_bookmarks_tree,DEL);
}

/**
 * Navigate to the currently selected bookmark from the
 * Bookmarks tool window. 
 * 
 * @categories Bookmark_Functions
 */
_command void goto_bookmark_in_tree() name_info(',')
{
   // Is the form visible? 
   int form_wid = _BookmarksFormWid();
   if (!form_wid) {
      return;
   }
   _nocheck _control ctl_bookmarks_tree;
   // Is the tree there?
   if (!form_wid.ctl_bookmarks_tree) {
      return;
   }
   // Call the ENTER event
   form_wid.ctl_bookmarks_tree.call_event(form_wid.ctl_bookmarks_tree,LBUTTON_DOUBLE_CLICK);
}

/**
 * Deletes the bookmark specified.
 * 
 * @param bm_id     is an identifier returned by one of the functions
 *                  <b>push_bookmark</b> or <b>set_bookmark</b>.
 *                  If <i>bm_id</i> is not found, this function does nothing.
 * @param vsbmflags
 * 
 * @return 
 * @categories Bookmark_Functions
 */
_command int delete_bookmark(_str bm_id='', int vsbmflags=VSBMFLAG_STANDARD) name_info(BOOKMARK_ARG','VSARG2_READ_ONLY)
{
   typeless BookmarkName='';
   typeless markid='';
   int bufid=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str Filename='';
   _str DocumentName='';

   int i=0;
   if (bm_id=='' && _isEditorCtl()) {
      for (i=0;i<_BookmarkQCount();++i) {
         _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                          bufid,
                          0,RealLineNumber,col,BeginLineROffset,LineData,
                          Filename,DocumentName);
         if (vsbmflags & VSBMFLAG_STANDARD && 
             Filename == p_buf_name && RealLineNumber == p_RLine) {
            _BookmarkRemove(i);
            updateBookmarksToolWindow(0);
            return (0);
         }
      }
      return(1);
   }

   i=_BookmarkFind(bm_id,vsbmflags);
   if ( i>=0) { /* found bookmark */
      _BookmarkRemove(i);
      updateBookmarksToolWindow(0);
      return (0);
   }
   return (1);
}

int _OnUpdate_delete_bookmark(CMDUI &cmdui,int target_wid,_str command)
{
   typeless BookmarkName='';
   typeless markid='';
   int vsbmflags=0;
   int bufid=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str Filename='';
   _str DocumentName='';

   if (_no_child_windows()) return MF_GRAYED;
   int i, n = _BookmarkQCount();
   for (i=0; i<n; ++i) {
      _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                       bufid,
                       0,RealLineNumber,col,BeginLineROffset,LineData,
                       Filename,DocumentName);
      if (vsbmflags & VSBMFLAG_STANDARD && 
          Filename == p_buf_name && RealLineNumber == p_RLine) {
         return (MF_ENABLED);
      }
   }
   return MF_GRAYED;
}


///////////////////////////////////////////////////////////////////////////
// Handlers for debugger breakpoints tool window
//

void updateBookmarksToolWindow(int form_wid=0)
{
   if (!form_wid) {
      form_wid = _BookmarksFormWid();
      if (!form_wid) {
         return;
      }
   }

   typeless BookmarkName='';
   typeless markid='';
   int vsbmflags=0;
   int bufid=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str Filename='';
   _str DocumentName='';

   int orig_wid = p_window_id;
   p_window_id = form_wid;

   boolean got_one=false;
   ctl_bookmarks_tree._TreeBeginUpdate(TREE_ROOT_INDEX);
   int i, n = _BookmarkQCount();
   for (i=0; i<n; ++i) {
      _BookmarkGetInfo(i,BookmarkName,markid,vsbmflags,
                       bufid,
                       0,RealLineNumber,col,BeginLineROffset,LineData,
                       Filename,DocumentName);
      if (vsbmflags & VSBMFLAG_STANDARD) {
         LineData = strip(stranslate(LineData, ' ', "[\t ]+", 'U'));
         _str caption = BookmarkName"\t"Filename"\t"RealLineNumber"\t"LineData;
         ctl_bookmarks_tree._TreeAddItem(TREE_ROOT_INDEX, caption,
                                         TREE_ADD_AS_CHILD, 0, 0, -1, 
                                         0, BookmarkName);
         got_one=true;
      }
   }
   ctl_bookmarks_tree._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_bookmarks_tree._TreeRefresh();
   int currentItem = ctl_bookmarks_tree._TreeCurIndex();
   ctl_bookmarks_tree._TreeTop();
   if (currentItem > 0) {
      ctl_bookmarks_tree._TreeSetCurIndex(currentItem);
   }

   ctl_add_btn.p_enabled = !_no_child_windows();
   ctl_clear_btn.p_enabled = got_one;
   ctl_del_btn.p_enabled = got_one;
   ctl_next_btn.p_enabled = got_one;
   ctl_prev_btn.p_enabled = got_one;
   p_window_id = orig_wid;

}

#define BOOKMARKS_TOOL_FORM "_tbbookmarks_form"
defeventtab _tbbookmarks_form;
void ctl_bookmarks_tree.on_create()
{
   ctl_bookmarks_tree._TreeSetColButtonInfo(0,1000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT,0,"Name");
   ctl_bookmarks_tree._TreeSetColButtonInfo(1,1000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_IS_FILENAME,0,"File");
   ctl_bookmarks_tree._TreeSetColButtonInfo(2,500, TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT|TREE_BUTTON_SORT_NUMBERS,0,"Line");
   ctl_bookmarks_tree._TreeSetColButtonInfo(3,1000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT|TREE_BUTTON_AUTOSIZE,0,"Text");
   ctl_bookmarks_tree._TreeRetrieveColButtonInfo();

   updateBookmarksToolWindow(p_active_form);
   ctl_bookmarks_tree._TreeTop();
}
void _tbbookmarks_form.on_destroy()
{
   ctl_bookmarks_tree._TreeAppendColButtonInfo();
   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id,ON_DESTROY,'2');
}
void ctl_bookmarks_tree.on_destroy()
{
}
void _tbbookmarks_form.on_resize()
{
   // adjust resizable icons
   ctl_bookmarks_tree.p_x = ctl_add_btn.p_x*2 + ctl_add_btn.p_width;
   ctl_clear_btn.p_y = ctl_add_btn.p_y + ctl_add_btn.p_height;
   ctl_del_btn.p_y = ctl_clear_btn.p_y + ctl_clear_btn.p_height;
   ctl_prev_btn.p_y  = ctl_del_btn.p_y + ctl_del_btn.p_height;
   ctl_next_btn.p_y  = ctl_prev_btn.p_y + ctl_prev_btn.p_height;

   int containerW = _dx2lx(SM_TWIP,p_active_form.p_client_width);
   int containerH = _dy2ly(SM_TWIP,p_active_form.p_client_height);

   // get gaps _before_ we resize any tab control
   int border_width   = ctl_bookmarks_tree.p_x;
   int border_height  = ctl_bookmarks_tree.p_y;
   if (border_width > border_height) {
      border_width=border_height;
   }

   // resize the tree height
   ctl_bookmarks_tree.p_width  = containerW  - ctl_bookmarks_tree.p_x - border_width;
   ctl_bookmarks_tree.p_height = containerH - ctl_bookmarks_tree.p_y - border_height;
}

/**
 * @return
 *    Return the window ID of the window containing the bookmarks toolbar.
 */
CTL_FORM _BookmarksFormWid()
{
   static CTL_FORM form_wid;
   if (_iswindow_valid(form_wid) && !form_wid.p_edit &&
       form_wid.p_object==OI_FORM && form_wid.p_name==BOOKMARKS_TOOL_FORM) {
      return(form_wid);
   }
   form_wid=_find_formobj(BOOKMARKS_TOOL_FORM,'N');
   return(form_wid);
}

int ctl_bookmarks_tree.on_change(int reason, int index)
{
   if (reason==CHANGE_SELECTED) {
      if (index>0 && _get_focus()==ctl_bookmarks_tree) {
         // show preview for this bookmark
         _str bm_name = _TreeGetUserInfo(index);
         int bm_index = _BookmarkFind(bm_name);
         if (bm_index < 0) {
            return bm_index;
         }
         VS_TAG_BROWSE_INFO cm;
         tag_browse_info_init(cm);
         _BookmarkGetInfo(bm_index,cm.member_name,0,0,0,
                          0,cm.line_no,cm.column_no,cm.seekpos,"",cm.file_name);
         cb_refresh_output_tab(cm, true, true, false, APF_BOOKMARKS);
      }
   } else if ( reason == CHANGE_LEAF_ENTER ) {
      call_event(p_window_id,LBUTTON_DOUBLE_CLICK);
   }
   return 0;
}
void ctl_bookmarks_tree.on_got_focus()
{
   call_event(CHANGE_SELECTED, _TreeCurIndex(), ctl_bookmarks_tree, ON_CHANGE, 'W');
}

void ctl_bookmarks_tree.DEL()
{
   int tree_index = _TreeCurIndex();
   if (tree_index > 0) {
      _str bm_name = _TreeGetUserInfo(tree_index);
      int bm_index = _BookmarkFind(bm_name);
      if (bm_index < 0) return;
      _BookmarkRemove(bm_index);
      _TreeDelete(tree_index);
   }
}

void ctl_bookmarks_tree.'S-DEL'()
{
   if ( ctl_clear_btn.p_enabled ) clear_bookmarks();
}

void ctl_bookmarks_tree.INS()
{
   if (!_no_child_windows()) {
      _mdi.p_child.set_bookmark("-n");
   }
}

/**
 * Display the right-click menu for the bookmarks
 */
void ctl_bookmarks_tree.rbutton_up()
{
   // get the menu form
   int index=find_index("_bookmarks_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   CTL_TREE tree_wid=p_window_id;

   // Show the menu.
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}
/**
 * Edit the current breakpoint
 */
int ctl_bookmarks_tree.lbutton_double_click()
{
   typeless BookmarkName='';
   typeless markid='';
   int vsbmflags=0;
   int bufid=0;
   int RealLineNumber=0;
   int col=0;
   long BeginLineROffset=0;
   _str LineData='';
   _str Filename='';
   _str DocumentName='';

   int index=_TreeCurIndex();
   if (index>0) {
      _str bm_name = _TreeGetUserInfo(index);
      int bm_index = _BookmarkFind(bm_name);
      if (bm_index < 0) {
         return bm_index;
      }
      _BookmarkGetInfo(bm_index,BookmarkName,
                       markid,vsbmflags,bufid,
                       0,RealLineNumber,col,BeginLineROffset,LineData,
                       Filename,DocumentName);
      if (_no_child_windows()) {
         edit(maybe_quote_filename(Filename));
         if (_no_child_windows()) {
            return 0;
         }
      }

      bm_index = _mdi.p_child.goto_bookmark(BookmarkName);
      if ( bm_index >= 0 ) {
         _tbDismiss(p_active_form);
      } else {
         activate_bookmarks();
      }
   }
   return(0);
}

void _switchbuf_bookmarks()
{
   relocateBookmarks();

   updateBookmarksToolWindow();
}

/**
 * Gets called when a buffer is closed. 
 * This function is used to generate relocatable code markers 
 * for bookmarks when their file is closed by a user. 
 *
 * @param buffid  p_buf_id of the buffer that was closed
 * @param name    p_buf_name of the buffer that was closed
 * @param docname p_DocumentName of the buffer that was closed
 * @param flags   assumed to be 0
 */
void _cbquit_bookmarks3(int buffid, _str name, _str docname='', int flags=0)
{
   build_bmRELOC_MARKERs(name);
}

static void build_bmRELOC_MARKERs (_str name)
{
   deleteRelocMarkersForFile(name);

   int temp_view_id;
   int orig_view_id;
   int status;
   status = _open_temp_view(name, temp_view_id, orig_view_id);
   if (!status) {
      int i;
      // bookmark attributes
      BookmarkSaveInfo bmInfo;
      int bm_bufid = 0;
      // Check each bookmark to see if it's in the buffer being quit.
      for (i = 0; i <_BookmarkQCount(); ++i) {
         _BookmarkGetInfo(i, bmInfo.BookmarkName, 0, bmInfo.vsbmflags, bm_bufid,
                          1, bmInfo.RealLineNumber, bmInfo.col,
                          bmInfo.BeginLineROffset, bmInfo.LineData, 
                          bmInfo.Filename, bmInfo.DocumentName);
         // Do not save relocatable markers for pushed bookmarks if they're to
         // be cleaned up.
         if (def_cleanup_pushed_bookmarks_on_quit &&
             (bmInfo.vsbmflags & VSBMFLAG_PUSHED)) {
            continue;
         }

         if ((bm_bufid != p_buf_id) || !file_eq(bmInfo.Filename, p_buf_name)) {
            continue;
         }

         RELOC_MARKER lm;
         p_RLine = bmInfo.RealLineNumber;
         _BuildRelocatableMarker(lm);
         addRelocMarker(name, bmInfo.BookmarkName, lm);
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
}
