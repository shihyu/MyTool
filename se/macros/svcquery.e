///////////////////////////////////////////////////////////////////////////////////
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
#include "svc.sh"
#import "diff.e"
#import "help.e"
#import "main.e"
#import "svc.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "svcautodetect.e"
#import "taggui.e"
#endregion

using se.vc.IVersionControl;

defeventtab _svc_query_form;
void ctllist_symbols.lbutton_up()
{
   filename := _GetDialogInfoHt("filename");
   status := GetSymbolInfo(filename,
                           auto symbolName="",
                           auto last_start_line_number=0,
                           auto lastLine=0,
                           auto commentLine=0,
                           auto tagType="");
   if ( !status ) {
      ctlsymbol_name.p_text = symbolName;
   }
}

bool gPause = false;

struct SVC_QUERY_INFO {
   IVersionControl *pInterface;
   _str filename;
   _str symbolName;
   INTARRAY WIDs;
   STRARRAY tempFileList;
   SVCHistoryInfo historyInfo[];
   int curIndex;
   int outputFormWID;
   int startLineNumber;
   int endLineNumber;
   _str lastRevision;
   _str lastRevisionCaption;
   _str lastFilename;
   bool symbolExistedInLastVersion;
   STRHASHTAB fileTable;
};

static int processOneFile(int outputFormWID)
{
   SVC_QUERY_INFO queryInfo = _GetDialogInfoHt("queryInfo",outputFormWID);
   status := 0;
   if ( queryInfo.historyInfo!=null && queryInfo.filename != "" ) {
      startLineNumber := 0;
      endLineNumber := 0;
      commentLineNumber := 0;
      tempFilename := "";
      process_events(gPause);
      curRevision := "";
      revisionCaption := "";
      fileWID := 0;
      // Going the wrong direction, working copy is coming up at end with beginning searches.
      if ( queryInfo.historyInfo[queryInfo.curIndex].picIndex==_pic_branch ||
           queryInfo.historyInfo[queryInfo.curIndex].revision=="root" ) {
         _nocheck _control ctlgauge1;
         ++queryInfo.outputFormWID.ctlgauge1.p_value;
         return 0;
      }else{
         curRevision = queryInfo.historyInfo[queryInfo.curIndex].revision;
         if ( curRevision=="Working file" ) {
            status = _open_temp_view(queryInfo.filename,fileWID,auto origWID);
            p_window_id = origWID;
         } else{
            status = queryInfo.pInterface->getFile(queryInfo.filename,curRevision,fileWID);

            // If a branch was removed, this could go away and come back, so
            // return 0 and wait to see what happens next time.
            if (status==VSRC_SVC_COULD_NOT_GET_CURRENT_VERSION_FILE) return 0;
         }
         if ( !_iswindow_valid(queryInfo.outputFormWID) ) return 0;
         revisionCaption = queryInfo.historyInfo[queryInfo.curIndex].revisionCaption;
         if ( revisionCaption=="" ) {
            revisionCaption = queryInfo.historyInfo[queryInfo.curIndex].revision;
         }
      }
      if ( !status ) {
         ARRAY_APPEND(queryInfo.WIDs,fileWID);
         origWID := p_window_id;
         p_window_id = fileWID;
         _SetEditorLanguage();
         tempFilename = _temp_path():+stranslate(_strip_filename(queryInfo.filename,'PE')'.'curRevision:+get_extension(queryInfo.filename,true),'',' ');

         queryInfo.tempFileList[queryInfo.tempFileList._length()] = tempFilename;

         _save_file("+o "tempFilename);
         queryInfo.fileTable:[curRevision] = tempFilename;
         _SetDialogInfoHt("queryInfo",queryInfo,outputFormWID);
         lastStartLineNumber := queryInfo.startLineNumber;
         lastEndLineNumber := queryInfo.endLineNumber;
         startLineNumber = 0;
         endLineNumber = 0;
         commentLineNumber = 0;
         int last_status=FindSymbolInfo(tempFilename,queryInfo.symbolName,"",
                                        startLineNumber, endLineNumber,commentLineNumber,
                                        auto last_tag_type="");
         if ( !last_status ) {
            if ( commentLineNumber>0 ) {
               startLineNumber = commentLineNumber;
            }
            if ( queryInfo.lastFilename!=null ) {
               CompareSections(queryInfo.lastFilename,lastStartLineNumber,lastEndLineNumber,
                               tempFilename,startLineNumber,endLineNumber,
                               auto sectionsMatched=false);
               if ( !sectionsMatched ) {
                  _nocheck _control ctlminihtml1;
                  cap := '<B>'queryInfo.symbolName'</B> changed between revision <B>'queryInfo.lastRevision'</B> and <B>'queryInfo.historyInfo[queryInfo.curIndex].revision'</B>';

                  cap :+= '<UL><LI><A href="diff:'queryInfo.historyInfo[queryInfo.curIndex].revision':'startLineNumber','endLineNumber' 'queryInfo.lastRevision':'lastStartLineNumber','lastEndLineNumber'">Diff Symbols</A></LI>';
                  cap :+= '<LI><A href="file:'queryInfo.historyInfo[queryInfo.curIndex].revision' 'queryInfo.lastRevision'">Diff Files</A></LI>';
                  cap :+= '<LI><A href="hist:'queryInfo.lastRevision'">View History for Version 'queryInfo.lastRevision'</A></LI>';
                  cap :+= '<LI><A href="histdiff:'queryInfo.lastRevision'">View History Diff for Version 'queryInfo.lastRevision'</A></LI></UL>';
                  if ( !_iswindow_valid(queryInfo.outputFormWID) ) return 0;
                  queryInfo.outputFormWID.ctlminihtml1._minihtml_GetScrollInfo(auto scrollInfo);
                  if ( queryInfo.outputFormWID.ctlminihtml1.p_text=="" ) {
                     queryInfo.outputFormWID.ctlminihtml1.p_text=cap;
                  } else {
                     queryInfo.outputFormWID.ctlminihtml1.p_text=queryInfo.outputFormWID.ctlminihtml1.p_text'<BR>'cap;
                  }
                  queryInfo.outputFormWID.ctlminihtml1._minihtml_SetScrollInfo(scrollInfo);
               }
            }
            p_window_id = origWID;
            queryInfo.startLineNumber = startLineNumber;
            queryInfo.endLineNumber = endLineNumber;
            queryInfo.lastFilename = tempFilename;
            queryInfo.symbolExistedInLastVersion = true;
         } else {
            if ( queryInfo.lastRevision!=null && queryInfo.symbolExistedInLastVersion ) {
               _nocheck _control ctlminihtml1;
               cap := '<B>'queryInfo.symbolName'</B> does not exist in revision <B>'queryInfo.historyInfo[queryInfo.curIndex].revision'</B>.';
               cap :+= '<UL><LI><A href="hist:'queryInfo.lastRevisionCaption'">View History for Version 'queryInfo.lastRevisionCaption'</A></LI></UL>';
               queryInfo.outputFormWID.ctlminihtml1._minihtml_GetScrollInfo(auto scrollInfo);
               if ( queryInfo.outputFormWID.ctlminihtml1.p_text=="" ) {
                  queryInfo.outputFormWID.ctlminihtml1.p_text=cap;
               } else {
                  queryInfo.outputFormWID.ctlminihtml1.p_text=queryInfo.outputFormWID.ctlminihtml1.p_text'<BR>'cap;
               }
               queryInfo.outputFormWID.ctlminihtml1._minihtml_SetScrollInfo(scrollInfo);
            }
            queryInfo.symbolExistedInLastVersion = false;
         }
      }
      if ( !_iswindow_valid(queryInfo.outputFormWID) ) return 0;
      _nocheck _control ctlgauge1;
      ++queryInfo.outputFormWID.ctlgauge1.p_value;
      queryInfo.lastRevision = queryInfo.historyInfo[queryInfo.curIndex].revision;
      queryInfo.lastRevisionCaption = revisionCaption;
   }
   _SetDialogInfoHt("queryInfo",queryInfo,outputFormWID);
   return status;
}

