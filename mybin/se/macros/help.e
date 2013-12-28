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
#include "eclipse.sh"
#include "hthelp.sh"
#include "pip.sh"
#include "xml.sh"
#import "codehelp.e"
#import "compile.e"
#import "context.e"
#import "dlgman.e"
#import "doscmds.e"
#import "helpidx.e"
#import "html.e"
#import "listbox.e"
#import "main.e"
#import "optionsxml.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "treeview.e"
#import "util.e"
#endregion

static _str help_class_number;
static _str help_class_type;

#define OS2_USE_HTHELP 1
_str def_bottom_border;
_str _retrieve;

#if __PCDOS__
_str def_msdn_coll;
#endif 

#define HELP_MIN_WIDTH 3000
#define HELP_LABEL_X 300
#define HELP_LABEL_Y 300
#define HELP_LEFTRIGHT_PADDING HELP_LABEL_X
#define HELP_OKBUTTON_WIDTH 1000
#define HELP_OKBUTTON_HEIGHT 400
#define HELP_OKBUTTON_FROM_BOTTOM 300
#define HELP_BETWEEN_LABEL_Y 400

#define SLICK_HELP_INDEXPAGE "ix01.htm"
#define SLICK_HELP_SEARCHPAGE "search.htm"

/**
 * Displays <i>message_text</i> in message box with an information 
 * icon displayed to the left of the message.  This function is typically 
 * used to display help information messages.
 * 
 * @param string     message to display
 * 
 * @see popup_message
 * @see _message_box
 * @see help
 * @see message
 * @see messageNwait
 * @see sticky_message
 * @see clear_message
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void popup_imessage(_str string="")
{
   popup_message(string,MB_OK|MB_ICONINFORMATION);
}
/**
 * Displays <i>message_text</i> in message box with an exclamation 
 * point displayed to the left of the message.  Use the new and more 
 * powerful <b>_message_box</b> function instead of this function.  
 * This function is typically used with the <b>_post_call</b> function to 
 * display an error message box during <b>on_got_focus</b> or 
 * <b>on_lost_focus</b> events.
 * 
 * @param string     message to display
 * @param flags      message box flags (MB_*)
 * @param title      message box title
 * 
 * @see popup_imessage
 * @see _message_box
 * @see help
 * @see message
 * @see messageNwait
 * @see sticky_message
 * @see clear_message
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void popup_message(_str string="", typeless flags="", _str title="")
{
   if (flags==''){
      flags=MB_OK|MB_ICONEXCLAMATION;
   }
   if (title=='') {
      title=editor_name('a');  // Application name
   }
   // Parse off switches
   for (;;) {
      string=strip(string,'L');
      if (substr(string,1,1)!='-'){
         break;
      }
      _str option="";
      parse string with option string;
      switch(lowcase(option)){
      case '-title':
         title=strip(parse_file(string),'B','"');
         break;
      }
   }
   _message_box(string,title,flags);
}

/**
 * Launches the help index page.
 * 
 * @param help_file URL of the help index page.  DO make sure that this path
 * is a valid URL in UNIX build e.g. file:///opt/slickedit/.....
 */
static void _help_contents(_str help_file)
{
   if (__UNIX__) {
      // Make sure that the path in help_file begins with 'file://', or it will not 
      // work if there is already a running instance of mozilla/firefox.
      goto_url(help_file, true);
      return;
   }
   typeless status=_syshtmlhelp(help_file);
   _help_error(status,help_file,'');
}
 #define VSHELP_PARTIALKEY 0x0105
