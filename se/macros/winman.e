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
#include "listbox.sh"
#import "listbox.e"
#import "main.e"
#import "stdprocs.e"
#endregion

defeventtab _unixwinman_form;

//P_USER variables that I use:
//
// _ctlok.p_user is the view id of the rc file.
// p_active_form.p_user is the view id of the window manager(not used much)
//

//If succesful returns 0, and sets Filename to whole name with path etc.
static int CopyResourceFile(_str HomeDir,_str &Filename)
{
   typeless status=0;
   _maybe_strip_filesep(HomeDir);
   ExistingFilename := file_match(HomeDir:+FILESEP:+Filename' -p',1);
   if (ExistingFilename=='') {
      _message_box(nls("You do not have '%s' file in your home directory.  \n\nSlickEdit will attempt to copy the system one for you.",Filename));
      if (_isUnix()) {
         switch (Filename) {
         case '.fvwmrc':
            rfilename := '/usr/lib/X11/fvwm/system'Filename;
            if (file_match("-p "rfilename,1)!="") {
               status=copy_file(rfilename,HomeDir:+FILESEP:+Filename);
            } else {
               status=copy_file('/etc/X11/fvwm/system'Filename,HomeDir:+FILESEP:+Filename);
            }
            break;
         case '.mwmrc':
            status=copy_file('/usr/lib/X11/system'Filename,HomeDir:+FILESEP:+Filename);
         }
      } else {
         switch (Filename) {
         case '.fvwmrc':
            status=copy_file('c:\usr\lib\X11\fvwm\system.fvw',HomeDir:+FILESEP:+Filename);
            break;
         case '.mwmrc':
            status=copy_file('c:\usr\lib\X11\system.mwm',HomeDir:+FILESEP:+Filename);
            break;
         }
      }
      if (status) {
         _message_box(nls("Could not copy %s",Filename));
         Filename='';
         return(status);
      }else{
         Filename=HomeDir:+FILESEP:+Filename;
      }
   }else{
      Filename=ExistingFilename;
   }
   return(0);
}

static int AttemptToSaveSystemFile(_str Filename)
{
   switch (Filename) {
   case '.mwmrc':
      if (_isUnix()) {
         Filename='/usr/lib/X11/system.mwmrc';
      } else {
         Filename='c:\usr\lib\X11\system.mwm';
      }
      break;
   case '.fvwmrc':
      if (_isUnix()) {
         Filename='/usr/lib/X11/fvwm/system.fvwmrc';
         if (file_match("-p "Filename,1)=="") {
            Filename='/etc/X11/fvwm/system.fvwmrc';
         }
      } else {
         Filename='c:\usr\lib\X11\fvwm\system.fvw';
      }
      break;
   }
   ViewId := 0;
   temp_view_id := 0;
   orig_view_id := 0;
   typeless status=_open_temp_view(Filename,temp_view_id,orig_view_id);
   if (status) {
      ViewId=0;Filename='';
      return(status);
   }
   ViewId=temp_view_id;
   p_window_id=temp_view_id;
   status=_save_file('+O');
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   if (status) clear_message();
   return(status);
}

//static typeless CopyGlobalResourceFile=0;

