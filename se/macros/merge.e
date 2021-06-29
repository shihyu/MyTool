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
#include "markers.sh"
#import "cua.e"
#import "diff.e"
#import "diffedit.e"
#import "guiopen.e"
#import "help.e"
#import "main.e"
#import "markfilt.e"
#import "menu.e"
#import "stdprocs.e"
#import "util.e"
#endregion

// Originally used Get/SetDialogInfo for this, but it was too slow.
int gBaseRev1Matches:[];
int gBaseRev2Matches:[];

int _pic_three_pane;
int _pic_four_pane;
int _pic_merged_rev1;
int _pic_merged_rev2;
int _pic_merge_line_deleted;

defeventtab _merge_form;

defload()
{
   if ( _pic_three_pane<=0 ) {
      _pic_three_pane=_update_picture(_pic_three_pane,'bbmerge_three_pane.svg');
      if ( _pic_three_pane>=0 ) {
         set_name_info(_pic_three_pane,"Do not show base file");
      }
   }
   if ( _pic_four_pane<=0 ) {
      _pic_four_pane=_update_picture(_pic_four_pane,'bbmerge_four_pane.svg');
      if ( _pic_four_pane>=0 ) {
         set_name_info(_pic_four_pane,"Show base file");
      }
   }
   if ( _pic_merged_rev1<=0 ) {
      _pic_merged_rev1=_update_picture(_pic_merged_rev1,'_ed_merge_left.svg');
   }
   if ( _pic_merged_rev2<=0 ) {
      _pic_merged_rev2=_update_picture(_pic_merged_rev2,'_ed_merge_right.svg');
   }
   if ( _pic_merge_line_deleted<=0 ) {
      _pic_merge_line_deleted=_update_picture(_pic_merge_line_deleted,'_ed_delete.svg');
   }
}

void ctlfour_panes.lbutton_up()
{
   FourPanes();
   refresh('W');
}

void ctlthree_panes.lbutton_up()
{
   ThreePanes();
   refresh('W');
}

void ctlclose.on_create(int NumPanes=3)
{
   if ( NumPanes==3 ) {
      ThreePanes();
   } else if ( NumPanes==4 ) {
      FourPanes();
   }
}

static void setupVscrollBar(int editorWID,int scrollbarWID)
{
   int WindowHeightInLines=editorWID.p_char_height;
   scrollbarWID.p_max=editorWID.p_Noflines+1-(WindowHeightInLines-1);
   scrollbarWID.p_large_change=WindowHeightInLines-1;
   scrollbarWID.p_user=ctlvscrollRevisions.p_value;
   MergeUpdateScrollThumbs(editorWID,scrollbarWID);
}

void ctlvscrollRevisions.on_change()
{
   _control ctlrev2;
   if (ctlvscrollRevisions.p_user=='') return;//Cursor moved
   wid := p_window_id;
   _control ctlrev1;
   if (ctlvscrollRevisions.p_value<ctlvscrollRevisions.p_user) {
      p_window_id=ctlrev1;
      _scroll_page('u',ctlvscrollRevisions.p_user-ctlvscrollRevisions.p_value);
      p_window_id=ctlrev2;
      _scroll_page('u',ctlvscrollRevisions.p_user-ctlvscrollRevisions.p_value);
   }else if (ctlvscrollRevisions.p_value>ctlvscrollRevisions.p_user) {
      p_window_id=ctlrev1;
      _scroll_page('d',ctlvscrollRevisions.p_value-ctlvscrollRevisions.p_user);
      p_window_id=ctlrev2;
      _scroll_page('d',ctlvscrollRevisions.p_value-ctlvscrollRevisions.p_user);
   }
   p_window_id=wid;
   p_user=p_value;
}

void ctlvscrollOutput.on_change()
{
   _control ctlrev2;
   if (ctlvscrollOutput.p_user=='') return;//Cursor moved
   wid := p_window_id;
   _control ctloutput;
   if (ctlvscrollOutput.p_value<ctlvscrollOutput.p_user) {
      p_window_id=ctloutput;
      _scroll_page('u',ctlvscrollOutput.p_user-ctlvscrollOutput.p_value);
   }else if (ctlvscrollOutput.p_value>ctlvscrollOutput.p_user) {
      p_window_id=ctloutput;
      _scroll_page('d',ctlvscrollOutput.p_value-ctlvscrollOutput.p_user);
   }
   p_window_id=wid;
   p_user=p_value;
}

static void decrementScroll()
{
   if ( p_value <= 0 ) return;
   --p_value;
}

static void incrementScroll()
{
   if ( p_value+1 >= p_max ) return;
   _control ctlvscrollOutput;
   ++p_value;
}

void ctlbase.wheel_up()
{
   ctlvscrollRevisions.decrementScroll();
}

void ctlbase.wheel_down()
{
   ctlvscrollRevisions.incrementScroll();
}

void ctlrev1.wheel_up()
{
   ctlvscrollRevisions.decrementScroll();
   ctlvscrollOutput.decrementScroll();
}

void ctlrev1.wheel_down()
{
   ctlvscrollRevisions.incrementScroll();
   ctlvscrollOutput.incrementScroll();
}

void ctlrev2.wheel_up()
{
   ctlvscrollRevisions.decrementScroll();
   ctlvscrollOutput.decrementScroll();
}

void ctlrev2.wheel_down()
{
   ctlvscrollRevisions.incrementScroll();
   ctlvscrollOutput.incrementScroll();
}

void ctlvscrollBase.on_scroll()
{
   if ( _GetDialogInfoHt("inScrollBase")==1 ) return;
   _SetDialogInfoHt("inScrollBase",1);
   inScrollRevisions := _GetDialogInfoHt("inScrollRevisions");
   inScrollOutput := _GetDialogInfoHt("inScrollOutput");
   wid := p_window_id;
   _control ctloutput;
   if (ctlvscrollBase.p_user=='') {
      _SetDialogInfoHt("inScrollBase",0);
      return;//Cursor moved
   }
   if (ctlvscrollBase.p_value<ctlvscrollBase.p_user) {
      //Should scroll up
      p_window_id=ctlbase;
      scrollAmount := ctlvscrollBase.p_user-ctlvscrollBase.p_value;
      _scroll_page('u',scrollAmount);
      if ( !inScrollRevisions && !inScrollOutput ) {
         for (i:=0;i<scrollAmount;++i) {
            ctlvscrollRevisions.decrementScroll();
            ctlvscrollOutput.decrementScroll();
         }
      }
   }else if (ctlvscrollBase.p_value>ctlvscrollBase.p_user) {
      //Should scroll down
      p_window_id=ctlbase;
      scrollAmount := ctlvscrollBase.p_value-ctlvscrollBase.p_user;
      _scroll_page('d',scrollAmount);
      if ( !inScrollRevisions && !inScrollOutput ) {
         for (i:=0;i<scrollAmount;++i) {
            ctlvscrollRevisions.incrementScroll();
            ctlvscrollOutput.incrementScroll();
         }                      
      }
   }
   ctlvscrollBase.p_user=ctlvscrollBase.p_value;
   p_active_form.refresh();
      p_window_id=wid;
   _SetDialogInfoHt("inScrollBase",0);
}

void ctlvscrollRevisions.on_scroll()
{
   if ( _GetDialogInfoHt("inScrollRevisions")==1 ) return;
   _SetDialogInfoHt("inScrollRevisions",1);
   inScrollOutput := _GetDialogInfoHt("inScrollOutput");
   inScrollBase := _GetDialogInfoHt("inScrollBase");
   _control ctlrev2;
   wid := p_window_id;
   if (ctlvscrollRevisions.p_user=='') {
      _SetDialogInfoHt("inScrollRevisions",0);
      return;//Cursor moved
   }
   if (ctlvscrollRevisions.p_value<ctlvscrollRevisions.p_user) {
      //Should scroll up
      p_window_id=ctlrev1;
      scrollAmount := ctlvscrollRevisions.p_user-ctlvscrollRevisions.p_value;
      _scroll_page('u',scrollAmount);
      p_window_id=ctlrev2;
      _scroll_page('u',scrollAmount);
      if ( !inScrollOutput && !inScrollBase ) {
         for (i:=0;i<scrollAmount;++i) {
            ctlvscrollOutput.decrementScroll();
            ctlvscrollBase.decrementScroll();
         }
      }
   }else if (ctlvscrollRevisions.p_value>ctlvscrollRevisions.p_user) {
      //Should scroll down
      p_window_id=ctlrev1;
      scrollAmount := ctlvscrollRevisions.p_value-ctlvscrollRevisions.p_user;
      _scroll_page('d',scrollAmount);
      p_window_id=ctlrev2;
      _scroll_page('d',scrollAmount);
      if ( !inScrollOutput && !inScrollBase ) {
         for (i:=0;i<scrollAmount;++i) {
            ctlvscrollOutput.incrementScroll();
            ctlvscrollBase.incrementScroll();
         }
      }
   }
   ctlvscrollRevisions.p_user=ctlvscrollRevisions.p_value;
   p_active_form.refresh();
   p_window_id=wid;
   _SetDialogInfoHt("inScrollRevisions",0);
}