int _word_help(_str help_file,_str word,boolean ImmediateHelp=false,boolean maybeWordHelp=false)
{
   if(isEclipsePlugin()) {
      _eclipse_help(word);
      return 0;
   }
   if(isVisualStudioPlugin()) {
      return 0;
   }

   // currently if maybe_word_help!=0 then help_file must be vslick.hlp
   if (maybeWordHelp && !_isEditorCtl()) {
      _help_contents(help_file);
      return(0);
   }
   if (_isEditorCtl() && word=='' && (
       file_eq('.'_get_extension(p_buf_name),_macro_ext) ||
       file_eq('.'_get_extension(p_buf_name),'.sh'))) {
      help_file=_help_filename('');
   } else if (maybeWordHelp) {
#if !__UNIX__
      _str second="", third="", rest="";
      parse def_wh with help_file ';' second ';' third ';' rest;
#endif
   }
   boolean allHelpWorkDone=false;
   int start_col=0;
   _str ext=_get_extension(help_file);
   if (word=='') {
      if( _isEditorCtl()) {
         word=_CodeHelpCurWord(allHelpWorkDone);
         if (word!='') {
            // When we are in code help, pressing F1 is like press Ctrl+F1 (word help)
            maybeWordHelp=false;
         }
         if (allHelpWorkDone) {
            return(0);
         }
         if (word=='') {
            word=cur_word(start_col);
         }
      }
      if (word=='') {
         if (__UNIX__ || !file_eq(ext,'idx') ) {
            if (maybeWordHelp) {
               _help_contents(help_file);
               return(0);
            } else {
               message(nls('No word at cursor'));
               return(0);
            }
         }
      }
   }

#if __PCDOS__

   // See if the user has elected to use MSDN keyword help
   // and maybe launch here if word is not ''. We also do not
   // launch MSDN help if the current document is a Slick-C macro
   // TODO: Also ignore if the help is in a collection for another
   // language that the user has configured using the help-index method
   if(word != '' && def_msdn_coll != '')
   {
      if(_isEditorCtl() && !(file_eq('.'_get_extension(p_buf_name),_macro_ext) || file_eq('.'_get_extension(p_buf_name),'.sh')))
      {
         if(msdn_do_word_help(word))
         {
            return 1;
         }
      }
   }
#endif

   _str filename="";
   typeless result=0;
   typeless status=0;
#if !__UNIX__
   if (file_eq(ext,'idx') && (word!='' || !maybeWordHelp)) {
      //_help_file_spec
      // do not search the current directory in case we are in the
      // slickedit install dir (which would skip over the file in the user's configuration)
      filename=slick_path_search(help_file, 'S');
      if (filename=='') {
         _message_box(nls("File %s not found.  You may need to build this help index file.  Use Help menu, Configure Index File.",help_file));
         return(FILE_NOT_FOUND_RC);
      }
      help_file=filename;
      result=show('-modal _help_index_form',help_file,word,'',ImmediateHelp,maybeWordHelp);
      if (result=='') return(1);
      if (result!=2) {
         status=0;
         //status=_syshelp(_param1, _param2, (def_help_flags&HF_EXACTMATCH)?HELP_KEY:HELP_PARTIALKEY);
         _help_error(status,help_file,word);
         return(0);
      }
   }

   help_file=_help_filename(help_file);
   // It would be nice if we supported + signs for .mvb and .hlp files here
   // instead of in _syshelp
   if (file_eq(ext,'mvb') && (word!='' || !maybeWordHelp)) {
      status=_winhelpfind(help_file,word,VSHELP_PARTIALKEY,0);
      if (!status || !maybeWordHelp) {
         if (status) {
            _message_box(nls("No help on '%s' found in %s",word,help_file));
            return(status);
         }
         _ntDefaultHelp(help_file,word);
         return(0);
      }
   }
   /*if (word=='') {
      if( _isEditorCtl()) {
         extension=get_extension(p_buf_name)
         if ( file_eq('.'extension,_macro_ext) || file_eq(extension,'cmd') ||
            (file_eq(extension,'sh')) ) {
            return(help(word));
         }
      }
   }
   */
#endif
#if __UNIX__
   if( _isEditorCtl()) {
      _str extension=_get_extension(p_buf_name);
      if ( file_eq('.'extension,_macro_ext) || file_eq(extension,'cmd') ||
         (file_eq(extension,'sh')) ) {
         _str new_keyword=h_match_exact(word);
         if (new_keyword=='') {
            if (maybeWordHelp) {
               _help_contents(help_file);
               return(0);
            }
            _message_box(nls("Help item '%s' not found",word));
            return(STRING_NOT_FOUND_RC);
         }
         word=new_keyword;
         html_keyword_help(_help_filename(''),word);
         return(0);
      }
   }
   if( _isEditorCtl()) {
      status=man(word);
      if (status && maybeWordHelp) {
         _help_contents(help_file);
         return(0);
      }
      return(status);
   } else {
      mou_hour_glass(1);
      int wid=_find_object("_unixman_form","n");
      if (wid) {
         _nocheck _control ctlfind;
         _nocheck _control ctleditorctl;
         wid._set_foreground_window();
         wid.ctleditorctl._set_focus();
         wid.ctlfind.call_event(word,1,wid.ctlfind,on_create,"");
         mou_hour_glass(0);
         return(0);
      }
      status=show("-xy -app _unixman_form",word,0);
      mou_hour_glass(0);
      return(status);
   }
#else
      if (maybeWordHelp) {
         help_file=_help_filename('');
      }
      if (word=='') {
         _help_contents(help_file);
         return(0);
      }
      status=html_keyword_help(help_file,word,true);
      return(0);
#endif
}