static int ResourceFilename(_str WindowManager,_str &Filename)
{
   if (_isUnix()) {
      Filename='.'WindowManager'rc';
      HomeDir := get_env('HOME');
      if (HomeDir=='/' || HomeDir=='/root') {
         typeless status=AttemptToSaveSystemFile(Filename);
         if (!status) {
            int result=_message_box(nls("You have write permissions for the default system file (%s)\n\n":+\
                                    "Do you wish to modifiy the default settings for all users?",
                                Filename),
                                '',
                                MB_YESNOCANCEL|MB_ICONQUESTION);
            if (result==IDYES) {
               //CopyGlobalResourceFile=1;
               switch (WindowManager) {
               case 'mwm':
                  Filename='/usr/lib/X11/system.mwmrc';
                  return(0);
               case 'fvwm':
                  Filename='/usr/lib/X11/fvwm/system.fvwmrc';
                  if (file_match("-p "Filename,1)=="") {
                     Filename='/etc/X11/fvwm/system.fvwmrc';
                  }
                  return(0);
               }
            }else if (result==IDNO) {
               //CopyGlobalResourceFile=0;
               CopyResourceFile(HomeDir,Filename);
               return(0);
            }else{
               return(COMMAND_CANCELLED_RC);
            }
         }else{
            //CopyGlobalResourceFile=0;
            CopyResourceFile(HomeDir,Filename);
            return(0);
         }
      }else{
         CopyResourceFile(HomeDir,Filename);
      }
      return(0);
   }
   Filename=WindowManager'rc';
   HomeDir := get_env('HOME');
   if (HomeDir=='') {
      set_env('HOME','/');
   }
   typeless status=0;
   typeless result=0;
   if (HomeDir=='\' || HomeDir=='c:\root') {
      status=AttemptToSaveSystemFile(Filename);
      if (!status) {
         result=_message_box(nls("You have write permissions for the default system file (%s)\n\n":+\
                                 "Do you wish to modifiy the default settings for all users?",
                             Filename),
                             '',
                             MB_YESNOCANCEL|MB_ICONQUESTION);
         if (result==IDYES) {
            //CopyGlobalResourceFile=1;
            switch (WindowManager) {
            case 'mwm':
               Filename='c:\usr\lib\X11\system.mwm';
               return(0);
            case 'fvwm':
               Filename='c:\usr\lib\X11\fvwm\system.fvw';
               return(0);
            }
         }else{
            //CopyGlobalResourceFile=0;
            CopyResourceFile(HomeDir,Filename);
            return(0);
         }
      }
   }else{
      CopyResourceFile(HomeDir,Filename);
   }
   return(0);
}

static void PrepListBox()
{                         //'Shift-Alt-Control-Right'
   //_col_width(0,_text_width('WWWWWWWWWWWWWWWWWWWWWWW')+200);
   _col_width(0,_text_width('Shift-Alt-Control-Right')+200);
                          //'Root Window|Title Bar|Frame|Any'
   //_col_width(1,_text_width('WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW')+200);
   _col_width(1,_text_width('Root Window|Title Bar|Frame|Any')+200);
   _col_width(-1,0);
}

//Check to see if there is a command that I can use to Restart the Window Manager
//Default for MOTIF is in "/usr/lib/X11/system.mwmrc
//Default for FVWM is in "/usr/lib/X11/fvwm/system.fvwmrc

static _str GetKeyName(_str ch, _str WindowManager)
{
   switch (lowcase(WindowManager)) {
   case 'fvwm':
      switch (ch) {
      case 'm':
      case 'M':
         return('Alt');
      case 's':
      case 'S':
         return('Shift');
      case 'c':
      case 'C':
         return('Control');
      }
      break;
   }
   return("");
}
static _str GetModifierKeyAbbreviation(_str KeyName, _str WindowManager)
{
   switch (lowcase(WindowManager)) {
   case 'fvwm':
      switch (lowcase(KeyName)) {
      case 'alt':
         return('M');
      case 'shift':
         return('S');
      case 'control':
         return('C');
      }
      break;
   case 'mwm':
      KeyName=strip(KeyName);
      return(KeyName);
   }
   return("");
}

static _str GetAreaName(_str ch,_str WindowManager)
{
   switch (lowcase(WindowManager)) {
   case 'fvwm':
      switch (lowcase(ch)) {
      case 'r':
         return('Root Window');
      case 't':
         return('Title Bar');
      case 'f':
         return('Frame');
      case 'a':
         return('Any');
      }
      break;
   }
   return("");
}
static _str GetAreaAbbreviation(_str AreaName, _str WindowManager)
{
   switch (lowcase(WindowManager)) {
   case 'fvwm':
      switch (lowcase(AreaName)) {
      case 'root window':
         return('R');
      case 'title bar':
         return('T');
      case 'frame':
         return('F');
      case 'any':
         return('A');
      }
      break;
   }
   return('');
}