void ctlvscrollOutput.on_scroll()
{
   if ( _GetDialogInfoHt("inScrollOutput")==1 ) return;
   _SetDialogInfoHt("inScrollOutput",1);
   inScrollRevisions := _GetDialogInfoHt("inScrollRevisions");
   inScrollBase := _GetDialogInfoHt("inScrollBase");
   wid := p_window_id;
   _control ctloutput;
   if (ctlvscrollOutput.p_user=='') {
      _SetDialogInfoHt("inScrollOutput",0);
      return;//Cursor moved
   }
   if (ctlvscrollOutput.p_value<ctlvscrollOutput.p_user) {
      //Should scroll up
      p_window_id=ctloutput;
      scrollAmount := ctlvscrollOutput.p_user-ctlvscrollOutput.p_value;
      _scroll_page('u',scrollAmount);
      if ( !inScrollRevisions && !inScrollBase ) {
         for (i:=0;i<scrollAmount;++i) {
            ctlvscrollRevisions.decrementScroll();
            ctlvscrollBase.decrementScroll();
         }
      }
   }else if (ctlvscrollOutput.p_value>ctlvscrollOutput.p_user) {
      //Should scroll down
      p_window_id=ctloutput;
      scrollAmount := ctlvscrollOutput.p_value-ctlvscrollOutput.p_user;
      _scroll_page('d',scrollAmount);
      if ( !inScrollRevisions && !inScrollBase ) {
         for (i:=0;i<scrollAmount;++i) {
            ctlvscrollRevisions.incrementScroll();
            ctlvscrollBase.incrementScroll();
   }                      
      }
   }
   ctlvscrollOutput.p_user=ctlvscrollOutput.p_value;
   p_active_form.refresh();
   p_window_id=wid;
   _SetDialogInfoHt("inScrollOutput",0);
}

static void MergeSetWindowFlags()
{
   p_window_flags|=(OVERRIDE_CURLINE_RECT_WFLAG|CURLINE_RECT_WFLAG|OVERRIDE_CURLINE_COLOR_WFLAG);
   p_window_flags&=~(CURLINE_COLOR_WFLAG);
   p_window_flags|=VSWFLAG_NOLCREADWRITE;
}

static void MergeUpdateScrollThumbs(int editorWID,int scrollbarWID)
{
   int old=scrollbarWID.p_user;
   scrollbarWID.p_user='';
   int YInLines=editorWID.p_cursor_y intdiv _ly2dy(SM_TWIP,editorWID._text_height());
   scrollbarWID.p_value=editorWID.p_line-YInLines;
   scrollbarWID.p_user=editorWID.p_line-YInLines;
   scrollbarWID.refresh();
}
static void MergeScrollDown(int Noflines)
{
   _control ctlrev2;
   if (ctlvscrollRevisions.p_user+Noflines>ctlvscrollRevisions.p_max) {
      Noflines=ctlvscrollRevisions.p_max-ctlvscrollRevisions.p_user;
   }
   //Should scroll down
   p_window_id=ctlrev1;
   _scroll_page('d',Noflines);
   p_window_id=ctlrev2;
   _scroll_page('d',Noflines);
   ctlvscrollRevisions.p_user+=Noflines;
   ctlvscrollRevisions.p_value=ctlvscrollRevisions.p_user;
}
static void ScrollUp(int Noflines)
{
   _control ctlrev2;
   if (ctlvscrollRevisions.p_user-Noflines<ctlvscrollRevisions.p_min) {
      Noflines=ctlvscrollRevisions.p_user-ctlvscrollRevisions.p_min;
   }
   //Should scroll down
   p_window_id=ctlrev1;
   _scroll_page('u',Noflines);
   p_window_id=ctlrev2;
   _scroll_page('u',Noflines);
   ctlvscrollRevisions.p_user-=Noflines;
   ctlvscrollRevisions.p_value=ctlvscrollRevisions.p_user;
}
void ctlrev1.on_vsb_line_down()
{
   p_window_id.MergeScrollDown(1);
}
void ctlrev2.on_vsb_line_down()
{
   p_window_id.MergeScrollDown(1);
}
void ctlrev1.on_vsb_line_up()
{
   p_window_id.ScrollUp(1);
}
void ctlrev2.on_vsb_line_up()
{
   p_window_id.ScrollUp(1);
}

static void ThreePanes()
{
   ctlbase_label.p_visible=ctlbase.p_visible=false;
   ctlfour_panes.p_enabled=true;
   ctlthree_panes.p_enabled=false;
   SetLeftEdges();
   ResizeMergeDialog();
}

static void FourPanes()
{
   ctlbase_label.p_visible=ctlbase.p_visible=true;
   ctlfour_panes.p_enabled=false;
   ctlthree_panes.p_enabled=true;
   SetLeftEdges();
   ResizeMergeDialog();
}

void _merge_form.on_resize()
{
   ResizeMergeDialog();
}

static void LayoutMergeButtons()
{
   int x = ctlfour_panes.p_x;
   int w = ctlfour_panes.p_width;
   int spacing = x intdiv 2;

   x+=(w+spacing);
   ctlthree_panes.p_x=x;

   x+=(w+w);
   ctlchoose_rev1.p_x=x;
   x+=(w+spacing);
   ctlchoose_rev1_next.p_x=x;

   x+=(w+w intdiv 2);
   ctlchoose_remove.p_x=x;

   x+=(w+w intdiv 2);
   ctlchoose_rev2_next.p_x=x;
   x+=(w+spacing);
   ctlchoose_rev2.p_x=x;

   x+=(w+w);
   ctlfirst_conflict.p_x=x;
   x+=(w+spacing);
   ctlprev_conflict.p_x=x;
   x+=(w+spacing);
   ctlnext_conflict.p_x=x;
   x+=(w+spacing);
   ctllast_conflict.p_x=x;
}

static void ResizeMergeDialog()
{
   wid := p_window_id;
   p_window_id=p_active_form;

   int client_height=_dy2ly(SM_TWIP,p_client_height);
   int client_width=_dx2lx(SM_TWIP,p_client_width);

   int xbuffer=ctlbase.p_x;
   int ybuffer=ctlfour_panes.p_y;
   int button_height=ctlfour_panes.p_height;

   int divisor=ctlbase.p_visible?3:2;
   int editor_area_y=client_height;
   editor_area_y-=(ctlclose.p_height+ctlbase_label.p_height+ctlrev1_label.p_height+ctloutput_label.p_height+button_height);
   if ( divisor==2 ) {
      editor_area_y-=(7*ybuffer);
      editor_area_y+=ctlbase_label.p_height;
   } else {
      editor_area_y-=(9*ybuffer);
   }

   ctlbase_label.p_y = ctlrev1_label.p_y = ctlrev2_label.p_y = ybuffer+button_height+ybuffer;

   int base_height=ctlrev1.p_height=ctlrev2.p_height=ctloutput.p_height=editor_area_y intdiv divisor;
   ctlbase.p_height=base_height;
   if ( divisor==2 ) {
      ctlrev1_label.p_y=ctlrev2_label.p_y=ctlbase_label.p_y;
      ctlrev1.p_y=ctlrev2.p_y=ctlbase.p_y;
   } else {
      ctlrev1_label.p_y=ctlrev2_label.p_y=ctlbase.p_y_extent+(2*ybuffer);
   }

   ctlrev1.p_y=ctlrev2.p_y=ctlrev1_label.p_y_extent+ybuffer;

   ctloutput_label.p_y=ctlrev1.p_y_extent+ybuffer;
   ctloutput.p_y=ctloutput_label.p_y_extent+ybuffer;

   ctlsave.p_y=ctlclose.p_y=ctloutput.p_y_extent+ybuffer;

   int editor_area=(client_width-ctlvscrollRevisions.p_width);

   ctlbase.p_width=ctloutput.p_width=(editor_area -(2*xbuffer));
   ctlrev1.p_width=ctlrev2.p_width=(editor_area-(3*xbuffer) ) intdiv 2 ;


   ctlvscrollBase.sizeAndPositionScrollBars(ctlbase);
   ctlvscrollRevisions.sizeAndPositionScrollBars(ctlrev1);
   ctlvscrollOutput.sizeAndPositionScrollBars(ctloutput);

   ctlrev2.p_x=ctlrev2_label.p_x=ctlvscrollRevisions.p_x_extent;
   setupVscrollBar(ctlbase,ctlvscrollBase);
   setupVscrollBar(ctlrev1,ctlvscrollRevisions);
   setupVscrollBar(ctloutput,ctlvscrollOutput);
   LayoutMergeButtons();

   p_window_id=wid;
}

static void sizeAndPositionScrollBars(int WID)
{
   p_x=WID.p_x_extent;
   p_y=WID.p_y;
   p_height=WID.p_height;
}

struct MERGE_INFO_T {
   _str basefilename;
   bool diskbase;
   _str rev1filename;
   bool disk1;
   _str rev2filename;
   bool disk2;
   _str outputfilename;
   bool overwriteoutput;
   bool smart;
   bool interleaved;
   bool AutoMerge;
   bool ShowChanges;
   bool ForceConflict;
   bool IgnoreSpaces;
};