_command void svc_query() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   gPause = false;
   autoVCSystem := svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,autoVCSystem));
      return;
   }
   status := _SVCGetLineNumbers(auto startLineNumber=0,auto endLineNumber=0,auto symbolName="");
   if ( status ) {
      _message_box(get_message(VSCODEHELPRC_CONTEXT_NOT_VALID));
      return;
   }
   filename := p_buf_name;
   status = GetSymbolInfo(filename,
                           symbolName,
                           auto last_start_line_number=0,
                           auto lastLine=0,
                           auto commentLine=0,
                           auto tagType="",
                           null,
                           false,
                           "Select a Symbol to Find Changes in");
   if ( status ) {
      return;
   }
   parse symbolName with symbolName '(' . ;
   outputFormWID := show('-xy _svc_query_output_form');
   SVC_QUERY_INFO queryInfo;
   pInterface->getHistoryInformation(filename,auto historyInfo,SVC_HISTORY_NO_BRANCHES|SVC_HISTORY_INCLUDE_WORKING_FILE);
   queryInfo.pInterface = pInterface;
   queryInfo.historyInfo = historyInfo;
   queryInfo.filename = filename;
   queryInfo.outputFormWID = outputFormWID;
   queryInfo.symbolName = symbolName;
   _nocheck _control ctlgauge1;
   outputFormWID.p_caption = "Revisions where "symbolName" changed";

   // Subtract one because there is one dummy entry for root.
   outputFormWID.ctlgauge1.p_max = historyInfo._length() - 1;
   processFiles(queryInfo,true);
}