static _str GetModifierKeyNames(_str ModStr,_str WindowManager)
{
   KeyNameStr := "";
   switch (lowcase(WindowManager)) {
   case 'fvwm':
      for (;;) {
         ch := substr(ModStr,1,1);
         if (ch=='') break;
         ModStr=substr(ModStr,2);
         if (KeyNameStr=='') {
            KeyNameStr=GetKeyName(ch,WindowManager);
         }else{
            KeyNameStr :+= '-'GetKeyName(ch,WindowManager);
         }
      }
      break;
   case 'mwm':
      KeyNameStr=strip(ModStr);
      KeyNameStr=stranslate(KeyNameStr,' ',"\t");
      while (pos('  ',KeyNameStr)) {
         KeyNameStr=stranslate(KeyNameStr,' ',"  ");
      }
      KeyNameStr=stranslate(KeyNameStr,'-'," ");
      //Now that the modifier names are in a regular format, be sure that they
      //are all real and that there aren't any menu mnemonics in here
      //This also gets rid of any garbage that might be in there because the line
      //was a doubled up menu line that is partially commented out.
      //Yes, its disgusting, but it seems to be _RELIABLE_.
      str := "";
      FinalStr := "";
      for (;;) {
         parse KeyNameStr with str '-' KeyNameStr;
         if (str=='') break;
         str=strip(str);
         if (pos(' 'str' ',' Alt Meta Extend Shift Ctrl ')) {
            if (FinalStr=='') {
               FinalStr=str;
            }else{
               FinalStr :+= '-'str;
            }
         }
      }
      KeyNameStr=FinalStr;
      break;
   }
   return(KeyNameStr);
}

static _str GetValidAreaNames(_str ValidAreaStr, _str WindowManager)
{
   ValidAreaNameStr := "";
   switch (lowcase(WindowManager)) {
   case 'fvwm':
      for (;;) {
         ch := substr(ValidAreaStr,1,1);
         if (ch=='') break;
         ValidAreaStr=substr(ValidAreaStr,2);
         if (ValidAreaNameStr=='') {
            ValidAreaNameStr=GetAreaName(ch,WindowManager);
         }else{
            ValidAreaNameStr :+= '|'GetAreaName(ch,WindowManager);
         }
      }
      break;
   case 'mwm':
      ValidAreaStr=strip(ValidAreaStr);
      ValidAreaStr=stranslate(ValidAreaStr,'',"\t");
      return(ValidAreaStr);
   }
   return(ValidAreaNameStr);
}

static bool IsValidKey( _str KeyName, _str WindowManager)
{
   KeyName=strip(KeyName);
   switch (lowcase(WindowManager)) {
   case 'fvwm':
   case 'mwm':
      if (pos('^(Left|Right|Up|Down)$',KeyName,'','ri')) return true;
      if (pos('^F:i$',KeyName,'','ri')) return true;
   }
   return(false);
}
static bool IsValidModifier( _str KeyName, _str WindowManager)
{
   KeyName=strip(KeyName);
   switch (lowcase(WindowManager)) {
   case 'mwm':
      if (pos('^(Alt|Ctrl|Shift)$',KeyName,'','ri')) return true;
   }
   return(false);
}

static int FVWMFillInListBoxes()
{
   Filename := "";
   int status=ResourceFilename('fvwm',Filename);
   if (status) return status;
   p_active_form.p_caption="Window Manager Resource File - "Filename;
   //status=SmartOpen(Filename,TempViewId,OrigViewId);
   TempViewId := 0;
   OrigViewId := 0;
   inmem := false;
   status=_open_temp_view(Filename,TempViewId,OrigViewId,'',inmem);
   if (status) {
      return(status);
   }
   if (!status) {
      top();up();
      string := '^( |\t)@(\#VS|)( |\t)@Key';
      while (!search(string,"@ri")) {
         _end_line();
         get_line(auto line);
         KeyName := ValidArea := Modifiers := Command := "";
         parse line with 'Key','i' KeyName ValidArea Modifiers Command;
         if (!IsValidKey(KeyName,'fvwm')) {
            p_window_id=TempViewId;
            continue;
         }
         KeyIsInactive := pos('#VS',line);
         p_window_id=OrigViewId;
         if (Command=='') {
            Command=Modifiers;
         }else{
            _str ModNameStr=GetModifierKeyNames(Modifiers,'fvwm');
            _str ValidAreaStr=GetValidAreaNames(ValidArea,'fvwm');
            if (ModNameStr!='') ModNameStr :+= '-';
            line=ModNameStr:+KeyName"\t"ValidAreaStr"\t"Command;
         }
         if (KeyIsInactive) {
            _ctlinactive_command_list._lbadd_item(line);
         }else{
            _ctlcommand_list._lbadd_item(line);
         }
         p_window_id=TempViewId;
      }
      p_window_id=OrigViewId;
      _ctlok.p_user=TempViewId' 'inmem;
   }else{
      _message_box(nls("Could not open file '%s'.\n\n%s",
                   Filename,
                   get_message(status)));
      p_active_form._delete_window();
      return(status);
   }
   return(0);
}