struct BASE_MATCHED_LINES {
   int rev1,rev2,output;
};

struct REV1_MATCHED_LINES {
   int base,rev2,output;
};

struct REV2_MATCHED_LINES {
   int base,rev1,output;
};

struct OUTPUT_MATCHED_LINES {
   int base,rev1,rev2;
};

struct MATCHED_LINE_INFO {
   BASE_MATCHED_LINES base[];
   REV1_MATCHED_LINES rev1[];
   REV2_MATCHED_LINES rev2[];
   OUTPUT_MATCHED_LINES output[];
} gMergeLineMatches;

static int MergeOpen(_str filename,int &view_id,
                     bool FilenameIsBuffer,
                     bool FilenameIsBufID,
                     bool FilenameIsViewId)
{
   int orig_view_id;
   load_options := "";
   if ( FilenameIsBufID ) {
      load_options='+bi 'filename;
      filename='';
   } else if ( FilenameIsBuffer ) {
      load_options='+b ';
   } else if ( FilenameIsViewId ) {
      load_options='+bi 'filename.p_buf_id;
      filename='';
   }
   int status=_open_temp_view(filename,view_id,orig_view_id,load_options);
   p_window_id=orig_view_id;
   return(status);
}


static void MergeOpenFileErrorMessage(_str filename,_str file_title,bool IsBufID,bool IsViewId,int status)
{
   msg := "";
   if ( IsViewId || IsBufID ) {
      msg=nls("Could not open %s file\n\n%s",file_title,get_message(status));
   } else {
      msg=nls("Could not open file '%s'\n\n%s",filename,get_message(status));
   }
   _message_box(msg);
}

static int GetPicIndex(MERGE_PIC_INFO PicIndexes)
{
   if (p_window_id==ctlrev1) {
      return(PicIndexes.Rev1);
   }else if (p_window_id==ctlrev2) {
      return(PicIndexes.Rev2);
   }else if (p_window_id==ctloutput) {
      return(PicIndexes.Output);
   }
   return(-1);
}

static bool MergeInConflictRegion(int &conflict_number=0,bool IncludeChanges=false)
{
   _str LineOffset;
   parse point() with LineOffset .;
   int list[];
   _LineMarkerFindList(list,p_window_id,p_line,(long)LineOffset,true);
   if (list==null) {
      return(false);
   }

   MERGE_PIC_INFO PicIndexes[]=_GetDialogInfoHt('PicIndexes');
   int i,len=PicIndexes._length();
   found := false;
   for (i=1;i<len;++i) {
      pic_index := GetPicIndex(PicIndexes[i]);
      if (pic_index==list[0]) {
         VSLINEMARKERINFO info;
         _LineMarkerGet(list[0],info);
         if ( !IncludeChanges &&
             (info.BMIndex==_pic_merged_rev1 || info.BMIndex==_pic_merged_rev2)) {
            // If we aren't Including the merged cases(not really conflicts),
            // and that is what this is, keep going
            continue;
         }
         found=true;
         break;
      }
   }
   if (i<len) {
      conflict_number=i;
   }
   return(found);
}

static void MergeTimerCallback(int form_wid)
{
   wid := p_window_id;
   p_window_id=form_wid;
   focus := _get_focus();
   if (!focus || focus.p_active_form!=p_active_form) {
      return;
   }
   p_window_id=focus;
   if (focus!=ctlrev1 && focus!=ctlrev2) {
      p_window_id=ctloutput;
   }

   int conflict_number=GetRevConflictNumber();
   _nocheck _control ctlchoose_rev1;
   _nocheck _control ctlchoose_rev2;
   _nocheck _control ctlchoose_rev1_next;
   _nocheck _control ctlchoose_rev2_next;
   _nocheck _control ctlchoose_remove;
   ctlchoose_rev1.p_enabled=conflict_number!=0;
   ctlchoose_rev2.p_enabled=conflict_number!=0;
   ctlchoose_rev1_next.p_enabled=conflict_number!=0;
   ctlchoose_rev2_next.p_enabled=conflict_number!=0;
   ctlchoose_remove.p_enabled=conflict_number!=0;
   p_window_id=wid;
}

static void ParseRev1(_str Line,int &Rev1LN)
{
   _str Rev1Info;
   parse Line with Rev1Info ',' .;
   Rev1LN=(int)Rev1Info;
}

static void ParseRev2(_str Line,int &Rev2LN)
{
   _str Rev2Info;
   parse Line with . ',' Rev2Info;
   Rev2LN=(int)Rev2Info;
}

static void MergePrepEditControl(int ViewId,_str Docname,int ReadOnly=-1,bool &CurrentReadOnly=false)
{
   _delete_buffer();
   load_files('+bi 'ViewId.p_buf_id);
   top();

   p_buser=p_color_flags;
   p_color_flags|=MODIFY_COLOR_FLAG;
   p_user=p_buf_id' 0 'p_readonly_mode;

   MergeSetCaption(Docname);
   if (p_buf_size<def_use_old_line_numbers_ksize*1024) {
      _SetAllOldLineNumbers();
   }
   CurrentReadOnly=p_readonly_mode;
   if (ReadOnly!=-1) {
      p_readonly_mode=ReadOnly!=0;
   }
   p_SoftWrap = false;
}

typedef void (*pfnParseFunc_tp)(_str Line,int &RevLN);