/**
 * Displays SDK help for the word at the cursor.  This command requires 
 * that the macro variable "def_wh" be set to the WinHelp file.  Make 
 * sure that the help file appears in your path.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command wh(_str word="") name_info(','VSARG2_EDITORCTL)
{
   _str first, second, third, rest;
   parse def_wh with first ';' second ';' third ';' rest ;
   return(_word_help(first,word));
}
_command wh2(_str word="") name_info(','VSARG2_EDITORCTL)
{
   _str first, second, third, rest;
   parse def_wh with first ';' second ';' third ';' rest ;
   return(_word_help(second,word));
}

_command wh3(_str word="") name_info(','VSARG2_EDITORCTL)
{
   _str first, second, third, rest;
   parse def_wh with first ';' second ';' third ';' rest ;
   return(_word_help(third,word));
}
_command qh(_str word="") name_info(','VSARG2_ICON|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (word=='') {
      int junk=0;
      word=cur_word(junk);
   }
   dos('qh 'word);
}

#if __PCDOS__

/**
 * Look up the symbol information for the symbol under the cursor 
 * and attempt to map that to a MSDN help topic, following the 
 * patterns we have observed from the MSDN help collection indexing. 
 * 
 * @return MSDN help topic (or topic prefix) on success. 
 *         '' if we can't do anything special.  
 */
static _str getMSDNTopicName()
{
   // current object must be an editor control
   if (!_isEditorCtl()) {
      return '';
   }

   // if the current language is not a Microsoft language, then
   // forget about all this stuff.
   lang := _GetEmbeddedLangId();
   if (!_LanguageInheritsFrom('c',lang) &&
       !_LanguageInheritsFrom('cs',lang) &&
       !_LanguageInheritsFrom('bas',lang) &&
       !_LanguageInheritsFrom('vbs',lang) &&
       !_LanguageInheritsFrom('jsl',lang)) {
      return '';
   }

   // Get the current word at the cursor
   status := tag_get_browse_info('', auto cm, true, auto all_choices, true);
   if (status) {
      return '';
   }

   // check that all the choices come from the same class
   if (all_choices._length() != 1) {
      VS_TAG_BROWSE_INFO acm;
      foreach (acm in all_choices) {
         if (acm.class_name!=cm.class_name) {
            return '';
         }
      }
   }

   // C++ STL is a special case
   if (_LanguageInheritsFrom('c') && lang==_Filename2LangId(cm.file_name)) {
      // and stl string deserves a special special casing
      if (cm.class_name=="std" && cm.member_name=='string') {
         return 'basic_string class';
      }
      // the help topics for 
      selectedWord := cm.member_name;
      if (tag_tree_type_is_func(cm.type_name) && cm.class_name != '') {
         selectedWord :+= " method";
      } else if (cm.type_name == 'struct') {
         selectedWord :+= " structure";
      } else if (cm.type_name == 'interface') {
         selectedWord :+= " interface";
      } else if (cm.type_name == 'class') {
         selectedWord :+= " class";
      } else if (cm.type_name == 'enum') {
         selectedWord :+= " enumeration";
      }
      return selectedWord;
   }

   // We are, presumably, in .NET API territory here.
   // convert the class name to "." form
   selectedWord := cm.class_name;
   if (selectedWord != '') {
      selectedWord = stranslate(selectedWord, '.', VS_TAGSEPARATOR_class);
      selectedWord :+= ".";
   }
   selectedWord :+= cm.member_name;

   // massage the final result, depending on the tag type
   boolean stripPackage = false;
   if (tag_tree_type_is_func(cm.type_name) && cm.class_name!='') {
      stripPackage = true;
      if (cm.flags & VS_TAGFLAG_constructor) {
         selectedWord :+= " constructor";
      } else {
         selectedWord :+= " method";
      }
   } else if (cm.type_name == 'prop') {
      selectedWord :+= " property";
      stripPackage = true;
   } else if (tag_tree_type_is_data(cm.type_name) && cm.class_name!='') {
      stripPackage = true;
   } else if (cm.type_name == 'struct') {
      selectedWord :+= " structure";
   } else if (cm.type_name == 'interface') {
      selectedWord :+= " interface";
   } else if (cm.type_name == 'class') {
      selectedWord :+= " class";
   } else if (tag_tree_type_is_class(cm.type_name)) {
      selectedWord :+= " class";
   } else if (cm.type_name == 'enum') {
      selectedWord :+= " enumeration";
   } else if (tag_tree_type_is_package(cm.type_name)) {
      selectedWord :+= " namespace";
   } else if (cm.class_name != '') {
      selectedWord = cm.member_name;
   }

   // strip the package name if we have a method or property
   if (stripPackage) {
      package_pos := lastpos(VS_TAGSEPARATOR_package, selectedWord);
      if (package_pos > 0) {
         selectedWord = substr(selectedWord,package_pos+1);
      }
   } else {
      // otherwise, just convert the separator to a dot.
      selectedWord = stranslate(selectedWord, '.', VS_TAGSEPARATOR_package);
   }

   //say("msdn_word_help: selectedWord="selectedWord);
   return selectedWord;
}