static int MWMFillInListBoxes()
{
   //Filename=MWMRCFilename();
   Filename := "";
   typeless status=ResourceFilename('mwm',Filename);
   if (status) return status;
   p_active_form.p_caption="Window Manager Resource File - "Filename;
   TempViewId := 0;
   OrigViewId := 0;
   inmem := false;
   status=_open_temp_view(Filename,TempViewId,OrigViewId,'',inmem);
   if (status) {
      return(status);
   }
   //status=SmartOpen(Filename,TempViewId,OrigViewId);
   if (!status) {
      top();up();
      //string='^( |\t)@(\!VS|)( |\t)@((Shift|Alt|Ctrl|)( |\t|))@<Key>'
      string := '((Shift|Meta|Extend|Alt|Ctrl|)( |\t|))@<Key>';
      //Since I have to look for key bindings inside menus as well, why waste
      //a lot of time doing a really specific search?(probably find out later!)
      while (!search(string,"@ri")) {
         _end_line();
         get_line(auto line);
         if (pos('!',line) && !pos('!VS',line,'','i')) {
            if (pos('!',line)<pos('~[ \t!]',line,'','r')) continue;
         }//Skip lines that start with comments
         Modifiers := KeyName := ValidArea := Command := "";
         parse line with Modifiers '<Key>','i' KeyName\
            ValidArea 'f.','i' +0 Command;
         if (pos('{\!VS}',Modifiers,'','ri')) {
            Modifiers=substr(Modifiers,pos('0')+1);
         }
         ValidArea=strip(ValidArea);
         if (!IsValidKey(KeyName,'mwm')) {
            p_window_id=TempViewId;
            continue;
         }
         KeyIsInactive := pos('!VS',line,'','i');
         p_window_id=OrigViewId;
         _str ModNameStr=GetModifierKeyNames(Modifiers,'mwm');
         _str ValidAreaStr=GetValidAreaNames(ValidArea,'mwm');
         if (ValidAreaStr=='') ValidAreaStr='Menu Key Binding'
         if (ModNameStr!='') ModNameStr :+= '-';
         //messageNwait('ModNameStr='ModNameStr' ValidAreaStr='ValidAreaStr' Command='Command);
         line=ModNameStr:+KeyName"\t"ValidAreaStr"\t"Command;
         if (KeyIsInactive) {
            _ctlinactive_command_list._lbadd_item(line);
         }else{
            p_window_id=OrigViewId;
            _ctlcommand_list._lbadd_item(line);
         }
         p_window_id=TempViewId;
      }
      p_window_id=OrigViewId;
      _ctlok.p_user=TempViewId' 'inmem;
   }else{
      _message_box(nls("Could not open file '%s'.\n\n%s",
                   Filename,
                   get_message(status)));
      p_active_form._delete_window();
      return(status);
   }
   return(0);
}

static void GetKeyNameAndModifiers(_str &KeyName, _str &Modifiers, _str WindowManager)
{
   Modifiers='';
   _str key=KeyName;
   for (;;) {
      KeyOrMod := "";
      parse key with KeyOrMod '-' key;
      if (!IsValidKey(KeyOrMod,WindowManager)) {
         _str ModStr=GetModifierKeyAbbreviation(KeyOrMod,WindowManager);
         switch (lowcase(WindowManager)) {
         case 'fvwm':
            Modifiers :+= ModStr;
            break;
         case 'mwm':
            if (Modifiers=='') {
               Modifiers=GetModifierKeyAbbreviation(KeyOrMod,WindowManager);
            }else{
               Modifiers :+= ' 'GetModifierKeyAbbreviation(KeyOrMod,WindowManager);
            }
            break;
         }
      }else{
         KeyName=KeyOrMod;
         break;
      }
   }
}