int MergeDialog(int BaseFileViewId,int Rev1ViewId,int Rev2ViewId,int OutputViewId1,
                _str (&BaseLineMatches)[],MERGE_DIALOG_INFO &DialogInfo,
                MERGE_PIC_INFO (&PicIndexes)[],_str (&LineInfo)[],
                bool CallerSaves,bool quiet=false,_str saveCallback=null,
                bool nosave=false,bool readonlyoutput=false)
{
   if (!_haveMerge()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Merge");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   origWID := p_window_id;
   int form_wid=show('-desktop -xy _merge_form');
   wid := p_window_id;
   p_window_id=form_wid;

   if ( nosave ) {
      ctlsave.p_visible = false;
      _SetDialogInfoHt("nosave",1);
   }
   if ( DialogInfo.DialogTitle!='' &&
        DialogInfo.DialogTitle!=null ) {
      form_wid.p_active_form.p_caption=DialogInfo.DialogTitle;
   }

   gMergeLineMatches=null;
   int i,len=LineInfo._length();


   gMergeLineMatches.base[0].rev1=0;
   gMergeLineMatches.base[0].rev2=0;
   gMergeLineMatches.base[0].output=0;
   // Use <= because we are looking at i-1

   int warning_size=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
   if (len>=warning_size) {
      _default_option(VSOPTION_WARNING_ARRAY_SIZE,len+1);
   }

   // Get less reallocs this way
   gMergeLineMatches.base[len].rev1=0;

   for (i=1;i<=len;++i) {
      _str baseln,rev1ln,rev2ln,outputln;
      parse LineInfo[i-1] with baseln rev1ln rev2ln outputln;
      gMergeLineMatches.base[(int)baseln].rev1=(int)rev1ln;
      gMergeLineMatches.base[(int)baseln].rev2=(int)rev2ln;
      gMergeLineMatches.base[(int)baseln].output=(int)outputln;

      gMergeLineMatches.rev1[(int)rev1ln].base=(int)baseln;
      gMergeLineMatches.rev1[(int)rev1ln].rev2=(int)rev2ln;
      gMergeLineMatches.rev1[(int)rev1ln].output=(int)outputln;

      gMergeLineMatches.rev2[(int)rev2ln].base=(int)baseln;
      gMergeLineMatches.rev2[(int)rev2ln].rev1=(int)rev1ln;
      gMergeLineMatches.rev2[(int)rev2ln].output=(int)outputln;

      gMergeLineMatches.output[(int)outputln].base=(int)baseln;
      gMergeLineMatches.output[(int)outputln].rev1=(int)rev1ln;
      gMergeLineMatches.output[(int)outputln].rev2=(int)rev2ln;
   }
   if (len>=warning_size) {
      _default_option(VSOPTION_WARNING_ARRAY_SIZE,warning_size);
   }

   bool BaseOrigReadOnly,Rev1OrigReadOnly,Rev2OrigReadOnly;
   ctlbase.MergePrepEditControl(BaseFileViewId,DialogInfo.BaseDocname,1,BaseOrigReadOnly);
   ctlrev1.MergePrepEditControl(Rev1ViewId,DialogInfo.Rev1Docname,1,Rev1OrigReadOnly);
   ctlrev2.MergePrepEditControl(Rev2ViewId,DialogInfo.Rev2Docname,1,Rev2OrigReadOnly);
   ctloutput.MergePrepEditControl(OutputViewId1,DialogInfo.OutputDocName);
   if ( readonlyoutput ) {
      ctloutput.p_readonly_mode = true;
   }

   _SetDialogInfoHt('BaseOrigReadOnly',BaseOrigReadOnly);
   _SetDialogInfoHt('Rev1OrigReadOnly',Rev1OrigReadOnly);
   _SetDialogInfoHt('Rev2OrigReadOnly',Rev2OrigReadOnly);
   _SetDialogInfoHt('saveCallback',saveCallback);

   ctloutput.p_AllowSave=true;

   _SetDialogInfoHt('BaseLineMatches',BaseLineMatches);

   int BaseRev1Matches:[],BaseRev2Matches:[];
   GetHashTabFromArray(BaseLineMatches,BaseRev1Matches,ParseRev1);
   GetHashTabFromArray(BaseLineMatches,BaseRev2Matches,ParseRev2);

   gBaseRev1Matches=BaseRev1Matches;
   gBaseRev2Matches=BaseRev2Matches;
   _SetDialogInfoHt('MergeNumConflicts',MergeNumConflicts());
   _SetDialogInfoHt('PicIndexes',PicIndexes);

   bool ConflictClearedInOutput[];
   for (i=0;i<=MergeNumConflicts();++i) {
      ConflictClearedInOutput[i]=false;
   }
   _SetDialogInfoHt('ConflictClearedInOutput',ConflictClearedInOutput);
   _SetDialogInfoHt('CallerSaves',CallerSaves);

   ctlrev1.merge_next_conflict(true);
   ctloutput._BlastUndoInfo();

   MergeSetAllWindowFlags();

   setupVscrollBar(ctlbase,ctlvscrollBase);
   setupVscrollBar(ctlrev1,ctlvscrollRevisions);
   setupVscrollBar(ctloutput,ctlvscrollOutput);
   p_window_id=wid;
   int timer_handle=_set_timer(100,MergeTimerCallback,form_wid);
   typeless status=_modal_wait(form_wid);
   _kill_timer(timer_handle);
   p_window_id = origWID;
   gMergeLineMatches=null;
   return(status);
}

static void MergeSetAllWindowFlags()
{
   ctlbase.MergeSetWindowFlags();
   ctlrev1.MergeSetWindowFlags();
   ctlrev2.MergeSetWindowFlags();
   ctloutput.MergeSetWindowFlags();
}

static void GetHashTabFromArray(_str (&BaseLineMatches)[],
                                int  (&BaseRevMatches):[],
                                pfnParseFunc_tp pfn)
{
   int i,len=BaseLineMatches._length();
   for (i=0;i<len;++i) {
      int RevLN;

      if (BaseLineMatches[i]._varformat()!=VF_EMPTY) {
         (*pfn)(BaseLineMatches[i],RevLN);
         if (RevLN) {
            BaseRevMatches:[RevLN]=i;
         }
      }
   }
}

/*static void RevisionLbuttonDown()
{
   rev_line_number := rev_num_lines := 0;
   int conflict_number=GetRevConflictNumber(p_window_id,rev_line_number,rev_num_lines);
   if (!conflict_number) {
      PositionOtherWindows();
      return;
   }
   CopyConflictToOutput(conflict_number);
   PositionOtherWindows();
   MergeUpdateScrollThumbs();
}*/

/*static void RevisionRbuttonDown()
{
   int MenuIndex=find_index("_merge_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   int x,y;
   mou_get_xy(x,y);
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
}*/

static void CopyConflictToOutput(int ConflictNumber,bool ClearOutputFirst=true)
{
   _str msg;

   MERGE_PIC_INFO PicIndexes[]=_GetDialogInfoHt('PicIndexes');

   bool ConflictClearedInOutput[]=_GetDialogInfoHt('ConflictClearedInOutput');
   if (!ClearOutputFirst) {
      ClearOutputFirst=!ConflictClearedInOutput[ConflictNumber];
   }

   VSLINEMARKERINFO info;
   _LineMarkerGet(GetPicIndex(PicIndexes[ConflictNumber]),info);
   int rev_line_number=info.LineNum;
   int rev_num_lines=info.NofLines;

   int status=_LineMarkerGet(PicIndexes[ConflictNumber].Output,info);
   int output_line_number=info.LineNum;
   int output_num_lines=info.NofLines;
   int type=info.type;
   wid := p_window_id;
   if (!status) {
      old_lines := 0;
      int markid=_alloc_selection();
      if (output_num_lines && ClearOutputFirst) {
         p_window_id=ctloutput;
         p_line=output_line_number;
         _select_line(markid);
        p_line+=output_num_lines-1;
         _select_line(markid);
         _delete_selection(markid);
         p_window_id=wid;
      }else{
         old_lines=output_num_lines;
      }

      typeless revision_pos;
      save_pos(revision_pos);
      p_line=rev_line_number;
      _select_line(markid);
      down(rev_num_lines-1);
      status=_select_line(markid);

      orig_output_num_lines := ctloutput.p_Noflines;
      p_window_id=ctloutput;
      p_line=output_line_number-1;
      _copy_to_cursor(markid);
      _end_select(markid);
      p_scroll_left_edge=-1;
      p_window_id=wid;
      current_output_num_lines := ctloutput.p_Noflines;
      _LineMarkerRemove(PicIndexes[ConflictNumber].Output);

      int output_box_line_number=output_line_number;

      int new_index=_LineMarkerAdd(ctloutput,output_box_line_number,false,(current_output_num_lines-orig_output_num_lines)+old_lines,0,type,"");
      _LineMarkerSetStyleColor(new_index,0x0000ff);
      restore_pos(revision_pos);
      _free_selection(markid);

   }
   p_window_id=wid;
   ConflictClearedInOutput[ConflictNumber]=true;
   _SetDialogInfoHt('ConflictClearedInOutput',ConflictClearedInOutput);
}

static void MergeSetCaption(_str Docname)
{
   name := "";
   if ( p_buf_name!='' ) {
      if (Docname=='') {
         name=p_buf_name;
      }else{
         name=Docname;
      }
   } else if ( p_DocumentName!='' ) {
      if (Docname=='') {
         name=p_DocumentName;
      }else{
         name=Docname;
      }
   } else {
      name=p_DocumentName=Docname;
   }
   p_prev.p_caption=name;
}

void ctlbase.up()
{
   up();
   PositionOtherWindows();
   //MoveToBaseLine();
}

void ctlbase.down()
{
   down();
   PositionOtherWindows();
   //MoveToBaseLine();
}

static void FindLinesBR2(int rev1_line,int &base_line,int &rev2_line)
{
   base_line=-1;rev2_line=-1;
   _str BaseLineMatches[]=_GetDialogInfoHt('BaseLineMatches');
   len := BaseLineMatches._length();
   int i;
   for ( i=1;i<len;++i ) {
      cur_rev1_line := cur_rev2_line := "";
      parse BaseLineMatches[i] with cur_rev1_line ',' cur_rev2_line;
      if ( cur_rev1_line==rev1_line ) {
         base_line=i;
         rev2_line=(int)cur_rev2_line;
      } else if ( cur_rev1_line>rev1_line ) {
         break;
      }
   }
}

void ctlrev1.up()
{
   up();ctlrev2.up();
}

static void PositionOutputConflict(int ConflictNumber)
{
   PositionOutputConflict2(ConflictNumber);
}

static void PositionOutputConflict2(int ConflictNumber)
{
   if (GetRevConflictNumber(ctloutput)==ConflictNumber) {
      return;
   }
   MERGE_PIC_INFO PicIndexes[]=_GetDialogInfoHt('PicIndexes');
   int rln,output_line_number,output_num_lines,bufid,bufname,bmindex,type,linedata,markid,roffset,col;
   _str msg;
   VSLINEMARKERINFO info;
   int status=_LineMarkerGet(PicIndexes[ConflictNumber].Output,info);
   output_line_number=info.LineNum;
   output_num_lines=info.NofLines;
   ctloutput.p_line=output_line_number;
}

int ctlclose.lbutton_up()
{
   int status=MaybeSaveOutputFile();
   caller_saves := _GetDialogInfoHt("CallerSaves");
   if ( status==COMMAND_CANCELLED_RC ) {
      return( status );
   }
   if ( status && !caller_saves ) {
      return(status);
   }
   ctlrev1._DiffRemoveImaginaryLines();
   ctlrev2._DiffRemoveImaginaryLines();
   ctloutput._DiffRemoveImaginaryLines();

   ctlbase.RestoreReadOnly(_GetDialogInfoHt('BaseOrigReadOnly'));
   ctlrev1.RestoreReadOnly(_GetDialogInfoHt('Rev1OrigReadOnly'));
   ctlrev2.RestoreReadOnly(_GetDialogInfoHt('Rev2OrigReadOnly'));

   MERGE_PIC_INFO PicIndexes[]=_GetDialogInfoHt('PicIndexes');
   int i,len=PicIndexes._length();
   for (i=1;i<len;++i) {
      if (PicIndexes[i].Rev1!=null && PicIndexes[i].Rev1>-1) {
         _LineMarkerRemove(PicIndexes[i].Rev1);
      }
      if (PicIndexes[i].Rev2!=null && PicIndexes[i].Rev2>-1) {
         _LineMarkerRemove(PicIndexes[i].Rev2);
      }
      if (PicIndexes[i].Output!=null && PicIndexes[i].Output>-1) {
         _LineMarkerRemove(PicIndexes[i].Output);
      }
   }
   DiffFreeAllColorInfo(ctlrev1.p_buf_id);
   DiffFreeAllColorInfo(ctlrev2.p_buf_id);
   ctlrev1._DiffClearLineFlags();
   ctlrev2._DiffClearLineFlags();
   ctlrev1._BlastUndoInfo();
   ctlrev2._BlastUndoInfo();
   p_active_form._delete_window(status);
   return(status);
}

static void RestoreReadOnly(bool ReadOnly)
{
   p_readonly_mode=ReadOnly;
}

static int MaybeSaveOutputFile(bool quiet=false)
{
   wid := p_window_id;
   p_window_id=ctloutput;
   _str filename=p_DocumentName;
   if ( filename=='' ) {
      filename=p_buf_name;
   }
   nosave := _GetDialogInfoHt("nosave");
   status := 0;
   if ( p_modify ) {
      int result=IDYES;
      if ( !quiet && !nosave ) {
         result=prompt_for_save(nls("Save changes to file '%s'?",filename));
      }

      saveCallback := _GetDialogInfoHt('saveCallback');
      if (saveCallback!=null) {
         status = (*saveCallback)(filename,p_window_id);
         return status;
      }
      caller_saves := _GetDialogInfoHt("CallerSaves");
      if (caller_saves) {
         switch (result) {
         case IDYES:
            return(1);
         case IDNO:
            return(2);
         case IDCANCEL:
            return(COMMAND_CANCELLED_RC);
         }
      }
      if ( result==IDYES && !nosave ) {
         options := "+n -l";
         // Prevent Eclipse save mechanism from happening by passing
         // Called From Ecliopse
         if (isEclipsePlugin()) {
            options = "-CFE "options;
         }
         status=save(options" "_maybe_quote_filename(filename));
         if ( status ) {
            _message_box(nls("Could not save file '%s'\n\n%s",filename,get_message(status)));
            status=gui_save_as();
         }
      }else if ( result==IDCANCEL ) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   p_window_id=wid;
   return(status);
}

/**
 * ctlbase must be active.
 */
static void MoveToBaseLine()
{
   if ( !p_line ) {
      ctlrev1.p_RLine=ctlrev2.p_RLine=0;
      return;
   }
   _str BaseLineMatches[]=_GetDialogInfoHt('BaseLineMatches');
   _str rev1_line,rev2_line;
   parse BaseLineMatches[p_line] with rev1_line ',' rev2_line;
   if ( rev1_line ) {
      ctlrev1.p_RLine=(int)rev1_line;
   }
   if ( rev2_line ) {
      ctlrev2.p_RLine=(int)rev2_line;
   }
}

static _str IgnoredCommands:[] = {
   "cmdline-toggle" => 1
};

static _str AlwaysValidCommands:[] = {
   "function-argument-help" => 1
   ,"gui-find"               => 1
   ,"find-next"              => 1
   ,"find-prev"              => 1
   ,"end-line"               => 1
   ,"end-line-text-toggle"   => 1
   ,"end-line-ignore-trailing-blanks"=> 1
   ,"vi-end-line"            => 1
   ,"begin-line"             => 1
   ,"begin-line-text-toggle" => 1
   ,"vi-begin-line"          => 1
   ,"cursor-up"              => 1
   ,"cursor-down"            => 1
   ,"cursor-left"            => 1
   ,"cursor-right"           => 1
   ,"page-down"              => 1
   ,"page-up"                => 1
   ,"vi-page-down"           => 1
   ,"vi-page-up"             => 1
   ,"top-of-buffer"          => 1
   ,"bottom-of-buffer"       => 1
   ,"vi-escape"              => 1
   ,"esc-alt-prefix"         => 1
   ,"safe-exit"              => 1
   ,"copy-line"              => 1
   ,"copy-to-clipboard"      => 1
   ,"copy-word"              => 1
   ,"select-char"            => 1
   ,"select-line"            => 1
   ,"select-block"           => 1
   ,"mou-click"              => 1
   ,"mou-select-word"        => 1
   ,"next-window"            => 1
   ,"undo-cursor"            => 1
   ,"find-matching-paren"    => 1
   ,"undo"                   => 1
   ,"undo-cursor"            => 1
   ,"deselect"               => 1
   ,"mou-click-menu-block"   => 1
   ,"cua-select"             => 1
   ,"next-proc"              => 1
   ,"prev-proc"              => 1
   ,"next-tag"               => 1
   ,"prev-tag"               => 1
};

static _str MovementCommands:[] = {
    "gui-find"               => 1
   ,"find-next"              => 1
   ,"find-prev"              => 1
   ,"end-line"               => 1
   ,"vi-end-line"            => 1
   ,"begin-line"             => 1
   ,"vi-begin-line"          => 1
   ,"cursor-up"              => 1
   ,"cursor-down"            => 1
   ,"cursor-left"            => 1
   ,"cursor-right"           => 1
   ,"page-down"              => 1
   ,"page-up"                => 1
   ,"vi-page-down"           => 1
   ,"vi-page-up"             => 1
   ,"top-of-buffer"          => 1
   ,"bottom-of-buffer"       => 1
   ,"mou-click"              => 1
   ,"undo-cursor"            => 1
   ,"find-matching-paren"    => 1
   ,"undo"                   => 1
   ,"undo-cursor"            => 1
   ,"mou-click-menu-block"   => 1
   ,"next-proc"              => 1
   ,"prev-proc"              => 1
   ,"next-tag"               => 1
   ,"prev-tag"               => 1
};

void ctlbase.\0-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
{
   RevisionHandler();
}

void ctlrev1.\0-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
{
   RevisionHandler();
}

void ctlrev2.\0-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
{
   RevisionHandler();
}

static void MergeRevisionMouClick()
{
   mou_click();
   if (p_window_id==ctlrev1) {
      ctlrev2.p_line=ctlrev1.p_line;
      ctlrev2.p_col=ctlrev1.p_col;
   }else if (p_window_id==ctlrev2) {
      ctlrev1.p_line=ctlrev2.p_line;
      ctlrev1.p_col=ctlrev2.p_col;
   }
}

static void RevisionHandler()
{
   _str lastevent=last_event();
   /*if (lastevent==RBUTTON_DOWN) {
      MergeRevisionMouClick();
      RevisionRbuttonDown();
      return;
   }*/
   _str eventname=event2name(lastevent);
   int key_index=event2index(lastevent);
   name_index := eventtab_index(_default_keys,ctloutput.p_mode_eventtab,key_index);
   kt_index := eventtab_index(_default_keys,ctloutput.p_mode_eventtab,key_index,'U');

   if (name_type(name_index)==EVENTTAB_TYPE) {
      kt_index=name_index;
      lastevent=get_event('k');
      key_index=event2index(lastevent);
      name_index=eventtab_index(kt_index,kt_index,key_index);
   }
   last_index(kt_index,'k');
   last_event(lastevent);

   command_name := name_name(name_index);
   if ( command_name=='' ) {
      return;
   }
   if (eventname=='A-F4' || eventname=='ESC') {
      ctlclose.call_event(ctlclose,LBUTTON_UP);
      return;
   }
   if (eventname=='TAB' || eventname=='C-TAB') {
      if (ctlfour_panes.p_enabled) {
         if (p_window_id==ctlrev1) {
            p_window_id=ctlrev2;
            _set_focus();
         }else if (p_window_id==ctlrev2) {
            p_window_id=ctloutput;
            _set_focus();
         }
      }else if (ctlthree_panes.p_enabled) {
         if (p_window_id==ctlbase) {
            p_window_id=ctlrev2;
            _set_focus();
         }else if (p_window_id==ctlrev2) {
            p_window_id=ctloutput;
            _set_focus();
         }else if (p_window_id==ctlrev1) {
            p_window_id=ctlbase;
            _set_focus();
         }
      }
      return;
   }else if (eventname=='S-TAB' || eventname=='C-S-TAB') {
      if (ctlfour_panes.p_enabled) {
         if (p_window_id==ctlrev2) {
            p_window_id=ctlrev1;
            _set_focus();
         }else if (p_window_id==ctlrev1) {
            p_window_id=ctloutput;
            _set_focus();
         }
      }else if (ctlthree_panes.p_enabled) {
         if (p_window_id==ctlrev2) {
            p_window_id=ctlbase;
            _set_focus();
         }else if (p_window_id==ctlbase) {
            p_window_id=ctlrev1;
            _set_focus();
         }else if (p_window_id==ctlrev1) {
            p_window_id=ctloutput;
            _set_focus();
         }
      }
      return;
   }else if (eventname=='C-F6') {
      merge_next_conflict();
      return;
   }else if (eventname=='C-S-F6') {
      merge_prev_conflict();
      return;
   }
   index := find_index(command_name,COMMAND_TYPE);
   if (index && index_callable(index)) {
      _str temp;
      parse name_info(index) with ',' temp ',';
      int flags=(int)temp;
      if ( IgnoredCommands._indexin(command_name) ) {
      } else {
         CMDUI cmdui;
         cmdui.menu_handle=0;
         cmdui.menu_pos=0;
         cmdui.inMenuBar=false;
         cmdui.button_wid=1;

         _OnUpdateInit(cmdui,p_window_id);

         cmdui.button_wid=0;

         int mfflags=_OnUpdate(cmdui,p_window_id,command_name);
         if (!mfflags || (mfflags&MF_ENABLED)) {
            if (select_active()) {
               _on_select();
            } else {
               call_index(index);
            }
         }else{
            _message_box(nls("Command not allowed in %s",p_window_id==ctlbase?'base':'revision'));
         }
      }
   }

   SetLeftEdges();

   PositionOtherWindows();
   mergeUpdateAllScrollThumbs();
   //say(ctlrev1.p_RLine'/'ctlrev2.p_RLine);
}

static void mergeUpdateAllScrollThumbs()
{
   MergeUpdateScrollThumbs(ctlbase,ctlvscrollBase);
   MergeUpdateScrollThumbs(ctlrev1,ctlvscrollRevisions);
   MergeUpdateScrollThumbs(ctloutput,ctlvscrollOutput);
}

static void SetLeftEdges()
{
   wid := p_window_id;

   p_window_id=ctlbase;
   p_scroll_left_edge=-1;

   p_window_id=ctlrev1;
   p_scroll_left_edge=-1;

   p_window_id=ctlrev2;
   p_scroll_left_edge=-1;

   p_window_id=ctloutput;
   p_scroll_left_edge=-1;

   p_window_id=wid;
}

_command void merge_next_conflict(bool quiet=false) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   MergeMoveAllToNextConflict('',quiet);
}

_command void merge_prev_conflict() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   MergeMoveAllToNextConflict('-');
}

