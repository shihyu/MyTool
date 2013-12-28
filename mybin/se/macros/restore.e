////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50143 $
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
#import "clipbd.e"
#import "compile.e"  
#import "dir.e"
#import "dlgeditv.e"
#import "eclipse.e"
#import "files.e"
#import "hex.e"
#import "main.e"
#import "recmacro.e"
#import "saveload.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbfilelist.e"
#import "tbview.e"
#import "toolbar.e"
#import "util.e"
#import "vc.e"
#import "window.e"
#import "wkspace.e"
#import "se/color/SymbolColorAnalyzer.e"
#endregion

static int window_config_id;
static _str clean_up_buf_ids;
static int dsRestoredENQ:[];

#define READONLY_ON 0x1
#define READONLY_SET_BY_USER 0x2
_str _no_resize;

/**
 * @return Returns the directory used to store auto restore files (see 
 * <b>auto_restore</b> command).
 * 
 * @categories File_Functions
 * 
 */ 
_str restore_path(typeless mustExist="")
{
   _str path=get_env(_SLICKRESTORE);
   if ( rc ) {
      path=_ConfigPath();
      if (path=='') {
         path=editor_name('p');
      }
      /* If directory must exist and it does not.  */
      if ( mustExist && !isdirectory(path) ) {
         path='';
      }
   }
   if ( path!='' && last_char(path):!=FILESEP ) {
      path=path:+FILESEP;
   }
   return(path);

}

/*
  Read in the window configuration file and create the same window/buffer
  size and positions.

    arg(1)     _str restore_option (Optional).  String of one or more
               of the following option letters.

                 N indicates restore without restore files.
                 R indicates restore everything.
                 G Just restore global info because we already
                   restore other information from the project file.
                 I Restoring from editor invocation.

    arg(2)     _str view_id (Optional).  View id which correndponds
               to restore file data.  Cursor should be at first
               line of restore information.

  To auto restore your own data define a global (not static)
  function that starts with "_sr_" or "_srg_".  The return type
  of your function is int.  Return 0 if successful.

  When SAVING restore information your function is called as follows:

    _sr_mymarker();    The function must use LOWER CASE letters only.
                       Sorry, we needed this for backward compatibility.
                       Your function should use insert_line(...) to
                       insert a header line as follows:

                         mymarker:  NoflinesWhichFollowThisLine [UserData]

                       mymarker: Must be the same name as the function
                       after the "_sr_".  UserData is optional.

  Note:  If you want your restore information stored globally
         (Not per project), prefix your function name with
         "_srg_" instead of "_sr_".

  When RESTORING, your function is called as follows

    _sr_mymarker(_str restore_option,_str LineAfterColon,
                boolean RestoringFromInvocation);

       restore_option     "N" or "R".  The N option indicates that files
                          are not being restored.  This occurs when the
                          user specifies a file argument from the command
                          line.
       LineAfterColon     Header line from auto restore buffer not including
                          leading mymarker: data.

       RestoringFromInvocation   'true' if restoring from an editor invocation.
                                 You may not want you information changed
                                 when the user switches projects.

*/
static boolean gHitToolbarsSection;
static boolean gHitGlobalSection;