static _str GetValidAreas( _str ValidAreas, _str WindowManager)
{
   switch (lowcase(WindowManager)) {
   case 'fvwm':
      _str areas=ValidAreas;
      str := "";
      for (;;) {
         cur := "";
         parse areas with cur '|' areas;
         if (cur=='') break;
         str :+= GetAreaAbbreviation(ValidAreas,WindowManager);
      }
      return str;
   case 'mwm':
      return(strip(ValidAreas));
   }
   return '';
}

static _str GetMWMModifiersRE( _str Modifiers)
{
   Modifiers=strip(Modifiers);
   while (pos('  ',Modifiers)) {
      stranslate(Modifiers,' ','  ');
   }
   Modifiers=stranslate(Modifiers,'( |\t)@',' ');
   return(Modifiers);
}


static void MaybeChangeKey(_str KeyName,
                           _str Modifiers,
                           _str ValidAreas,
                           _str Command,
                           int RCFileViewId, 
                           _str WindowManager,
                           bool Activate)
{
   OrigViewId := 0;
   p := len := 0;
   str := "";
   line := "";
   _str OrigLine=0;
   newline := "";
   typeless status=0;

   switch (lowcase(WindowManager)) {
   case 'fvwm':
      OrigViewId=p_window_id;
      p_window_id=RCFileViewId;
      top();up();
      str='^( |\t)@(\#VS|)( |\t)@Key( |\t)@'KeyName'( |\t)@'ValidAreas'( |\t)@'Modifiers;
      status=search(str,'@ri');
      if (status) {
         //messageNwait('could not find key 'KeyName);
      }else{
         get_line(line);
         p=pos('{\#vs( |\t)@}',line,'','ri');
         if (Activate) {
            if (p) {
               line=substr(line,1,pos('S0')-1):+substr(line,pos('0')+1);
            }
         }else{
            if (!p) {
               line='#VS 'line;
            }
         }
         replace_line(line);
      }
      p_window_id=OrigViewId;
      break;
   case 'mwm':
      OrigViewId=p_window_id;
      p_window_id=RCFileViewId;
      top();up();
      typeless ModRE=GetMWMModifiersRE(Modifiers);
      typeless ValidRE=GetMWMModifiersRE(ValidAreas);
      if (ValidAreas!='Menu Key Binding') {
         str='^( |\t)@(\!VS|)( |\t)@'ModRE'( |\t)@<Key>( |\t)@'KeyName'( |\t)@'ValidRE'( |\t)@';
      }else{
         str=ModRE'?@<Key>( |\t)@'KeyName'( |\t)@'Command;
      }
      status=search(str,'@ri');
      if (status) {
         _message_box('could not find key 'Modifiers' 'KeyName);
      }else{
         get_line(line);
         p=pos('{\!vs}',line,'','ri');
         if (Activate) {
            if (p) {
               if (ValidAreas!='Menu Key Binding') {
                  line=substr(line,1,pos('S0')-1):+substr(line,pos('0')+1);
               }else{
                  get_line(line);
                  p=pos('!VS ',line,'','i');len=4;
                  if (!p) {
                     p=pos('!VS',line,'','i');len=3;
                  }
                  line=substr(line,p+len);
               }
            }
         }else{
            if (!p) {
               if (ValidAreas!='Menu Key Binding') {
                  line='!VS 'line;
               }else{
                  get_line(line);
                  OrigLine=line;
                  lp := lastpos('f.',line,'','i');
                  p=pos('Shift|Alt|Ctrl|<Key>',line,'','ri');
                  if (p) {
                     newline=substr(line,1,p-1):+substr(line,lp-1);
                  }
                  line=newline' !VS 'OrigLine;
               }
            }
         }
         replace_line(line);
      }
      p_window_id=OrigViewId;
      break;
   }
}

static void ActivateOrDeactivate( bool Activate, int RCFileViewId, _str WindowManager)
{
   switch (WindowManager) {
   case 'fvwm':
   case 'mwm':
      _lbtop();_lbup();
      while (!_lbdown()) {
         _str line=_lbget_text();
         KeyName := ValidAreas := Command := "";
         parse line with KeyName "\t" ValidAreas "\t" Command;
         typeless Modifiers="";
         GetKeyNameAndModifiers(KeyName,Modifiers,WindowManager);
         ValidAreas=GetValidAreas(ValidAreas,WindowManager);
         MaybeChangeKey(KeyName,Modifiers,ValidAreas,Command,RCFileViewId,WindowManager,Activate);
      }
      break;
   }
}