static void merge_save_pos(typeless &p,...)
{
   p=p_line" "p_col " "p_hex_nibble" "p_cursor_y " "p_left_edge' 'point();
}

void merge_restore_pos(typeless p)
{
   _str linenum,col,hex_nibble,cursor_y,left_edge;
   parse p with linenum col hex_nibble cursor_y left_edge p;
   p_line=(int)linenum;
   p_col=(int)col;p_hex_nibble=hex_nibble!="0";
   set_scroll_pos((int)left_edge,(int)cursor_y);
}

static void AdjustOtherScrollPositions(bool AdjustOutput=true)
{
   otherwid1 := otherwid2 := otherwid3 := 0;
   if (p_window_id==ctlbase) {
      otherwid1=ctlrev1;
      otherwid2=ctlrev2;
      if (AdjustOutput) otherwid3=ctloutput;
   }else if (p_window_id==ctlrev1) {
      otherwid1=ctlbase;
      otherwid2=ctlrev2;
      if (AdjustOutput) otherwid3=ctloutput;
   }else if (p_window_id==ctlrev2) {
      otherwid1=ctlbase;
      otherwid2=ctlrev1;
      if (AdjustOutput) otherwid3=ctloutput;
   }else if (p_window_id==ctloutput) {
      otherwid1=ctlbase;
      otherwid2=ctlrev1;
      otherwid3=ctlrev2;
   }
   int rev1_on_nosave=ctlrev1._lineflags()&NOSAVE_LF;
   int rev2_on_nosave=ctlrev2._lineflags()&NOSAVE_LF;

   turn_on_nosave := 0;
   if ((rev1_on_nosave && !rev2_on_nosave) ||
       (!rev1_on_nosave && rev2_on_nosave)
       ) {
      if (rev1_on_nosave) {
         ctlrev1._lineflags(0,NOSAVE_LF);
         turn_on_nosave=1;
      }else if (rev2_on_nosave) {
         ctlrev2._lineflags(0,NOSAVE_LF);
         turn_on_nosave=2;
      }
   }
   if (otherwid1) otherwid1.set_scroll_pos(p_left_edge,p_cursor_y);
   if (otherwid2) otherwid2.set_scroll_pos(p_left_edge,p_cursor_y);
   if (otherwid3) otherwid3.set_scroll_pos(p_left_edge,p_cursor_y);

   if (turn_on_nosave==1) {
      ctlrev1._lineflags(NOSAVE_LF,NOSAVE_LF);
   }else if (turn_on_nosave==2) {
      ctlrev2._lineflags(NOSAVE_LF,NOSAVE_LF);
   }
}

