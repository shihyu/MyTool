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
#pragma option(pedantic, on)
#region Imports
#include "slick.sh"
#require "se/util/Observer.e"
#require "se/util/Subject.e"
#require "se/lineinfo/LineInfo.e"
#require "se/lineinfo/TypeInfo.e"
#endregion

namespace se.lineinfo;


class LineInfoCollection : se.util.Subject {
   protected _str m_files:[];
   //protected LineInfo m_lineInfos[];
   //protected TypeInfo m_typeInfos[];
   protected int m_indices:[][];
   
   LineInfoCollection () {
      Subject();
   }
   ~LineInfoCollection () {}

   // For LineInfoFiles.
   void getFiles () {}
   void setFile (_str inFile="") {}
   // For LineInfoDefinitions.
   void getDefinitions () {}
   void setDefinition (LineInfo inLineInfo) {}
   // For LineInfoBrowser and LineInfoFiles.
   void getLineInfos () {}
   // For LineInfoBrowser.
   void setLineInfo () {}
};


namespace default;


static se.lineinfo.LineInfoCollection lineInfoCollections[];



/**
 * Handles safe_exit() callback.
 */
void _exit_LineInfo ()
{
}
/**
 * Timer callback for updating (LineInfo) browsers to possibly 
 * select the (LineInfo) on the active buffer's current line. 
 */
void _UpdateLineInfo ()
{
}
/**
 * Called when a workspace is opened.
 */
void _workspace_opened_LineInfo ()
{
}
/**
 * Called when a workspace is closed.
 */
void _wkspace_close_LineInfo ()
{
}
/**
 * Called when a project is opened. 
 */
void _prjopen_LineInfo ()
{
}
/**
 * Called when a project is closed. 
 */
void _prjclose_LineInfo ()
{
}
/**
 * Callback function to support dragging around a LineInfo's 
 * gutter glyph. Registered in _srg_LineInfo(). 
 *  
 * Limitation: It is possible to have multiple LineInfos on the 
 * same line. Only one line marker is dragged at a time. Only 
 * the first line marker listed will be passed to 
 * mouseClickLineInfo(). (The first line marker listed has its 
 * message at the top of the hover over preview, so users will 
 * know which annotation will be moved). 
 *  
 * @param MarkerIndex  The index to the line marker to be moved
 * 
 * @return int
 */
static int mouseClickLineInfo (int MarkerIndex)
{
   return(0);
}
/** 
 * Call _MarkerTypeSetCallbackMouseEvent to make sure it knows about the new 
 * address of mouseClickLineInfo.
 * 
 * @param module
 */
void _on_load_module_LineInfo (_str module)
{
}
/**
 * Restore on a global (non per-project) basis.
 */
int _srg_LineInfo (_str option='', _str info='')
{
   return(0);
}
/**
 * Disable 'New (Line Info)' button on (Line Info) Browser 
 * dialog if there are no buffers open. 
 */
void _cbquit_LineInfo (int buffid, _str name, _str docname= '', int flags = 0)
{
}
/**
 * Disable 'New (LineInfo)' button on (LineInfo) Browser dialog
 * if there are no buffers open.
 */
void _switchbuf_LineInfo (_str oldbuffname, _str flag)
{
}
void _document_renamed_LineInfo (int buf_id, _str old_bufname,
                                 _str new_bufname, int buf_flags)
{
}
void _buffer_renamed_LineInfo (int buf_id, _str old_bufname,
                               _str new_bufname, int buf_flags)
{
}
void _buffer_renamedAfter_LineInfo (int buf_id, _str old_bufname,
                                    _str new_bufname, int buf_flags)
{
}
void _buffer_add_LineInfo_markers (int newBuffID, _str name, int flags = 0)
{
}
//int _OnUpdate_??? (CMDUI &cmdui,int target_wid,_str command)
//{
//   return MF_ENABLED;
//}