/**
 * Displays SDK help from MSDN Libraries (Visual Studio, Platform SDK, any Help 2.0 collection)
 * for the word at the cursor.  This command requires 
 * that the macro variable "def_msdn_coll" be set to a preferred collection in the
 * form ms-help://namespace where namespace is a valid Help 2.0 URL like MS.VSCC.v80.
 * The namespaces installed on the machine can be listed and a preferred collection chosen
 * by invoking the _msdn_collections_form. The configuration form can be acccessed by
 * calling the msdn_configure_collection macro, or choosing 'Configure MSDN F1 Help'
 * from the MDI help menu.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command msdn_word_help() name_info(','VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // get the current word at the cursor
   _str selectedWord = getMSDNTopicName();
   if (selectedWord == '') {
      selectedWord = cur_word(auto startCol);
   }
   if(selectedWord == null || length(selectedWord) < 1) {
      message("No word at cursor");
      return 0;
   }

   // If the user hasn't configured a help collection, ask.
   if(def_msdn_coll == '') {
      _str retVal = _message_box("You have not chosen a preferred MSDN collection. Would you like to select one now?", 
                "MSDN Collection not configured",
                MB_YESNO | MB_ICONINFORMATION);

      if(retVal == IDYES) {
         msdn_configure_collection();
      }
   }

   msdn_do_word_help(selectedWord);
   
}

static int msdn_do_word_help(_str keyword)
{
   if(def_msdn_coll == '')
   {
      message("MSDN Help collection not configured.");
      return 0;
   }
   // The preferred MSDN help collection is chosen via the _msdn_collections_form
   // and is stored in the def_msdn_coll variable
   _str helpColl = "ms-help://"def_msdn_coll;
   // The filter parameter is not yet a settable value, even though the 
   // msdn_keyword_help function fully supports it. 
   _str filter = "";

   return msdn_keyword_help(keyword, helpColl, filter);
}

/**
 * Displays the configuration dialog to choose an MSDN collection
 * 
 * @return typeless
 */
_command msdn_configure_collection()
{
   config('Help Options > General'); 
}
#endif

