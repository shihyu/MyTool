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
#include "minihtml.sh"
#import "diff.e"
#import "difftags.e"
#import "files.e"
#import "listbox.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#endregion

defeventtab _diff_insert_symbol_form;

static _str gDiffInsertSymbolValidCommands:[] = {
    "list-symbols"           => 1
   ,"function-argument-help" => 1
   ,"gui-find"               => 1
   ,"find-next"              => 1
   ,"find-prev"              => 1
   ,"end-line"               => 1
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
   ,"undo"                   => 1
   ,"next-window"            => 1
   ,"undo-cursor"            => 1
};

struct DIFF_INSERT_SYMBOL_INFO {
   struct {
      _str Filename;
      _str NewFilename;
      int bufid,markid;
      boolean inmem;
      int symbolviewid,wid;
      boolean readonly,modify;
   }SourceInfo;
   struct {
      _str Filename;
      int bufid,inmem,wid;
      boolean modify;
   }DestInfo;
};

#define gSymInfo     ctledit1.p_user
#define gFlip        ctledit2.p_user
#define gOldFlags    ctllabel1.p_user

#define FUNCTION_PLACMENT_INDICATOR '********* Symbol Goes Here *********'

int ctlok.lbutton_up()
{
   DIFF_INSERT_SYMBOL_INFO syminfo;
   syminfo=gSymInfo;

   int status=prompt_for_save(nls("Save changes to '%s'?",syminfo.DestInfo.Filename),'',false);
   boolean saved=false;
   if (status==IDYES) {
      //Copy the symbol in...
      int wid=p_window_id;
      p_window_id=ctledit1;
      int markid=_alloc_selection();
      top();
      _select_line(markid);
      bottom();
      status=_select_line(markid);
      if (status) {
         clear_message();
      }
      _control ctledit2;
      p_window_id=ctledit2;
      int line=p_line;
      _copy_to_cursor(markid);
      _free_selection(markid);
      p_line=line;
      _delete_line();
      p_AllowSave=true;
      status=save();
      if (!status) {
         int tree1=syminfo.SourceInfo.wid,
             tree2=syminfo.DestInfo.wid;
         if (tree1.p_name!='tree1') {
            tree1.p_parent._DiffExpandTags2(syminfo.DestInfo.bufid,
                                            syminfo.SourceInfo.bufid,
                                            tree1._TreeGetParentIndex(tree1._TreeCurIndex()),
                                            tree2._TreeGetParentIndex(tree2._TreeCurIndex()),
                                            '+bi','+bi');
         }else{
            tree1.p_parent._DiffExpandTags2(syminfo.SourceInfo.bufid,
                                            syminfo.DestInfo.bufid,
                                            tree1._TreeGetParentIndex(tree1._TreeCurIndex()),
                                            tree2._TreeGetParentIndex(tree2._TreeCurIndex()),
                                            '+bi','+bi');
         }
      }
      p_window_id=wid;
      saved=true;
   }

   int linenum=ctledit2.p_line;
   p_active_form._delete_window(linenum);
   return(linenum);
}

void _diff_insert_symbol_form.on_load()
{
   if (gFlip) {
      ctledit2._set_focus();
   }else{
      ctledit1._set_focus();
   }
}

int ctlok.on_create(_str Filename,_str SymbolName,int StartLine,int EndLine,
                    _str DestFilename,boolean Flip,int SourceTreeWID,int DestTreeWid,
                    int InitDestLine=-1)
{
   if (Flip) {
      int temp=ctledit2.p_x;
      ctledit2.p_x=ctledit1.p_x;
      ctledit1.p_x=temp;
      gFlip=1;
   }
   p_active_form.p_caption='Insert 'SymbolName' into 'DestFilename;
   ctllabel1.p_caption=SymbolName' ('Filename')';
   ctllabel2.p_caption=DestFilename;

   DIFF_INSERT_SYMBOL_INFO syminfo;
   int status=_DiffLoadFileAndGetRegionView(Filename,false,false,StartLine,EndLine,
                                            false,
                                            syminfo.SourceInfo.NewFilename,
                                            syminfo.SourceInfo.bufid,
                                            syminfo.SourceInfo.markid,
                                            syminfo.SourceInfo.inmem,
                                            syminfo.SourceInfo.symbolviewid,
                                            syminfo.SourceInfo.readonly,
                                            syminfo.SourceInfo.modify);

   if (status) {
      return(status);
   }
   ctledit1._delete_buffer();
   ctledit2._delete_buffer();

   syminfo.SourceInfo.Filename=Filename;
   syminfo.DestInfo.Filename=DestFilename;
   ctledit1.load_files('+bi 'syminfo.SourceInfo.NewFilename);

   int wid=p_window_id;
   _control ctledit2;
   p_window_id=ctledit2;
   syminfo.DestInfo.inmem=1;
   status=load_files('+q +b 'DestFilename);
   if (status) {
      syminfo.DestInfo.inmem=0;
      status=load_files('+q 'maybe_quote_filename(DestFilename));
      if (status) {
         _message_box(nls("Could not load file '%s'",DestFilename));
         p_active_form._delete_window(status);
         return(status);
      }
      _SetEditorLanguage();
   }
   _BlastUndoInfo();
   gOldFlags=p_color_flags;
   p_color_flags|=MODIFY_COLOR_FLAG;
   syminfo.DestInfo.modify=p_modify;
   syminfo.DestInfo.bufid=p_buf_id;
   top();up();
   boolean gOldReadOnly=p_readonly_mode;
   if (InitDestLine>-1) {
      ctledit2.p_line=InitDestLine;
   }
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
   p_window_id=wid;

   syminfo.SourceInfo.wid=SourceTreeWID;
   syminfo.DestInfo.wid=DestTreeWid;

   gSymInfo=syminfo;
   return(0);
}