static int processFiles(SVC_QUERY_INFO &queryInfo,bool useLastIndex=false)
{
   i := queryInfo.curIndex;
   if ( useLastIndex ) {
      i = getLastIndex(queryInfo);
   }
   if (i<0) return 1;
   for (;i>=0;) {
      queryInfo.curIndex = i;
      _SetDialogInfoHt("queryInfo",queryInfo,queryInfo.outputFormWID);
      status := processOneFile(queryInfo.outputFormWID);
      if ( !_iswindow_valid(queryInfo.outputFormWID) ) break;
      process_events(gPause);
      if ( status ) break;
      if ( gPause ) break;
        
      if ( !_iswindow_valid(queryInfo.outputFormWID) ) break;
      queryInfo = _GetDialogInfoHt("queryInfo",queryInfo.outputFormWID);
      if ( queryInfo.historyInfo[i].lsibIndex>=0 ) {
         i = queryInfo.historyInfo[i].lsibIndex;
      } else {
         i = queryInfo.historyInfo[i].parentIndex;
      }
   }
   // When we're done, be sure gauge is at 100%.  It might not be if there are
   // items on a branch we did not traverse.
   _nocheck _control ctlgauge1;
   if ( i<0 ) {
      queryInfo.outputFormWID.ctlgauge1.p_value = queryInfo.outputFormWID.ctlgauge1.p_max;
   }
   _nocheck _control ctlpause;
   _nocheck _control ctlminihtml1;
   if ( _iswindow_valid(queryInfo.outputFormWID) && !gPause ) {
      queryInfo.outputFormWID.ctlpause._delete_window();
      if ( queryInfo.outputFormWID.ctlminihtml1.p_text=="" ) {
         queryInfo.outputFormWID.ctlminihtml1.p_text = "No difference detected";
      }
   }
   return 0;
}

static int getLastIndex(SVC_QUERY_INFO &queryInfo)
{
   vcSystem := svc_get_vc_system(queryInfo.filename);
   IVersionControl *pInterface = svcGetInterface(vcSystem);
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,vcSystem));
      return VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC;
   }

#if 0
   status := pInterface->getCurRevision(queryInfo.filename,auto curRevision);
   if ( status ) {
      return status;
   }

   len := queryInfo.historyInfo._length();
   for (i:=0;i<len;++i) {
      if ( queryInfo.historyInfo[i].revision==curRevision) {
         return i;
      }
   }
#else
   len := queryInfo.historyInfo._length();
   for (i:=0;i<len;++i) {
      if ( queryInfo.historyInfo[i].revision=="Working file" ) {
         return i;
      }
   }
#endif
   return -1;
}

static int CompareSections(_str filename1,int start_line_number1,int end_line_number1,
                           _str filename2,int start_line_number2,int end_line_number2,
                           bool &sectionsMatched)
{
   sectionsMatched=false;

   int status;
   int temp_view_id1,orig_view_id;
   status=_open_temp_view(filename1,temp_view_id1,orig_view_id);
   if (status) return(status);

   p_window_id=orig_view_id;
   int temp_view_id2;
   status=_open_temp_view(filename2,temp_view_id2,orig_view_id);
   if (status) return(status);

   p_window_id=orig_view_id;

   _str ImaginaryLineCaption=null;
   int OutputBufId;
   DIFF_INFO info;
   info.iViewID1 = temp_view_id1;
   info.iViewID2 = temp_view_id2;
   info.iOptions = def_diff_flags|DIFF_NO_BUFFER_SETUP|DIFF_DONT_COMPARE_EOL_CHARS|DIFF_OUTPUT_BOOLEAN;
   info.iNumDiffOutputs = 0;
   info.iIsSourceDiff = false;
   info.loadOptions = def_load_options;
   info.iGaugeWID = 0;
   info.iMaxFastFileSize = 800;
   info.lineRange1 = start_line_number1'-'end_line_number1;
   info.lineRange2 = start_line_number2'-'end_line_number2;
   info.iSmartDiffLimit = def_smart_diff_limit;
   info.imaginaryText = ImaginaryLineCaption;
   info.tokenExclusionMappings=null;

   diffStatus := Diff(info);
   if ( diffStatus<0 ) {
      if (diffStatus!=-1 && diffStatus != COMMAND_CANCELLED_RC) _message_box(nls("Diff failed\n\n%s",get_message(diffStatus)));
      return diffStatus;
   }
   sectionsMatched = diffStatus!=0;

   _delete_temp_view(temp_view_id1);
   _delete_temp_view(temp_view_id2);


   return(status);
}