/**
 * Resumes the last edit session which was terminated by the 
 * <b>safe_exit</b> command.  The <b>safe_exit</b> command will 
 * save the window/buffer configuration only if auto restore is set to on.  
 * When auto restore is on and the editor is invoked with no file or 
 * command parameters, the <b>restore</b> command is automatically 
 * invoked.  SlickEdit stores auto restore information in
 * the file "vrestore.slk". You may define an environment
 * variable called VSLICKRESTORE and assign it a path where you
 * want SlickEdit to look for this file.
 * 
 * @see auto_restore
 * @see save_window_config
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command restore(_str options="",int alternate_view_id=0, _str relativeToDir=null,boolean restoreFiles=true,boolean restoringFromProject=false)
{
   //this is a little bit of a hack.
   //the quit() function for the file
   //will try to call in to eclipse to close the editor
   //if this flag isn't set.  We have to set it back at all
   //return points as well.
  if (isEclipsePlugin()) {
      setInternalCallFromEclipse(true);
   }
   boolean RestoringFromInvocation=false;
   _str restore_options=upcase(options);
   if (pos("I",restore_options)) {
      RestoringFromInvocation=true;
   }
   if (RestoringFromInvocation && (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
      _mdi._ShowWindow();
   }

   typeless status=0;
   _str restore_filename="";
   int alternate_buf_id=0;
   int temp_view_id=0;
   int junk_view_id=0;

   if (alternate_view_id) {
      clean_up_buf_ids='';
      activate_window(alternate_view_id);
      alternate_buf_id=p_buf_id;
   } else {
      if (_default_option(VSOPTION_DONT_READ_CONFIG_FILES)) {
         return 0;
      }
      activate_window(VSWID_HIDDEN);
      restore_filename=editor_name("r");
      if (restore_filename==''){
         restore_filename=editor_name('p'):+_WINDOW_CONFIG_FILE;
         if (restore_filename==''){
            if (isEclipsePlugin()) {
                setInternalCallFromEclipse(false);
             }

            return(0);
         }
      }
      /* p_window_id=_mdi._edit_window() */
      status=_open_temp_view(restore_filename,temp_view_id,junk_view_id);
      //status=load_files(_load_option_encoding(restore_filename)" +q "maybe_quote_filename(restore_filename));
      if ( status ) {
         if ( status==NEW_FILE_RC ) {
            _delete_buffer();
         }
         tbResetAll();
         if (isEclipsePlugin()) {
             setInternalCallFromEclipse(false);
          }
         return(1);
      }
      //clean_up_buf_ids=p_buf_id;
      clean_up_buf_ids='';
   }
   gHitToolbarsSection=false;
   gHitGlobalSection=false;
   orig_actapp := def_actapp;
   def_actapp |= ACTAPP_DONT_RELOAD_ON_SWITCHBUF;
   status=restore2(options,relativeToDir,restoreFiles,restoringFromProject);
   def_actapp = orig_actapp;
   if (!gHitToolbarsSection &&
          (  gHitGlobalSection ||
             (!alternate_view_id &&
               file_eq(_strip_filename(restore_filename,'P'),_WINDOW_CONFIG_FILE)
              )
          )
      ) {
      tbResetAll();
   }
   int view_id=0;
   if (alternate_view_id) {
      get_window_id(view_id);
      activate_window(alternate_view_id);
      p_buf_id=alternate_buf_id;
      activate_window(view_id);
   } else {
      get_window_id(view_id);
      _delete_temp_view(temp_view_id);
      if (view_id!=temp_view_id) {
         activate_window(view_id);
      }
   }
   if (isEclipsePlugin()) {
      setInternalCallFromEclipse(false);
   }

   return(status);
}
static boolean screen_size_changed;
static int restore2(_str restore_options,_str relativeToDir,boolean restoreFiles,boolean restoringFromProject)
{
   // Initialize data set ENQ failed list.
   dsRestoredENQ._makeempty();
   dsRestoredENQ:["JUNK"] = 0; // force this var to be a hash table

   int view_id=0;
   _open_temp_view('',window_config_id,view_id,'+bi 'p_buf_id);

   boolean do_one_window=0;
   typeless mdi_state="";
   boolean JustRestoreGlobalInfo=false;
   boolean RestoringFromInvocation=false;
   restore_options=upcase(restore_options);
   if (pos("I",restore_options)) {
      restore_options=stranslate(restore_options,"","I");
      RestoringFromInvocation=true;
   }
   // IF we already restored from project and just want to restore
   //    global auto restore info.
   if (pos("G",restore_options)) {
      restore_options=stranslate(restore_options,"","G");
      JustRestoreGlobalInfo=true;
      restore_options="N";
   }
   _str callback_prefix="_sr_";
   typeless screen_size_line="";
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_SAVERESTORE_EDIT_WINDOWS)) {
      restore_options='N';
   }

   typeless status=0;
   typeless width=0;
   typeless height=0;
   typeless count=0;
   _str v="";
   _str buf="";
   typeless line="";
   _str type="";
   _str ntype="";
   _str rtype="";
   _str bi_info="";
   _str viewline="";
   _str bufferline="";
   int WorkspaceCallbackIndex=0,WorkspaceLine=-1;
   screen_size_changed=false;
   for (;;) {
      get_line(line);
      parse line with rtype line;
      //say('ro='restore_options' ln='p_line' rtype=<'rtype'> 'line);
      // IF we are restoring files
      if ( restore_options!='N' ) {
         if ( rtype == 'WINDOW:' ) {
            status=down(); get_line(buf);
            parse buf with type bufferline;
            if ( ! status && type=='BUFFER:' ) {
               down();get_line(v);
               activate_window(view_id);
               parse v with . viewline;
               if (restoreFiles) {
                  status=process_window(line,bufferline,viewline,relativeToDir);
               } else {
                  status=0;
               }
            } else {
               if ( ! status ) up();
               /* 
                  Now that the 10.0 code always gives buffer and view data for windows,
                  just don't create the window for this case and users can just
                  create a new window and the do a next buffer.
               */
               status=0;
            }
            if (status == PROCESS_ALREADY_RUNNING_RC) {
               // already open or will be opened later
               status = 0;
            } else if ( status ) {
               //clean_up();
               if ( status!=NEW_FILE_RC ) {
                  _message_box('Restore: 'get_message(status));
               }
               break;
               //return(status);
            }
            get_window_id(view_id);
         } else if ( rtype == 'BUFFER:' ) {
            down();
            get_line(bi_info);
            parse bi_info with ntype bi_info;
            down();
            get_line(viewline);
            parse viewline with ntype viewline;
            activate_window(view_id);
            if (restoreFiles) {
               int load_file_status=0;
               status = process_buffer(line,'',bi_info,relativeToDir,load_file_status);
               if (status == PROCESS_ALREADY_RUNNING_RC) {
                  // already open or will be opened later
                  status = 0;
               } else if ( status ) {
                  //clean_up()
                  if ( status!=NEW_FILE_RC ) {
                     _message_box('Restore: 'get_message(status));
                  }
                  break;
                  //return(status)
               } else {
                  process_view(viewline);
               }
            }
         } else if ( rtype=='MARK:' ) {
            if (restoreFiles) {
               restore_select_data();
            }
         } else if( rtype == 'MDISTATE:' ) {
            parse line with count .;
            if ( (int)count > 0 ) {
               down();
               _str state = '';
               get_line(state);
               down(--count);
               if ( restoreFiles ) {
                  process_mdistate(state);
               }
            }
         }
      }
      if ( rtype=='RETRIEVE:' ) {
         restore_retrieve_data(line);
      } else if ( rtype=="DIALOGS:") {
         _xsrg_dialogs('R',line/*,RestoringFromInvocation*/);
      } else if ( rtype=="GSTART:") {
         gHitGlobalSection=true;
         callback_prefix="_srg_";
      } else if (rtype=="GEND:") {
         callback_prefix="_sr_";
         if (JustRestoreGlobalInfo) {
            //messageNwait("restore2: JustRestoreGlobalInfo="JustRestoreGlobalInfo);
            status=0;
            break;
         }
      } else if ( rtype=='SCREEN:' && !JustRestoreGlobalInfo && restoreFiles && !restoringFromProject) {
         screen_size_line=line;
         parse line with width height .;
         /* If screen size different */
         if ( _screen_height()!=height || _screen_width()!=width ) {
            screen_size_changed=1;
         }

         // DJB 03-14-2007 -- restore fullscreen mode
         parse line with .    .    .    . .    .    . . . . . . . .   .  auto fs;
         if (fs==1) fullscreen(1);

      } else if ( rtype=='CWD:' && (def_restore_flags & RF_CWD) &&
                  (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_SAVERESTORE_CWD)
                  ) {
         if (!JustRestoreGlobalInfo) {
            //chdir(line,1);
            // Don't have to call cd here, but we must do call_list
            // and it make sense to do process_cd
            cd('-a 'maybe_quote_filename(absolute(line,relativeToDir)));
         }
      }
      if (rtype=='TOOLBARS5:') {
         gHitToolbarsSection=true;
      }
      if ( ! pos(rtype,'SCREEN:GSTART:GEND:CWD:RETRIEVE:DIALOGS:MARK:WINDOW:BUFFER:BI:VIEW:MDISTATE:') ) {
         //_mdi.p_visible=1;messageNwait("rtype="rtype);
         _str name=callback_prefix:+strip(lowcase(rtype),'',':');
         int index=find_index(name,PROC_TYPE);
         // IF there is a callable function
         if ( index_callable(index)) {

            typeHandled := false;
            // do we want to restore a workspace?
            if (rtype == 'WORKSPACE:') {
               if ((def_restore_flags & RF_WORKSPACE) == 0) {
                  // in this case, we don't want to restore the workspace
                  typeHandled = true;
               } else if (!gHitToolbarsSection) {
                  //4:52pm 2/10/2000
                  //We do not want to run the workspace restore until after the
                  //toolbar restore has run.
                  //This is because a SCC version control system being initialized
                  //may cause output to the Output toolbar, which would show the
                  //output toolbar.  Restore would then show another copy.
                  WorkspaceCallbackIndex=index;
                  WorkspaceLine=p_line;
                  parse line with count .;
                  down(count);

                  typeHandled = true;
               }
            }

            if (!typeHandled) {
               // just call the callback for this one
               _str a1=restore_options;
               if ( a1=="" ) {
                  a1="R";
               }
               status=call_index(a1,line,RestoringFromInvocation,relativeToDir,index);

               if ( status ) break;
            }
         } else {
            /* Skip over lines that can't be processed. */
            parse line with count .;
            if (isnumber(count)) {
               down(count);
            }
         }
      }
      activate_window(window_config_id);
      if ( down()) {
         status=0;
         break;
      }
   }
   activate_window(window_config_id);
   if (WorkspaceCallbackIndex) {
      //4:54pm 2/10/2000
      //Deferred calling the workspace callback earlier.
      //4:52pm 2/10/2000
      //We do not want to run the workspace restore until after the
      //toolbar restore has run.
      //This is because a SCC version control system being initialized
      //may cause output to the Output toolbar, which would show the
      //output toolbar.  Restore would then show another copy.
      save_pos(auto p);
      p_line=WorkspaceLine;
      get_line(line);
      parse line with rtype line;
      _str a1=restore_options;
      if ( a1=="" ) {
         a1="R";
      }
      if (RestoringFromInvocation && line != "" && line != "0") {
         restore_info := line;
         restore_name := parse_file(restore_info,false);
         restore_name = parse_file(restore_info,false);
         restore_name = _strip_filename(restore_name,'P');
         _SplashScreenStatus("Opening workspace: "restore_name);
      }
      typeless status2=call_index(a1,line,RestoringFromInvocation,WorkspaceCallbackIndex);
      if ( status2 ) {
         clean_up();
         return(status2);
      }
      activate_window(window_config_id);
      restore_pos(p);
   }
   if (status) {
      clean_up();
      return(status);
   }
   //messageNwait('after loop');
   activate_window(view_id);
   clean_up();

   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_SAVERESTORE_EDIT_WINDOWS)) {
   } else {
      if (screen_size_line!="") {
         set_screen_size(screen_size_line,do_one_window,mdi_state,RestoringFromInvocation);
      }
   }
   // IF we are restoring files AND MDI screen size changed AND
   //    we are not in one file per window mode
   if (restore_options!='N' && do_one_window && def_one_file=='') {
      one_window();
   }