void ctlok.on_destroy()
{
   DIFF_INSERT_SYMBOL_INFO syminfo;
   syminfo=gSymInfo;

   ctledit1._delete_buffer();
   int orig_view_id=p_window_id;
   p_window_id=VSWID_HIDDEN;
   _begin_select(syminfo.SourceInfo.markid);
   if (!syminfo.SourceInfo.inmem) {
      _free_selection(syminfo.SourceInfo.markid);
      _delete_buffer();
   }else{
      p_readonly_mode=syminfo.SourceInfo.readonly;
      _free_selection(syminfo.SourceInfo.markid);
      p_modify=syminfo.SourceInfo.modify;
   }
   p_window_id=orig_view_id;
   p_window_id=syminfo.SourceInfo.symbolviewid;
   _delete_window();
   p_window_id=orig_view_id;
   int wid=p_window_id;
   p_window_id=ctledit2;

   if (!syminfo.DestInfo.inmem) {
      _delete_buffer();
   }else{
      _str line='';
      get_line(line);
      if (line==FUNCTION_PLACMENT_INDICATOR) {
          _delete_line();
         p_modify=syminfo.DestInfo.modify;
      }
      p_color_flags=gOldFlags;
      _BlastUndoInfo();
   }
   p_window_id=wid;
}

int _DiffInsertSymbol(_str Filename,_str SymbolName,int StartLine,int EndLine,
                      _str DestFilename,int SourceTreeWID,int DestTreeWID,boolean flip=false,
                      int InitDestLine=-1)
{
   int status=show('-modal _diff_insert_symbol_form',Filename,SymbolName,StartLine,EndLine,DestFilename,flip,SourceTreeWID,DestTreeWID,InitDestLine);
   return(status);
}

static void diffsym_up()
{
   _delete_line();
   up();up();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(0,INSERTED_LINE_LF);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}

static void diffsym_down()
{
   _delete_line();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}

static void diffsym_pageup()
{
   _delete_line();
   up();
   page_up();
   up();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(0,INSERTED_LINE_LF);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}

static void diffsym_pagedown()
{
   _delete_line();
   up();
   page_down();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}

static void diffsym_next_proc()
{
   _delete_line();
   next_proc();
   up();
   center_line();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}

static void diffsym_prev_proc()
{
   _delete_line();
   up();
   prev_proc();
   up();
   center_line();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}

static void diffsym_next_tag()
{
   _delete_line();
   next_tag();
   up();
   center_line();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}

static void diffsym_prev_tag()
{
   _delete_line();
   up();
   prev_tag();
   up();
   center_line();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}

static void diffsym_top_of_buffer()
{
   _delete_line();
   top();up();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(0,INSERTED_LINE_LF);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}

static void diffsym_bottom_of_buffer()
{
   _delete_line();
   bottom();
   insert_line(FUNCTION_PLACMENT_INDICATOR);
   _lineflags(MODIFY_LF,INSERTED_LINE_LF|MODIFY_LF);
}


static void DestEditControlEventHandler1()
{
   typeless lastevent=last_event();
   _str eventname=event2name(lastevent);
   int key_index=event2index(lastevent);
   int name_index=eventtab_index(_default_keys,ctledit1.p_mode_eventtab,key_index);
   _str command_name=name_name(name_index);

   //This is to handle C-X combinations
   if (name_type(name_index)==EVENTTAB_TYPE) {
      int eventtab_index2=name_index;
      typeless event2=get_event('k');
      key_index=event2index(event2);
      name_index=eventtab_index(_default_keys,eventtab_index2,key_index);
      command_name=name_name(name_index);
   }

   switch (eventname) {
   case 'TAB':
      p_next._set_focus();
      break;
   case 'ESC':
      p_active_form._delete_window('');
      return;
   case 'A-F4':
      p_active_form._delete_window('');
      return;
   }
   if (gDiffInsertSymbolValidCommands._indexin(command_name)) {
      int index=find_index(command_name,COMMAND_TYPE);
      if (index_callable(index)) {
         call_index(index);
      }
   }
}

ctledit1.\0-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
{
   DestEditControlEventHandler1();
}