static void PositionBaseWindow()
{
   wid := p_window_id;
   p_window_id=ctlbase;
   // Need to use old line numbers here, but the old line number stuff
   // does not currently support RLines, or I am missing something.

   p_window_id=ctlrev1;
   // Have to move the cursor.  We are most likely at the top of a conflict,
   // and there will be no old line info for that.
   up();

   if (p_window_id==ctlrev1) {
      if ( gMergeLineMatches.rev1[p_RLine]!=null && !(_lineflags()&NOSAVE_LF) ) {
         ctlbase._GoToOldLineNumber(gMergeLineMatches.rev1[p_RLine].base);
      }
   }else if (p_window_id==ctlrev2) {
      if ( gMergeLineMatches.rev2[p_RLine]!=null && !(_lineflags()&NOSAVE_LF) ) {
         ctlbase._GoToOldLineNumber(gMergeLineMatches.rev2[p_RLine].base);
      }
   }else if (p_window_id==ctloutput) {
      if ( gMergeLineMatches.output[p_RLine]!=null && !(_lineflags()&NOSAVE_LF) ) {
         ctlbase._GoToOldLineNumber(gMergeLineMatches.output[p_RLine].base);
      }
   }
   ctlbase.down();
   p_window_id=ctlrev1;
   down();
   p_window_id=wid;
}

static void PositionOtherWindows()
{
   OtherRevSet := false;
   int cur_line_flags=_lineflags();
   orig_output_line := ctloutput.p_line;

   if (p_window_id==ctlbase) {
      // Need to use old line numbers here, but the old line number stuff
      // does not currently support RLines, or I am missing something.

      if ( gMergeLineMatches.base[p_RLine]!=null && !(cur_line_flags&NOSAVE_LF) ) {
         ctlrev1._GoToOldLineNumber(gMergeLineMatches.base[p_RLine].rev1);
         ctlrev2._GoToOldLineNumber(gMergeLineMatches.base[p_RLine].rev2);
         ctloutput._GoToOldLineNumber(gMergeLineMatches.base[p_RLine].output);
      }
   }else if (p_window_id==ctlrev1) {
      if ( gMergeLineMatches.rev1[p_RLine]!=null && !(cur_line_flags&NOSAVE_LF) ) {
         ctlrev2.p_line=ctlrev1.p_line;
         ctlbase._GoToOldLineNumber(gMergeLineMatches.rev1[p_RLine].base);
         ctloutput._GoToOldLineNumber(gMergeLineMatches.rev1[p_RLine].output);
         OtherRevSet=true;
      }else if (cur_line_flags&NOSAVE_LF) {
         ctlrev2.p_line=ctlrev1.p_line;
      }
   }else if (p_window_id==ctlrev2) {
      if ( gMergeLineMatches.rev2[p_RLine]!=null && !(_lineflags()&NOSAVE_LF) ) {
         ctlrev1.p_line=ctlrev2.p_line;
         ctlbase._GoToOldLineNumber(gMergeLineMatches.rev2[p_RLine].base);
         ctloutput._GoToOldLineNumber(gMergeLineMatches.rev2[p_RLine].output);
         OtherRevSet=true;
      }else if (cur_line_flags&NOSAVE_LF) {
         ctlrev1.p_line=ctlrev2.p_line;
      }
   }else if (p_window_id==ctloutput) {

      if (!(cur_line_flags&INSERTED_LINE_LF)) {
         old_line := p_RLine;
         save_pos(auto p);
         orig_line := p_RLine;
         _GoToOldLineNumber(p_RLine);
         old_line=p_RLine;
         restore_pos(p);

         int diff=old_line-p_RLine;
         int output_line=p_RLine-diff;
         if ( gMergeLineMatches.output[output_line]!=null && !(cur_line_flags&NOSAVE_LF) ) {
            ctlbase._GoToOldLineNumber(gMergeLineMatches.output[output_line].base);
            ctlrev1._GoToOldLineNumber(gMergeLineMatches.output[output_line].rev1);
            ctlrev2._GoToOldLineNumber(gMergeLineMatches.output[output_line].rev2);
         }
      }
   }

   if (!OtherRevSet) {
      if (p_window_id==ctlrev1) {
         ctlrev2.p_line=ctlrev1.p_line;
      }else if (p_window_id==ctlrev2) {
         ctlrev1.p_line=ctlrev2.p_line;
      }
   }

   AdjustOutput := (orig_output_line!=ctloutput.p_line);
   AdjustOtherScrollPositions(AdjustOutput);
}

static void PlaceBase(int LineNumberToFind,int (&BaseLineMatches):[])
{
   if (BaseLineMatches._indexin(LineNumberToFind)) {
      ctlbase.p_RLine=BaseLineMatches:[LineNumberToFind];
   }
}