#if 0
   if (mdi_state!='') {
      // Unfortunately change the state to iconized does not work.
      if (mdi_state!='I') {
         _mdi.p_window_state=mdi_state;
      }
   }
#endif
   //old_line=line;
   return(0);
}
static void restore_select_data()
{
   _str line="";
   get_line(line);
   _str line_type="";
   _str mt="";
   _str buf_name="";
   typeless start_line=0;
   typeless start_col=0;
   typeless last_line=0;
   typeless end_col=0;
   parse line with line_type 'MT='mt'BN='buf_name'SL='start_line'SC='start_col'LL='last_line'EC='end_col;
   int temp_view_id=0;
   int this_buf=0;
   int status=_open_temp_view(strip(strip(buf_name),'B','"'),temp_view_id,this_buf,'+b');
   if ( status) {
      clear_message();
      return;
   }
   _deselect();
   _goto_rpoint(start_line);p_col=start_col;select_it(mt,'');
   _goto_rpoint(last_line);p_col=end_col;select_it(mt,'');
   _delete_temp_view(temp_view_id);
   activate_window(this_buf);

}
static _str process_window(_str line,_str bufferline,_str viewline,_str relativeToDir)
{
   typeless x=0, y=0, width=0, height=0, icon_x=0, icon_y=0, state=0;
   typeless wf="", wt="", font_info="";
   typeless dup_id="";
   parse line with x y width height icon_x icon_y state 'WF=' wf 'WT=' wt '"' font_info '"' 'DID='dup_id .;
   if (font_info=='') {
      font_info=_default_font(CFG_WINDOW_TEXT);
   }
#ifndef not_finished
   // TODO
   // Problems with early zoom during autorestore. No problem since MDISTATE:
   // layout line will taking care of zooming anyway.
   state = 'N';
#endif
   _str orig_state=state;
   if (machine()=='WINDOWS' && state=='I' && icon_x) {
      state='N';
   }
   _str font_name="";
   typeless font_size=0;
   typeless font_flags=0;
   typeless charset=0;
   parse font_info with font_name "," font_size "," font_flags","charset;
   if (!isinteger(charset)) {
      charset=VSCHARSET_DEFAULT;
   }
   int view_id=0;
   get_window_id(view_id);
   int load_file_status=0;
   _no_resize=1;
   typeless status=0;
   if (screen_size_changed) {
      status=process_buffer(bufferline,'+i','',relativeToDir,load_file_status);
   } else {
      status=process_buffer(bufferline,'+i:'x' 'y' 'width' 'height' 'state,'',relativeToDir,load_file_status);
   }
   _no_resize='';
   /* messageNwait('status='status) */
   if ( status || !p_HasBuffer || load_file_status) {
      return(status);
   }
   p_old_x=x;p_old_y=y;p_old_width=width;p_old_height=height;
   if (icon_x>=0) {
      _no_resize=1;
      _MDIChildSetWindow(x,y,width,height,'N',icon_x,icon_y);
      if (machine()=='WINDOWS' && orig_state=='I') {
         p_window_state='I';
      }
      _no_resize='';
   }
   /* p_window_state=state */
   p_window_flags=wf;
   p_tile_id=wt;
   if(isinteger(dup_id)) {
      p_mdi_child_duplicate_id=dup_id;
   }

   //Process Font Information
   if (font_name!='') {
      p_redraw=0;
      p_font_name = font_name;
      p_font_size = font_size;
      p_font_bold = font_flags & F_BOLD;
      p_font_italic = font_flags & F_ITALIC;
      p_font_strike_thru = font_flags & F_STRIKE_THRU;
      p_font_underline = font_flags & F_UNDERLINE;
      p_font_charset= charset;
      p_redraw=1;
   }
   //End Process Font Information

   return(process_view(viewline));
}
static _str process_view(_str line)
{
   if ( line!='' && p_buf_name!='.process') {
      typeless ln="", cl="", le="", cx="", cy="", wi="", bi="";
      typeless hex_toppage="", hex_nibble="", hex_field="", hex_Nofcols="";
      parse line with 'LN=' ln ' CL=' cl ' LE=' le ' CX=' cx ' CY=' cy ' WI=' wi ' BI=' bi ' HT='hex_toppage' HN='hex_nibble' HF='hex_field' HC='hex_Nofcols .;
      cy=cy*p_font_height;
      cx=cx*p_font_width;
      _goto_rpoint(ln);
      typeless offset="";
      parse cl with '.' offset;
      if (offset!='') {
         boolean try_EOR=(offset<0);
         if (try_EOR) {
            offset= -offset;
         }
         _GoToROffset(offset);
         if (p_col==1 && try_EOR) {
            up();_end_line();
         }
      }
      if (hex_toppage!='' && !p_UTF8) {
         p_hex_toppage=hex_toppage;
         p_hex_nibble=hex_nibble;p_hex_field=hex_field;
         p_hex_Nofcols=hex_Nofcols;
      }
      /* if (pos('test.e',p_buf_name)) {trace} */
      if (offset=='') {
         p_col=cl;
      }
      set_scroll_pos(le,cy);
      /* message 'buf_name='p_buf_name' cy='cy' p_cursor_y='p_cursor_y' p_ch='p_client_height' font_name='p_font_name;get_event('r'); */
   }
   return(0);

}
static _str process_buffer(_str buf_info,_str window_options,_str bufferProperties,_str relativeToDir,int &load_file_status)
{
#if 0
   _str mode_name="";
   parse buf_info with 'MN=' mode_name ' BN=' rest;
   // IF mode name not present (old format )
   if (rest=='') {
      parse buf_info with 'BN=' rest;
   }
#endif
   _str rest="";
   parse buf_info with 'BN=' rest;
   _str bn=_replace_envvars2(parse_file(rest));
   if (relativeToDir!=null) {
      bn=strip(bn,'B','"');
      bn='"'absolute(bn,relativeToDir)'"';
   }
   _str DocumentName=strip(parse_file(rest),'B','"');
   typeless margins="", tabs="", word_wrap_style="";
   typeless indent_with_tabs="", ShowSpecialChars="";
   typeless indent_style="", buf_width="", undo_steps="";
   typeless readonly_flags="", showeof="", shownlchars="";
   typeless binary="", mode_name="", hex_mode="";
   typeless ModifyFlags="", TruncateLength="", MaxLineLength="";
   typeless AutoSelectLanguage="", line_numbers_len="", LCFlags="";
   typeless caps="", encoding="", encoding_set_by_user="";
   _str CLscheme="", SCscheme="";
   typeless SCenabled="", SCerrors="";
   if ( bufferProperties!='' ) {
      parse bufferProperties with 'MA=' margins ' TABS=' tabs ' WWS=' word_wrap_style ' IWT=' indent_with_tabs 'ST=' ShowSpecialChars 'IN=' indent_style 'BW=' buf_width 'US=' undo_steps 'RO='readonly_flags 'SE=' showeof 'SN='shownlchars 'BIN='binary 'MN='mode_name"\t" 'HM='hex_mode' MF='ModifyFlags' TL='TruncateLength' MLL='MaxLineLength' ASE='AutoSelectLanguage' LNL='line_numbers_len' LCF='LCFlags' CAPS='caps' E='encoding' ESBU2='encoding_set_by_user' CL="'CLscheme'" SC="'SCscheme'" SCE='SCenabled' SCU='SCerrors .;
   }
   if ( bn =='' ) {
      // bn should never be ''.  This code is here for completeness.
      return(FILE_NOT_FOUND_RC);
   }
   if ( buf_width==0 || buf_width=='' ) {
      buf_width='';
   } else {
      buf_width='+'buf_width;
   }
   /* messageNwait('window_options='window_options); */
   /* messageNwait('bn='bn); */
   typeless options="";
   typeless status=0;
   typeless result=0;
   if (strip(bn,'B','"')=='.process') {
      load_file_status=status=load_files('-w +q 'window_options' +b .process');
      if (def_restore_flags & RF_PROCESS) {
         _post_call(find_index("restore_build_window", COMMAND_TYPE));
         load_file_status = status = PROCESS_ALREADY_RUNNING_RC;
      }
   } else {
      options='';
      if (bufferProperties!='') {
         if (strip(binary))  {
            options=options' +lb';
         } else {
            if (strip(shownlchars)) options=options' +ln';
            if (strip(showeof)) options=options' +le';
         }
      }
      if (isinteger(encoding)) {
         options=options' '_EncodingToOption(encoding);
      }
      int normaledit = 1;
      _str dsROCmd = "";
      // If the data set was not properly ENQ, do not try to
      // edit the data set again. This can happen when the editor
      // is restored a BUFFER: and later a WINDOW: which uses
      // the previously ENQ failed buffer.
      _str nameonly = strip(bn,'B','"');
      if (_DataSetIsFile(nameonly)) {
         // If a previous data set restore failed, skip the second
         // edit completely.
         if (dsRestoredENQ._indexin(nameonly) && dsRestoredENQ:[nameonly]) {
            normaledit = 0;
            status = ACCESS_DENIED_RC;
         } else {
            // If the data set to be restored is supposed to be
            // in read-only mode, tell edit() to go into read-only
            // mode and skip ENQ.
            //
            // A side effect is that the buffer to
            // switch to read-only mode twice: one in edit()
            // and one more later in this function.
            //
            // If the data set was previously restored in read-only
            // mode, do the same here without checking readonly_flags.
            // This is important because processing WINDOW: from
            // vrestore.slk does not have readonly_flags.
            _str dsROkey = nameonly :+ "_readonly";
            if (dsRestoredENQ._indexin(dsROkey) && dsRestoredENQ:[dsROkey]) {
               dsROCmd = '"-*read_only_mode 1" ';
            } else {
               int dsReadOnly;
               if (!isinteger(strip(readonly_flags))) {
                  dsReadOnly = 0;
               } else {
                  dsReadOnly = (int)strip(readonly_flags);
               }
               if (dsReadOnly & READONLY_ON) dsROCmd = '"-*read_only_mode 1" ';
               dsRestoredENQ:[dsROkey] = (dsReadOnly & READONLY_ON);
            }
         }
      }
      if (normaledit) {
         load_file_status=status=edit('-w 'window_options" "options" "buf_width " "dsROCmd:+bn,EDIT_NOUNICONIZE,0);
      }
   }
   if ( status ) {
      if ( status!=NEW_FILE_RC && status!=FILE_NOT_FOUND_RC && status!=PATH_NOT_FOUND_RC
           && status!=MEMBER_IN_USE_RC
           && status!=DATASET_IN_USE_RC
           && status!=DATASET_OR_MEMBER_IN_USE_RC
           ) {
         return(status);
      }
      _str nameonly = strip(bn,'B','"');
      if (_DataSetIsFile(nameonly) && (status == MEMBER_IN_USE_RC || status == DATASET_IN_USE_RC || status == DATASET_OR_MEMBER_IN_USE_RC)) {
         // If data set edit was skipped, no nothing more
         if (dsRestoredENQ._indexin(nameonly)) return(status);

         // Remember the ENQ failed on this buffer to prevent it
         // from being edited again during the restore.
         //
         // Technically, it does not hurt to do the ENQ twice but
         // since a failed ENQ also displays a message box, we don't
         // want to see the message box twice for the same data set.
         dsRestoredENQ:[nameonly] = 1;
         result=_message_box("Restore:  ":+
                              nls("Can't edit data set '%s'.\n\n%s\n\nContinue?",nameonly,get_message(status)),'',MB_YESNOCANCEL|MB_ICONQUESTION);
      } else {
         //FileNotRestoredList[FileNotRestoredList._length()]=bn;
         result=IDYES;
      }
      if (status==NEW_FILE_RC) {
         clean_up_buf_ids=clean_up_buf_ids" "p_buf_id;
      }
      if (result!=IDYES) {
         return(status);
      }
   } else {
      if (DocumentName!="") {
         docname(DocumentName);
      }
      if (bufferProperties!='') {
         // IF we are in readonly mode
         readonly_flags=strip(readonly_flags);
         if (!isinteger(readonly_flags)) readonly_flags=0;
         if (strip(bn,'B','"')!='.process') {
            _restore_filepos(p_buf_name);
         }
         if (isinteger(encoding_set_by_user)) {
            p_encoding_set_by_user=encoding_set_by_user;
            //say('put back');
         }
         if( readonly_flags & READONLY_ON) {
            read_only_mode();
            p_readonly_set_by_user=(readonly_flags & READONLY_SET_BY_USER);
            if (def_actapp&ACTAPP_AUTOREADONLY) maybe_set_readonly();
         // IF have mode name
         } else if (mode_name!='') {
            // Get extension from mode name
            _str lang="";
            if (_ModenameEQ(mode_name,'fundamental') || _ModenameEQ(mode_name,'Plain Text')) {
               lang = _Modename2LangId('fundamental');
               if (p_LangId:!=lang) {
                  fundamental_mode();
               }
            } else {
               lang = _Modename2LangId(mode_name);
               // Made this changes so that _xml_init_file() did not get called twice.
               if (p_LangId:!=lang) {
                  _SetEditorLanguage(lang);
               }
            }
            if (def_actapp&ACTAPP_AUTOREADONLY) maybe_set_readonly();
#if 0
            // Get extension from mode name
            typeless junk="";
            lang=_Modename2LangId(mode_name);
            if (lang=='') {
               if (_ModenameEQ(mode_name,'Fundamental') || _ModenameEQ(mode_name,'Plain Text')) {
                  fundamental_mode();
               }
            } else {
               _SetEditorLanguage(lang);
            }
#endif
         }
         /* call _SetEditorLanguage() */
         p_margins=margins;
         p_tabs=tabs;
         p_word_wrap_style=word_wrap_style;
         p_indent_with_tabs=indent_with_tabs;
         p_ShowSpecialChars=ShowSpecialChars;
         p_indent_style=indent_style;
         p_undo_steps=undo_steps;
         if (hex_mode!='' && !p_UTF8) {
            if (!p_hex_mode && hex_mode) {
               if (hex_mode==HM_HEX_ON) { 
                  hex();
               } else {
                  linehex();
               }
            } else {
               p_hex_mode=hex_mode;
            }
         }
         if (isinteger(ModifyFlags)) {
            p_ModifyFlags|=(ModifyFlags& MODIFYFLAG_FTP_NEED_TO_SAVE);
         }
         if (isinteger(TruncateLength)) {
            p_TruncateLength=TruncateLength;
         }
         if (!p_MaxLineLength && isinteger(MaxLineLength)) {
            p_MaxLineLength=MaxLineLength;
         }
         if (isinteger(AutoSelectLanguage)) {
            p_AutoSelectLanguage=AutoSelectLanguage;
         }
         if (isinteger(line_numbers_len)) {
            p_line_numbers_len=line_numbers_len;
         }
         if (isinteger(LCFlags)) {
            p_LCBufFlags=LCFlags;
         }
         if (isinteger(caps)) {
            p_caps=caps;
         }
         if (CLscheme == def_color_scheme && SCscheme != "") {
            _SetSymbolColoringSchemeName(SCscheme);
         }
         if (isinteger(SCenabled)) _SetSymbolColoringEnabled(SCenabled);
         if (isinteger(SCerrors))  _SetSymbolColoringErrors(SCerrors);
      }
   }
   return(0);


}