static int WindowManagerWriteFile( _str WindowManager)
{
   OrigViewId := p_window_id;
   typeless TempViewId=0;
   typeless inmem=false;
   parse _ctlok.p_user with TempViewId inmem;
   _ctlcommand_list.ActivateOrDeactivate(true,TempViewId,WindowManager);
   _ctlinactive_command_list.ActivateOrDeactivate(false,TempViewId,WindowManager);
   p_window_id=TempViewId;
   int status=_save_file('+O');
   p_window_id=OrigViewId;
   return(status);
}

int _ctlok.on_create(typeless userInfo="")
{
   wid := p_window_id;p_window_id=_control _ctlcommand_list;
   _ctlcommand_list.PrepListBox();
   _ctlinactive_command_list.PrepListBox();
   p_active_form.p_user=lowcase(userInfo);
#if 1
   typeless status=0;
   switch (p_active_form.p_user) {
   case 'fvwm':
      status=FVWMFillInListBoxes();
      break;
   case 'mwm':
      status=MWMFillInListBoxes();
      break;
   }
   if (status) {
      if (status!=COMMAND_CANCELLED_RC) {
         _message_box(nls("%s",get_message(status)));
      }
      p_active_form._delete_window(status);
      return(status);
   }
#else
   //Cleaner, functions have to be global though.
   int index=find_index(upcase(userInfo)'FillInListBoxes',PROC_TYPE);
   if (index && index_callable(index)) {
      call_index(index);
   }
#endif
   _ctlcommand_list._lbsort();
   _ctlcommand_list._lbtop();_ctlcommand_list._lbselect_line();
   _ctlinactive_command_list._lbsort();
   _ctlinactive_command_list._lbtop();_ctlinactive_command_list._lbselect_line();
   p_window_id=wid;
   return(0);
}

void _ctlok.on_destroy()
{
   //SmartClose(_ctlok.p_user);

   if (_ctlok.p_user=='') {
      return;
   }
   typeless temp_view_id=0;
   typeless inmem=false;
   parse _ctlok.p_user with temp_view_id inmem;
   orig_view_id := p_window_id;
   _delete_temp_view(temp_view_id);
}

static typeless get_unique_filename()
{
   int i;
   for (i=0;;++i) {
      while (file_match(i'.slk -p',1)!='');
   }
   return(i'.slk');
}

static void RestartWindowManager(typeless WindowManager)
{
#if 1
   _message_box(nls("These changes will not take effect until you restart %s",WindowManager));
#else
   int result=_message_box(nls("These changes will not take effect until you restart %s\n\n":+\
                           "Do you wish to restart the %s now?",WindowManager,WindowManager),
                           MB_YESNOCANCEL|MB_ICONQUESTION);
   if (result==IDYES) {
      _str tempfile=get_unique_filename();
      shell('ps -e > 'tempfile);
      temp_view_id := 0;
      orig_view_id := 0;
      _open_temp_view(tempfile,temp_view_id,orig_view_id);
      p_window_id=temp_view_id;
      top();up();
      status := search(WindowManager,'w=A-Za-z0-9_$');
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      delete_file(tempfile);
      if (!status) {
         get_line(auto line);
         _str processid;
         parse line with processid .;
         shell('kill -9 'processid);
         shell(WindowManager);
      }
   }
#endif
}