_help_list(_str file_spec="")
{
   if (file_spec=="") {
      file_spec=get_env("VSROOT"):+SLICK_HELPLIST_FILE;
   }
   //file_spec=_config_path():+SLICK_HELPLIST_FILE;
   if (!file_exists(file_spec)) {
      _message_box(nls("Can't find help file '%s'",SLICK_HELPLIST_FILE));
   }
   return(file_spec);
}
_str _help_filename(_str file_spec="")
{
#if __UNIX__
   if (file_spec=='') {
      file_spec=_help_file_spec;
   }
   if(file_spec=='') {
      file_spec=get_env('VSROOT'):+'help':+FILESEP:+SLICK_HELP_FILE;
      if (!file_exists(file_spec)) {
         _message_box(nls("Can't find help file '%s'",SLICK_HELP_FILE));
         //_message_box(nls("Can't find help file '%s",SLICK_HELP_FILE))
      }
      if (file_spec!='') {
         _help_file_spec=absolute(file_spec);
         file_spec=_help_file_spec;
      }
      return(file_spec);
   }
   if (pos('+',file_spec)) {
      return(file_spec);
   }
   _str temp=slick_path_search(file_spec,"S");
   if (temp=='') {
      _message_box(nls("Can't find help file '%s'",file_spec));
      return('');
   }
   if (file_spec=='' && temp!='') {
      _help_file_spec=absolute(temp);
   }
   temp=_parse_project_command(temp, '', '', '');
   return(temp);
#else
   if (file_spec=='') {
      file_spec=_help_file_spec;
   }
   if(file_spec=='') {
      file_spec=get_env('VSROOT'):+'help':+FILESEP:+SLICK_HELP_FILE;
      if (!file_exists(file_spec)) {
         _message_box(nls("Can't find help file '%s'",file_spec));
         //_message_box(nls("Can't find help file '%s",SLICK_HELP_FILE))
      }
      if (file_spec!='') {
         _help_file_spec=absolute(file_spec);
         file_spec=_help_file_spec;
      }
      return(file_spec);
   }
   if (pos('+',file_spec)) {
      return(file_spec);
   }
   _str temp=slick_path_search(file_spec,"S");
   if (temp=='') {
      _message_box(nls("Can't find help file '%s'",file_spec));
      return('');
   }
   if (file_spec=='' && temp!='') {
      _help_file_spec=absolute(temp);
   }
   temp=_parse_project_command(temp, '', '', '');
   return(temp);
#endif
}
static _str hmpu_sellist_callback(int sl_event,_str &result,_str info)
{
   if (sl_event==SL_ONDEFAULT) {
      // check that the item in the combo box is a valid Slick-C identifier
      result=_sellist._lbget_text();
      _param1=_sellist.p_line-1;
      return(1);
   }
   return('');
}
_str h_match_pick_url(_str name,boolean &CrossReferenceMultiplyDefined=false,_str helpindex_filename=SLICK_HELPINDEX_FILE,boolean quiet=false,boolean justVerifyHaveKeyword=false,int xmlcfg_helpindex_handle= -1)
{
   CrossReferenceMultiplyDefined=false;
   int IndexTopicNodes[];
   _str filename="";
   int handle=xmlcfg_helpindex_handle;
   if (handle<0) {
      filename=get_env("VSROOT"):+'help':+FILESEP:+helpindex_filename;
      //filename=maybe_quote_filename(_config_path():+SLICK_HELPLIST_FILE);
      int status;
      handle=_xmlcfg_open(filename,status);
      if (handle<0) {
         if ( handle==FILE_NOT_FOUND_RC ) {
            _message_box(nls("File '%s' not found",filename));
         } else {
            _message_box(nls("Error loading help file '%s'",filename));
         }
         return('');
      }
   }
   
   int key;
   if (pos("'",name)) {
      key=_xmlcfg_find_simple(handle,'/indexdata/key[strieq(@name,"'name'")]');
   } else {
      key=_xmlcfg_find_simple(handle,"/indexdata/key[strieq(@name,'"name"')]");
   }

   if (key<0) {
      if (xmlcfg_helpindex_handle<0) _xmlcfg_close(handle);
      if (!quiet) {
         _message_box(nls("%s1 not found in the help index",name));
      }
      return('');
   }
   _str array[];
   _str array_url[];
   _xmlcfg_find_simple_array(handle,"topic/@name",array,key,VSXMLCFG_FIND_VALUES);
   _xmlcfg_find_simple_array(handle,"topic/@url",array_url,key,VSXMLCFG_FIND_VALUES);
   if (xmlcfg_helpindex_handle<0) _xmlcfg_close(handle);
   if (!array._length()) {
      if (!quiet) {
         _message_box(nls("Error in help file.  No URL's for help index item '%s1'",name));
      }
      return('');
   }
   if (array._length()==1 || justVerifyHaveKeyword ) {
      return(array_url[0]);
   }
   CrossReferenceMultiplyDefined=1;
   
   typeless result=show('-modal _sellist_form',
                        'Choose a Help Topic',
                        SL_DEFAULTCALLBACK|SL_SELECTCLINE, // flags
                        array,   // input_data
                        "OK", // buttons
                        '',   // help item
                        '',   // font
                        hmpu_sellist_callback   // Call back function
                       );
   if (result=='') {
      return('');
   }
   return(array_url[_param1]);
}