static boolean process_mdistate(_str state)
{
   return _MDIRestoreState(state);
}

static void clean_up()
{
   p_window_id=_mdi._edit_window();
   _delete_temp_view(window_config_id);
   for (;;) {
      typeless id="", clean_up_buf_ids="";
      parse clean_up_buf_ids with id clean_up_buf_ids;
      if ( id=='' ) {
         break;
      }
      int status=edit('+bi 'id);
      if (!status) {
         /*
             Here we are using close_buffer() instead of _delete_buffer()
             to fix a bug in our X windows HP SoftBench support.  Note
             that it is possible for close_buffer() to be called here
             where the buffer was not created by calling the edit()
             command.
         */
         close_buffer(false,true /* Allow delete_buffer on hidden window. */);
      }
   }
   p_window_id=_mdi._edit_window();
}
boolean _project_save_restore_done;

/**
 * Saves the auto restore information.  All auto restore information is 
 * stored in the "vrestore.slk" file.
 * 
 * @return Returns 0 if successful.
 * 
 * @see restore
 * @see auto_restore
 * 
 * @categories File_Functions
 * 
 */ 
_command save_window_config(boolean project_info_only=false,int alternate_view_id=0,boolean exiting_editor=false,_str relativeToDir=null)
{
//   if (isEclipsePlugin()) {
//      return 0;
//   }

   if (_default_option(VSOPTION_CANT_WRITE_CONFIG_FILES)) {
      return 0;
   }

   // DJB 03-14-2007 - do not leave fullscreen mode
   //fullscreen(0);
   
   _save_all_filepos();
   int orig_view_id=0;
   get_window_id(orig_view_id);
   p_window_id=_mdi.p_child;
   int home_view=0;
   get_window_id(home_view);
   activate_window(VSWID_HIDDEN);
   _str rpath=restore_path(0);

   //project_info_only=(lowcase(arg(2))=='p');
   //alternate_view_id=arg(3);
   //check_exists=arg(4);
   //exiting_editor=arg(5)!="";

   int restore_view_id=0;
   typeless status=0;
   if (alternate_view_id) {
      activate_window(alternate_view_id);
   } else {
      status=1;
      _str restore_filename=rpath:+_WINDOW_CONFIG_FILE;
      if (buf_match(restore_filename,1,'he')!='') {
         status=_open_temp_view(restore_filename,restore_view_id,auto orig_wid,'',auto buffer_already_exists,true,false,0,true);
         if (!status) {
            p_UTF8=true;
         }
      }
      if (status) {
         status=_create_temp_view(restore_view_id,'',restore_filename);
      }
   }

   int mdi_x=0, mdi_y=0, mdi_width=0, mdi_height=0, mdi_ix=0, mdi_iy=0;
   int mdiclient_width=0, mdiclient_height=0;
   _str window_state="";
   typeless junk="";
   typeless p=0;
   boolean fullScreenMode = _tbFullScreenQMode();
   if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
      _mdi._get_window(mdi_x,mdi_y,mdi_width,mdi_height,'N',mdi_ix,mdi_iy);
      window_state=_mdi.p_window_state;
      if (window_state=='I'){
         window_state='N';
      }
      _mdi._MDIClientGetWindow(junk,junk,mdiclient_width,mdiclient_height);
   } else {
      mdi_x=0;mdi_y=0;mdi_width=0;mdi_height=0;mdi_ix=0;mdi_iy=0;
      mdiclient_width=0;mdiclient_height=0;
      window_state='N';
   }
   // SCREEN: must be first item in vrestore.slk because vs executable
   // expects this line to be first.  This is because vs creates
   // the MDI window visible.  This is likely to change in the future.
   _str screen_line='SCREEN: '_screen_width()' '_screen_height()' 'mdi_x' 'mdi_y' 'mdi_width:+
                   ' 'mdi_height' 'mdi_ix' 'mdi_iy' 'window_state:+
                   ' 0 0 0 0 'mdiclient_width' 'mdiclient_height' 'fullScreenMode;
   get_window_id(restore_view_id);
   int buf_id=p_buf_id;
   insert_line(screen_line);
   insert_line("CWD: "((relativeToDir==null)?getcwd():relative(getcwd(),relativeToDir)));
   if (!project_info_only) {
      insert_line("GSTART:");
      typeless gstart;
      save_pos(gstart);
      // Add the retrieve information.
      write_retrieve_data(restore_view_id);
      /* call external global save/restore functions. */
      _project_save_restore_done=0;
      _srg_workspace();
      _srg_tbfilelist();
      _project_save_restore_done=1;
      call_list('_srg_');
      _project_save_restore_done=0;

      _save_pos2(p);
      if (exiting_editor) {
         if (find_index('_tbexiting_editor',PROC_TYPE)) {
            _tbexiting_editor();
         }
      }

      restore_pos(gstart);
      _xsrg_dialogs();
      _restore_pos2(p);
      insert_line("GEND:");
   }

   /* For each buffer write non-active view information. */
   _str word="", rest="";
   activate_window(VSWID_HIDDEN);
   load_files("+m +bi "restore_view_id.p_buf_id);
   _str not_on_disk_list="";
   int restore_process=(def_restore_flags & RF_PROCESS);
   buf_id=p_buf_id;
   boolean bufferDataWritten:[];  // Indicates which buffers we need windows for.

   // if the home_view is maximized, make sure we save the last buffer
   // this fixes the issue of an unsaved buffer being the home_view, 
   // which keeps the maximized state from being saved
   lastBuffer := 0;
   if (home_view.p_window_state == 'M') {
      lastBuffer = -1;
   }

   for (;;) {
      _next_buffer('H');
      if ( p_buf_id==buf_id ) {
         break;
      }
      parse p_buf_name with word rest;
      if (!(p_buf_flags & VSBUFFLAG_HIDDEN) &&
          (
            (_need_to_save() && p_buf_name != '') ||
            (p_buf_name=='.process' && restore_process)
          )) {
         if ( (file_exists(p_buf_name)) ||
              (p_buf_name=='.process' && restore_process)) {
            bufferDataWritten:[p_buf_id]=true;
            write_buffer_data(relativeToDir,restore_view_id,1);
            write_view_data(restore_view_id);

            // check to see if we are keeping track of the last buffer
            if (p_buf_id == home_view.p_buf_id) lastBuffer = 0;         // we will be writing this anyway, so just turn off the last buffer mess
            else if (lastBuffer) lastBuffer = p_buf_id;
         } else {
            not_on_disk_list=not_on_disk_list' 'p_buf_id;
         }
      }
   }
   /* for every window enter window, buffer, and view info */
   activate_window(home_view);

   if (!_no_child_windows()) {
      int first_window_id=p_window_id;
      for (;;) {
         // our direction depends on the next window style
         // we want to restore the same order that we had
         if (_default_option(VSOPTION_NEXTWINDOWSTYLE) == 1) {
            _prev_window("HF");
         } else {
            _next_window("HF");
         }
         /* write out the window's data */
         if (p_window_id != VSWID_HIDDEN) {
            int orig_buf_id=p_buf_id;
            int i;
            for (i=0;;++i) {
               if (bufferDataWritten._indexin(p_buf_id)) {
                  write_window_data(restore_view_id,i==0,p_buf_id == lastBuffer);
                  write_buffer_data(relativeToDir,restore_view_id);
                  write_view_data(restore_view_id);
                  if (p_buf_id!=orig_buf_id) {
                     // Changing the buffer id will force the editor out of
                     // scroll mode (p_scroll_left_edge==-1).  This is called 
                     // from autosave, so we really don't want the scroll 
                     // postion to be changed.  This is not perfect, it will
                     // still have problems if a buffer is not named ( like 
                     // a list buffer ).
                     p_buf_id=orig_buf_id;
                  }
                  break;
               }
               if (def_one_file!='') {
                  break;
               }
               _prev_buffer();
               if (p_buf_id==orig_buf_id) {
                  break;
               }
            }
         }
         if ( p_window_id==first_window_id ) {
            break;
         }
      }
      write_mdistate_data(restore_view_id);
   }

   /* save and exit the status file */
   activate_window(restore_view_id);
   write_select_data();
   //IF we are save data to global auto restore file.
   /* call external save/restore functions. */
   call_list('_sr_','','','',relativeToDir);
   status=0;
   if (!alternate_view_id) {
      if ( rpath!='' && rpath==_ConfigPath() ) {
         status=_create_config_path();
      }
      if ( ! status ) {
         status=_save_file('+o');
         /* Don't care if get error. */
         status=0;
      }
      _delete_temp_view(restore_view_id);
      activate_window(home_view);
      //activate_window home_view
      if ( status<0 ) {
         message(get_message(status));
      }
   }
   activate_window(orig_view_id);
   return(status);

}
static void write_select_data()
{
   if ( _select_type()!='' && _select_type('','S')!='C' ) {
      int start_col=0, end_col=0, buf_id=0;
      _str buf_name="";
      _get_selinfo(start_col,end_col,buf_id,'',buf_name);
      int temp_view_id=0;
      int orig_view_id=0;
      int status=_open_temp_view(buf_name,temp_view_id,orig_view_id,'+b');
      if ( status ) {
         clear_message();
      } else {
         _begin_select();
         typeless start_line=_get_rpoint();
         up();int lfb=_lineflags();
         _end_select();
         typeless last_line=_get_rpoint();
         up();int lfe=_lineflags();
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         if (!(lfb & EOL_MISSING_LF) && !(lfe & EOL_MISSING_LF)) {
            insert_line("MARK: MT="_select_type()' BN="'buf_name'" SL='start_line' SC='start_col' LL='last_line' EC='end_col);
         }
      }
   }
}
static void write_window_data(int buf,boolean specifyFont,boolean forceMaximized)
{
   int this_buf=0;
   get_window_id(this_buf);
   int x=0, y=0, width=0, height=0, icon_x=0, icon_y=0;
   _MDIChildGetWindow(x,y,width,height,'N',icon_x,icon_y);
   _str out='WINDOW: ';
   _str font_info="";

   if (specifyFont) {
      // see if our current font matches the default
      font_info = '"':+p_font_name:+",":+p_font_size",":+_font_props2flags()",":+p_font_charset:+'"';
      default_font_info := '"'strip(_default_font(CFG_WINDOW_TEXT), 'T',',')'"';
      if (font_info == default_font_info) {
         font_info = '",,,"';
      } 
   } else {
      font_info = '",,,"';
   }
   windowState := forceMaximized ? 'M' : p_window_state;

   out=out:+x' 'y' 'width:+' 'height' 'icon_x' 'icon_y' 'windowState' ':+
       ' WF='p_window_flags:+' WT='p_tile_id' 'font_info:+' DID='p_mdi_child_duplicate_id;
   activate_window(buf);
   insert_line(out);
   activate_window(this_buf);
}
static void write_view_data(int buf)
{
   int this_buf=0;
   get_window_id(this_buf);
   _str out="VIEW: ";
   int cx=p_cursor_x;
   int cy=p_cursor_y;
   cy=cy intdiv p_font_height;
   cx=cx intdiv p_font_width;
   _str col=p_col;
   save_pos(auto p);
   up();int lf=_lineflags();
   restore_pos(p);
   if (lf & EOL_MISSING_LF) {
      // Calculate number of characters past the end of the line
      long offset=_QROffset();
      if (p_col>=_text_colc()+1) {
         offset= -offset;
      }
      col='.'offset;
   }

   out :+= 'LN='_get_rpoint()' CL='col' LE='p_left_edge' CX='cx:+
           ' CY='cy' WI='p_window_id' BI='p_buf_id' HT='p_hex_toppage:+
           ' HN='p_hex_nibble' HF='p_hex_field' HC='p_hex_Nofcols;
   activate_window(buf);
   insert_line(out);
   activate_window(this_buf);
}
static void write_buffer_data(_str relativeToDir,int buf,boolean insertBufferInfo=false)
{
   _str buf_name="";
   int this_buf=0;
   get_window_id(this_buf);
   if (relativeToDir==null) {
      buf_name=p_buf_name;
   } else {
      buf_name=relative(p_buf_name,relativeToDir);
   }
   _str out="";
   if (p_DocumentName!="") {
      out='BUFFER: BN="'buf_name'"' '"'p_DocumentName'"';
   } else {
      out='BUFFER: BN="'buf_name'"';
   }
   int readonly_flags=(p_readonly_mode)?READONLY_ON:0;
   if (p_readonly_set_by_user) {
      readonly_flags|=READONLY_SET_BY_USER;
   }
   CLscheme := def_color_scheme;
   SCscheme := _GetSymbolColoringSchemeName();
   if (def_symbol_color_scheme==null ||
       def_symbol_color_scheme.m_name == null ||
       SCscheme == def_symbol_color_scheme.m_name) {
      SCscheme = "";
      CLscheme = "";
   }
   _str SCenabled = _QSymbolColoringEnabled();
   _str SCerrors  = _QSymbolColoringErrors();
   if (SCenabled == _QSymbolColoringEnabled(true)) SCenabled = "";
   if (SCerrors  == _QSymbolColoringErrors(true))  SCerrors  = "";
      
   _str out2='BI: MA='p_margins:+' TABS='p_tabs:+' WWS='p_word_wrap_style:+
             ' IWT='p_indent_with_tabs:+' ST='p_ShowSpecialChars:+
             ' IN='p_indent_style' BW='p_buf_width:+' US='p_undo_steps:+
             ' RO='readonly_flags' SE=' p_showeof' SN=0 BIN='p_binary:+
             ' MN='p_mode_name"\tHM="p_hex_mode" MF="p_ModifyFlags:+
             " TL="p_TruncateLength" MLL="p_MaxLineLength" ASE="p_AutoSelectLanguage:+
             ' LNL='p_line_numbers_len' LCF='p_LCBufFlags' CAPS='p_caps:+
             ' E='p_encoding' ESBU2='p_encoding_set_by_user:+
             ' CL='_dquote(CLscheme)' SC='_dquote(SCscheme):+
             ' SCE='SCenabled' SCU='SCerrors;
   activate_window(buf);
   insert_line(out);
   if ( insertBufferInfo ) {  /* Insert buffer info? */
      insert_line(out2);
   }
   activate_window(this_buf);
}