_ctlok.lbutton_up()
{
   orig_view_id := p_window_id;
   typeless vid=0, inmem=0;
   parse _ctlok.p_user with vid inmem;
   p_window_id=vid;
   _str rcfilename=p_buf_name;
   p_window_id=orig_view_id;

   homedir := get_env('HOME');
   _maybe_append_filesep(homedir);

   typeless winman=p_active_form.p_user;
   typeless status=WindowManagerWriteFile(winman);//Name of Window Man.
   if (status) {
      _message_box(nls("Could not save file %s.\n\n%s",rcfilename,get_message(rc)));
   }/*else{
      if (CopyGlobalResourceFile) {
         result='';
         Filename=file_match(homedir:+'.'winman'rc -p',1);
         if (Filename!='') {
            msg=nls("You have modified the global %s file, but you already have one in your HOME directory.\n\n":+\
                    "Would you like to copy the global file to your HOME directory?\n\n":+\
                    "%s will be backed up to %s",winman'rc',winman'rc',winman'rc.slk')
         }else{
            msg=nls("You have modified the global %s file.\n\n":+\
                    "Would you like to put a local copy in your HOME directory?",winman'rc');
         }
         result=_message_box(msg,'',MB_YESNOCANCEL|MB_ICONQUESTION);
         if (result==IDYES) {
            if (Filename!='') {
               status=copy_file(homedir:+'.'winman'rc',homedir:+'.'winman'rc.slk');//make backup
               //status=shell('copy 'homedir:+winman'rc 'homedir:+winman'rc.slk','W');
               if (status) {
                  _message_box(nls("Could not create back up of %s\n\n%s",homedir:+winman'rc',get_message(status)));
               }
            }
            if (Filename==''||!status) {
               status=copy_file(rcfilename,homedir:+winman'rc');
               //status=shell('copy 'rcfilename' 'homedir:+winman'rc','W');
               if (status) {
                  _message_box(nls("Could not %s to %s\n\n%s",rcfilename,homedir:+winman'rc',get_message(status)));
               }
            }
         }
      }
   }*/
   RestartWindowManager(p_active_form.p_user);
   p_active_form._delete_window(status);
}

static void MoveLine(int WidFrom,int WidTo)
{
   if (WidFrom.p_Noflines) {
      _str line=WidFrom._lbget_text();
      WidFrom._lbdelete_item();
      WidTo._lbadd_item(line);
   }
   WidTo._lbsort();
   WidTo._lbselect_line();
   WidFrom._lbsort();
   WidFrom._lbselect_line();
}

_ctldisable.lbutton_up()
{
   if (p_window_id==_ctldisable) {
      MoveLine(_ctlcommand_list,_ctlinactive_command_list);
   }else{
      MoveLine(_ctlinactive_command_list,_ctlcommand_list);
   }
}

_ctlcommand_list.lbutton_double_click()
{
   _ctldisable.call_event(_ctldisable,LBUTTON_UP);
}

_ctlinactive_command_list.lbutton_double_click()
{
   _ctlenable.call_event(_ctlenable,LBUTTON_UP);
}

#if 0
defeventtab _winman_selection_form;
void _ctlok.on_create()
{
   wid := p_window_id;
   orig_wid := p_window_id;
   for (;;) {
      wid=wid.p_next;
      if (wid==orig_wid) break;
      if (wid.p_object==OI_RADIO_BUTTON) {
         wid.p_value=1;
         break;
      }
   }
}

 _ctlok.lbutton_up()
{
   Name := "";
   int orig_wid=_control _winman_frames.p_child;
   int wid=orig_wid;
   for (;;) {
      if (wid.p_object==OI_RADIO_BUTTON && wid.p_value) {
         parse wid.p_caption with Name '(' . ;
      }
      wid=wid.p_next;
      if (wid==orig_wid) break;
   }
   p_active_form._delete_window(strip(Name));
}
#endif
_command void EditWinManResourceFile() name_info(HELP_ARG','VSARG2_CMDLINE|VSARG2_NOEXIT_SCROLL)
{
   if (get_env('HOME')=='') {
      _message_box(nls("You must have a HOME environment variable to use this feature."));
      return;
   }
   typeless result=show('-modal _sellist_form',
            'Select Window Manager',
            SL_SELECTCLINE,   // flags
            "MWM (Motif Window Manger)\nFVWM (Virtual Window Manager)", // input_data
            "",   // buttons
            '?Determines what window manager resource files are edited',  // help item
            '',   // font
            '',   // Call back function
            '',   // Item separator for list_data
            '',   // Retrieve form name
            '',   // Combo box. Completion property value.
            '',   // minimum list width
            '' // Combo Box initial value
           );
   if (result=='') {
      return;
   }
   typeless WindowManager="";
   parse result with WindowManager '(' ;
   WindowManager=strip(WindowManager);
   if (WindowManager!='') {
      show('-modal _unixwinman_form',WindowManager);
   }
}