_str h_match_exact(_str name)
{
   int view_id=0;
   get_window_id(view_id);
   activate_window(VSWID_HIDDEN);
   //tname=lowcase(translate(name,'_','-'));
   typeless result=h_match(name,1);
   for (;;) {
      if (result=='') {
          h_match(name,2);
          activate_window(view_id);
          return('');
      }
      if (strieq(name,result) /*lowcase(translate(result,'_','-'))*/) {
          h_match(name,2);
          activate_window(view_id);
          return(result);
      }
      result=h_match(name,0);
   }
}
int gxmlcfg_help_index_handle;
static _str ghm_array[];
static int ghm_i;
_str h_match(_str &name,int find_first)
{
   _str filename="";
   _str tname=lowcase(translate(name,'_','-'));
   if ( find_first ) {
      if ( find_first:==2 ) {
         ghm_array._makeempty();
         return('');
      }
      ghm_array._makeempty();ghm_i=0;
      if (!gxmlcfg_help_index_handle) {
         filename=get_env("VSROOT"):+'help':+FILESEP:+SLICK_HELPINDEX_FILE;
         //filename=maybe_quote_filename(_config_path():+SLICK_HELPLIST_FILE);
         int status;
         int handle=_xmlcfg_open(filename,status);
         if (handle<0) {
            if ( handle==FILE_NOT_FOUND_RC ) {
               _message_box(nls("File '%s' not found",filename));
            } else {
               _message_box(nls("Error loading help file '%s'",filename));
            }
            return('');
         }
         gxmlcfg_help_index_handle=handle;
      }
      _xmlcfg_find_simple_array(gxmlcfg_help_index_handle,"/indexdata/key/@name",ghm_array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
      //name=_escape_re_chars(translate(name,"\n\n","-_"));
      //name=stranslate(name,'[\-_]',"\n");
      //status=search('^ ('name'|:ghm_i, 'name')','ri@');
   }
   for (;;) {
      if (ghm_i>=ghm_array._length()) {
         return('');
      }
      if (length(ghm_array[ghm_i])>=length(name) && 
          strieq(tname,substr(translate(ghm_array[ghm_i],'_','-'),1,length(name)))
          ) {
         break;
      }
      ++ghm_i;
   }
   ++ghm_i;
   return(ghm_array[ghm_i-1]);
}
static _help_error(int status,_str in_filenames,_str word)
{
   if (status==STRING_NOT_FOUND_RC) {
      _message_box(nls('No help on %s',word));
      return('');
   }
   if (status==FILE_NOT_FOUND_RC) {
      _str filename="";
      _str filenames=in_filenames;
      for (;;) {
         parse filenames with filename '+' filenames ;
         filename=strip(filename,'B');
         if (filename=='') {
            _message_box(nls("File '%s' not found.",in_filenames));
            return('');
         }
         _str ext=_get_extension(filename);
         typeless result=slick_path_search(filename);
         if (result=='') {
            _message_box(nls("File '%s' not found.",filename));
            return('');
         }
      }
   }
}
static _str EmulateHelpItem()
{
   if (def_keys == "vcpp-keys") {
      return "Visual C++ Emulation Keys";
   }
   return longEmulationName(def_keys) :+ " Emulation Keys";
}
static int html_keyword_help(_str filename,_str keyword,boolean show_contents_if_keyword_not_found=false)
{
   boolean junk=false;
   _str index_filename=_strip_filename(_strip_filename(filename,'P'),'E'):+"index.xml";
#if __UNIX__
   // All OEMs using their own help file must put an index file in the slickedit/help directory
   // named "u<helpfilename>index.xml".
   index_filename="u":+index_filename;

   // Check to see if this is the SlickEdit system helpfile, which is treated a little differently
   system_help_filename:=_help_filename();
   if ( file_eq(filename,system_help_filename) ) {
      // Just use SLICK_HELPINDEX_FILE, which will not match the format above on UNIX 
      index_filename=SLICK_HELPINDEX_FILE;
   }
#endif 
   _str url=h_match_pick_url(keyword,junk,index_filename,show_contents_if_keyword_not_found,__UNIX__);
   if (url=='') {
      _help_contents(filename);
      return(1);
   }
#if __UNIX__
   url=absolute(get_env('VSROOT'):+'help/WebHelp/':+url);
   /*
   //url=relative(url,get_env('VSROOT'):+'help/WebHelp/');
   if (_isMac() && ('..':+FILESEP:+'api':==lowcase(substr(url,1,6)))) {
      url=absolute(get_env('VSROOT'):+'help/WebHelp/'SLICK_HELP_MAINPAGE'#':+url);
   } else {
      url=absolute(get_env('VSROOT'):+'help/WebHelp/'SLICK_HELP_MAINPAGE'?index=':+keyword);
   }
   */ 
   url='file:///':+url;
   url=stranslate(url,'%20',' ');
   url=stranslate(url,'%28','(');
   url=stranslate(url,'%29',')');
   //_message_box('url='url);
   goto_url(url,true);
   return(0);
#if 0
   // Add a timestamp to make every url unique, so the browser never thinks
   // it already has the page loaded.
   _str path, hashref, query;
   parse url with path '#' +0 hashref;
   parse path with path '?' +0 query;
   if( query=="" ) {
      query="?timestamp="_time('B');
   } else {
      query=query"&timestamp="_time('B');
   }
   url=path:+query:+hashref;

   url=absolute(get_env('VSROOT'):+'help/WebHelp/':+url);
   url=relative(url,get_env('VSROOT'):+'help/WebHelp/');
   url=absolute(get_env('VSROOT'):+'help/WebHelp/'SLICK_HELP_MAINPAGE'?url=':+url);
   url='file:///':+url;
   url=stranslate(url,'%20',' ');
   //_message_box('url='url);
   return(goto_url(url,true));
#endif

#else
   return(_syshtmlhelp(filename,HH_DISPLAY_TOPIC,url));
#endif
}
/**
 * <p>The help command allows you to use the command line to get help on a 
 * specific help item.  The <i>name</i> parameter is one of over 1700 possible 
 * help items (stored in "vslick.lst" or "uvslick.lst" for UNIX).  You don't 
 * have to memorize every help item.  Use the space bar and '?' keys 
 * (completion) to help you enter the name.  If you are looking at some macro 
 * source code and want help on a function, invoke the <b>help</b> command and 
 * specify the name of the function.  Browse some of the features on the Help 
 * menu.  You may find them useful as well.  If you specify "-search" for 
 * <i>name</i>, the help search dialog box is displayed.  For UNIX, if you 
 * specify "-using" for <i>name</i>, help on using help is displayed.</p>
 * 
 * <p>Press the ESC key to toggle the cursor to the command line.</p>
 *
 * @example
 * <pre>
 *      help substr
 *    help _control
 *    help windows keys
 *    help slickedit keys
 *    help emacs keys
 *    help brief keys
 *    help regular expressions
 *    help operators
 * </pre>
 * 
 * <p>F1 displays context sensitive help.  When you are not in any context, help 
 * on table of contents is displayed.</p>
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command help(_str keyword="", _str filename="") name_info(HELP_ARG','VSARG2_CMDLINE)
{
   if(isEclipsePlugin()) {
      _str url = h_match_pick_url(keyword);
      if (url != '') {
         _eclipse_help(url);
      }
      return 0;
   }
   if(isVisualStudioPlugin()) {
      return 0;
   }

   int i=0;
   _str first_ch="";
   _str command="";
   typeless status=0;
   _str url="";

   if ( p_window_id==_cmdline && keyword=='' && filename=='') {
      /* Check if a command is on the command line */
      _cmdline.get_command(command);
      parse command with command .;
      first_ch=substr(command,1,1);
      i=pos('[~A-Za-z0-9_\-]',command,1,'r');
      if ( i ) {
         command=substr(command,1,i-1);
      }
      if ( isdigit(first_ch) ) {
         command='0';
      } else if ( ! isalpha(first_ch) ) {
         command=first_ch;
      }
      if ( command!='' ) {
         if (def_keys=='ispf-keys' && h_match_exact('ispf-'lowcase(command))!='') {
            return(help('ispf-'lowcase(command)));
         }
         if (h_match_exact(command)!='') {
            return(help(command));
         }
         ucommand := stranslate(command, '_', '-');
         if (h_match_exact(ucommand)!='') {
            return(help(ucommand));
         }
         // Show table of contents item
         keyword='';
      }
   }
   orig_filename := filename;
   filename=_help_filename(filename);
   if (filename=='') {
      return(1);
   }
   if ( keyword=='') {
      _word_help(filename,'',false,1);
      // Show table of contents

      //status=_syshelp(filename,'',HELP_CONTENTS);
      //_help_error(status,filename,'');
      return(1);
   }
   if (lowcase(keyword)=='-contents') {
#if __UNIX__
      filename = 'file://' :+ filename;
#endif
      _help_contents(filename);
      return(1);
   }
   if (lowcase(keyword)=='-index') {
#if __UNIX__
      url=get_env('VSROOT'):+'help/WebHelp/'SLICK_HELP_INDEXPAGE;
      url='file:///':+url;
      url=stranslate(url,'%20',' ');
      return(goto_url(url,true));
#else
      status=_syshtmlhelp(filename,HH_DISPLAY_INDEX);
      _help_error(status,filename,'');
      return(1);
#endif
   }
   if (lowcase(keyword)=='-using') {
      _message_box('-using option no longer supported');
      return(1);
   }
   if (lowcase(keyword)=='-search') {
#if __UNIX__
      url=get_env('VSROOT'):+'help/WebHelp/'SLICK_HELP_SEARCHPAGE;
      url='file:///':+url;
      url=stranslate(url,'%20',' ');
      return(goto_url(url,true));
#else
      status=_syshtmlhelp(filename,HH_DISPLAY_SEARCH);
      _help_error(status,filename,'');
#endif
      return(1);
   }
   if (lowcase(keyword)=='summary of keys') {
      keyword=EmulateHelpItem();
   }
   if (_isMac() && lowcase(keyword)=='macro functions by category') {
      url=get_env('VSROOT'):+'help/api/macro_functions_by_category.html';
      url=stranslate(url,'%20',' ');
      return(goto_url(url,true));
   }
   if (orig_filename==''){
      if (def_error_check_help_items) {
         _str new_keyword='';
         if (def_keys=='ispf-keys') {
            new_keyword=h_match_exact('ispf-'lowcase(keyword));
         }
         if (new_keyword=='') {
            new_keyword=h_match_exact(keyword);
         }
         if (new_keyword=='') {
            new_keyword=h_match_exact(stranslate(keyword, '_', '-'));
         }
         if (new_keyword=='') {
            _message_box(nls("Help item '%s' not found",keyword));
            return(STRING_NOT_FOUND_RC);
         }
         keyword=new_keyword;
      }
   }
   if (def_error_check_help_items || __UNIX__) {
      _str ext=_get_extension(filename);
      if ( file_eq(ext,'chm') || file_eq(ext,'htm') ) {
         status=html_keyword_help(filename,keyword);
      }else if ( file_eq(ext,'hlp') ) {
         _syshelp(filename,keyword);
      }
   } else {
      status=_syshtmlhelp(filename,HH_KEYWORD_LOOKUP,keyword);
      _help_error(status,filename,keyword);
   }

   // log this event in the Product Improvement Program
   if (def_pip_on) {
      name := p_name;
      if (p_object == OI_EDITOR) {
         name = p_mode_name' file';
      }
      _pip_log_help_event(keyword, p_object, name);
   }

   return(0);
}