static int GetRevConflictNumber(int wid=p_window_id,int &LineNumber=0,int &NumLines=0)
{
   MERGE_PIC_INFO PicIndexes[]=_GetDialogInfoHt('PicIndexes');
   len := PicIndexes._length();
   int i;
   int rln,ln,noflines,bufid,bufname,bmindex,type,markid,roffset,col;
   _str msg,linedata;
   for (i=1;i<len;++i) {
      LineMarkerIndex := -1;
      if (wid==ctlrev1) {
         LineMarkerIndex=PicIndexes[i].Rev1;
      }else if (wid==ctlrev2) {
         LineMarkerIndex=PicIndexes[i].Rev2;
      }else if (wid==ctloutput) {
         LineMarkerIndex=PicIndexes[i].Output;
      }
      VSLINEMARKERINFO info;
      _LineMarkerGet(LineMarkerIndex,info);
      LineNumber=info.LineNum;NumLines=info.NofLines;
      if (wid.p_buf_id==info.buf_id &&
          wid.p_line>=LineNumber && wid.p_line<LineNumber+NumLines) {
         return(i);
      }
   }
   return(0);
}

static void _merge_docharkey()
{
   _str key=last_event();
   _str cmdname=name_name(eventtab_index(p_mode_eventtab,p_mode_eventtab,event2index(key)));
   if (cmdname!='') {
      index := find_index(cmdname,COMMAND_TYPE);
      if (index && index_callable(index)) {
         call_index(index);
      }
   }else{
      keyin(key);
   }
}

int ctloutput.\33-'range-last-char-key'()
{
   if (ctloutput.p_readonly_mode) {
      _message_box(nls("Command not allowed in Read Only mode"));
      return(1);
   }
   //We are not in a Version Control Merge
   if ((!select_active() ||
       ( _select_type('','U')=='P' && _select_type('','S')=='E' ))
       ) {
      //!_within_char_selection keeps us from deleting selections created
      //by word completion
      _merge_docharkey();
   }else{
      if (!_within_char_selection() ) {
         deselect();
         _merge_docharkey();
      }
   }
   return(0);
}
//void ctloutput.\0-\32,\129-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
void ctloutput.'range-first-nonchar-key'-'all-range-last-nonchar-key',' ', 'range-first-mouse-event'-'all-range-last-mouse-event',ON_SELECT()
{
   _str lastevent=last_event();
   if (lastevent==LBUTTON_DOWN) {
      mou_click();
      PositionOtherWindows();
      mergeUpdateAllScrollThumbs();
      return;
   }
   _str eventname=event2name(lastevent);
   if (eventname=='ESC') {
      ctlclose.call_event(ctlclose,LBUTTON_UP);
      return;
   }
   if (eventname=='C-TAB') {
      p_window_id=ctlrev1;
      _set_focus();
      return;
   }else if (eventname=='C-S-TAB') {
      p_window_id=ctlrev2;
      _set_focus();
      return;
   }
   if ( eventname=='WHEEL-UP' ) {
      ctlvscrollOutput.decrementScroll();
      ctlvscrollRevisions.decrementScroll();
      return;
   }
   if ( eventname=='WHEEL-DOWN' ) {
      ctlvscrollOutput.incrementScroll();
      ctlvscrollRevisions.incrementScroll();
      return;
   }
   int key_index=event2index(lastevent);
   name_index := eventtab_index(_default_keys,ctloutput.p_mode_eventtab,key_index);
   kt_index := eventtab_index(_default_keys,ctloutput.p_mode_eventtab,key_index,'U');

   if (name_type(name_index)==EVENTTAB_TYPE) {
      kt_index=name_index;
      lastevent=get_event('k');
      key_index=event2index(lastevent);
      name_index=eventtab_index(kt_index,kt_index,key_index);
   }
   last_index(kt_index,'k');
   last_event(lastevent);

   command_name := name_name(name_index);
   if ( command_name!='' ) {
      if (select_active() &&
          ( command_name=='rubout'
            || command_name=='linewrap-rubout'
            || command_name=='delete-char'
            || command_name=='linewrap-delete-char'
            || command_name=='delete-line' )
          ) {
         delete_selection();
      }else{
         if (command_name=='undo' || command_name=='undo-cursor') {
            _message_box(nls("Undo not currently allowed in output"));
            return;
         }
         index := find_index(command_name,COMMAND_TYPE);
         if ( index && index_callable(index) ) {
            CMDUI cmdui;
            cmdui.menu_handle=0;
            cmdui.menu_pos=0;
            cmdui.inMenuBar=false;
            cmdui.button_wid=1;

            _OnUpdateInit(cmdui,p_window_id);

            cmdui.button_wid=0;

            int mfflags=_OnUpdate(cmdui,p_window_id,command_name);

            if (mfflags&MF_ENABLED) {
               if (select_active()) {
                  _on_select();
               } else {
                  call_index(index);
               }
            }else{
               // This code does not have any effect at right now because we
               // are not currently allowing undo.  We will for v8.01 though.
               if ( (command_name=='undo' || command_name=='undo-cursor') &&
                    _undo_status():==NOTHING_TO_UNDO_RC) {
                  _message_box(nls("%s",get_message(NOTHING_TO_UNDO_RC)));
               }else{
                  _message_box(nls("Command not currently allowed in output"));
               }
            }
         }
      }
   }
   PositionOtherWindows();

   if ( MovementCommands:[command_name]!=null ) {
      SetLeftEdges();
      mergeUpdateAllScrollThumbs();
   }

}

void ctlchoose_remove.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctloutput;
   int conflict_number;
   in_conflict := MergeInConflictRegion(conflict_number);
   if ( !in_conflict ) {
      return;
   }
   MERGE_PIC_INFO PicIndexes[]=_GetDialogInfoHt('PicIndexes');
   int output_line_number,output_num_lines;
   VSLINEMARKERINFO info;
   int status=_LineMarkerGet(PicIndexes[conflict_number].Output,info);
   output_line_number=info.LineNum;
   output_num_lines=info.NofLines;
   if (output_num_lines) {
      int markid=_alloc_selection();
      typeless p;
      _save_pos2(p);
      p_line=output_line_number;
      _select_line(markid);
      down(output_num_lines-1);
      _select_line(markid);
      _delete_selection(markid);
      _restore_pos2(p);
      _free_selection(markid);
   }
   p_window_id=wid;
}

/**
 * ctloutput must be active when calling this function
 */
static void CopyConflictFromFile(int FileNum)
{
   srcwid := -1;
   if ( FileNum==1 ) {
      srcwid=ctlrev1;
   } else if ( FileNum==2 ) {
      srcwid=ctlrev2;
   }
   int list[];
   _str LineOffset;
   parse point() with LineOffset .;
   _LineMarkerFindList(list,p_window_id,p_line,(long)LineOffset,true);
   if (list!=null) {
      MERGE_PIC_INFO PicIndexes[]=_GetDialogInfoHt('PicIndexes');
      len := PicIndexes._length();
      int i;
      for (i=1;i<len;++i) {
         if (PicIndexes[i].Output == list[0]) break;
      }
      if (i<len) {
         VSLINEMARKERINFO info;
         _LineMarkerGet(PicIndexes[i].Output,info);
         int output_line_number=info.LineNum;
         int output_num_lines=info.NofLines;

         // Delete what is there
         p_line=output_line_number;
         int my_markid=_alloc_selection();
         _select_line(my_markid);
         down(output_num_lines);
         _select_line(my_markid);
         _delete_selection(my_markid);

         // copy in the new stuff
         wid := p_window_id;
         p_window_id=srcwid;
         _LineMarkerGet(srcwid.GetPicIndex(PicIndexes[i]),info);
         int srcwid_line_number=info.LineNum;
         int srcwid_num_lines=info.NofLines;
         p_line=srcwid_line_number;
         _select_line(my_markid);
         down(srcwid_num_lines);
         _select_line(my_markid);
         wid.up();
         wid._copy_to_cursor(my_markid);
         p_window_id=wid;

         _free_selection(my_markid);
      }
   }
}

/**
 * Source window must be active.
 *
 * IF A MARKID IS RETURNED, THE CALLER IS RESPONSIBLE FOR FREEING IT.
 *
 * @param conflict_num
 *               number of conflict 1..n
 *
 * @return markid if sucessful.  Negative error code otherwise
 */
static int MergeSelectConflict(int conflict_num)
{
   int status=MergeFindConflict(conflict_num);
   if ( status ) {
      return(status);
   }
   int markid=_alloc_selection();
   _select_line(markid);
   MergeFindEndOfConflict();
   status=_select_line(markid);
   if ( status ) {
      clear_message();
   }
   return(markid);
}