defeventtab _svc_query_output_form;

static void resizeDialog()
{
   xbuffer := ctlminihtml1.p_x;
   ybuffer := ctlminihtml1.p_y;

   clientWidth := _dx2lx(SM_TWIP,p_client_width);
   clientHeight := _dy2ly(SM_TWIP,p_client_height);

   htmlArea := clientHeight-(ctlclose.p_height+ctlgauge1.p_height+(6*ybuffer));

   ctlminihtml1.p_height = htmlArea;
   ctlminihtml1.p_width = ctlgauge1.p_width = clientWidth-(2*xbuffer);
   ctlgauge1.p_y = ctlminihtml1.p_y_extent+ybuffer;
   ctlclose.p_y = ctlgauge1.p_y_extent+ybuffer;
   if ( _find_control('ctlpause') ) {
      ctlpause.p_y = ctlclose.p_y;
   }
}

void _svc_query_output_form.on_resize()
{
   resizeDialog();
}

void ctlminihtml1.on_change(int reason,_str hrefText)
{
   formWID := p_active_form;
   inOnChange := _GetDialogInfoHt("inOnChange",ctlminihtml1);
   if ( inOnChange == true ) {
      return;
   }
   _SetDialogInfoHt("inOnChange",true,ctlminihtml1);
   SVC_QUERY_INFO queryInfo = _GetDialogInfoHt("queryInfo");
   parse hrefText with auto leader ':' .;
   switch (leader) {
   case "diff":
      {
         parse hrefText with "diff:" auto rev1 ':' auto lineRange1 auto rev2 ':' auto lineRange2;
         filename1 := queryInfo.fileTable:[rev1];
         filename2 := queryInfo.fileTable:[rev2];
         diff('-modal -r1 -r2 -range1:'lineRange1' -range2:'lineRange2' -file1title '_maybe_quote_filename(queryInfo.symbolName':'rev1)' -file2title '_maybe_quote_filename(queryInfo.symbolName':'rev2)' '_maybe_quote_filename(filename1)' '_maybe_quote_filename(filename2));
         break;
      }
   case "hist":
      {
         systemName := lowcase(queryInfo.pInterface->getSystemNameCaption());
         parse hrefText with "hist:" auto rev1;
         svc_history(queryInfo.filename,SVC_HISTORY_NOT_SPECIFIED,rev1,searchUserInfoForVersion:systemName=="git");
         break;
      }
   case "histdiff":
      {
         parse hrefText with "histdiff:" auto rev1;
         svc_history_diff(queryInfo.filename,"",rev1,true);
         break;
      }
   case "file":
      {
         parse hrefText with "file:" auto rev1 auto rev2;
         filename1 := queryInfo.fileTable:[rev1];
         filename2 := queryInfo.fileTable:[rev2];
         diff('-modal -r1 -r2 -file1title '_maybe_quote_filename(queryInfo.filename':'rev1)' -file2title '_maybe_quote_filename(queryInfo.filename':'rev2)' '_maybe_quote_filename(filename1)' '_maybe_quote_filename(filename2));
         break;
      }
   }
   if ( _iswindow_valid(formWID) ) {
      formWID._set_focus();
   }
   _SetDialogInfoHt("inOnChange",false,formWID.ctlminihtml1);

   inOnChange = _GetDialogInfoHt("inOnChange",formWID.ctlminihtml1);
   if ( inOnChange == true ) {
      return;
   }
}

void ctlpause.lbutton_up()
{
   if ( p_caption == "&Pause" ) {
      p_caption = "Resume";
      gPause = true;
   } else {
      p_caption = "&Pause";
      gPause = false;
      SVC_QUERY_INFO queryInfo = _GetDialogInfoHt("queryInfo");
      if ( queryInfo!=null ) {
         processFiles(queryInfo);
      }
   }
}

void _svc_query_output_form.on_destroy()
{
   SVC_QUERY_INFO queryInfo = _GetDialogInfoHt("queryInfo");
   len := queryInfo.WIDs._length();
   for (i:=0;i<len;++i) {
      _delete_temp_view(queryInfo.WIDs[i]);
   }
   for (i=0;i<len;++i) {
      delete_file(queryInfo.tempFileList[i]);
   }
}