// static _str get_system_browser_command()
// {
//    // Predefined list of browsers to search for and their command
//    // to open a URL (%f).
//    _str browser_list[][];
//    browser_list._makeempty();
//    int i = 0;
//    browser_list[i][0] = "firefox";
//    browser_list[i++][1] = "'%f'";
//    browser_list[i][0] = "mozilla";
//    browser_list[i++][1] = "-remote 'openURL('%f')'";
//    browser_list[i][0] = "netscape";
//    browser_list[i++][1] = "-remote 'openURL('%f')'";
//
//    int size = browser_list._length();
//    for (i = 0; i < size; ++i) {
//       _str browser_path = path_search(browser_list[i][0]);
//       if (!browser_path._isempty()) {
//          // System browser found.
//          _str cmd = browser_path' 'browser_list[i][1];
//          return cmd;
//       }
//    }
//    return '';
// }
//
// /**
//  * Open a specified URL using user's web browser of choice.
//  *
//  * @param url URL to open.  Must be well-formatted (e.g.
//  *            file:///path/to/file).
//  */
// void launch_web_browser(_str url='')
// {
//    if (_isMac() || !__UNIX__) {
//       // Use the old way for Mac for now.  But we need to revisit
//       // this after beta and fix it the right way.
//       goto_url(url, true);
//       return;
//    }
//    _str browser_cmd = get_system_browser_command();
//    if (!browser_cmd._isempty()) {
//       browser_cmd = stranslate(browser_cmd, url, '%f');
//       shell(browser_cmd, 'A');
//    }
// }