static void write_mdistate_data(int restore_wid)
{
   int orig_wid;
   get_window_id(orig_wid);

   _str state = '';
   _MDISaveState(state);
   activate_window(restore_wid);
   int noflines = 1;
   insert_line('MDISTATE: ':+noflines);
   insert_line(state);

   activate_window(orig_wid);
}

static void write_retrieve_data(int view_id)
{
   typeless mark=_alloc_selection();
   if ( mark<0) {
      return;
   }
   activate_window(VSWID_RETRIEVE);
   top();
   // Check for embedded carriage return or line feed
   // Can't save retrieve info if there is an embedded cr or lf
   if (_embedded_crlf()) {
      bottom();
      activate_window(view_id);
      _free_selection(mark);
      return;
   }
   _select_line(mark);
   bottom();
   _select_line(mark);
   int Noflines=count_lines_in_selection(mark);
   activate_window(view_id);
   insert_line("RETRIEVE: "Noflines);
   _copy_to_cursor(mark);
   bottom();
   _free_selection(mark);
}
static void restore_retrieve_data(int Noflines)
{
   if ( ! Noflines ) {
      return;
   }
   typeless mark=_alloc_selection();
   if ( mark<0) {
      down(Noflines);
      return;
   }
   int view_id=0;
   get_window_id(view_id);
   down();
   _select_line(mark);
   down(Noflines-1);
   _select_line(mark);
   activate_window(VSWID_RETRIEVE);
   if ( !_line_length()) {
      _delete_line();
   }
   _copy_to_cursor(mark);
   _free_selection(mark);
   bottom();
   activate_window(view_id);
}
static void set_screen_size(typeless line,var do_one_window,var mdi_state,boolean RestoreFromInvocation)
{
   typeless width=0, height=0, mdi_x=0, mdi_y=0, mdi_width=0, mdi_height=0, mdi_ix=0, mdi_iy=0, ifl=0, dft=0, ifr=0, ufb=0, client_width=0, client_height=0;
   parse line with width height mdi_x mdi_y mdi_width mdi_height mdi_ix mdi_iy mdi_state ifl dft ifr ufb client_width client_height ;
   /* If screen size different */
   if ( _screen_height()!=height || _screen_width()!=width ) {
      do_one_window=1;
   }
#if 0
   if ( ifl<_mdi.p_in_from_left || dft<_mdi.p_down_from_top || ifr<_mdi.p_in_from_right || ufb<_mdi.p_up_from_bottom) {
      do_one_window=1;
   }
#endif
   typeless junk=0;
   int mdiclient_width=0, mdiclient_height=0;
   _mdi._MDIClientGetWindow(junk,junk,mdiclient_width,mdiclient_height);
   if ( client_width=="" || client_width>mdiclient_width || client_height>mdiclient_height) {
      //do_one_window=1;
   }
   if (!RestoreFromInvocation) {
      // Don't want to restore position of icon.  Let Windows determine position
      // so that the icon does not overlap an existing icon.
      if (mdi_state!='M' && mdi_state!='N') {
         mdi_state='N';
      }
      if (mdi_width && mdi_height) {
         _mdi._move_window(mdi_x,mdi_y,mdi_width,mdi_height,"N" /*mdi_state*/);
         _mdi.p_window_state=mdi_state;
      }
   } else if(mdi_state=='N') {
      // Make sure mdi frame is visible on any monitor
      _mdi._CenterIfFormNotVisible();
   }
}