static void DestEditControlEventHandler2()
{
   typeless lastevent=last_event();
   _str eventname=event2name(lastevent);
   int key_index=event2index(lastevent);
   int name_index=eventtab_index(_default_keys,ctledit1.p_mode_eventtab,key_index);
   _str command_name=name_name(name_index);

   //This is to handle C-X combinations
   if (name_type(name_index)==EVENTTAB_TYPE) {
      int eventtab_index2=name_index;
      typeless event2=get_event('k');
      key_index=event2index(event2);
      name_index=eventtab_index(_default_keys,eventtab_index2,key_index);
      command_name=name_name(name_index);
   }

   switch (eventname) {
   case 'TAB':
      p_next._set_focus();
      break;
   case 'ESC':
      p_active_form._delete_window('');
      return;
   case 'A-F4':
      p_active_form._delete_window('');
      return;
   case 'ENTER':
      ctlok.call_event(ctlok,LBUTTON_UP);
      return;
   }
   switch (command_name) {
   case 'cursor-up':
      diffsym_up();
      break;
   case 'cursor-down':
      diffsym_down();
      break;

   case 'page-up':
      diffsym_pageup();
      break;
   case 'page-down':
      diffsym_pagedown();
      break;

   case 'next-proc':
      diffsym_next_proc();
      break;
   case 'next-tag':
      diffsym_next_tag();
      break;

   case 'prev-proc':
      diffsym_prev_proc();
      break;
   case 'prev-tag':
      diffsym_prev_tag();
      break;

   case 'begin-line':
      begin_line();
      break;

   case 'end-line':
      end_line();
      break;

   case 'begin-line-text-toggle':
      begin_line();
      break;

   case 'bottom-of-buffer':
      diffsym_bottom_of_buffer();
      break;

   case 'top-of-buffer':
      diffsym_top_of_buffer();
      break;

   }
}

ctledit2.\0-MBUTTON_UP,'S-LBUTTON-DOWN'-ON_SELECT()
{
   DestEditControlEventHandler2();
}

void _diff_insert_symbol_form.on_resize()
{
   int xbuffer=0;
   if (gFlip==1) {
      xbuffer=ctledit2.p_x;
   }else{
      xbuffer=ctledit1.p_x;
   }
   int xbufferd2=xbuffer intdiv 2;
   int cilent_width=_dx2lx(SM_TWIP,p_client_width);
   if (gFlip==1) {
      ctledit1.p_x=ctledit2.p_x+ctledit2.p_width+xbufferd2;
   }else{
      ctledit2.p_x=ctledit1.p_x+ctledit1.p_width+xbufferd2;
   }
   ctledit1.p_width=ctledit2.p_width=(cilent_width intdiv 2)-(xbuffer+xbufferd2);

   int ybuffer=ctllabel1.p_y;
   int ybufferd2=ybuffer intdiv 2;
   int cilent_height=_dy2ly(SM_TWIP,p_client_height);
   ctledit2.p_height=ctledit1.p_height=cilent_height-(ctlok.p_height+ctledit1.p_y+(ybuffer*2));
   ctlok.p_y=ctlok.p_next.p_y=ctledit1.p_y+ctledit1.p_height+ybuffer;
   ctllabel2.p_x=ctledit2.p_x;
}

defeventtab _diff_delete_symbol_form;

ctlminihtml1.on_create(_str CommentDescriptions[],_str LineRange)
{
   p_backcolor=0x80000022;
   _str DashRange=stranslate(LineRange,'-',',');
   ctlcomment.p_caption='Comment out lines 'DashRange' with:';
   ctldelete.p_caption='Delete lines 'DashRange;
   if (!CommentDescriptions._length()) {
      p_text=nls('There are no line comments defined for this extension.<P>SlickEdit can only delete this symbol by actually deleting the lines from the file.<P>This operation cannot be undone.');
      ctlcomment.p_enabled=ctlcomment_list.p_enabled=0;
      ctldelete.p_value=1;
   }else{
      int i=0;
      p_text=nls('For safety, we recommend that you choose a line comment type to initially remove this symbol from the file.<P>If you choose to delete the lines from the file, it cannot be undone.');
      int wid=p_window_id;
      p_window_id=ctlcomment_list;
      for (i=0;i<CommentDescriptions._length();++i) {
         _lbadd_item(CommentDescriptions[i]);
      }
      _lbtop();
      p_window_id=wid;
      ctlcomment_list.p_text=ctlcomment_list._lbget_text();
      if (ctlcomment_list.p_Noflines==1) {
         //If there is only one to choose from, do not give the user a choice
         ctlcomment_list.p_visible=0;
         int ShrinkSize=(ctlcomment_list.p_y+ctlcomment_list.p_height)-(ctlcomment.p_y+ctlcomment.p_height);
         ctldelete.p_y-=ShrinkSize;
         ctlok.p_y-=ShrinkSize;
         ctlok.p_next.p_y-=ShrinkSize;
         p_active_form.p_height-=ShrinkSize;
         _str newcap='';
         parse ctlcomment.p_caption with newcap ' with:';
         ctlcomment.p_caption=newcap;
      }
      ctlcomment.p_value=1;
   }
}

int ctlok.lbutton_up()
{
   if (ctlcomment.p_value) {
      _param1=ctlcomment_list.p_line;
   }else{
      _param1=-1;
   }
   p_active_form._delete_window(0);
   return(0);
}