defeventtab _comboisearch_form;
void list1.lbutton_double_click()
{
   _ok.call_event(_ok,lbutton_up);
}
_ok.on_create()
{
   list1.p_completion=HELP_ARG;
   list1.p_ListCompletions=false;
   _str filename=get_env("VSROOT"):+'help':+FILESEP:+SLICK_HELPINDEX_FILE;
   //filename=maybe_quote_filename(_config_path():+SLICK_HELPLIST_FILE);
   int status;
   int handle=_xmlcfg_open(filename,status);
   if (handle<0) {
      if ( handle==FILE_NOT_FOUND_RC ) {
         _message_box(nls("File '%s' not found",filename));
      } else {
         _message_box(nls("Error loading help file '%s'",filename));
      }
      return('');
   }
   _str array[];
   _xmlcfg_find_simple_array(handle,"/indexdata/key/@name",array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
   _xmlcfg_close(handle);
   int wid=list1.p_window_id;
   int i;
   for (i=0;i<array._length();++i) {
      wid._lbadd_item(array[i]);
   }

   //list1.p_cb_list_box.search('^ :i,','@r','');
   list1._lbtop();
   list1._lbselect_line();
   return('');
}

void list1.on_change(int reason)
{
   switch (reason) {
   case CHANGE_OTHER:
      list1._lbselect_line();
      list1.line_to_top();
   }
}

void _ok.lbutton_up()
{
   p_active_form._delete_window(list1._lbget_text());
}