static void _goto_rpoint(typeless line)
{
   line=strip(line);
   if ( substr(line,1,1)=='.' ) {
      typeless p=substr(line,2);
      typeless status=_GoToROffset(p);
      if ( status ) {
         clear_message();
         if ( p>0 ) {
            bottom();
         }
      }
      _begin_line();
   } else {
      p_RLine=line;
   }
}
static _str _get_rpoint()
{
   save_pos(auto p);
   _begin_line();
   _str result='.'_QROffset();
   restore_pos(p);
   return(result);
}

int _srg_open(_str option='',_str info='')
{
   if ( option=='R' || option=='N' ) {
      parse info with . _last_open_path"\t"_last_open_cwd;
   } else {
      insert_line('OPEN: 0 '_last_open_path"\t"_last_open_cwd);
   }
   return(0);
}
int _srg_debug_window(_str option='',_str info='')
{
   // deprecated restore callback
   // DEBUG_WINDOW: x y z
   //    x is not number of lines to read
   return(0);
}
int _srg_debug_window2(_str option='',_str info='')
{
   typeless x,y,w,h;
   if ( option=='R' || option=='N' ) {
      _DebugWindowRestore(info);
   } else if (!_DebugWindowSave(info)) {
      insert_line('DEBUG_WINDOW2: 'info);
   }
   return(0);
}