static int MergeFindConflict(int conflict_num)
{
   int line_number;
   MERGE_PIC_INFO PicIndexes[]=_GetDialogInfoHt('PicIndexes');
   VSLINEMARKERINFO info;
   int status=_LineMarkerGet(GetPicIndex(PicIndexes[conflict_num]),info);
   line_number=info.LineNum;
   if (!status) {
      MergeDeselectInAll();
      // 7:13:25 PM 2/11/2003
      // Have to use real line number here, because sometmes the start of the conflict
      // could be a nosave line
      p_line=line_number;
      center_line();
   }
   PositionBaseWindow();
   return(0);
}

static int MergeFindNextConflict(_str direction='',int &ConflictFound=-1,
                                 bool quiet=false)
{
   MERGE_PIC_INFO PicIndexes[]=_GetDialogInfoHt('PicIndexes');
   int i,len=PicIndexes._length();
   rev_line_number := -1;
   if (direction=='-') {
      for (i=len-1;i>0;--i) {
         pic_index := GetPicIndex(PicIndexes[i]);

         VSLINEMARKERINFO info;
         _LineMarkerGet(pic_index,info);
         rev_line_number=info.LineNum;
         if (rev_line_number<p_line) {
            break;
         }
      }
   }else{
      for (i=1;i<len;++i) {
         pic_index := GetPicIndex(PicIndexes[i]);

         VSLINEMARKERINFO info;
         _LineMarkerGet(pic_index,info);
         rev_line_number=info.LineNum;
         if (rev_line_number>p_line) {
            break;
         }
      }
   }
   if (rev_line_number>-1) {
      MergeDeselectInAll();
      // 7:13:25 PM 2/11/2003
      // Have to use real line number here, because sometmes the start of the conflict
      // could be a nosave line
      p_line=rev_line_number;
   }
   found := !(i>=len || i<1);
   if (p_line==p_Noflines && rev_line_number>p_Noflines) {
      found=false;
   }
   if (found) {
      ConflictFound=i;
      center_line();
   }else if (!quiet) {
      _message_box(get_message(VSDIFF_NO_MORE_CONFLICTS_RC));
   }
   PositionBaseWindow();
   return((int)(!found));
}

static void MergeDeselectInAll()
{
   ctlbase.deselect();
   ctlrev1.deselect();
   ctlrev2.deselect();
   ctloutput.deselect();
}

static void MergeFindEndOfConflict()
{
   // Ok to use p_line here because we know the whole
   // file has been loaded
   start_line := p_line;
   while ( !down() ) {
      int flags=_lineflags();
      if ( !(flags&(NOSAVE_LF|MODIFY_LF)) ) {
         up();
         break;
      }
   }
}

static int MergeGetConflictNumber()
{
   wid := p_window_id;
   p_window_id=ctloutput;
   save_pos(auto p);
   int status=search('^(Conflict)','@-rcv');
   if ( status ) {
      restore_pos(p);
      p_window_id=wid;
      return(-1);
   }
   get_line(auto line);
   restore_pos(p);
   p_window_id=wid;
   _str conflict_num;
   parse line with 'Conflict' conflict_num;
   return((int)conflict_num);
}

void ctlchoose_rev1.lbutton_up()
{
   ChooseButton();
}

void ctlchoose_rev2.lbutton_up()
{
   ChooseButton();
}

void ctlchoose_rev1_next.lbutton_up()
{
   ChooseButton();
   get_default_editorctl_wid().MergeMoveAllToNextConflict();
}

void ctlchoose_rev2_next.lbutton_up()
{
   ChooseButton();
   get_default_editorctl_wid().MergeMoveAllToNextConflict();
}

static void ChooseButton()
{
   int conflict_number;
   srcwid := -1;
   if (p_window_id==ctlchoose_rev1 || p_window_id==ctlchoose_rev1_next) {
      srcwid=ctlrev1;
   }else if (p_window_id==ctlchoose_rev2 || p_window_id==ctlchoose_rev2_next) {
      srcwid=ctlrev2;
   }
   in_conflict := srcwid.MergeInConflictRegion(conflict_number);
   if ( !in_conflict ) {
      return;
   }
   srcwid.CopyConflictToOutput(conflict_number,false);
}

static int get_default_editorctl_wid()
{
   wid := _get_focus();
   if ( wid!=ctlrev1 && wid!=ctlrev2 && wid!=ctloutput ) {
      wid=ctlrev1;
   }
   return(wid);
}
void ctlnext_conflict.lbutton_up()
{
   get_default_editorctl_wid().MergeMoveAllToNextConflict();
}

void ctlprev_conflict.lbutton_up()
{
   get_default_editorctl_wid().MergeMoveAllToNextConflict('-');
}

void ctlfirst_conflict.lbutton_up()
{
   get_default_editorctl_wid().MergeMoveAllToNextConflict('',true,1);
}

void ctllast_conflict.lbutton_up()
{
   wid := get_default_editorctl_wid();
   cur_conflict_num := last_conflict_num := 0;
   while ( !wid.MergeFindNextConflict('',cur_conflict_num,true) ) {
      last_conflict_num=cur_conflict_num;
   }
   if ( last_conflict_num ) {
      wid.MergeMoveAllToNextConflict('',true,last_conflict_num);
   }
}

void ctlsave.lbutton_up()
{
   MaybeSaveOutputFile(true);
}

/**
 * Moves current line to next conflict in all windows.
 *
 * If for some reason the current lines were different,
 * it will move everything to the next conflict in the
 * current window.
 *
 * @param direction if "-", finds the previous conflict
 */
static int MergeMoveAllToNextConflict(_str direction='',bool quiet=false,int ConflictNumber=0)
{
   int wid=_get_focus(),other_wid1,other_wid2;
   if ( wid==ctlrev1 ) {
      other_wid1=ctlrev2;
      other_wid2=ctloutput;
   } else if ( wid==ctlrev2 ) {
      other_wid1=ctlrev1;
      other_wid2=ctloutput;
   } else if ( wid==ctloutput ) {
      other_wid1=ctlrev1;
      other_wid2=ctlrev2;
   } else {
      wid=ctlrev1;
      other_wid1=ctlrev2;
      other_wid2=ctloutput;
   }
   status := 0;
   if ( !ConflictNumber ) {
      status=wid.MergeFindNextConflict(direction,ConflictNumber,quiet);
   } else {
      status=wid.MergeFindConflict(ConflictNumber);
   }
   if ( !status ) {
      other_wid1.MergeFindConflict(ConflictNumber);
      other_wid2.MergeFindConflict(ConflictNumber);
   }
   AdjustOtherScrollPositions();

   p_scroll_left_edge=-1;
   p_window_id=other_wid1;
   p_scroll_left_edge=-1;
   p_window_id=other_wid2;
   p_scroll_left_edge=-1;
   p_window_id=wid;

   mergeUpdateAllScrollThumbs();
   return(status);
}

/**
 * This function is run when you popup the rclick menu in one of the revision files
 * in the merge.  It copies the current conflict from one or both revisions to the
 * output.
 *
 * @param FromRevisionList
 *               List of revisions to copy from to output
 */
_command void merge_copy_conflict(_str FromRevisionList='') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (p_active_form.p_name!='_merge_form') {
      return;
   }
   int conflict_number;
   // Can just choose ctlrev1 here because we know that the conflict regions
   // are adjacent and symetrical.
   in_conflict := ctlrev1.MergeInConflictRegion(conflict_number);
   if ( !in_conflict ) {
      return;
   }
   first_interation := true;
   for (;;first_interation=false) {
      _str cur;
      parse FromRevisionList with cur FromRevisionList;
      if (cur=='') break;
      if (cur=='1') {
         ctlrev1.CopyConflictToOutput(conflict_number,first_interation);
      }else if (cur=='2') {
         ctlrev2.CopyConflictToOutput(conflict_number,first_interation);
      }
   }
}

void _on_popup_merge(_str menu_name,int menu_handle)
{
   wid := _get_focus();
   if (!wid || wid.p_active_form.p_name!='_merge_form') {
      return;
   }
   if (wid.p_name!='ctlrev1' && wid.p_name!='ctlrev2') {
      return;
   }
   if (MergeInConflictRegion()) {
      // Insert in reverse order
      _menu_insert(menu_handle,0,MF_ENABLED,'-');
      _menu_insert(menu_handle,0,MF_ENABLED,"Copy From Both Revisions to Output","merge-copy-conflict 1 2");
      _menu_insert(menu_handle,0,MF_ENABLED,"Copy From Revision 2 to Output","merge-copy-conflict 2");
      _menu_insert(menu_handle,0,MF_ENABLED,"Copy From Revision 1 to Output","merge-copy-conflict 1");
   }
   int submenu_handle,submenu_pos;
   int status=_menu_find(menu_handle,'version-control',submenu_handle,submenu_pos,'C');
   if (!status) {
      _menu_delete(submenu_handle,submenu_pos);
      if (submenu_pos<_menu_info(menu_handle)) {
         int mf_flags;
         _str caption;
         _menu_get_state(menu_handle,submenu_pos,mf_flags,'P',caption);
         if (caption=='-') {
            _menu_delete(menu_handle,submenu_pos);
         }
      }
   }
}

void _on_close_popup_merge()
{
   if (p_active_form.p_name!='_merge_form') {
      return;
   }
   PositionOtherWindows();
}
