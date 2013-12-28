////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50018 $
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
#include "cbrowser.sh"
#include "tagsdb.sh"
#include "eclipse.sh"
#import "backtag.e"
#import "bind.e"
#import "caddmem.e"
#import "codehelputil.e"
#import "context.e"
#import "debuggui.e"
#import "eclipse.e"
#import "files.e"
#import "ini.e"
#import "jrefactor.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "pushtag.e"
#import "picture.e"
#import "quickrefactor.e"
#import "recmacro.e"
#import "refactor.e"
#import "saveload.e"
#import "seldisp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tags.e"
#import "tagwin.e"
#import "tbautohide.e"
#import "tbfilelist.e"
#import "tbtabgroup.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "treeview.e"
#import "util.e"
#import "vc.e"
#import "tbxmloutline.e"
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "se/util/MousePointerGuard.e"
#endregion

using se.lang.api.LanguageSettings;

#define TBCBROWSER_FORM "_tbcbrowser_form"

//############################################################################

struct CB_TAG_CATEGORY {
   typeless tag_types[];          // either int (VS_TAGTYPE_*) or
                                  // a string (user defined type)
   int     sequence_number;       // sequence number, for sorting
   int     flag_mask;             // AND'd with tag's flags
   boolean mask_nzero;            // should result be 0 or !=0?
   boolean use_package_separator; // use package or class sep here?
   boolean level3_inheritance;    // enable inheritance tree at level 3
   boolean level4_inheritance;    // enable inheritance tree at level 4
   boolean is_container;          // are the items in this ctg containers?
   boolean remove_duplicates;     // remove duplicate captions under this category?
};

static struct CB_TAG_CATEGORY gh_cb_categories:[] = {
   // packages and namespaces
   "Programs" => {
      {VS_TAGTYPE_program},
      110, 0, false, true, false, false, true, false
   },
   "Libraries" => {
      {VS_TAGTYPE_library},
      120, 0, false, true, false, false, true, false
   },
   CB_packages => {
      {VS_TAGTYPE_package},
      130, 0, false, true, false, true, true, true
   },
   // class and record types
   "Interfaces" => {
      {VS_TAGTYPE_interface},
      210, 0, false, false, true, true, true, true
   },
   CB_classes => {
      {VS_TAGTYPE_class},
      220, 0, false, false, true, true, true, true
   },
   "Structures" => {
      {VS_TAGTYPE_struct},
      230, 0, false, false, true, true, true, false
   },
   "Unions" => {
      {VS_TAGTYPE_union},
      240, 0, false, false, false, false, true, false
   },
   "Groups" => {
      {VS_TAGTYPE_group, VS_TAGTYPE_mixin},
      250, 0, false, false, false, false, true, false
   },
   // type definitions
   "Enumerated Types" => {
      {VS_TAGTYPE_enum},
      310, 0, false, false, false, false, true, false
   },
   "Type Definitions" => {
      {VS_TAGTYPE_typedef},
      320, 0, false, false, false, false, false, false
   },
   // tasks, procedures, functions
   "Tasks" => {
      {VS_TAGTYPE_task},
      410, 0, false, false, false, false, true, false
   },
   "Global Functions" => {
      {0, VS_TAGTYPE_proto, VS_TAGTYPE_function},
      420, VS_TAGFLAG_static, false, false, false, false, false, true
   },
   "Static Functions" => {
      {0, /*VS_TAGTYPE_proto,*/ VS_TAGTYPE_function},
      430, VS_TAGFLAG_static, true, false, false, false, false, false
   },
   "Global Procedures" => {
      {VS_TAGTYPE_proc, VS_TAGTYPE_procproto},
      440, VS_TAGFLAG_static, false, false, false, false, false, true
   },
   "Static Procedures" => {
      {VS_TAGTYPE_proc /*, VS_TAGTYPE_procproto*/},
      450, VS_TAGFLAG_static, true, false, false, false, false, false
   },
   "Nested Functions" => {
      {VS_TAGTYPE_subproc, VS_TAGTYPE_subfunc},
      460, 0, false, false, false, false, false, false
   },
   // data / storage
   "Global Variables" => {
      {VS_TAGTYPE_gvar, VS_TAGTYPE_var},
      510, VS_TAGFLAG_static, false, false, false, false, false, false
   },
   "Static Variables" => {
      {VS_TAGTYPE_gvar},
      520, VS_TAGFLAG_static, true, false, false, false, false, false
   },
   "Properties" => {
      {VS_TAGTYPE_property},
      530, 0, false, false, false, false, false, false
   },
   // preprocessing and constants
   "Defines" => {
      {VS_TAGTYPE_define},
      610, 0, false, false, false, false, false, false
   },
   "Constants" => {
      {VS_TAGTYPE_constant},
      620, 0, false, false, false, false, false, false
   },
   // database
   "Database Objects" => {
      {VS_TAGTYPE_database},
      710, 0, false, false, false, false, true, false
   },
   "Tables and Views" => {
      {VS_TAGTYPE_table,VS_TAGTYPE_view},
      720, 0, false, false, false, false, true, false
   },
   "Indexes, Cursors, Triggers" => {
      {VS_TAGTYPE_index,VS_TAGTYPE_cursor,VS_TAGTYPE_trigger},
      730, 0, false, false, false, false, true, false
   },
   "Data Files" => {
      {VS_TAGTYPE_file},
      740, 0, false, false, false, false, false, false
   },
   // graphical interface objects
   "GUI Objects" => {
      {VS_TAGTYPE_form,VS_TAGTYPE_menu,VS_TAGTYPE_control},
      810, 0, false, false, false, false, true, false
   },
   "GUI Event Tables" => {
      {VS_TAGTYPE_eventtab},
      820, 0, false, false, false, false, true, false
   },
   // include statements, imports, and copy files
   "Imports/Uses" => {
      {VS_TAGTYPE_import},
      910, 0, false, false, false, false, false, true
   },
   CB_includes => {
      {VS_TAGTYPE_include},
      920, 0, false, false, false, false, false, true
   },
   CB_includesCB => {
      {VS_TAGTYPE_include},
      920, 0, false, false, false, false, false, true
   },
   "Tags" => {
      {VS_TAGTYPE_tag,VS_TAGTYPE_taguse}, // SGML tags
      930, 0, false, false, true, true, true, false
   },
   "Targets" => {
      {VS_TAGTYPE_target}, // ANT targets
      940, 0, false, false, false, false, false, false
   },
   "Labels" => {
      {VS_TAGTYPE_label}, // XML ids,HTML anchors
      950, 0, false, false, false, false, false, false
   },
   // anything else!!!
   CB_misc => {
      {-1},
      1000, 0, false, false, false, false, false, false
   },
};



//////////////////////////////////////////////////////////////////////////////
// Window id's for symbol browser related forms
//
static int gtbprops_wid;     // wid of _tbprops_form
static int gcbcalls_wid;     // wid of _cbcalls_form
static int gcbparents_wid;   // wid of _cbparents_form
static int gcboptions_wid;   // wid of _cboptions_form
static int gtbcbrowser_wid;  // wid of _tbcbrowser_form
/**
 *
 * @return int
 */
int gClassBrowserTimerId=-1;

//////////////////////////////////////////////////////////////////////////////
// Temporary used for expand/collapse operations.  Prior to expanding
// an item, we iterate through the items in the list, deleting the leaves,
// and hashing the captions and tree indexes of the interior nodes into
// this table.  When inserting the new items into the tree, we first check
// if the target caption is in this table, and if so, simply delete it
// from the hash table instead of inserting a new copy into the tree.
// After everything has been inserted, we iterate through what remains in
// this structure and delete them from the tree.
//
//static int gh_captions_index_map:[][];


// Filter-by-types array (1=allow; 0=disallow).
int def_cb_filter_by_types[] = {
   // 0-54 (0 - VS_TAGTYPE_LASTID
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1,
   // Reserved 55-127
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1,
   // 128-159 (VS_TAGTYPE_FIRSTUSER - VS_TAGTYPE_LASTUSER
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1,
   // 160-255 (VS_TAGTYPE_FIRSTOEM - VS_TAGTYPE_LASTOEM
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   1, 1, 1, 1, 1, 1   // VS_TAGTYPE_MAXIMUM
};

//////////////////////////////////////////////////////////////////////////////

/**
 * Indicates the maximum depth which to expand the symbol browser's
 * derived classes dialog.  If set to 1 (the default), only the
 * immediate derived classes will be expanded.  If set higher, the
 * entire inheritance tree can be exposed on one operation.
 * 
 * @default 1
 * @categories Configuration_Variables
 */
int def_cb_max_derived_class_depth = 1;

/**
 * Indicates whether or not to show symbols in the preview 
 * window when the mouse is hovered over them in tagging related 
 * tool windows or the file tabs. 
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_tag_hover_preview = true;
/**
 * The amount of time to delay before previewing a symbol in
 * the preview tool window when the mouse is hovered over a
 * symbol in a tagging related tool window or the file tabs. 
 * 
 * @default 500 ms
 * @categories Configuration_Variables
 */
int def_tag_hover_delay = 500;

//////////////////////////////////////////////////////////////////////////////
// These globals are used only for comparing values when refreshing
// the symbol browser.  It allows us to compare the new settings with
// the old and avoid expensive refreshes if possible.
//
static  int gi_sort_by_line;        // sort by line number instead of name
static  int gi_sort_float_to_top=1; // float structs, unions to top
static _str gz_class_filter;        // regular expression for class filter
static _str gz_member_filter;       // regular expression for method filter

//////////////////////////////////////////////////////////////////////////////
// The name of a member/caption to be excluded from filtering so that
// restore_position can force the member to show up in the symbol browser.
// This is allowed only in restore_position.
//
static _str gz_exception_name;

//////////////////////////////////////////////////////////////////////////////
// Global flags indicating that we are in an un-interuptable refresh
// operation and if a refresh is needed for a dormant (hidden) class
// browser.
//
static int gi_in_refresh=0;
static int gi_need_refresh=0;


//////////////////////////////////////////////////////////////////////////////
// Picture indexes used by symbol browser
//
static int gi_pic_proj_open;       // selected tag file (project)
static int gi_pic_proj_close;      // closed / not selected tag file
static int gi_pic_cat_open;        // selected tag category
static int gi_pic_cat_close;       // closed / not selected category

//////////////////////////////////////////////////////////////////////////////
// Two-dimensional array of picture indexes for different tag types
// and access levels.  The the correct way to index into this array
// is access major, type minor, eg.   gi_pic_access_type[i_access][i_type].
//
static int gi_pic_access_type[][];

struct CB_BITMAP_INFO {
   _str name;
   _str description;
   boolean global_only;
   _str type_name;
   _str text_symbol;  // used for saving to file and printing
};

static CB_BITMAP_INFO gi_code_type[] = {
   {'fun','Static/Global Function or class Method',false,'func',"Fn"},       // CB_type_function        0
   {'prt','Static/Extern Function or Method Prototype',false,'func',"Fx"},   // CB_type_prototype       1
   {'dat','Member or local/static/global Variable',false,'var'," o"},        // CB_type_data            2
   {'opr','Overloaded Operator',false,'func', "op"},                         // CB_type_operator        3
   {'cns','Class Constructor',false,'func', "Cn"},                           // CB_type_constructor     4
   {'dst','Class Destructor',false,'func',"Dn"},                             // CB_type_destructor      5
   {'enm','Enumeration Constant',false,'enumc',"en"},                        // CB_type_enumeration     6
   {'typ','Type Definition',false,'typedef', "tp"},                          // CB_type_typedef         7
   {'def','Preprocessor Macro Definition',true,'define', " #"},              // CB_type_define          8
   {'prp','Property',false,'prop'," p"},                                     // CB_type_property        9
   {'con','Constant',false,'constant', " ="},                                // CB_type_constant       10
   {'lab','Label',true,'label', " ="},                                       // CB_type_label          11
   {'imp','Imports or Uses',true,'import', "im"},                            // CB_type_import         12
   {'frn','Friend Relationship',true,'friend', " *"},                        // CB_type_friend         13
   {'ndx','Database Index',true,'index', " x"},                              // CB_type_index          14
   {'trg','Database Event Trigger',true,'trigger', " *"},                    // CB_type_trigger        15
   {'ctl','GUI Control or Widget',true,'control', " *"},                     // CB_type_control        16
   {'men','GUI Menu',true,'menu', " *"},                                     // CB_type_menu           17
   {'prm','Function or Template Parameter',true,'param', " a"},              // CB_type_param          18
   {'prc','Procedure or class Method',false,'func', "Pn"},                   // CB_type_proc           19
   {'ppt','Procedure or Method Prototype',false,'func', "Px"},               // CB_type_procproto      20
   {'inc','Includes or Depends on (with)',true,'include', "inc"},            // CB_type_include        21
   {'fil','File or Report Definition',true,'file', " *"},                    // CB_type_file           22
   {'sfn','Nested Function',true,'subfunc', "[f"},                           // CB_type_subfunc        23
   {'spr','Nested Procedure',true,'subproc', "[p"},                          // CB_type_subproc        24
   {'crs','Database Cursor',true,'cursor', " >"},                            // CB_type_cursor         25
   {'ann','Annotation or Attribute',true,'annotation', " @"},                // CB_type_annotation     26
   {'oth','',false,'', " ?"},                                                // reserved for expansion 27
   {'unk','Unidentified symbol type',true,'', " ?"},                         // CB_type_unknown        28
   {'oth','Miscellaneous Item',false,'', " ?"},                              // CB_type_miscellaneous  29
   {'sts','Structure or Record',false,'struct', " S"},                       // CB_type_struct         30
   {'ens','Enumerated Type',false,'enum', " E"},                             // CB_type_enum           31
   {'cls','Class',false,'class', " C"},                                      // CB_type_class          32
   {'tps','Template Class',false,'class', "T<>"},                            // CB_type_template       33
   {'abs','Base Class',false,'class', " B"},                                 // CB_type_base_class     34
   {'pks','Package, Namespace or Unit',true,'package', "pkg"},               // CB_type_package        35
   {'uns','Union or Variant',false,'union', " U"},                           // CB_type_union          36
   {'dbs','File or Database',true,'database', "db"},                         // CB_type_database       37
   {'tbl','Database Table or View',true,'table', "tab"},                     // CB_type_table          38
   {'frm','GUI Form or Menu',true,'form', " *"},                             // CB_type_form           39
   {'etb','GUI Event Table',true,'eventtab', " *"},                          // CB_type_eventtab       40
   {'tsk','Task or Thread',true,'task', " T"},                               // CB_type_task           41
   {'grp','Group or Category with members or mixin',false,'group', " S"},    // CB_type_group          42
   {'tag','SGML or XML Tag',true,'tag', "<>"},                               // CB_type_tag            43
   {'tag','SGML or XML Tag Instance',true,'taguse', "<>"},                   // CB_type_taguse         44
   {'sta','Statement',true,'statement', " s"},                               // CB_type_statement      45
   {'ant','Annotation or Attribute Type',false,'annotype', " A"},            // CB_type_annotype       46
   {'scl','Function or Method Call Statement',true,'call', " cl"},           // CB_type_call           47
   {'sif','If, Switch, or Case Statement',true,'if', " if"},                 // CB_type_if             48
   {'mss','Miscellaneous Container',false,'', "??"},                         // CB_type_misc           49
   {'slp','Loop Statement',true,'loop', " lp"},                              // CB_type_loop           50
   {'sbk','Break Statement',true,'break', " bk"},                            // CB_type_break          51
   {'scn','Continue Statement',true,'continue', " cn"},                      // CB_type_continue       52
   {'srt','Return or Throw Statement',true,'return', " rt"},                 // CB_type_return         53
   {"sgt",'Goto Statement',true,'goto', " gt"},                              // CB_type_goto           54
   {"str",'Try, Catch, Finally Statement',true,'try'," tr"},                 // CB_type_try            55
   {"spp",'Preprocessing Statement',true,'cpp'," pp"},                       // CB_type_preprocessing  56
   {"int",'Interface',false,'interface'," I"},                               // CB_type_interface      57
   {'ctp','Class Constructor Prototype',false,'proto', "Cp"},                // CB_type_constr_proto   58
   {'dtp','Class Destructor Prototype',false,'proto',"Dp"},                  // CB_type_destr_proto    59
   {'atg','Ant Target Tag',true,'target', "<>"},                             // CB_type_target         60
   {'opp','Overloaded Operator Prototype ',false,'proto', "op"},             // CB_type_operator_proto 61
   {'asn','Assignment Statement',true,'assign', " ="},                       // CB_type_assign         62
   {'sel','Method selector',true,'selector', " -"},                          // CB_type_selector       63
   {'sse','Static method selector',true,'selector', " +"},                   // CB_type_selector_stat  64
};

// Maps bitmap id to text symbols for printing and saving to file
_str gmap_bitmapid_to_symbol:[];

static CB_BITMAP_INFO gi_code_access[] = {
   {'0','Public or Global scope'}, // CB_access_public         0
   {'1','Protected Scope'},        // CB_access_protected      1
   {'2','Private scope'},          // CB_access_private        2
   {'3','Package scope'},          // CB_access_package        3
};

 //############################################################################
//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (before defload).  Used to
// initialize the timer variable and window IDs.
//
definit()
{
   // IF editor is initalizing from invocation
   if (arg(1)!='L') {
      gClassBrowserTimerId=-1;
      gtbprops_wid=0;
      gcbparents_wid=0;
      gcboptions_wid=0;
      gtbcbrowser_wid=0;
      gz_exception_name='';
      gz_class_filter='';
      gz_member_filter='';
      gi_in_refresh=0;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Called when this module is loaded (after definit).  Used to
// correctly initialize the window IDs (if those forms are available),
// and loads the array of pictures used for different tag types.
//
defload()
{
   if( def_cb_filter_by_types._varformat()!=VF_ARRAY || def_cb_filter_by_types._length()<(VS_TAGTYPE_MAXIMUM+1) ) {
      // Initialize the filter-by-types array
      int i;
      for( i=0;i<=VS_TAGTYPE_MAXIMUM;++i ) {
         def_cb_filter_by_types[i]=1;
      }
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   _pic_file_d=_update_picture(-1,'_filed.ico');
   _pic_file_d12=_update_picture(-1,'_filed12.ico');
   // try to find the related forms
   gtbprops_wid    = _find_formobj("_tbprops_form","n");
   gcbparents_wid  = _find_formobj("_cbparents_form","n");
   gcboptions_wid  = _find_formobj("_cboptions_form","n");
   gtbcbrowser_wid = _find_formobj("_tbcbrowser_form","n");

   // project and category open/close pictures
   gi_pic_proj_open  = _pic_fldtags;
   gi_pic_proj_close = _pic_fldctags;
   gi_pic_cat_open   = _pic_fldopen12;
   gi_pic_cat_close  = _pic_fldclos12;

   // pictures we have not yet loaded
   _str pics_not_loaded='';
   int result = 0;

   // loop through all access levels and tag picture types
   // and load the picture.  Substitute _pic_file for any
   // that fail to load.
   int i,j,status;
   for (i=0; i<=CB_access_LAST; ++i) {
      _str zaccess = gi_code_access[i].name;
      _str zdesc   = gi_code_access[i].description;
      for (j=0; j<=CB_type_LAST; ++j) {
         if (i>0 && gi_code_type[j].global_only) {
            gi_pic_access_type[i][j] = gi_pic_access_type[0][j];
         } else {
            _str ztype = gi_code_type[j].name;
            _str filename = CB_pic_class_prefix :+ ztype :+ zaccess :+ CB_pic_icon;
            status=_cb_add_type(i,j,filename,gi_code_type[j].description,gi_code_type[j].text_symbol,gi_code_type[j].global_only);
            if( status ) {
               result = status;
               if (pics_not_loaded == '') {
                  pics_not_loaded = filename;
               } else {
                  pics_not_loaded = pics_not_loaded ', ' filename;
               }
            }
         }
      }
   }

   gmap_bitmapid_to_symbol:[_pic_file]       = "||";
   gmap_bitmapid_to_symbol:[_pic_file_d]     = "||";
   gmap_bitmapid_to_symbol:[_pic_file12]     = "||";
   gmap_bitmapid_to_symbol:[_pic_file_d12]   = "||";
   gmap_bitmapid_to_symbol:[_pic_fldclos]    = "[]";
   gmap_bitmapid_to_symbol:[_pic_fldopen]    = "[]";
   gmap_bitmapid_to_symbol:[_pic_fldclos12]  = "[]";
   gmap_bitmapid_to_symbol:[_pic_fldopen12]  = "[]";
   gmap_bitmapid_to_symbol:[_pic_func]       = "Fn";
   gmap_bitmapid_to_symbol:[_pic_workspace]  = "[W]";

   // report any errors loading pictures.
   if (result) {
      _message_box(nls('Unable to load picture(s) "%s"',pics_not_loaded)'. 'get_message(result));
   }
}
int GetCBViewWid()
{
   if (isEclipsePlugin()) {
      int formWid = _find_object(ECLIPSE_CLASSBROWSER_CONTAINERFORM_NAME,'n');
      if (formWid > 0) {
         return formWid.p_child;
      }
      return 0;
   } else {
      int f = gtbcbrowser_wid;
      if( f!=0 && _iswindow_valid(f) && f.p_name==TBCBROWSER_FORM ) {
         return f;
      }
      return 0;
   }
}

int isClassBrowserActive()
{
   int index = find_index('_isClassBrowserActive',PROC_TYPE);
   if( index_callable(index) ) {
      return (call_index(index));
   }
   int f = gtbcbrowser_wid;
   if( f!=0  && _iswindow_valid(f) && f.p_name==TBCBROWSER_FORM ) {
      if( !_tbIsWidActive(gtbcbrowser_wid) ) {
         return 0;
      } else {
         return 1;
      }
   }
   return 0;
}
int ActivateClassBrowser()
{
   int index = find_index('_activateClassBrowser',PROC_TYPE);
   if( index_callable(index) ) {
      return (call_index(index));
   }
   int f = gtbcbrowser_wid;
   if( f  && _iswindow_valid(f) && f.p_name==TBCBROWSER_FORM ) {
      activate_cbrowser();
      return 0;
   }
   return 1;
}
static int _cb_add_type(int i_access,int i_type,_str pic_filename,_str description,_str text_symbol,boolean global_only)
{
   _str filename;
   _str access_descr;
   int index;
   int status;

   status=0;

   filename=pic_filename;
   if( filename=="" ) {
      return(1);
   }
   if( i_access<0 || i_access>CB_access_LAST ) {
      return(1);
   }
   access_descr=gi_code_access[i_access].description;
   index=_update_picture(-1,filename);
   if( index<0 ) {
      status=index;
      index=_pic_file12;
   } else if( description!="" ) {
      _str descr = description;
      if (!global_only) {
         descr=description', 'access_descr;
      }
      replace_name(index,filename,descr);
   }
   gi_pic_access_type[i_access][i_type]=index;
   // set reverse mapping
   gmap_bitmapid_to_symbol:[index]=text_symbol;

   return(status);
}

static void _cb_update_picture(_str pic_name, _str type_name, _str pic_filename_public, _str pic_filename_protected="", _str pic_filename_private="", _str pic_filename_package="")
{
   if( pic_name=="" && type_name=="" ) {
      return;
   }
   if( pic_filename_public=="" ) {
      return;
   }
   int i_type;
   for( i_type=0;i_type<gi_code_type._length();++i_type ) {
      _str thisPicName = gi_code_type[i_type].name;
      _str thisTypeName = gi_code_type[i_type].type_name;
      if( pic_name==thisPicName || type_name==thisTypeName ) {
         boolean global_only = gi_code_type[i_type].global_only;
         int pic_index_public = _update_picture(-1,pic_filename_public);
         int pic_index_protected = pic_index_public;
         int pic_index_private = pic_index_public;
         int pic_index_package = pic_index_public;
         if( !global_only ) {
            if( pic_filename_protected!="" ) pic_index_protected=_update_picture(-1,pic_filename_protected);
            if( pic_filename_private!="" ) pic_index_private=_update_picture(-1,pic_filename_private);
            if( pic_filename_package!="" ) pic_index_package=_update_picture(-1,pic_filename_package);
         }
         gi_pic_access_type[CB_access_public][i_type]=pic_index_public;
         gi_pic_access_type[CB_access_protected][i_type]=pic_index_protected;
         gi_pic_access_type[CB_access_private][i_type]=pic_index_private;
         gi_pic_access_type[CB_access_package][i_type]=pic_index_package;
         if( pic_name==thisPicName ) {
            // The pic name should be unique, so we are done
            return;
         }
         // If we got here, then we are matching on type names. Type names
         // are not unique in the list, so must iterate through entire list
         // in order to replace them all.
      }
   }
}

/**
 * Update the picture used by a pic type name.
 *
 * <p>
 * If protected, private, or package access type pictures are not specified,
 * then the public picture will be used for the access type picture.
 * </p>
 *
 * <p>
 * IMPORTANT:<br>
 * Pictures are cached ONCE per editor session, so it is best to call this
 * function in a defload() and build a state file around it.
 * </p>
 *
 * @param type_name              Type name. See CB_BITMAP_INFO.type_name and
 *                               gi_code_type[] in cbrowser.e for a list of
 *                               type names.
 * @param pic_filename_public    Picture to be used for public scope symbols of type type_name.
 * @param pic_filename_protected (optional). Picture to be used for protected scope symbols of type type_name.
 * @param pic_filename_private   (optional). Picture to be used for private scope symbols of type type_name.
 * @param pic_filename_package   (optional). Picture to be used for package scope symbols of type type_name.
 *
 * @see cb_add_user_type()
 */
void cb_update_picture_by_type(_str type_name, _str pic_filename_public, _str pic_filename_protected="", _str pic_filename_private="", _str pic_filename_package="")
{
   _cb_update_picture("",type_name,pic_filename_public,pic_filename_protected,pic_filename_private,pic_filename_package);
}

/**
 * Update the picture used by a pic name.
 *
 * <p>
 * If protected, private, or package access type pictures are not specified,
 * then the public picture will be used for the access type picture.
 * </p>
 *
 * <p>
 * The pic name is the name part used to assemble the bitmap filename.
 * For example, the name part 'fun' is used to assemble the bitmaps used
 * to represent functions: _clsfun0.ico, _clsfun1.ico, _clsfun2.ico, _clsfun3.ico,
 * where the numbers 0-3 represent the access type (see CB_access_*).
 * </p>
 *
 * <p>
 * IMPORTANT:<br>
 * Pictures are cached ONCE per editor session, so it is best to call this
 * function in a defload() and build a state file around it.
 * </p>
 *
 * @param pic_name               Pic name. See CB_BITMAP_INFO.name and
 *                               gi_code_type[] in cbrowser.e for a list of
 *                               type names.
 * @param pic_filename_public    Picture to be used for public scope symbols of type type_name.
 * @param pic_filename_protected (optional). Picture to be used for protected scope symbols of type type_name.
 * @param pic_filename_private   (optional). Picture to be used for private scope symbols of type type_name.
 * @param pic_filename_package   (optional). Picture to be used for package scope symbols of type type_name.
 *
 * @see cb_add_user_type()
 */
void cb_update_picture_by_name(_str pic_name, _str pic_filename_public, _str pic_filename_protected="", _str pic_filename_private="", _str pic_filename_package="")
{
   _cb_update_picture(pic_name,"",pic_filename_public,pic_filename_protected,pic_filename_private,pic_filename_package);
}

/**
 * Add a user tag type for use anywhere that uses an icon to represent a
 * tag type (e.g. Symbol browser, Procs tab, etc.).
 *
 * <p>
 * Note:<br>
 * Since only the name part (i.e. no path) of the picture filenames are stored
 * in the names table, the picture files must exists in a path pointed to by
 * the VSLICKBITMAPS environment variable (set in vslick.ini). VSLICKBITMAPS
 * is set to %VSROOT%\bitmaps\ if not set explicitly in vslick.ini.
 * </p>
 *
 * <p>
 * Important:<br>
 * If the name part (i.e. no path) of the picture filenames do not start with
 * '_' (underscore), then they will be removed from the state file the next
 * time the configuration is saved.
 * </p>
 *
 * @param type_id                Tag type ID in the range VS_TAGTYPE_OEM-VS_TAGTYPE_MAXIMUM
 * @param type_name              Type name (e.g. 'customtype').
 * @param is_container           1=type is a container (e.g. struct), 0=not a container (e.g. var)
 * @param description            Description of type.
 * @param text_symbol            Text used when saving to file or printing a tree.
 * @param pic_filename_public    Icon to be used for public scope symbols of type type_name.
 * @param pic_filename_protected Icon to be used for protected scope symbols of type type_name.
 * @param pic_filename_private   Icon to be used for private scope symbols of type type_name.
 * @param pic_filename_package   Icon to be used for package scope symbols of type type_name.
 * @param filterFlags            (optional) VS_TAGFILTER_* 
 *
 * @return 0 on success; otherwise non-zero on error.
 */
int cb_add_user_type(int type_id, _str type_name,
                     boolean is_container, _str description, _str text_symbol,
                     _str pic_filename_public, _str pic_filename_protected="",
                     _str pic_filename_private="", _str pic_filename_package="",
                     int filterFlags = VS_TAGFILTER_ANYTHING)

{
   int i_access;
   int i_type;
   int status;
   int result;
   _str pics_not_loaded;
   _str access_descr;
   _str filename;
   _str msg;

   if( type_id<VS_TAGTYPE_FIRSTOEM || type_id>VS_TAGTYPE_LASTOEM ) {
      msg="Invalid type ID";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   if( type_name=="" ) {
      msg="Invalid type name";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   // If type_name already exists, then replace it
   for( i_type=CB_type_LAST+1;i_type<gi_code_type._length();++i_type ) {
      if( gi_code_type[i_type].type_name==type_name ) {
         // Found it
         break;
      }
   }
   // Do not allow us to add before CB_type_LAST
   if( i_type<=CB_type_LAST ) {
      msg="Type '"type_name"' already exists in pre-defined tag types";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   // At this point i_type is pointing to the next available entry in gi_code_type
   // array. If we found an already-existing entry to replace, then i_type points
   // to it.

   // Update gi_code_type array
   boolean global_only = (pic_filename_protected=="" && pic_filename_private=="" && pic_filename_package=="");
   gi_code_type[i_type].name="";   // Not used
   gi_code_type[i_type].type_name=type_name;
   gi_code_type[i_type].description=description;
   gi_code_type[i_type].global_only=global_only;
   gi_code_type[i_type].text_symbol=text_symbol;

   // Update gi_pic_access_type array
   status=0;
   pics_not_loaded="";
   // Public
   filename=pic_filename_public;
   i_access=CB_access_public;
   result=_cb_add_type(i_access,i_type,filename,description,text_symbol,global_only);
   if( result ) {
      status=result;
      if( pics_not_loaded=="" ) {
         pics_not_loaded=filename;
      } else {
         pics_not_loaded=pics_not_loaded', 'filename;
      }
   }
   // Protected, private, package access
   if( global_only ) {
      // Protected
      gi_pic_access_type[CB_access_protected][i_type]=gi_pic_access_type[CB_access_public][i_type];
      // Private
      gi_pic_access_type[CB_access_private][i_type]=gi_pic_access_type[CB_access_public][i_type];
      // Package
      gi_pic_access_type[CB_access_package][i_type]=gi_pic_access_type[CB_access_public][i_type];
   } else {
      // Protected
      filename=pic_filename_protected;
      i_access=CB_access_protected;
      if( filename=="" ) {
         gi_pic_access_type[i_access][i_type]=gi_pic_access_type[CB_access_public][i_type];
      } else {
         result=_cb_add_type(i_access,i_type,filename,description,text_symbol,global_only);
         if( result ) {
            status=result;
            if( pics_not_loaded=="" ) {
               pics_not_loaded=filename;
            } else {
               pics_not_loaded=pics_not_loaded', 'filename;
            }
         }
      }
      // Private
      filename=pic_filename_private;
      i_access=CB_access_private;
      if( filename=="" ) {
         gi_pic_access_type[i_access][i_type]=gi_pic_access_type[CB_access_public][i_type];
      } else {
         result=_cb_add_type(i_access,i_type,filename,description,text_symbol,global_only);
         if( result ) {
            status=result;
            if( pics_not_loaded=="" ) {
               pics_not_loaded=filename;
            } else {
               pics_not_loaded=pics_not_loaded', 'filename;
            }
         }
      }
      // Package
      filename=pic_filename_package;
      i_access=CB_access_package;
      if( filename=="" ) {
         gi_pic_access_type[i_access][i_type]=gi_pic_access_type[CB_access_public][i_type];
      } else {
         result=_cb_add_type(i_access,i_type,filename,description,text_symbol,global_only);
         if( result ) {
            status=result;
            if( pics_not_loaded=="" ) {
               pics_not_loaded=filename;
            } else {
               pics_not_loaded=pics_not_loaded', 'filename;
            }
         }
      }
   }

   // Register the new type with tagsdb
   tag_register_type(type_id,type_name,(int)is_container,description,filterFlags);
   tag_tree_register_cb_type(type_id,i_type,
                             gi_pic_access_type[CB_access_public][i_type],
                             gi_pic_access_type[CB_access_protected][i_type],
                             gi_pic_access_type[CB_access_private][i_type],
                             gi_pic_access_type[CB_access_package][i_type]);

   // Report any errors loading pictures
   if( result ) {
      _message_box(nls('Unable to load picture(s) "%s"',pics_not_loaded)'. 'get_message(result));
   }

   return(status);
}

/**
 * Add type ID type_id to category category_name in symbol browser. If
 * category does not exist, it is created.
 *
 * @param category_name      Name of category (e.g. "Structures")
 * @param type_id            Type ID in range VS_TAGTYPE_OEM - VS_TAGTYPE_MAXIMUM
 * @param is_container       true=container type (e.g. struct), false=not a container
 * @param add_after_category If category_name does not exist, then it will be added after add_after_category
 *
 * @return 0 on success, otherwise non-zero.
 */
int cb_add_to_category(_str category_name,int type_id,boolean is_container=false,_str add_after_category="")
{
   CB_TAG_CATEGORY *p;
   _str msg;

   if( category_name=="" ) {
      msg="Invalid category name";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   if( type_id<VS_TAGTYPE_FIRSTOEM || type_id>VS_TAGTYPE_LASTOEM ) {
      msg="Invalid type ID";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   p=gh_cb_categories._indexin(category_name);
   if( p ) {
      // Adding to existing category
      p->tag_types[p->tag_types._length()]=type_id;
   } else {
      CB_TAG_CATEGORY ctc;
      ctc._makeempty();
      ctc.tag_types[ctc.tag_types._length()]=type_id;
      ctc.flag_mask=0;
      ctc.mask_nzero=0;
      ctc.use_package_separator=false;
      ctc.level3_inheritance=true;
      ctc.level4_inheritance=true;
      ctc.is_container=is_container;
      ctc.remove_duplicates=true;
      // Calculate sequence number
      int sequence_number=999;   // Sanity
      if( add_after_category!="" ) {
         p=gh_cb_categories._indexin(add_after_category);
         if( !p ) {
            msg='No category "'add_after_category'" to add after.';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return(1);
         }
      } else {
         p=gh_cb_categories._indexin(CB_misc);
         if( p ) {
            // Add before "Miscellaneous" in order
            sequence_number=p->sequence_number-1;
         }
      }
      ctc.sequence_number=sequence_number;
      gh_cb_categories:[category_name]=ctc;
   }
   // Flag the editor that the configuration has changed
   _config_modify_flags(CFGMODIFY_DEFDATA);

   return(0);
}

//############################################################################
// function for selection bitmap given tag type and flags
// This function is not normally called for 'standard' tag types,
// icon selection for those is done in the tagsdb DLL, which delagates
// to this function if it cannot resolve the tag type.
//
int cb_select_icon(_str tag_type, int tag_flags)
{
   switch (tag_type) {
   case 'macro':
      return CB_type_define;
   case 'dd':
   case 'db':
   case 'dw':
      return CB_type_data;
   case 'equ':
      return CB_type_constant;
   default:
      int index;
      index=find_index('cb_user_select_icon',PROC_TYPE);
      if( index ) {
         return call_index(tag_type,tag_flags,index);
      }
      break;
   }
   return CB_type_miscellaneous;
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// kill the existing symbol browser update timer
//
static void cb_kill_timer()
{
   //say("cb_kill_timer("gClassBrowserTimerId")");
   if (gClassBrowserTimerId != -1) {
      _kill_timer(gClassBrowserTimerId);
      gClassBrowserTimerId=-1;
   }
}

//////////////////////////////////////////////////////////////////////////////
// kill the existing symbol browser update timer
//
static void cb_start_timer(typeless timer_cb, int index=-1, int timer_delay=0)
{
   if (gtbprops_wid || gcbparents_wid || gcbcalls_wid ||
       _GetTagwinWID(false) || _GetReferencesWID(false)) {
      if (timer_delay <= 0) {
         timer_delay=max(CB_TIMER_DELAY_MS,_default_option(VSOPTION_DOUBLE_CLICK_TIME));
      }
      gClassBrowserTimerId=_set_timer(timer_delay, timer_cb, index);
   }
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Event table for the _tbcbrowser_form (which the symbol browser is in).
//
defeventtab _tbcbrowser_form.ctl_class_tree_view;

//////////////////////////////////////////////////////////////////////////////
// Keyboard shortcuts for all symbol browser menu options
//
def 'A-g'=cb_goto_proc;
def 'A-d'=cb_goto_decl;
def 'A-l'=cb_sortby_line;
def 'A-t'=cb_sortby_name;
def 'A-o'=cb_options;
def 'A-f'=cb_find;
def 'A-i'=gui_make_tags;
def 'A-2'=cb_expand_twolevels;
def 'A-e'=cb_expand_children;
def 'A-c'=cb_collapse;
def 'A-s'=cb_crunch;
def 'A-h'=cb_parents;
def 'A-p'=cb_props;
def 'A-a'=cb_args;
def 'A-r'=cb_references;
def 'A-u'=cb_calltree;

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Event table for the _tbcbrowser_form (which the symbol browser is in).
//
defeventtab _tbcbrowser_form;

_tbcbrowser_form.'F12'()
{
   if (isEclipsePlugin()) {
      eclipse_activate_editor();
   } else if (def_keys == 'eclipse-keys') {
      activate_editor();
   }
}

_tbcbrowser_form.'C-S-PAD-SLASH'()
{
   if (isEclipsePlugin() || def_keys == 'eclipse-keys') {
      cb_crunch();
   }
   
}

_tbcbrowser_form.'C-M'()
{
   if (isEclipsePlugin()) {
      eclipse_maximize_part();
   }
}

//////////////////////////////////////////////////////////////////////////////
// Add keyboard bindings to menu items
//
static void menu_add_bindings(int menu_handle, _str cmd, _str cmd2, _str args)
{
   _str bindings = _mdi.p_child.where_is(cmd,2);
   if (bindings=='' && cmd2!='') {
      bindings = _mdi.p_child.where_is(cmd2,2);
   }
   int flags;
   _str caption;
   if (bindings != '') {
      _menu_get_state(menu_handle, cmd:+args, flags, 'M', caption);
      parse caption with caption "\t" .;
      _menu_set_state(menu_handle, cmd:+args, flags, 'M', caption "\t" bindings);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Hide the given item(s)
//
static void menu_hide_item(int menu_handle, _str cat)
{
   int mh,mpos;
   int status=_menu_find(menu_handle,cat,mh,mpos,'C');
   if (!status) {
     _menu_delete(mh,mpos);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle right-button released event, in order to display pop-up menu
// for the symbol browser.  Also responsible for graying inactive items
// depending where we are in the symbol browser tree.
//
void ctl_class_tree_view.rbutton_up()
{
   // kill the refresh timer, prevents delays before the menu comes
   // while the refreshes are finishing up.
   cb_kill_timer();

   // get the menu form
   int index=find_index("_cbrowse_menu",oi2type(OI_MENU));
   if (!index) {
      return;
   }
   int menu_handle=p_active_form._menu_load(index,'P');
   int cbWid = GetCBViewWid();
   //int cbWid = ActivateClassBrowser();
   // blow away parts of the menu, depending on where
   // it is being shown from
   if (isEclipsePlugin()) {
      gtbcbrowser_wid = p_active_form;
   }
   if (_get_focus() == cbWid.ctl_class_tree_view) {
      struct VS_TAG_BROWSE_INFO cm;
      int k = gtbcbrowser_wid.ctl_class_tree_view._TreeCurIndex();
      // If we right clicked on a class.
      if (gtbcbrowser_wid.ctl_class_tree_view.get_user_tag_info(k, cm, false)) {
         _str lang=_Filename2LangId(cm.file_name);
         qrIndex := _menu_find_loaded_menu_category(menu_handle, "quick_refactoring", auto qrMenu);
         if (cm.type_name=='class') {
            if (lang=='c') {
               _menu_insert(qrMenu,-1,MF_ENABLED,
                            'Add Member Function...','cb_add_member 0','',
                            'help Symbols tool window',
                            'Adds a member function to the this class');
               _menu_insert(qrMenu,-1,MF_ENABLED,
                            'Add Member Variable...','cb_add_member 1','',
                            'help Symbols tool window',
                            'Adds a member function to the this class');
            }
            // Might want to get C# working here too.
            if (lang=='c') {
               // This DOES NOT work for works for all extensions with a
               // generate_match_signature function.  Some special code in override_method
               // is needed.
               //int gen_index = find_index('_'ext'_generate_match_signature',PROC_TYPE);
               //if (gen_index) {
               int status=tag_read_db(cm.tag_database);
               if (status >= 0) {
                  _str parents = cm.class_parents;
                  if (parents == '') {
                     tag_get_inheritance(cm.qualified_name,parents);
                  }
                  if (parents!='') {
                     _menu_insert(qrMenu,-1,MF_ENABLED,
                                  'Override Virtual Function...','cb_override_method','',
                                  'help Symbols tool window',
                                  'Adds a function which overrides a base class virtual method');
                  }
               }
               //}
            } else if (lang=='java') {
               _menu_insert(qrMenu,-1,MF_ENABLED,
                            'Override Method...','cb_override_method','',
                            'help Symbols tool window',
                            'Adds a method which overrides a base class method');
            }
         }
         if (tag_tree_type_is_func(cm.type_name)) {
            if (lang=='c' || lang=='java') {
               _menu_insert(qrMenu,-1,MF_ENABLED,
                            'Delete','cb_delete','',
                            'help Symbols tool window',
                            'Deletes the method');
            }
         }
         if (isEclipsePlugin() && lang=='java') {
            menu_hide_item(menu_handle, "set_breakpoint");
         }
      }
   } else if ((p_active_form == gcbparents_wid) ||
              (p_active_form == gtbprops_wid) || 
              (p_active_form == gcboptions_wid)) {
      menu_hide_item(menu_handle, "expand");
      menu_hide_item(menu_handle, "expand2");
      menu_hide_item(menu_handle, "collapseothers");
      menu_hide_item(menu_handle, "collapseall");
      menu_hide_item(menu_handle, "derived");
      menu_hide_item(menu_handle, "parents");
      menu_hide_item(menu_handle, "options");
      menu_hide_item(menu_handle, "filters");
      menu_hide_item(menu_handle, "sortby");
      menu_hide_item(menu_handle, "findtag");
      menu_hide_item(menu_handle, "cpp_refactoring");
      menu_hide_item(menu_handle, "quick_refactoring");
      menu_hide_item(menu_handle, "organize_imports");
      menu_hide_item(menu_handle, "set_breakpoint");
      menu_hide_item(menu_handle, "expandtwolevels");
   } else {
      // don't know where we are
      return;
   }

   // hide C/C++ refactoring if it is disabled
   if (def_disable_cpp_refactoring) {
      menu_hide_item(menu_handle, "cpp_refactoring");
   }

   // get the id of the symbol browser form
   _nocheck _control ctl_class_tree_view;
   _nocheck _control ctl_class_filter_label;
   _nocheck _control ctl_member_filter_label;
   int f = GetCBViewWid();
   if (!f) return;

   // get position in tree control
   int i = f.ctl_class_tree_view._TreeCurIndex();
   int depth = (i<0)? 0 : f.ctl_class_tree_view._TreeGetDepth(i);

   // If a tag is not selected, disable tag operations.
   if ((depth <= 2) || (i == TREE_ROOT_INDEX)) {
      _menu_set_state(menu_handle, "properties", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "arguments", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "references", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "calltree", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "derived", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "parents", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "declaration", MF_GRAYED, 'C');
      _menu_set_state(menu_handle, "definition", MF_GRAYED, 'C');
   }

   // If at first level below categories, disable inheritance
   // unless we are under structs, classes, or interfaces.
   int p,g;
   _str caption='';
   if (depth == 3) {
      p = f.ctl_class_tree_view._TreeGetParentIndex(i);
      caption = f.ctl_class_tree_view._TreeGetCaption(p);
      parse caption with caption CB_delimiter .;
      CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(caption);
      if (!ctg || !ctg->level3_inheritance) {
         _menu_set_state(menu_handle, "derived", MF_GRAYED, 'C');
         _menu_set_state(menu_handle, "parents", MF_GRAYED, 'C');
      }
   }

   // If at a second level below categories, disable inheritance unless
   // we are under structs, classes, interfaces, packages, programs, or libraries.
   if (depth == 4) {
      p = f.ctl_class_tree_view._TreeGetParentIndex(i);
      g = f.ctl_class_tree_view._TreeGetParentIndex(p);
      caption = f.ctl_class_tree_view._TreeGetCaption(g);
      parse caption with caption CB_delimiter .;
      CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(caption);
      if (!ctg || !ctg->level4_inheritance) {
         _menu_set_state(menu_handle, "derived", MF_GRAYED, 'C');
         _menu_set_state(menu_handle, "parents", MF_GRAYED, 'C');
      }
   }

   // Gray goto-proc (goto_decl) if the current item is not a function
   int show_children=0;
   caption = '';
   if (i>=0) {
      f.ctl_class_tree_view._TreeGetInfo(i, show_children);
      caption = f.ctl_class_tree_view._TreeGetCaption(i);
   }
   if (show_children != TREE_NODE_LEAF || pos("(", caption)==0) {
      _menu_set_state(menu_handle, "declaration", MF_GRAYED, 'C');
   }

   // stuff the key shortcut into the memu item for cb_find
   menu_add_bindings(menu_handle, 'cb_goto_decl', '', '');
   menu_add_bindings(menu_handle, 'cb_goto_proc', '', '');
   menu_add_bindings(menu_handle, 'cb_find', 'cf', ' -');
   menu_add_bindings(menu_handle, 'gui_make_tags', '', '');
   menu_add_bindings(menu_handle, 'cb_parents', '', '');
   menu_add_bindings(menu_handle, 'cb_crunch', '', '');
   menu_add_bindings(menu_handle, 'cb_props', '', '');
   menu_add_bindings(menu_handle, 'cb_args', '', '');
   menu_add_bindings(menu_handle, 'cb_references', '', '');
   menu_add_bindings(menu_handle, 'cb_calltree', '', '');
   menu_add_bindings(menu_handle, 'cb_options', '', '');

   // set check marks depending on state of gi_sort_by_line
   if (gi_sort_by_line) {
      _menu_set_state(menu_handle, "sortline", MF_CHECKED, 'C');
   } else {
      _menu_set_state(menu_handle, "sortname", MF_CHECKED, 'C');
   }
   if (gi_sort_float_to_top) {
      _menu_set_state(menu_handle, "sortfloat", MF_CHECKED, 'C');
   }

   // set check marks depending on presence/absence of filters
   if (f.ctl_class_filter_label.p_visible) {
      _menu_set_state(menu_handle,"class",MF_CHECKED,'C');
   }
   if (f.ctl_member_filter_label.p_visible) {
      _menu_set_state(menu_handle,"member",MF_CHECKED,'C');
   }

   // populate refactoring submenu
   struct VS_TAG_BROWSE_INFO refcm;
   if(f.ctl_class_tree_view.get_user_tag_info(i, refcm, false)) {
      addCPPRefactoringMenuItems(menu_handle, "cb", refcm);
      addQuickRefactoringMenuItems(menu_handle, "cb", refcm);
   } else {
      addCPPRefactoringMenuItems(menu_handle, "cb", null);
      addQuickRefactoringMenuItems(menu_handle, "cb", null);
   }

   // populate organize imports submenu
   struct VS_TAG_BROWSE_INFO oicm;
   if(f.ctl_class_tree_view.get_user_tag_info(i, oicm, false)) {
      addOrganizeImportsMenuItems(menu_handle, "cb", oicm, false, _mdi.p_child.p_buf_name);
   } else {
      addOrganizeImportsMenuItems(menu_handle, "cb", null, false, _mdi.p_child.p_buf_name);
   }

   // Show the menu.
   int x=mou_last_x('M')-100;
   int y=mou_last_y('M')-100;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   _KillToolButtonTimer();
   call_list('_on_popup2_',translate("_cbrowse_menu",'_','-'),menu_handle);
   _menu_show(menu_handle,VPM_LEFTALIGN|VPM_RIGHTBUTTON,x,y);
   _menu_destroy(menu_handle);
}

//////////////////////////////////////////////////////////////////////////////
// Toggle display of class filter
//
_command cb_filterby_menu(_str option="") name_info(','VSARG2_CMDLINE)
{
   if (option=='') {
      return '';
   }

   _nocheck _control ctl_class_filter_label;
   _nocheck _control ctl_member_filter_label;
   int f = GetCBViewWid();
   if (!f) {
      return '';
   }

   // based on menu selection
   switch (option) {
   case 'class':
      f.ctl_class_filter_label.p_user = (f.ctl_class_filter_label.p_user)? 0:1;
      break;
   case 'member':
      f.ctl_member_filter_label.p_user = (f.ctl_member_filter_label.p_user)? 0:1;
      break;
   case 'options':
      return cb_options();
   default:
      return '';
   }

   f.checkShowHideControls();
   return cb_refresh();
}

//////////////////////////////////////////////////////////////////////////////
// Reposition the controls depending on whether they want the member
// and class filters visible or not.
//
// Expects p_window_id to be the form containing the symbol browser
// and all symbol browser controls.
//
static void checkShowHideControls()
{
   _nocheck _control ctl_class_filter_combo_box;
   _nocheck _control ctl_member_filter_combo_box;
   _nocheck _control ctl_class_filter_label;
   _nocheck _control ctl_member_filter_label;
   _nocheck _control ctl_class_tree_view;
   _nocheck _control ctl_filter_check_box;

   // vertical margin
   int border_height = ctl_filter_check_box.p_y;

   // grab bit flags
   int show_class_filter  = ctl_class_filter_label.p_user;
   int show_member_filter = ctl_member_filter_label.p_user;

   if (show_class_filter != ctl_class_filter_combo_box.p_visible ||
       show_member_filter != ctl_member_filter_combo_box.p_visible) {

      // hide/show class filter
      ctl_class_filter_combo_box.p_visible = (show_class_filter)? 1:0;
      ctl_class_filter_label.p_visible     = (show_class_filter)? 1:0;

      // compute initial y position for class tree view
      int label_height = ctl_class_filter_combo_box.p_height + border_height;
      int tree_view_y = ctl_class_filter_combo_box.p_y;
      if (show_class_filter) {
         tree_view_y += label_height;
      }

      // hide/show member filter
      ctl_member_filter_combo_box.p_visible = (show_member_filter)? 1:0;
      ctl_member_filter_label.p_visible     = (show_member_filter)? 1:0;

      // position the member filter, and maybe adjust position of tree view
      ctl_member_filter_combo_box.p_y = tree_view_y;
      ctl_member_filter_label.p_y     = tree_view_y;
      if (show_member_filter) {
         tree_view_y += label_height;
      }

      resizeSymbolsBrowser();
   }
}

//////////////////////////////////////////////////////////////////////////////
// Save the state of the class tree.  This is a recursive function whose
// output is a string (open_cats) which represents the set of open
// non-leaf nodes in the tree.  The syntax of the output string is:
//
//    c_1{s}c_2{s}...c_n{s}
//
// where 'c_i' is the caption of the tree item (pre-tab) and 's' is any
// string of the same form.
//
// p_window_id must be the symbol browser tree control.
//
static void save_class_tree_view(int i, _str parent, _str &open_cats)
{
   // search for member
   int child = _TreeGetFirstChildIndex(i);
   while (child > 0) {
      int show_children;
      _TreeGetInfo(child, show_children);
      if (show_children == TREE_NODE_EXPANDED) {
         _str caption = _TreeGetCaption(child);
         parse caption with caption "\t" .;
         parse caption with caption CB_delimiter .;
         open_cats = open_cats :+ caption '{';
         save_class_tree_view(child, caption, open_cats);
         open_cats = open_cats '}';
      }
      child = _TreeGetNextSiblingIndex(child);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Compare the caption at tree index 'i' with the given caption string.
// Handles special cases of tabs and PARTIAL LISTs for categories.
// p_window_id must be the symbol browser tree control.
//
static int caption_is_equal(int i, _str &label)
{
   _str caption='',label_no_paren='';
   parse _TreeGetCaption(i) with caption "\t" .;
   parse caption with caption CB_delimiter .;
   parse caption with caption '(' .;
   // DJB 11-15-2005
   // remove template parameter signatures
   if (pos('>',caption) > pos('<',caption) && !pos('<',label)) {
      parse caption with caption '<' .;
   }
   parse label with label_no_paren '(' .;
   return (caption :== label_no_paren)? 1:0;
}

//////////////////////////////////////////////////////////////////////////////
// Remove entries from open categories string until synchronized on
// a closing brace.  This function is nearly identical in structure
// to restore_class_tree_view(), except that it does not interact with
// the tree at all.
//
static void strip_restore_error(_str &open_cats)
{
   // loop until we hit the end of the list
   _str label='';
   while (pos("}", open_cats) != 1) {
      parse open_cats with label '{' open_cats;
      if (label == '') {
         return;
      }
      strip_restore_error(open_cats);
   }

   // clean up (remove trailing brace)
   if (pos("}", open_cats) == 1) {
     open_cats = substr(open_cats, 2);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Restores the state of the class tree.  This is a recursive function
// whose input (open_cats) is of the form described above in
// save_class_tree_view.  It parses the input string and opens
// tree nodes with matching headlines, causing them to be expanded
// in accordance with the current filtering options.
// p_window_id must be the symbol browser tree control.
//
static void restore_class_tree_view(int i, _str &open_cats)
{
   //say("restore_class_tree_view: i="i" open_cats="open_cats);
   int child = _TreeGetFirstChildIndex(i);

   // loop until we hit the end of the list
   _str label='';
   while (pos("}", open_cats) != 1) {

      // get the item label to search for
      parse open_cats with label '{' open_cats;
      if (label == '') {
         return;
      }

      // search each child node (including the current child)
      while (child > 0) {
         int show_children=0;
         _TreeGetInfo(child, show_children);
         if (show_children==TREE_NODE_COLLAPSED && caption_is_equal(child,label)) {
            //say("Found: "label" index="child);
            call_event(CHANGE_EXPANDED,child,p_window_id,ON_CHANGE,'w');
            _TreeSetInfo(child, TREE_NODE_EXPANDED);
            restore_class_tree_view(child, open_cats);
            child = _TreeGetNextSiblingIndex(child);
            break;
         }
         child = _TreeGetNextSiblingIndex(child);
      }

      if (child <= 0 && open_cats != '' && pos("}", open_cats) != 1) {
         strip_restore_error(open_cats);
         child = _TreeGetFirstChildIndex(i);
      }
   }

   // clean up (remove trailing brace)
   if (pos("}", open_cats) == 1) {
     open_cats = substr(open_cats, 2);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Restores the position of the currently selected item in the
// symbol browser tree view.  The input is the form window ID and
// a comma separated list of captions.  This function may also
// be used to set the position of the symbol browser.  This is how
// cb_find (Find Tag) works.
//
// This function recursively tries all tree paths that match until
// it finds one that matches.  On exit it will return either
// -1, indicating that the item was not found, or the tree index
// of the item.  It is the caller's responsibility to set the current
// index in the tree control after calling this function.
//
// p_window_id must be the symbol browser tree control.
//
static int restore_position(int index, _str path)
{
   // boundary case, return if this is successful
   if (path=='') {
      //say("restore_position: empty path");
      return index;
   }

   // grab the first item off of the path
   //say('entering with--'path);
   _str label='';
   parse path with label ',' path;

   // get first child of tree node 'index'
   _str caption;
   int child, found_at;
   found_at = -1;
   child = _TreeGetFirstChildIndex(index);
   while (child > 0) {
      if (caption_is_equal(child, label)) {
         found_at = child;
         int show_children=0;
         _TreeGetInfo(child, show_children);
         if (show_children == TREE_NODE_COLLAPSED && path != '') {
            //say(label '=========' path);
            parse path with caption ',' .;
            parse caption with gz_exception_name '(' .;
            call_event(CHANGE_EXPANDED,child,p_window_id,ON_CHANGE,'w');
            gz_exception_name = '';
         }
         int result = restore_position(child, path);
         if (result >= 0) {
            //say('expanding--'label);
            if (show_children == TREE_NODE_COLLAPSED && path != '') {
               _TreeSetInfo(child, TREE_NODE_EXPANDED);
            }
            return result;
         }
      }
      child = _TreeGetNextSiblingIndex(child);
   }

   // maybe we had a category that broke into sections?
   int depth = _TreeGetDepth(index);
   if (depth == 2) {
      _str first_char = substr(label, 1, 1) ':';
      child = _TreeSearch(index, first_char, 'PI');
      if (child > 0) {
         found_at = child;
         path = label :+ ((path=='')? '' : ',') :+ path;
         int show_children;
         _TreeGetInfo(child, show_children);
         call_event(CHANGE_EXPANDED,child,p_window_id,ON_CHANGE,'w');
         int result = restore_position(child, path);
         if (result >= 0) {
            //say('letter expanding--'label);
            if (show_children == TREE_NODE_COLLAPSED && path != '') {
               _TreeSetInfo(child, TREE_NODE_EXPANDED);
            }
            return result;
         }
      }
   }


   // bail out if we don't find a matching caption
   //say("restore_position: found_at="found_at);
   return found_at;
}

//////////////////////////////////////////////////////////////////////////////
// Save the current position of the symbol browser as a comma-separated
// list of captions appropriate for use with restore_position (above).
// p_window_id must be the symbol browser tree control.
//
static void save_position(_str &curr_path)
{
   // save the current position
   curr_path = '';
   int child = _TreeCurIndex();
   while (child > 0) {
      _str caption = _TreeGetCaption(child);
      parse caption with caption "\t" .;
      parse caption with caption CB_delimiter .;
      if (curr_path != '') {
         curr_path = caption ',' curr_path;
      } else {
         curr_path = caption;
      }
      child = _TreeGetParentIndex(child);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the class tree view, starting at the given 'index' and doing
// everything below.  This is a recursive function, calling itself to
// refresh non-leaf children.  The function assumes that the tree index
// passed in is a tree index of a non-leaf tree node.
// p_window_id must be the symbol browser tree control.
//
static void refresh_class_tree_view(int index)
{
   // expand/close this tree item
   call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');

   // recursively refresh our children
   int child  = _TreeGetFirstChildIndex(index);
   while (child > 0) {
      int show_children;
      _TreeGetInfo(child, show_children);
      if (show_children==TREE_NODE_EXPANDED) {
         refresh_class_tree_view(child);
      } else if (show_children==TREE_NODE_COLLAPSED) {
         _TreeDelete(child, 'c');
      }
      child = _TreeGetNextSiblingIndex(child);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the inheritance and tag properties dialogs if they are up.
// p_window_id must be the symbol browser tree control.
//
static void refresh_dialog_views()
{
   // get the details about the current selection
   int currIndex = _TreeCurIndex();
   if (currIndex <= 0) {
      return;
   }

   int show_children = 0;
   _TreeGetInfo(currIndex, show_children);
   struct VS_TAG_BROWSE_INFO cm;
   get_user_tag_info(currIndex, cm, false);

   // refresh the properties toolbar
   int f = gtbprops_wid;
   if (f) {
      cb_refresh_property_view(cm);
   }

   // refresh the inheritance tree
   f = gcbparents_wid;
   if (f) {
      if (show_children == TREE_NODE_LEAF) {
         int parentIndex = _TreeGetParentIndex(currIndex);
         get_user_tag_info(parentIndex, cm, false);
      }
      _nocheck _control ctl_member_tree_view;
      if (f.ctl_member_tree_view.p_user != 1) {
         f.refresh_inheritance_view(cm,null,true);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Recursive function used by _TagFileModified_cbrowser (below) that
// handles updating items that were inherited from classes in another
// tag file that was modified.
// p_window_id must be the symbol browser tree control.
//
static void refresh_inherited_tags(int index, int prj_key)
{
   int child = _TreeGetFirstChildIndex(index);
   while (child > 0) {
      typeless v = _TreeGetUserInfo(child);
      if (v._varformat()==VF_LSTR && isinteger(v)) {
         if ((v intdiv (CB_MAX_LINE_NUMBER*CB_MAX_FILE_NUMBER)) == prj_key) {
            refresh_class_tree_view(index);
            return;
         }
      }
      int show_children;
      _TreeGetInfo(child, show_children);
      if (show_children==TREE_NODE_EXPANDED) {
         refresh_inherited_tags(child, prj_key);
      } else if (show_children==TREE_NODE_COLLAPSED) {
         _TreeDelete(child, 'c');
      }
      child = _TreeGetNextSiblingIndex(child);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Refresh display for given tag file name.  This function handles both
// updating everything under the tag file that was modified, as well as
// updating items in other tag files that were inherited by this item.
//
void _TagFileModified_cbrowser(_str tag_db_name)
{
   int f = GetCBViewWid();
   if (!f) {
      return;
   }
   _nocheck _control ctl_class_tree_view;

   // blow out of here if we are not the active tab
   if (!isClassBrowserActive()) {
      gi_need_refresh=1;
      return;
   }                                       

   // make the symbol browser tree control the current object
   int orig_wid = p_window_id;
   p_window_id = f.ctl_class_tree_view;
   gi_in_refresh = 1;

   // search for project
   int prj_index  = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   _str prj_db_name;
   while (prj_index > 0) {
      _str caption = _TreeGetCaption(prj_index);
      parse caption with . ':' prj_db_name;
      if (file_eq(strip(prj_db_name), tag_db_name)) {
         break;
      }
      prj_index = _TreeGetNextSiblingIndex(prj_index);
   }
   if (prj_index < 0) {
      prj_index = 0;
   }

   // refresh the class tree view under this project
   int show_children=0;
   _TreeGetInfo(prj_index, show_children);
   if (show_children==TREE_NODE_EXPANDED) {
      refresh_class_tree_view(prj_index);
   }

   // refresh the class tree view for inherited members from this tag file
   int prj_key = _TreeGetUserInfo(prj_index);
   int index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      if (index != prj_index) {
         int count=0;
         int child = _TreeGetFirstChildIndex(index);
         while (child > 0 && ++count<8) {
            _TreeGetInfo(child, show_children);
            if (show_children==TREE_NODE_EXPANDED) {
               refresh_inherited_tags(child, prj_key);
            }
            child = _TreeGetNextSiblingIndex(child);
         }
      }
      index = _TreeGetNextSiblingIndex(index);
   }
   _TreeRefresh();

   // refresh the derived classes dialog, parent classes, properties, etc
   refresh_dialog_views();

   gi_in_refresh = 0;
   p_window_id = orig_wid;
   return;
}

//////////////////////////////////////////////////////////////////////////////
// Update the list of tag files in the symbol browser tree
// p_window_id must be the symbol browser tree control.
//
void refresh_tagfiles()
{
   // populate restoration hash table
   int i,count = 1;
   _TreeBeginUpdate(TREE_ROOT_INDEX);
   // put in the project tags file names
   _str tag_files = project_tags_filename();
   if(isEclipsePlugin())
   {
      int status = _eclipse_get_projects_tagfiles(tag_files);
//    tag_files = _GetEclipseTagFiles("java");
//    _str cFiles = _GetEclipseTagFiles("c");
//    _str wsFiles = _GetEclipseTagFiles("");
//    if(cFiles != '') {
//       tag_files = tag_files:+ cFiles;
//    }
//    if(wsFiles != '') {
//       tag_files = tag_files:+ wsFiles;
//    }
   }
   _str filename=next_tag_file(tag_files,true);
   while (filename != '') {
      i=add_tag_file(filename, CB_project_tag_file, ++count);
      filename=next_tag_file(tag_files,false);
   }

   // now put in the auto-updated workspace tag files
   tag_files = auto_updated_tags_filename();
   filename = next_tag_file(tag_files,true);
   while (filename != '') {
      i=add_tag_file(filename, CB_autoupdated_tag_file, ++count);
      filename=next_tag_file(tag_files,false);
   }

   // now put in the global tags file names
   tag_files = global_tags_filename();
   //say('global tags:'tag_files);
   filename=next_tag_file(tag_files,true);
   while (filename != '') {
      i=add_tag_file(filename, CB_global_tag_file, ++count);
      filename=next_tag_file(tag_files,false);
   }

   // now put in the extension specific tags file names
   _str langTagFileTable:[];
   LanguageSettings.getTagFileListTable(langTagFileTable);

   foreach (auto langId => auto langTagFileList in langTagFileTable) {
      mode_name := _LangId2Modename(langId);
      tag_files=AbsoluteList(_replace_envvars(langTagFileList));
      filename=next_tag_file(tag_files,true);
      while (filename != '') {
         add_tag_file(filename, '"'mode_name'"', ++count);
         filename=next_tag_file(tag_files,false);
      }
   }

   // now put in the compiler tags file names
   tag_files = compiler_tags_filename('c');
   filename=next_tag_file(tag_files,true);
   while (filename != '') {
      i=add_tag_file(filename, CB_cpp_compiler_tag_file, ++count);
      filename=next_tag_file(tag_files,false);
   }


   tag_files = compiler_tags_filename('java');
   filename=next_tag_file(tag_files,true);
   while (filename != '') {
      i=add_tag_file(filename, CB_java_compiler_tag_file, ++count);
      filename=next_tag_file(tag_files,false);
   }


   //cb_remove_stale_items(TREE_ROOT_INDEX);
   _TreeEndUpdate(TREE_ROOT_INDEX);
   _TreeSortUserInfo(TREE_ROOT_INDEX, 'N');
   _TreeRefresh();
}

//////////////////////////////////////////////////////////////////////////////
// Refresh list of tag databases.  It uses prepare_for_expand() to set up
// a hash table of all the current tag database captions.  Tries to insert
// the new ones, and deletes all the stale items afterward.
//
void _TagFileAddRemove_cbrowser(_str file_name, _str options)
{
   int f = GetCBViewWid();
   if (!f) return;
   _nocheck _control ctl_class_tree_view;

   // blow out of here if we are not the active tab
   if (!isClassBrowserActive()) {
      gi_need_refresh=1;
      return;
   }                                       

   // refresh tag files
   f.ctl_class_tree_view.refresh_tagfiles();
}

//////////////////////////////////////////////////////////////////////////////
// Callback for refreshing the symbol browser, as required by the background
// tagging.  Since we handle the AddRemove and Modified callbacks, we don't
// have to do anything for refresh, we are already totally up-to-date.
//
void _TagFileRefresh_cbrowser()
{
   int f = GetCBViewWid();
   if (!f) return;
   _nocheck _control ctl_class_tree_view;

   // blow out of here if we are not the active tab
   if (!isClassBrowserActive()) {
      gi_need_refresh=1;
      return;
   }                                       

   // refresh tag files
   int orig_refresh = gi_in_refresh;
   gi_in_refresh = 1;
   f.ctl_class_tree_view.refresh_tagfiles();
   f.ctl_class_tree_view.refresh_dialog_views();
   gi_in_refresh = orig_refresh;
}

//////////////////////////////////////////////////////////////////////////////
// Restore the symbol browser tree when they open a new project
//
void _prjopen_cbrowser()
{
   // symbol browser restore options turned off?
   if (!(def_restore_flags & RF_CBROWSER_TREE)) {
      return;
   }

   // find the symbol browser
   int f = GetCBViewWid();
   if (!f) return;
   _nocheck _control ctl_class_tree_view;

   // blow out of here if we are not the active tab
   if (!isClassBrowserActive()) {
      gi_need_refresh=1;
      return;
   }                                       

   // refresh tag files, we get this callback before Addremove (above)
   f.ctl_class_tree_view.refresh_tagfiles();

   // now restore open items
   _str open_cats, curr_path;
   open_cats = _retrieve_value("_tbcbrowser_form.ctl_member_filter_label");
   curr_path = _retrieve_value("_tbcbrowser_form.ctl_class_filter_label");

   gi_in_refresh = 1;
   f.ctl_class_tree_view.restore_class_tree_view(TREE_ROOT_INDEX, open_cats);
   int index = f.ctl_class_tree_view.restore_position(TREE_ROOT_INDEX, curr_path);
   if (index > 0) {
      f.ctl_class_tree_view._TreeSetCurIndex(index);
   }
   f.ctl_class_tree_view._TreeRefresh();
   gi_in_refresh = 0;
}

//////////////////////////////////////////////////////////////////////////////
// Force a refresh of the symbol browser.
//
_command cb_refresh() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      return '';
   }

   gi_in_refresh = 1;
   boolean orig_redraw=f.ctl_class_tree_view.p_redraw;
   f.ctl_class_tree_view.p_redraw=false;
   f.ctl_class_tree_view.refresh_class_tree_view(TREE_ROOT_INDEX);
   f.ctl_class_tree_view.refresh_dialog_views();
   f.ctl_class_tree_view.p_redraw=orig_redraw;
   gi_need_refresh = 0;
   gi_in_refresh = 0;
}

//////////////////////////////////////////////////////////////////////////////
// shortcuts for sort by line and short by name
//
_command cb_sortby_line() name_info(','VSARG2_EDITORCTL)
{
   cb_sortby_menu('sortline');
}
_command cb_sortby_name() name_info(','VSARG2_EDITORCTL)
{
   cb_sortby_menu('sortname');
}
_command cb_sortby_float() name_info(','VSARG2_EDITORCTL)
{
   cb_sortby_menu('floattotop');
}
//////////////////////////////////////////////////////////////////////////////
// Change gi_sort_by_line and force a refresh of the symbol browser
//
_command cb_sortby_menu(_str option='') name_info(','VSARG2_EDITORCTL)
{
   if (option=='') {
      return '';
   }

   int f = GetCBViewWid();
   if (!f) {
      return '';
   }

   // based on menu selection
   switch (option) {
   case 'sortline':
      gi_sort_by_line = 1;
      break;
   case 'sortname':
      gi_sort_by_line = 0;
      break;
   case 'floattotop':
      gi_sort_float_to_top = (int) !gi_sort_float_to_top;
      break;
   default:
      return '';
   }

   return cb_refresh();
}

//////////////////////////////////////////////////////////////////////////////
// Retrieve and translate the class filter and member filter regular
// expressions.  If the input expression (p_text) contains vertical
// bars, open parentheses, or left curly braces, then do not perform
// translation.  The following translations are performed:
//    -- convert all comma's, semicolons, and spaces to | (OR)
//    -- eliminate adjacent vertical bars
//    -- For brief regular expressions, add grouping
//    -- For brief regular expression, shift BOL/EOL symbols to begin/end
//
// p_window_id must be the combo box containing the regular expression.
//
static _str cb_get_filter()
{
   if (p_visible) {
      _str re = p_text;
      if (!pos('|',re) && !pos('(',re) && !pos('{',re)) {
         _str s = strip(re);
         s = translate(s,'|||',';, ');
         s = stranslate(s,'|','[|][|]#', 'R');
         if (pos('|',s) && (def_re_search&BRIEFRE_SEARCH)) {
            s = '\(' :+ stranslate(s, '\)|\(', '|') :+ '\)';
         }
         return s;
      }
      return re;
   }
   return '';
}

//////////////////////////////////////////////////////////////////////////////
// right click callback for filtering options image, simply
// displays the options dialog.
//
void ctl_filter_check_box.rbutton_up()
{
   cb_options();
}

//////////////////////////////////////////////////////////////////////////////
// single-click callback for filtering options image button,
// pick up new value of options and apply changes (if any)
//
void ctl_filter_check_box.lbutton_up()
{
   if (p_value) {
      ctl_class_filter_combo_box.p_text  = '';
      ctl_member_filter_combo_box.p_text = '';
   }
   cb_refresh();
}

//////////////////////////////////////////////////////////////////////////////
// 'enter' event handler for both the class filter or member filter
// combo-box controls.  Retrieves both filters and updates the class
// browser if either one of them has changed.
//
void ctl_class_filter_combo_box.enter()
{
   _nocheck _control ctl_class_filter_combo_box;
   _nocheck _control ctl_member_filter_combo_box;
   _nocheck _control ctl_class_tree_view;

   // for dialog box retrieval
   _append_retrieve(ctl_class_filter_combo_box, ctl_class_filter_combo_box.p_text);
   _append_retrieve(ctl_member_filter_combo_box, ctl_member_filter_combo_box.p_text);
   _save_form_response();
   ctl_class_filter_combo_box._retrieve_list();
   ctl_member_filter_combo_box._retrieve_list();

   // get the current filters
   _str c_filter = ctl_class_filter_combo_box.cb_get_filter();
   _str m_filter = ctl_member_filter_combo_box.cb_get_filter();
   if (c_filter :== gz_class_filter && m_filter :== gz_member_filter) {
      return;
   } else {
      gz_class_filter  = c_filter;
      gz_member_filter = m_filter;
   }
   if (c_filter!='' || m_filter!='') {
      ctl_filter_check_box.p_value=0;
   }

   // update the symbol browser (refreshs everything)
   cb_refresh();
}

//////////////////////////////////////////////////////////////////////////////
// Add a tag file to the tree control, return the new index
// p_window_id must be the symbol browser tree control.
//
static int add_tag_file(_str file_name, _str file_type, int sequence_number)
{
   // open the tag database for business
   int status = tag_read_db(file_name);
   if ( status < 0 ) {
      return(status);
   }

   // get tag file description
   _str caption = file_type ": " file_name;
   _str descr = tag_get_db_comment();
   if (descr != '') {
      caption = caption ' (' descr ')';
   }

   int j = _TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, gi_pic_proj_close, gi_pic_proj_open, TREE_NODE_COLLAPSED, 0, sequence_number);
   return j;
}

//////////////////////////////////////////////////////////////////////////////
// on form creation, popuplate the tree widget, set initial focus
//
void ctl_class_tree_view.on_create()
{
   gtbcbrowser_wid=p_active_form;

   ctl_class_filter_label.p_user  = _retrieve_value("_tbcbrowser_form.ctl_class_filter_label.p_visible");
   ctl_member_filter_label.p_user = _retrieve_value("_tbcbrowser_form.ctl_member_filter_label.p_visible");
   _str v=_retrieve_value("_tbcbrowser_form.ctl_filter_check_box");
   if (v!='' && isnumber(v)) {
      ctl_filter_check_box.p_value=(int)v;
   }
   ctl_class_filter_combo_box._retrieve_value();
   ctl_member_filter_combo_box._retrieve_value();
   ctl_class_filter_combo_box._retrieve_list();
   ctl_member_filter_combo_box._retrieve_list();
   if (ctl_filter_check_box.p_value) {
      ctl_class_filter_combo_box.p_text='';
      ctl_member_filter_combo_box.p_text='';
   }
   gz_class_filter  = ctl_class_filter_combo_box.cb_get_filter();
   gz_member_filter = ctl_member_filter_combo_box.cb_get_filter();
   ctl_class_tree_view.p_user = _retrieve_value("_tbcbrowser_form.ctl_class_tree_view");
   if (ctl_class_tree_view.p_user == "") {
      ctl_class_tree_view.p_user = CB_DEFAULTS;
   }
   ctl_filter_check_box.p_user = _retrieve_value("_tbcbrowser_form.ctl_filter_check_box.p_user");
   if (ctl_filter_check_box.p_user == "") {
      ctl_filter_check_box.p_user = CB_DEFAULTS2;
   }
   gi_sort_by_line = _retrieve_value("_cbrowse_menu.cb_sort_by_line");
   gi_sort_float_to_top = _retrieve_value("_cbrowse_menu.cb_sort_float");

   // insert items for each tag file
   ctl_class_tree_view.refresh_tagfiles();

   if (def_restore_flags & RF_CBROWSER_TREE) {
      _str open_cats, curr_path;
      open_cats = _retrieve_value("_tbcbrowser_form.ctl_member_filter_label");
      curr_path = _retrieve_value("_tbcbrowser_form.ctl_class_filter_label");

      gi_in_refresh = 1;
      ctl_class_tree_view.restore_class_tree_view(TREE_ROOT_INDEX, open_cats);
      int index = ctl_class_tree_view.restore_position(TREE_ROOT_INDEX, curr_path);
      if (index > 0) {
         ctl_class_tree_view._TreeSetCurIndex(index);
      }
      gi_in_refresh = 0;
   }

   checkShowHideControls();
   ctl_class_tree_view._TreeRefresh();
   ctl_class_tree_view._MakePreviewWindowShortcuts();
}

///////////////////////////////////////////////////////////////////////////////
// For saving and restoring the state of the classes tool window
// when the user undocks, pins, unpins, or redocks the window.
//
struct SYMBOL_BROWSER_WINDOW_STATE {
   int restore_flags;
   typeless nodes;
   int column_width;
};
void _tbSaveState__tbcbrowser_form(SYMBOL_BROWSER_WINDOW_STATE& state, boolean closing)
{
   //if( closing ) {
   //   return;
   //}
   state.restore_flags = def_restore_flags;
   ctl_class_tree_view._TreeSaveNodes(state.nodes);
   def_restore_flags &= ~RF_CBROWSER_TREE;
}
void _tbRestoreState__tbcbrowser_form(SYMBOL_BROWSER_WINDOW_STATE& state, boolean opening)
{
   //if( opening ) {
   //   return;
   //}
   if (state == null) return;
   ctl_class_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
   ctl_class_tree_view._TreeRestoreNodes(state.nodes);
   ctl_class_tree_view._TreeSizeColumnToContents(0);
   def_restore_flags = state.restore_flags;
}

//////////////////////////////////////////////////////////////////////////////
// Called when the symbol browser is resized
//
void cbrowser_on_resize(int avail_width, int avail_height)
{
   int f = GetCBViewWid();
   if (!f) return;

   // available width, height, and amount of border
   int border_width   = f.ctl_class_tree_view.p_x;
   int border_height  = f.ctl_filter_check_box.p_y;
   avail_width    -= border_width;
   avail_height   -= border_height;

   // count the number of label/combo-boxes visible
   int labels_visible=0;
   if (f.ctl_class_filter_label.p_visible) {
      labels_visible++;
   }
   if (f.ctl_member_filter_label.p_visible) {
      labels_visible++;
   }

   // adjust x position and width of filters
   f.ctl_filter_check_box.p_width = avail_width - border_width;
   int label_x     = f.ctl_class_filter_label.p_x;
   int label_w1    = f.ctl_class_filter_label.p_width;
   int label_w2    = f.ctl_member_filter_label.p_width;
   int label_width = (label_w1>label_w2)? label_w1:label_w2;
   int label_height   = border_height + f.ctl_class_filter_combo_box.p_height;
   int filter_x = label_width + label_x;
   int filter_w = avail_width - filter_x;
   f.ctl_class_filter_combo_box.p_x = filter_x;
   f.ctl_class_filter_combo_box.p_width = filter_w;
   f.ctl_member_filter_combo_box.p_x = filter_x;
   f.ctl_member_filter_combo_box.p_width = filter_w;
   f.ctl_member_filter_label.p_x = label_x;
   int label_y = f.ctl_class_filter_combo_box.p_y + labels_visible*label_height;

   // adjust the size and position the class tree view
   f.ctl_class_tree_view.p_y = label_y;
   f.ctl_class_tree_view.p_width  = avail_width - border_width;
   f.ctl_class_tree_view.p_height = avail_height - 
                                    labels_visible*label_height - 
                                    2*border_height - f.ctl_filter_check_box.p_height;

   // adjust y position of member filter
   f.ctl_member_filter_combo_box.p_y = label_y - label_height - border_height;
   f.ctl_member_filter_label.p_y     = f.ctl_member_filter_combo_box.p_y +
            (f.ctl_member_filter_combo_box.p_height - f.ctl_member_filter_label.p_height)/2;
}

static void resizeSymbolsBrowser()
{
   int old_wid, clientW, clientH;
   if (isEclipsePlugin()) {
      int classesOutputContainer = GetCBViewWid();
      if(!classesOutputContainer) return;
      old_wid = p_window_id;
      p_window_id = classesOutputContainer;
      eclipse_resizeContainer(classesOutputContainer);
      clientW = classesOutputContainer.p_parent.p_width; 
      clientH = classesOutputContainer.p_parent.p_height;
   } else {
      clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
      clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   }
   
   // Resize width
   ctl_class_tree_view.p_width = clientW - 2 * ctl_class_tree_view.p_x;
   ctl_class_filter_combo_box.p_width = clientW - ctl_class_filter_combo_box.p_x - ctl_class_tree_view.p_x;
   ctl_member_filter_combo_box.p_width = clientW - ctl_member_filter_combo_box.p_x - ctl_class_tree_view.p_x;

   // Resize height
   ctl_class_tree_view.p_height = clientH - ctl_class_tree_view.p_y - ctl_class_tree_view.p_x;
   cbrowser_on_resize(clientW, clientH);

   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

void _tbcbrowser_form.on_resize()
{
   resizeSymbolsBrowser();
}

//////////////////////////////////////////////////////////////////////////////
// Called by on_destroy event for _tbcbrowser_form
//
void cbrowser_on_destroy()
{
   // get the window ID of the form
   int f = GetCBViewWid();
   if (!f) return;

   // save all the currently open categories
   _str open_cats = '';
   _str curr_path = '';
   if (def_restore_flags & RF_CBROWSER_TREE) {
      f.ctl_class_tree_view.save_class_tree_view(TREE_ROOT_INDEX, '', open_cats);
      f.ctl_class_tree_view.save_position(curr_path);
   }

   // save options and current position
   _nocheck _control ctl_member_filter_label;
   _nocheck _control ctl_class_filter_label;
   _append_retrieve(0, f.ctl_member_filter_label.p_user, "_tbcbrowser_form.ctl_member_filter_label.p_visible");
   _append_retrieve(0, f.ctl_class_filter_label.p_user,  "_tbcbrowser_form.ctl_class_filter_label.p_visible");
   _append_retrieve(f.ctl_member_filter_combo_box, f.ctl_member_filter_combo_box.p_text, "_tbcbrowser_form.ctl_member_filter_combo_box");
   _append_retrieve(f.ctl_class_filter_combo_box,  f.ctl_class_filter_combo_box.p_text,  "_tbcbrowser_form.ctl_class_filter_combo_box");
   _append_retrieve(0, f.ctl_class_tree_view.p_user, "_tbcbrowser_form.ctl_class_tree_view" );
   _append_retrieve(0, f.ctl_filter_check_box.p_user, "_tbcbrowser_form.ctl_filter_check_box.p_user" );
   _append_retrieve(0, open_cats, "_tbcbrowser_form.ctl_member_filter_label" );
   _append_retrieve(0, curr_path, "_tbcbrowser_form.ctl_class_filter_label" );
   _append_retrieve(0, gi_sort_by_line, "_cbrowse_menu.cb_sort_by_line" );
   _append_retrieve(0, gi_sort_float_to_top, "_cbrowse_menu.cb_sort_float" );
   _append_retrieve(0, f.ctl_filter_check_box.p_value, "_tbcbrowser_form.ctl_filter_check_box");

   // reset the cached window ID's
   gtbcbrowser_wid  = 0;
   gcbparents_wid  = 0;
   gcboptions_wid  = 0;
   //gtbprops_wid    = 0;
}

void _tbcbrowser_form.on_destroy()
{
   cbrowser_on_destroy();
   call_event(p_window_id,ON_DESTROY,'2');
}

//////////////////////////////////////////////////////////////////////////////
// Decompose the typeless user data into database ID, file_id, and line_no
//
int cb_get_db_file_line(typeless value, int &db_id, int &file_id, int &line_no)
{
   if ((VF_IS_INT(value) || value._varformat()==VF_LSTR) &&
       !value._isempty() && isnumber(value)) {

      // simple little computations
      line_no = value % CB_MAX_LINE_NUMBER;
      value   = value intdiv CB_MAX_LINE_NUMBER;
      file_id = value % CB_MAX_FILE_NUMBER;
      db_id   = value intdiv CB_MAX_FILE_NUMBER;
      return 0;
   }
   // invalid user info
   db_id=file_id=line_no=0;
   return 1;
}

static _str get_language_from_symbol_browser_database_caption(_str caption)
{
   if (caption == "Workspace" || caption == "Auto Updated") {
      return "";
   }
   if (pos(" Compiler",caption)) {
      parse caption with caption . ;
      if (caption == "C++") caption = "C/C++";
   }
   caption = strip(caption,"B","\"");
   lang := _Modename2LangId(caption);
   return lang;
}

//////////////////////////////////////////////////////////////////////////////
// grab the supplementary information stored with each tag in the tree widget
// p_window_id must be the symbol browser tree control.
//
static int get_user_tag_info(int j, struct VS_TAG_BROWSE_INFO &cm, boolean no_db_access)
{
   tag_browse_info_init(cm);

   // bail out if j <= 0
   int extra_depth=0;
   if (j <= 0) {
      return 0;
   }

   // handle things differently depending on the current depth
   int p,g;
   _str caption,file_name;
   int tree_depth = _TreeGetDepth(j);
   switch (tree_depth) {
   case 0:  // bail out if this is the tree root
      return 0;

   case 1:  // project/global tag file?
      caption = _TreeGetCaption(j);
      parse caption with caption ':' file_name ' (' .;
      cm.tag_database = absolute(strip(file_name));
      cm.language = get_language_from_symbol_browser_database_caption(caption);
      return 0;

   case 2: // category?
      p = _TreeGetParentIndex(j);
      caption = _TreeGetCaption(p);
      parse caption with caption ':' file_name ' (' .;
      cm.tag_database = absolute(strip(file_name));
      cm.language = get_language_from_symbol_browser_database_caption(caption);
      caption = _TreeGetCaption(j);
      parse caption with cm.category CB_delimiter .;
      return 0;

   case 3:
      // get the tag database name and category caption
      p = _TreeGetParentIndex(j);
      g = _TreeGetParentIndex(p);
      caption = _TreeGetCaption(g);
      parse caption with caption ':' file_name ' (' .;
      cm.tag_database = absolute(strip(file_name));
      cm.language = get_language_from_symbol_browser_database_caption(caption);
      caption = _TreeGetCaption(p);
      parse caption with cm.category CB_delimiter .;
      if (_TreeGetUserInfo(j) == '') {
         return 0;
      }
      caption = _TreeGetCaption(j);
      parse caption with cm.member_name CB_delimiter .;
      break;

   default:
      // traverse up the tree and locate tag database and category name
      p = _TreeGetParentIndex(j);
      g = _TreeGetParentIndex(p);
      int cat_index = j;
      int prj_index = p;
      while (g > 0) {
         if (_TreeGetUserInfo(g) != '') {
            cat_index = prj_index;
            prj_index = g;
         } else {
            extra_depth=1;
         }
         g = _TreeGetParentIndex(g);
      }

      // get the tag database name and category caption
      caption = _TreeGetCaption(prj_index);
      parse caption with caption ': ' file_name ' (' .;
      cm.tag_database = absolute(strip(file_name));
      cm.language = get_language_from_symbol_browser_database_caption(caption);
      caption = _TreeGetCaption(cat_index);
      parse caption with cm.category CB_delimiter .;
      cm.member_name  = _TreeGetCaption(j);
      parse cm.member_name with cm.member_name "\t" cm.class_name '(' .;
      //int lp=lastpos("::",cm.class_name);
      //if (lp) {
      //   cm.class_name=substr(cm.class_name,1,lp-1);
      //}
      parse cm.member_name with cm.member_name CB_delimiter .;
      break;
   }

   // normalize member name
   _str dummy='';
   tag_tree_decompose_caption(cm.member_name,cm.member_name,dummy,cm.arguments,cm.template_args);

   // get basic location info for this tag
   typeless value = _TreeGetUserInfo(j);
   int tag_file_id,file_id;
   cb_get_db_file_line(value, tag_file_id, file_id, cm.line_no);
   //say("file="file_id" line="cm.line_no" tagfile="tag_file_id" value="_TreeGetUserInfo(j));

   // find the tag file with the given sequence number (tag_file_id)
   int child=0;
   if (tag_file_id > 0) {
      child = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (child > 0) {
         int sequence_number;
         sequence_number = _TreeGetUserInfo(child);
         if (sequence_number == tag_file_id) {
            caption = _TreeGetCaption(child);
            parse caption with . ':' file_name ' (' .;
            cm.tag_database = absolute(strip(file_name));
            break;
         }
         child = _TreeGetNextSiblingIndex(child);
      }
   }

   // get the class name and member name for the fully qualified class name
   _str class_name,member_name;
   _str pcaption;
   _str separator;
   int target_depth;
   int show_children=0;
   _TreeGetInfo(j, show_children);
   if (show_children != TREE_NODE_LEAF) {
      class_name = cm.class_name;
      member_name = cm.member_name;
      target_depth = 4;
   } else {
      p = _TreeGetParentIndex(j);
      pcaption = _TreeGetCaption(p);
      parse pcaption with member_name "\t" class_name '(' .;
      int lp=lastpos("::",class_name);
      if (lp) {
         class_name=substr(class_name,1,lp-1);
      }
      target_depth = 5;
   }

   // get the picture index for the parent node
   int parent_show_children=0;
   int parent_pic_index=0;
   _TreeGetInfo(p, parent_show_children, parent_pic_index);

   // select the class separator and construct qualified name
   if (class_name != '') {
      separator = VS_TAGSEPARATOR_class;
      if (tree_depth == target_depth+extra_depth) {
         CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(cm.category);
         if (ctg && ctg->use_package_separator) {
            separator = VS_TAGSEPARATOR_package;
         } 
      } else if (parent_pic_index == gi_pic_access_type[CB_access_public][CB_type_package]) {
         separator = VS_TAGSEPARATOR_package;
      }
      cm.qualified_name = class_name :+ separator :+ member_name;
   } else {
      cm.qualified_name = member_name;
   }
   parse cm.qualified_name with cm.qualified_name '(' .;

   // bail out if we were asked not to touch the database
   if (no_db_access) {
      return 1;
   }

   // blow out of here if member_name == ''
   if (cm.member_name == '') {
      return 1;
   }

   // open the tag database for business
   int status = tag_read_db(cm.tag_database);
   if ( status < 0 ) {
      return(status);
   }

   // convert the tag file id to a real name
   status = tag_get_file(file_id, file_name);
   if (status) {
      return status;
   }
   cm.file_name = file_name;

   status = tag_get_language(file_name,cm.language);
   if (status) {
      cm.language="";
   } else if (cm.language=='jar' || cm.language=='zip') {
      cm.language='java';
   }

   // find the given tag in the file at the given line (case sensitive)
   status = tag_find_closest(cm.member_name, cm.file_name, cm.line_no, 1);
   if (!status) {
      tag_get_detail(VS_TAGDETAIL_type,      cm.type_name);
      tag_get_detail(VS_TAGDETAIL_flags,     cm.flags);
      tag_get_detail(VS_TAGDETAIL_return,    cm.return_type);
      tag_get_detail(VS_TAGDETAIL_arguments, cm.arguments);
      tag_get_detail(VS_TAGDETAIL_throws,    cm.exceptions);
      tag_get_detail(VS_TAGDETAIL_class_parents, cm.class_parents);
      tag_get_detail(VS_TAGDETAIL_template_args, cm.template_args);
      if (cm.type_name=='include' && cm.return_type!='' && file_exists(cm.return_type)) {
         cm.file_name=cm.return_type;
         cm.line_no=1;
      }
   }

   tag_reset_find_tag();
   return 1;
}

//////////////////////////////////////////////////////////////////////////////
// Find which tag file the given class belongs to, and normalize the
// class name (qualifies class name with package name) if (normalize!=0).
// Returns the tag file that the class was found in, or '' if not found.
//
static int find_class_in_cur_tag_file(_str cur_class_name, _str class_name,
                                      _str &qualified_name, boolean normalize,
                                      boolean ignore_case=false)
{
   //say("find_class_in_cur_tag_file: cur="cur_class_name" class="class_name);
   // disect the current class name into package and outer components
   _str inner_name,outer_name;
   tag_split_class_name(cur_class_name,inner_name,outer_name);

   if (normalize) {
      // first, try to find it in the current tag file, and current class context
      int status = tag_find_class(qualified_name, class_name, normalize, !ignore_case, outer_name);
      if (!status) {
         tag_reset_find_class();
         return 0;
      }

      // now try the current tag file, and current package
      if (pos(VS_TAGSEPARATOR_package,outer_name)>0) {
         outer_name = substr(outer_name,1,pos('S')-1);
         status = tag_find_class(qualified_name, class_name, normalize, !ignore_case, outer_name);
         if (!status) {
            tag_reset_find_class();
            return 0;
         }
      }
   }

   // OK, now try general case
   result := tag_find_class(qualified_name, class_name, normalize, ignore_case);
   tag_reset_find_class();
   return result;
}

//////////////////////////////////////////////////////////////////////////////
// Find which tag file the given class belongs to, and normalize the
// class name (qualifies class name with package name) if (normalize!=0).
// Returns the tag file that the class was found in, or '' if not found.
//
_str find_class_in_tag_file(_str cur_class_name, _str class_name,
                                   _str &qualified_name, boolean normalize,
                                   typeless &tag_files, boolean ignore_case=false)
{
   // disect the current class name into package and outer components
   _str inner_name,outer_name;
   tag_split_class_name(cur_class_name,inner_name,outer_name);

   // first, try to find it in the current tag file, and current class context
   _str orig_tag_file = tag_current_db();
   int status = find_class_in_cur_tag_file(cur_class_name,class_name,
                                           qualified_name,normalize,ignore_case);
   //say("find_class_in_tag_file1: qual="qualified_name" class="class_name" status="status" tagfile="orig_tag_file);
   if (status==0) {
      return orig_tag_file;
   }

   // didn't find it in our tag file, search others
   int i=0;
   _str filename=next_tag_filea(tag_files,i,false,true);
   while (filename != '') {
      if (! file_eq(filename, orig_tag_file)) {
         status = find_class_in_cur_tag_file(cur_class_name,class_name,
                                             qualified_name,normalize,ignore_case);
         //say("find_class_in_tag_file2: qual="qualified_name" class="class_name" status="status" tagfile="orig_tag_file);
         if (status==0) {
            tag_read_db(orig_tag_file);
            return filename;
         }
      }
      filename=next_tag_filea(tag_files,i,false,true);
   }

   // re-open the original tag file
   status = tag_read_db(orig_tag_file);
   return '';
}

int tag_get_browse_inheritance(VS_TAG_BROWSE_INFO &cm)
{
   // already have the information
   if (cm.class_parents != '') {
      return 0;
   }

   // check in tag database
   if (cm.tag_database != '') {
      // open the tag database
      tag_read_db(cm.tag_database);
   } 

   if (_isEditorCtl() && file_eq(cm.file_name, p_buf_name)) {

      // make sure that context and locals are up to date
      _UpdateContext(true);
      _UpdateLocals(true);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext();

      // check locals
      i := tag_find_local_iterator(cm.member_name, true, true, false, cm.class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_local_type, i, auto type_name);
         if (type_name == cm.type_name || cm.type_name == '') {
            tag_get_detail2(VS_TAGDETAIL_local_parents, i, cm.class_parents);
            tag_get_detail(VS_TAGDETAIL_local_line, auto file_line);
            if (file_line == cm.line_no || (cm.line_no==0 && cm.class_parents!='')) {
               if (cm.file_name=='') cm.file_name = p_buf_name;
               if (cm.line_no==0)    cm.line_no = file_line;
               return 0;
            }
         }
         // next please
         i = tag_next_local_iterator(cm.member_name, i, true, true, false, cm.class_name);
      }

      // check context
      i = tag_find_context_iterator(cm.member_name, true, true, false, cm.class_name);
      while (i > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type, i, auto type_name);
         if (type_name == cm.type_name || cm.type_name == '') {
            tag_get_detail2(VS_TAGDETAIL_context_parents, i, cm.class_parents);
            tag_get_detail(VS_TAGDETAIL_context_line, auto file_line);
            if (file_line == cm.line_no || (cm.line_no==0 && cm.class_parents!='')) {
               if (cm.file_name=='') cm.file_name = p_buf_name;
               if (cm.line_no==0)    cm.line_no = file_line;
               return 0;
            }
         }
         // next please
         i = tag_next_context_iterator(cm.member_name, i, true, true, false, cm.class_name);
      }
   }

   // we found some match, just not on the expected line
   if (cm.class_parents != '') {
      return 0;
   }

   // find all instances of the tag, tag first with class parents
   file_name:='';
   status := 0;
   if (cm.type_name!='') {
      status = tag_find_tag(cm.member_name, cm.type_name, cm.class_name, cm.arguments);
   } else {
      status = tag_find_equal(cm.member_name, true, cm.class_name);
   }
   while (!status) {
      // check file name and line number
      tag_get_detail(VS_TAGDETAIL_file_name, file_name);
      if (cm.file_name=='' || file_eq(file_name, cm.file_name)) { 
         tag_get_detail(VS_TAGDETAIL_class_parents, cm.class_parents);
         tag_get_detail(VS_TAGDETAIL_file_line, auto file_line);
         if (file_line == cm.line_no || (cm.line_no==0 && cm.class_parents!='')) {
            if (cm.file_name=='') cm.file_name = file_name;
            if (cm.line_no==0)    cm.line_no = file_line;
            tag_reset_find_tag();
            return 0;
         }
      }
      // next please
      if (cm.type_name!='') {
         status = tag_next_tag(cm.member_name, cm.type_name, cm.class_name, cm.arguments);
      } else {
         status = tag_next_equal(true, cm.class_name);
      }
   }
   tag_reset_find_tag();

   // we found some match, just not on the expected line
   if (cm.class_parents != '') {
      cm.file_name = file_name;
      cm.tag_database = tag_current_db();
      return 0;
   }

   // no luck finding symbol
   return BT_RECORD_NOT_FOUND_RC;
}

void tag_get_info_from_return_type(VS_TAG_RETURN_TYPE &rt,
                                   VS_TAG_BROWSE_INFO &cm) 
{
   tag_browse_info_init(cm);
   tag_tree_decompose_tag(rt.taginfo, 
                          cm.member_name, cm.class_name, 
                          cm.type_name, cm.flags, 
                          cm.arguments, cm.return_type);
   cm.file_name = rt.filename;
   cm.line_no   = rt.line_number;
   cm.qualified_name = rt.return_type;
}

int tag_get_context_inheritance(VS_TAG_BROWSE_INFO &cm, 
                                VS_TAG_RETURN_TYPE (&parents)[],
                                typeless tag_files)
{
   already_exists := false;
   status := 0;
   temp_wid := orig_wid := 0;
   if (cm.file_name!='' && !_QBinaryLoadTagsSupported(cm.file_name)) {
      status = _open_temp_view(cm.file_name, 
                               temp_wid, orig_wid,
                               '', already_exists, false, true);
      if (status) {
         parents._makeempty();
         return status;
      }
      p_RLine = cm.line_no;
      if (cm.scope_seekpos != 0) {
         _GoToROffset(cm.scope_seekpos);
      }
   } else {
      temp_wid = 0;
   }

   // make sure the 'cm' has the class inheritance information
   status = tag_get_browse_inheritance(cm);
   if (status && cm.file_name!='' && cm.class_parents=='') {
      cm.file_name='';
      cm.line_no=0;
      tag_get_browse_inheritance(cm);
   }

   // clear out the output array
   parents._makeempty();

   // convert the list of class parents to an array
   split(cm.class_parents, VS_TAGSEPARATOR_parents, auto class_parents);

   // for each parent class, parse it as a return type 
   VS_TAG_RETURN_TYPE visited:[];
   _str norm_visited:[];  norm_visited._makeempty();
   int i, n = class_parents._length();

   for (i=0; i<n; ++i) {

      if (_isEditorCtl()) {
         _str errorArgs[];
         VS_TAG_RETURN_TYPE tmp_rt;
         tag_return_type_init(tmp_rt);
         isjava := _LanguageInheritsFrom('java', cm.language) ||
                   _LanguageInheritsFrom('cs', cm.language);

         status = _Embeddedparse_return_type(errorArgs, tag_files, 
                                             cm.member_name, cm.class_name, 
                                             cm.file_name, class_parents[i], 
                                             isjava, tmp_rt, visited);
         //tag_return_type_dump(parents[i]);
         if (!status) {
            parents[i] = tmp_rt;
            continue;
         }
      }

      status = tag_normalize_classes(class_parents[i], 
                                     cm.qualified_name, 
                                     cm.file_name,
                                     tag_files, false, true, 
                                     auto normalized_parent,
                                     auto normalized_type,
                                     auto normalized_file, 
                                     norm_visited);
      if (status) {
         continue;
      }

      parents[i].return_type = normalized_parent;
      parents[i].filename = normalized_file;
      tag_split_class_name(normalized_parent, auto tag_name, auto class_name);
      parents[i].taginfo = tag_tree_compose_tag(tag_name, class_name, normalized_type);
   }

   if (temp_wid) {
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
   }

   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Customized function to get the parents of a class, fully qualified.
// This is currently our best approach to package name resolution.
// Utilizes find_class_in_tag_file() above to find the fully qualified
// class name and what tag file it belongs to.  This allows us to trace
// inheritance across multiple projects.
//
_str cb_get_normalized_inheritance(_str class_name,
                                   _str &in_tag_files,
                                   typeless &tag_files,
                                   boolean check_context=false,
                                   _str orig_parents='',
                                   _str file_name='',
                                   _str &parent_types='',
                                   boolean includeTemplateParameters=false)
{
   //say("cb_get_normalized_inheritance: orig_parents="orig_parents" class_name="class_name" file_name="file_name);
   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   tag_split_class_name(class_name, cm.member_name, cm.class_name);
   cm.qualified_name = class_name;
   cm.class_parents = orig_parents;
   cm.file_name = file_name;
   in_tag_files = '';
   parent_types = '';

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   orig_db := tag_current_db();
   VS_TAG_RETURN_TYPE parents[] = null;
   tag_get_context_inheritance(cm, parents, tag_files);
   tag_read_db(orig_db);
   if (cm.class_parents=='') {
      return '';
   }

   class_parents := '';
   int i,n = parents._length();
   for (i=0; i<n; ++i) {
      _maybe_append(class_parents, VS_TAGSEPARATOR_parents);
      _maybe_append(parent_types, VS_TAGSEPARATOR_parents);
      _maybe_append(in_tag_files, ';');
//      _maybe_append_filesep(in_tag_files);
      class_parents = class_parents :+ parents[i].return_type;
      if (includeTemplateParameters) {
         _str argName="";
         _str argTypes[];
         foreach (argName in parents[i].template_names) {
            if (parents[i].template_types != null &&
                parents[i].template_types._indexin(argName) &&
                parents[i].template_types:[argName].return_type != "") {
               argTypes[argTypes._length()] = parents[i].template_types:[argName].return_type;
            } else {
               argTypes[argTypes._length()] = parents[i].template_args:[argName];
            }
         }
         _str argList = "";
         if (argTypes._length() > 0) {
            argList = "<":+join(argTypes,","):+">";
            class_parents:+=argList;
         }
      }
      tag_tree_decompose_tag(parents[i].taginfo, 
                             auto parent_name, auto parent_class,
                             auto parent_type, auto parent_flags); 
      parent_types = parent_types :+ parent_type;
      _str parent_tagfile = find_class_in_tag_file(parent_name, parent_class, auto qual_name, false, tag_files);
      in_tag_files = in_tag_files :+ parent_tagfile;
   }

   if (class_parents != '') {
      return class_parents;
   }

   //say("cb_get_normalized_inheritance: class_name="class_name);
   boolean found_definition = false;
   if (check_context && orig_parents=='') {
      _str type_name='';
      _str inner_name='';
      _str outer_name='';
      tag_split_class_name(class_name, inner_name, outer_name);

      // check locals
      i = tag_find_local_iterator(inner_name, true, false, false, outer_name);
      while (i > 0) {
         //say("cb_get_normalized_inheritance: local");
         tag_get_detail2(VS_TAGDETAIL_local_type, i, type_name);
         if (tag_tree_type_is_class(type_name)) {
            found_definition = true;
            tag_get_detail2(VS_TAGDETAIL_local_parents, i, orig_parents);
            break;
         }
         i = tag_next_local_iterator(inner_name, i, true, false, false, outer_name);
      }

      // check context
      if (!found_definition) {
         i = tag_find_context_iterator(inner_name, true, false, false, outer_name);
         while (i > 0) {
            //say("cb_get_normalized_inheritance: context");
            tag_get_detail2(VS_TAGDETAIL_context_type, i, type_name);
            if (tag_tree_type_is_class(type_name)) {
               found_definition = true;
               tag_get_detail2(VS_TAGDETAIL_context_parents, i, orig_parents);
               break;
            }
            i = tag_next_context_iterator(inner_name, i, true, false, false, outer_name);
         }
      }
   }

   // get the list of parents from the database
   if (!found_definition && orig_parents=='') {
      tag_get_inheritance(class_name, orig_parents);
   }

   // start searching in the workspace tag file
   _str project_tag_database=project_tags_filename();
   if (project_tag_database!='') {
      tag_read_db(project_tag_database);
   }

   // this is better code
   _str normal_parents='';
   _str visited[];  visited._makeempty();

   int status=tag_normalize_classes(orig_parents,class_name,file_name,tag_files,false,true,normal_parents,parent_types,in_tag_files, visited);
   if (!status) {
      // here we go
      return normal_parents;
   }

   // for each parent
   _str new_parents='';
   _str parent='';
   in_tag_files='';
   while (orig_parents != '') {
      parse orig_parents with parent ';' orig_parents;
      if (parent != '') {

         // attempt to normalize the class name
         //say("cb_get_normalized_inheritance: parent="parent);
         _str normalized='';
         _str parent_tag_file = find_class_in_tag_file(class_name, parent, normalized, true, tag_files);
         //say("cb_get_normalized_inheritance: normal="normalized);
         if (parent_tag_file=='') {
            parent_tag_file = find_class_in_tag_file(class_name, parent, normalized, true, tag_files, true);
            if (parent_tag_file=='') {
               normalized = parent;
               parent_tag_file = tag_current_db();
            }
         }

         // append to the new parent list
         if (new_parents == '') {
            new_parents  = normalized;
            in_tag_files = parent_tag_file;
         } else {
            new_parents  = new_parents ';' normalized;
            in_tag_files = in_tag_files ';' parent_tag_file;
         }
      }
   }

   return new_parents;
}

//////////////////////////////////////////////////////////////////////////////
// Return the filename name of the n'th tag file, and vice-versa
// p_window_id must be the symbol browser tree control.
//
//static _str get_tag_file_name(int i)
//{
//   int child = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
//   while (child > 0) {
//      int sequence_number = _TreeGetUserInfo(child);
//      if (sequence_number == i) {
//         _str caption = _TreeGetCaption(child);
//         parse caption with . ':' file_name ' (' .;
//         return absolute(strip(file_name));
//      }
//      child = _TreeGetNextSiblingIndex(child);
//   }
//   return '';
//}

//////////////////////////////////////////////////////////////////////////////
// Return the sequence number of the given tag file name.  If the given
// tag file is in the list twice, it will only return the first occurance.
// p_window_id must be the symbol browser tree control.
//
static int get_tag_file_number(_str &tag_file_name)
{
   int child = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (child > 0) {
      _str caption = _TreeGetCaption(child);
      _str file_name;
      parse caption with . ':' file_name ' (' .;
      file_name = absolute(strip(file_name));
      if (file_eq(file_name, tag_file_name)) {
         return _TreeGetUserInfo(child);
      }
      child = _TreeGetNextSiblingIndex(child);
   }
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Add the members inherited from all our parent classes.
// Uses the hash table (classes_visited) to mark which
// classes we have already visited.  This is done to circumvent the
// unusual case of circular references, a potential result of
// incorrect package name resolution.  This function is recursive, but
// limited to CB_MAX_INHERITANCE_DEPTH levels of recursion, limiting
// the amount of recursion we are willing to traverse.
// p_window_id must be the symbol browser tree control.
//
static int add_class_inherited(_str class_name, int depth,
                               int &count, typeless &tag_files,
                               _str class_parents,
                               _str search_file_name,
                               boolean (&classes_visited):[]
                               )
{
   if (depth >= CB_MAX_INHERITANCE_DEPTH) {
      return 0;
   }

   // check if we have visited this class already
   if (classes_visited._indexin(class_name)) return 0;
   classes_visited:[class_name]=true;

   // get the fully qualified parents of this class
   _str orig_tag_file = tag_current_db();
   _str tag_dbs = '';
   _str parents = cb_get_normalized_inheritance(class_name, tag_dbs, tag_files, 
                                                false, class_parents, search_file_name);

   // add each of them to the list also
   _str p1,t1;
   int result = 0;
   while (parents != '') {
      parse parents with p1 ';' parents;
      parse tag_dbs with t1 ';' tag_dbs;
      int status = tag_read_db(t1);
      if (status < 0) {
         continue;
      }

      // add transitively inherited class members
      parse p1 with p1 '<' .;
      result = add_class_inherited(p1, depth+1, count, tag_files, '', '', classes_visited);

      // add the members inherited from the given class
      int tag_file_id = get_tag_file_number(t1);
      tag_tree_add_members_of(p1, '', tag_file_id, count);
   }

   // return to the original tag file and return, successful
   tag_read_db(orig_tag_file);
   return result;
}

//////////////////////////////////////////////////////////////////////////////
// If 'cm' is a prototype, attempt to locate it's corresponding definition
//
static void maybe_convert_proto_to_proc(VS_TAG_BROWSE_INFO &cm)
{
   int const_flag = (cm.flags & VS_TAGFLAG_const);
   boolean found  = false;
   VS_TAG_RETURN_TYPE visited:[];
   if ((cm.type_name:=='proto' || cm.type_name:=='procproto') &&
       !(cm.flags & (VS_TAGFLAG_native|VS_TAGFLAG_abstract))) {
      _str search_arguments  = VS_TAGSEPARATOR_args:+cm.arguments;
      _str search_class=stranslate(cm.class_name,VS_TAGSEPARATOR_class,'::');

      if (tag_find_tag(cm.member_name, 'proc', search_class, search_arguments)==0 ||
          tag_find_tag(cm.member_name, 'func', search_class, search_arguments)==0 ||
          tag_find_tag(cm.member_name, 'constr', search_class, search_arguments)==0 ||
          tag_find_tag(cm.member_name, 'destr', search_class, search_arguments)==0) {
         tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
         tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
         found=true;
      } else if (pos(VS_TAGSEPARATOR_package,search_class)) {
         search_class=substr(search_class,1,pos('S')-1):+
                       VS_TAGSEPARATOR_class:+
                       substr(search_class,pos('S')+1);
         if (tag_find_tag(cm.member_name, 'proc', search_class, search_arguments)==0 ||
             tag_find_tag(cm.member_name, 'func', search_class, search_arguments)==0 ||
             tag_find_tag(cm.member_name, 'constr', search_class, search_arguments)==0 ||
             tag_find_tag(cm.member_name, 'destr', search_class, search_arguments)==0) {
            tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
            tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
            found=true;
         }
      }
      tag_reset_find_tag();

      // find alternate matches until we locate proc with correct constness
      while (found && (cm.flags & VS_TAGFLAG_const) != const_flag &&
             !tag_next_tag(cm.member_name, cm.type_name, cm.class_name, search_arguments)) {
         tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
         tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
      }
      tag_reset_find_tag();

      /*
         Could have namespace problem.

         file1.h                                 file1.cpp
            namespace Browse {                      #include "file1.h"     
                class AE {                          using namespace Browse;
                  public:                           AE::AE() {             
                    AE();                           }                      
                    static void load();             void AE::load() {      
                  };                                }                      
               }
            }

         The case of the above files fails to find definitions because the function definition is
         void AE::load() instead of void Browse::AE::load().  Here we look for some inner stuff
      */
      if (false && !found) {
         _str match_class_name=translate(search_class,VS_TAGSEPARATOR_class,VS_TAGSEPARATOR_package);
         search_class=match_class_name;
         _str c_namespace='';

         for (;;) {
            /* 
               Look for class separator.  Don't need to look for package separator
               because this method definition was outside the scope of the namespace.
            */
            //_message_box('h1 search_class='search_class);
            int i=pos('['_escape_re_chars(VS_TAGSEPARATOR_class)']',search_class,1,'r');
            if (!i) {
               break;
            }
            if (c_namespace=='') {
               c_namespace=substr(search_class,1,i-1);
            } else {
               c_namespace=c_namespace:+VS_TAGSEPARATOR_package:+substr(search_class,1,i-1);
            }
            // Strip what could be a package name
            search_class=substr(search_class,i+1);
            if (tag_find_tag(cm.member_name, 'proc', search_class, search_arguments)==0 ||
                tag_find_tag(cm.member_name, 'func', search_class, search_arguments)==0 ||
                tag_find_tag(cm.member_name, 'constr', search_class, search_arguments)==0 ||
                tag_find_tag(cm.member_name, 'destr', search_class, search_arguments)==0) {

               _str member_name;
               _str type_name;
               _str file_name;
               int line_no;
               _str class_name;
               int flags;
               _str extension;
               tag_get_info(member_name, type_name, file_name, line_no, class_name, flags);
               tag_get_detail(VS_TAGDETAIL_language_id,extension);


               // find alternate matches until we locate proc with correct constness
               while ((flags & VS_TAGFLAG_const) != const_flag &&
                      !tag_next_tag(member_name, type_name, search_class, search_arguments)) {
                  tag_get_info(member_name, type_name, file_name, line_no, class_name, flags);
                  tag_get_detail(VS_TAGDETAIL_language_id,extension);
               }
               tag_reset_find_tag();

               //_message_box('namespace='c_namespace' search_class='search_class);
               /*
                   Now check if this file using statement with this namespace.
               */
               _str match_namespace=stranslate(c_namespace,'::',VS_TAGSEPARATOR_package);
               int status=tag_find_in_file(file_name);
               while (!status) {
                  _str member_name2;
                  _str type_name2;
                  _str file_name2;
                  int line_no2;
                  _str class_name2;
                  int flags2;
                  tag_get_info(member_name2, type_name2, file_name2, line_no2, class_name2, flags2);
                  //tag_get_detail(VS_TAGDETAIL_file_ext,extension);
                  if (type_name2=='import' && member_name2==match_namespace) {
                     //say('member_name2='member_name2);
                     //say('class_name2='class_name2);
                     //_message_box('found it');

                     cm.member_name=member_name;
                     cm.type_name=type_name;
                     cm.file_name=file_name;
                     cm.line_no=line_no;
                     cm.class_name=class_name;
                     cm.flags=flags;
                     cm.language=extension;
                     found=true;
                     break;
                  }


                  status=tag_next_in_file();
               }
            }
            tag_reset_find_tag();
            tag_reset_find_in_file();
         }
      }

      if (!found) {

         // put together list of tag files (just this tag file)
         _str tag_files[];
         tag_files._makeempty();
         tag_files[0] = cm.tag_database;

         // list of functions with this tag name in some class context
         _str errorArgs[];   errorArgs._makeempty();
         _str tag_matches[]; tag_matches._makeempty();
         _str tag_name='', type_name='', file_name='', class_name='', arguments='';
         typeless line_no=0, tag_flags=0;

         // find all matching functions and populate 'tag_matches' array
         int status = tag_find_equal(cm.member_name, true);
         while (status == 0 && tag_matches._length() < def_tag_max_function_help_protos) {
            tag_get_info(tag_name, type_name, file_name, line_no, class_name, tag_flags);
            if (tag_tree_type_is_func(type_name) && !pos("proto",type_name) && class_name!='') {
               tag_get_detail(VS_TAGDETAIL_arguments, arguments);
               if (tag_tree_compare_args(VS_TAGSEPARATOR_args:+arguments, search_arguments, true)==0) {
                  tag_matches[tag_matches._length()] = tag_name "\t" type_name "\t" file_name "\t" line_no "\t" class_name "\t" tag_flags;
               }
            }
            status = tag_next_equal(true);
         }
         tag_reset_find_tag();

         // For each match, evaluate it's class name as a return type
         // this will resolve typedefs, namespaces, namespace aliases.
         int i, n=tag_matches._length();
         for (i=0; i<n; ++i) {
            parse tag_matches[i] with tag_name "\t" type_name "\t" file_name "\t" line_no "\t" class_name "\t" tag_flags;
            VS_TAG_RETURN_TYPE rt; tag_return_type_init(rt);

            int orig_wid = p_window_id;
            int temp_view_id,orig_view_id;
            boolean inmem=false;
            status=_open_temp_view(file_name,temp_view_id,orig_view_id,'',inmem,false,true);
            if (!status) {
               // go to the specified line and evaluate the return type
               p_RLine = line_no; p_col = 1;
               int rt_status = _Embeddedparse_return_type(errorArgs, tag_files, cm.member_name,
                                                          class_name, file_name, class_name, 
                                                          false, rt, visited);

               // close the temporary view and restore the window and view id's.
               _delete_temp_view(temp_view_id);
               p_window_id=orig_view_id;
               p_window_id = orig_wid;

               // success?
               if (rt_status==0 && rt.return_type == cm.class_name) {
                  cm.type_name   = type_name;
                  cm.member_name = tag_name;
                  cm.class_name  = class_name;
                  cm.file_name   = file_name;
                  cm.line_no     = line_no;
                  cm.flags       = tag_flags;
                  found = true;
                  break;
               }

            }

            // break out of look as soon as we find a match
            if (found) {
               break;
            }
         }

         // restore the current tag database
         tag_read_db(cm.tag_database);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the symbol browser tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _ClassBrowserTimerCallback()
{
   // kill the timer
   cb_kill_timer();

   // if something is going on, get out of here
   if( _IsKeyPending() ) {
      return;
   }

   // get the symbol browser form window id
   int f = GetCBViewWid();
   if (!f) {
      return;
   }
   _nocheck _control ctl_class_tree_view;

   // get the details about the current selection
   int currIndex = f.ctl_class_tree_view._TreeCurIndex();
   if (currIndex < 0) {
      return;
   }
   int show_children=0;
   f.ctl_class_tree_view._TreeGetInfo(currIndex, show_children);
   int parentIndex = 0;
   if (currIndex > 0) {
      parentIndex = f.ctl_class_tree_view._TreeGetParentIndex(currIndex);
   }
   struct VS_TAG_BROWSE_INFO cm;
   f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false);

   // grab the window ID of the class tree view
   int orig_wid=p_window_id;
   p_window_id=f.ctl_class_tree_view;

   // if something is going on, get out of here
   if( _IsKeyPending() ) {
      return;
   }

   // set flag to know we are in refresh code
   int orig_refresh = gi_in_refresh;
   gi_in_refresh = 1;

   // refresh the property dialog if available
   f = gtbprops_wid;
   if (f) {
      int orig_window_id = p_window_id;
      cb_refresh_property_view(cm);
      p_window_id = orig_window_id;
   }

   // find the output tagwin and update it
   cb_refresh_output_tab(cm, true, true, false, APF_SYMBOLS);

   // find the output references tab and update it
   if (def_autotag_flags2 & AUTOTAG_UPDATE_CALLSREFS) {
      refresh_references_tab(cm);
   }

   // refresh the inheritance dialog if available
   if (def_autotag_flags2 & AUTOTAG_UPDATE_CALLSREFS) {
      f = gcbcalls_wid;
      if (f) {
         struct VS_TAG_BROWSE_INFO fcm = cm;
         if (cm.tag_database!='' && tag_read_db(cm.tag_database) >= 0) {
            maybe_convert_proto_to_proc(fcm);
         }
         cb_refresh_calltree_view(fcm);
      }
   }

   // refresh the inheritance dialog if available
   f = gcbparents_wid;
   if (f) {
      if (show_children == TREE_NODE_LEAF) {
         get_user_tag_info(parentIndex, cm, false);
      }
      f.refresh_inheritance_view(cm);
   }

   // restore the window ID
   gi_in_refresh = orig_refresh;
   p_window_id=orig_wid;
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the symbol browser tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _ClassBrowserHighlightCallback(int index)
{
   // kill the timer
   cb_kill_timer();

   // if something is going on, get out of here
   if( _IsKeyPending() ) {
      return;
   }

   // get the symbol browser form window id
   int f = GetCBViewWid();
   if (!f) {
      return;
   }
   _nocheck _control ctl_class_tree_view;

   // get the details about the current selection
   int currIndex = index;
   if (currIndex < 0) {
      return;
   }

   int show_children=0;
   f.ctl_class_tree_view._TreeGetInfo(currIndex, show_children);
   int parentIndex = 0;
   if (currIndex > 0) {
      parentIndex = f.ctl_class_tree_view._TreeGetParentIndex(currIndex);
   }
   struct VS_TAG_BROWSE_INFO cm;
   f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false);

   // now update the preview window only
   _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
}

//////////////////////////////////////////////////////////////////////////////
// Handle double-click event (mapped to goto-proc), unless the tree depth
// is less than or equal to two, in which case we simply call expand/collapse
//
void ctl_class_tree_view.enter,lbutton_double_click()
{
   // Is there a on_change timer event queued, then cancel it
   cb_kill_timer();
   // IF this is an item we can go to like a class name
   int i = _TreeCurIndex();
   int d = (i<0)? 0:_TreeGetDepth(i);
   if (d > 2) {
      cb_goto_proc();
   } else if (i>=0) {
      int show_children=0;
      _TreeGetInfo(i,show_children);
      if (show_children == TREE_NODE_LEAF) {
         call_event(CHANGE_LEAF_ENTER,i,p_window_id,ON_CHANGE,'w');
      } else {
         call_event(show_children?CHANGE_COLLAPSED:CHANGE_EXPANDED,i,p_window_id,ON_CHANGE,'w');
         _TreeSetInfo(i,(int)!show_children);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Add the given category to the tree under its project index (j).
// If there are no global items appropriate for the category, do not
// add the category to the tree.  This function looks for any global with
// a type of either t1, t2, t3, or t4 where the mask evaluates to either
// zero or nzero, as requested.  Categories are inserted with a sequence
// number which they are sorted by.
// p_window_id must be the symbol browser tree control.
//
static void maybe_add_category(int j, _str category, CB_TAG_CATEGORY &ctg, int count)
{
   // change "includes/copy book" to just includes
   if (category :== CB_includesCB || category :== CB_includes) {
      int license1=_default_option(VSOPTION_PACKFLAGS1);
      if (!(license1&VSPACKFLAG1_COB) && !(license1&VSPACKFLAG1_ASM)) {
         if (category:==CB_includesCB) {
            return;
         }
      } else {
         if (category:==CB_includes) {
            return;
         }
      }
   }

   // miscellaneous is special
   int status;
   int tag_flags;
   _str type_name;
   _str cn;
   if (category :== CB_misc) {
      // try to find the item
      status=tag_find_global(-1, ctg.flag_mask, (ctg.mask_nzero? 1:0));
      while (!status) {
         tag_get_detail(VS_TAGDETAIL_flags, tag_flags);
         tag_get_detail(VS_TAGDETAIL_type,  type_name);
         cn = type_to_category(type_name, tag_flags, 0);
         if (cn :== CB_misc) {
            j = _TreeAddItem(j, category, TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open, TREE_NODE_COLLAPSED, 0, ctg.sequence_number);
            tag_reset_find_in_class();
            return;
         }
         status=tag_next_global(-1, ctg.flag_mask, (ctg.mask_nzero? 1:0));
      }
      tag_reset_find_in_class();
      return;
   }

   int i;
   for (i=0; i<ctg.tag_types._length(); i++) {
      // get the tag type, has to be either a string or an int
      int t1 = ctg.tag_types[i];
      if (t1._varformat() == VF_LSTR) {
         if (!isinteger(t1)) {
            t1 = tag_get_type_id(t1);
            if (t1 < 0) {
               continue;
            }
         }
      } else if (!VF_IS_INT(t1)) {
         continue;
      }

      // try to find the item
      status=tag_find_global(t1, ctg.flag_mask, (ctg.mask_nzero? 1:0));
      if (status==0) {
         j = _TreeAddItem(j, category, TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open, TREE_NODE_COLLAPSED, 0, ctg.sequence_number);
         tag_reset_find_in_class();
         return;
      }
   }
   tag_reset_find_in_class();
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
// Add all members in the global scope with the given type (t1), matching
// the mask as either zero or nzero, as specified.  This function will not
// insert more that CB_NOAHS_WATER_MARK items under a single category.
// During a refresh, it will stop inserting items after CB_LOW_WATER_MARK
// items are inserted.  During a user expand/collapse, it will stop inserting
// items after CB_HIGH_WATER_MARK items are inserted and prompt the user
// If the user does not cancel, it will continue inserting until it reaches
// CB_FLOOD_WATER_MARK items and every subsequent CB_FLOOD_WATER_MARK items.
// p_window_id must be the symbol browser tree control.
//
static void add_members_in_category(int j, _str ctg_name, CB_TAG_CATEGORY &ctg, _str letter, int &count)
{
   // Miscellaneous category is a very special case
   int status;
   _str cn,caption;
   _str tag_name,type_name,file_name,class_name;
   int line_no,tag_flags,file_id;
   int i,pic_member;
   if (ctg_name :== CB_misc) {
      status=tag_find_global(-1, ctg.flag_mask, (ctg.mask_nzero? 1:0));
      while (!status) {
         tag_get_info(tag_name, type_name, file_name, line_no, class_name, tag_flags);
         cn = type_to_category(type_name, tag_flags, 0);
         if (cn :== CB_misc) {
            int i_type, i_access;
            status = tag_tree_filter_member2(0xffffffff, 0xffffffff, type_name, ((class_name!='')? 1:0), tag_flags, i_access, i_type);
            if (status) {
               int ucm;
               tag_get_detail(VS_TAGDETAIL_file_id, file_id);
               ucm = (file_id * CB_MAX_LINE_NUMBER) + line_no;
               caption = tag_tree_make_caption_fast(VS_TAGMATCH_tag,0,true,true,true);
               pic_member = gi_pic_access_type[i_access][CB_type_miscellaneous];
               if (_TreeAddItem(j,caption,TREE_ADD_AS_CHILD,pic_member,pic_member,TREE_NODE_LEAF,0,ucm) < 0) {
                  break;
               }
            }
         }
         status=tag_next_global(-1, ctg.flag_mask, (ctg.mask_nzero? 1:0));
      }
      tag_reset_find_in_class();
      return;
   }

   for (i=0; i<ctg.tag_types._length(); i++) {
      // get the tag type, has to be either a string or an int
      int t1 = ctg.tag_types[i];
      if (t1._varformat()==VF_LSTR) {
         if (!isinteger(t1)) {
            t1 = tag_get_type_id(t1);
            if (t1 < 0) {
               continue;
            }
         }
      } else if (!VF_IS_INT(t1)) {
         continue;
      }

      // add all items with this type to the category
      int in_count = count;
      if (letter=='') {
         status = tag_tree_add_members_in_category(t1, ctg.flag_mask, (ctg.mask_nzero? 1:0), ctg_name, in_count);
         count = in_count;
         //say("count = "in_count);
         if (status < 0) {
            _TreeSetCaption(j, ctg_name CB_delimiter CB_partial);
         } else if (status > 0) {
            // indicates that category was divided
            return;
         }
      } else {
         status = tag_tree_add_members_in_section(letter, t1, ctg.flag_mask, (ctg.mask_nzero? 1:0), ctg_name, in_count);
         //say("count = "in_count);
         count = in_count;
         if (status < 0) {
            _TreeSetCaption(j, letter ': ' ctg_name CB_delimiter CB_partial);
         }
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// pop up a message box warning that a huge number of items are about
// to be inserted into the symbol browser tree, giving the user the
// oportunity to terminate the operation.
//
int cb_warn_overflow(int t, int j, _str ctg_name, int count)
{
   int orig_autotag_flags = def_autotag_flags2;
   def_autotag_flags2=0;
   int status = _message_box(nls("Expanding a large number (%s) of items under '%s'.  Continue?", count, ctg_name), '', MB_YESNOCANCEL|MB_ICONQUESTION);
   def_autotag_flags2 = orig_autotag_flags;
   if (status!=IDYES) {
      count = CB_NOAHS_WATER_MARK;
      t._TreeSetCaption(j, ctg_name CB_delimiter CB_partial);
   }
   return count;
}

//////////////////////////////////////////////////////////////////////////////
// pop up a message box warning that we were unable to load the
// given DLL.  This is used in the BSC code, through a call to _post_call
// when we are unable for some reason to load msbsc50.dll.
//
void cb_warn_no_bsc(_str dll_name)
{
   int orig_autotag_flags = def_autotag_flags2;
   def_autotag_flags2=0;
   _message_box(nls("Unable to load Visual C++ 5.0 Browser DLL: %s",dll_name));
   def_autotag_flags2 = orig_autotag_flags;
}

//////////////////////////////////////////////////////////////////////////////
// pop up a message box warning that a huge number of items are about
// to be inserted into the symbol browser tree, giving the user the
// oportunity to terminate the operation.
//
int cb_divide_category(int t, int j, int type_id, int mask, int nzero, _str ctg_name)
{
   CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(ctg_name);
   if (ctg && ctg->level3_inheritance) {
      return -1;
   }

   // if we plan to remove duplicates, just do it,
   // but don't create categories
   if (ctg && ctg->remove_duplicates) {
      t._TreeSortCaption(j,'U');
      int num_items = _TreeGetNumChildren(j);
      if (num_items < def_cbrowser_low_refresh/2) {
         return num_items;
      }
   }

   // letters to add, include '$' and '_' if there are tags like that
   _str alphabet = "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z [Misc]";
   if (tag_find_prefix("$") == 0) {
      alphabet = '$ ' alphabet;
   }
   if (tag_find_prefix("_") == 0) {
      alphabet = '_ ' alphabet;
   }
   tag_reset_find_tag();

   // add the letters of the alphabet and 'misc'
   t._TreeDelete(j, 'C');
   t._TreeSetUserInfo(j, 0);
   while (alphabet != '') {
      _str letter;
      parse alphabet with letter alphabet;
      t._TreeAddItem(j, letter ': ' ctg_name, TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open, TREE_NODE_COLLAPSED);
   }

   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Remove duplicate items under the given tree index (j).
// Assume that the items under 'f' have already been sorted by caption.
// p_window_id must be the symbol browser tree control.
//
//static void remove_duplicates_under(int f, int j)
//{
//   k = _TreeGetFirstChildIndex(j);
//   if (k > 0) {
//      kcap = _TreeGetCaption(k);
//      parse kcap with kcap CB_delimiter rest;
//      while (k > 0) {
//         m = _TreeGetNextSiblingIndex(k);
//         if (m > 0) {
//            mcap = _TreeGetCaption(m);
//            parse mcap with mcap CB_delimiter .;
//            if (kcap :== mcap) {
//               _TreeGetInfo(m, mshow);
//               if (mshow > 0) {
//                  _TreeDelete(k);
//               } else {
//                  _TreeDelete(m);
//                  m=k;
//               }
//            } else {
//               //messageNwait("retaining: "kcap);
//               kcap = mcap;
//            }
//         }
//         k=m;
//      }
//   }
//}

//////////////////////////////////////////////////////////////////////////////
// Possibly the most important function for the entire symbol browser.
// This function handles the on_change event for the symbol browser tree
// control.  What is done depends on the tree depth, current index, and
// the specific event, which includes the following:
//    CHANGE_EXPANDED:
//          0  -- refresh list of tag files
//          1  -- refresh set of categories for a tag file
//          2  -- refresh set of globals for a category
//          3+ -- refresh set of members in a class (container)
//    CHANGE_COLLAPSED:
//          0  -- should never happen
//          1  -- do nothing
//          2  -- trim "...PARTIAL LIST" off of categories
//          3+ -- do nothing
//    CHANGE_SELECTED:
//          3+ -- start timer for refreshing other views
//    CHANGE_LEAF_ENTER:
//          3+ -- goto definition for the selected item
//
void ctl_class_tree_view.on_change(int reason,int index)
{
   // context index for the selected item
   //say("ctl_class_tree_view.on_change: reason="reason" index="index);
   struct VS_TAG_BROWSE_INFO cm;
   int count,status;
   _str caption,full_caption,rest;

   // grab our window ID, this shouldn't be necessary
   int f = GetCBViewWid();
   if (!f) return;
   // blow out of here if index is invalid
   if (index < 0) {
      return;
   }

   // scrolling through list, kill the existing timer and start a new one
   if (reason == CHANGE_SELECTED) {
      cb_kill_timer();
      cb_start_timer(_ClassBrowserTimerCallback);
      f.ctl_class_tree_view._TreeRefresh();

   } else if (reason == CHANGE_EXPANDED) {
      int orig_wid = p_window_id;
      p_window_id = f.ctl_class_tree_view;
      
      // handled change_expanded event, show hour glass and prepare list
      se.util.MousePointerGuard hour_glass;
      int d = _TreeGetDepth(index);

      // root level, list of tag files
      if (d == 0) {

         refresh_tagfiles();

      } else if (d == 1) {  // list of categories in a project

         // get tag details
         _TreeBeginUpdate(index, CB_delimiter);
         get_user_tag_info(index, cm, true);

         /**
          * For Eclipse, we want to make sure that the JDK tag file 
          * associated with the Project is the appropriate version. 
          *  
          * Calling _eclipse_update_tag_list here will take care of 
          * everything for us. 
          */
         if (isEclipsePlugin()) {
            eclipse_proj_name := _strip_filename(cm.tag_database, 'PE');
            _eclipse_update_tag_list(eclipse_proj_name);
         }

         // open the tag database for business
         status = tag_read_db(cm.tag_database);
         if ( status < 0 ) {
            if ( status==NEW_FILE_RC || status==FILE_NOT_FOUND_RC) {
               _message_box(nls("Tag file '%s' not found.\n\nIf you have tag files which were created before version 3.0 you need to rebuild them.",cm.tag_database));
            } else {
               _message_box(nls("Error reading tag file '%s'",cm.tag_database)". "get_message(status));
            }
            p_window_id = orig_wid;
            return;
         }

         count=1;
         typeless ctg_name;
         CB_TAG_CATEGORY ctg;
         for (ctg_name._makeempty();;) {
            gh_cb_categories._nextel(ctg_name);
            if (ctg_name._isempty()) break;
            if (ctg_name._varformat() == VF_LSTR) {
               ctg = gh_cb_categories._el(ctg_name);
               maybe_add_category(index, ctg_name, ctg, ++count);
            }
         }
         // p_window_id = f;
         //cb_remove_stale_items(index);
         _TreeEndUpdate(index);
         _TreeSortUserInfo(index, 'N');

      } else if (d == 2 || (d == 3 && f.ctl_class_tree_view._TreeGetUserInfo(index) == '')) {
         // list of globals in a category

         _TreeBeginUpdate(index, CB_delimiter);
         full_caption = _TreeGetCaption(index);
         _str letter = '';
         if (d == 3) {
            parse full_caption with letter ':' .;
         }
         parse full_caption with caption CB_delimiter .;
         if (full_caption :!= caption) {
            _TreeSetCaption(index, caption);
         }

         // get filtration mask
         int show_mask1, show_mask2;
         if (f.ctl_filter_check_box.p_value) {
            show_mask1 = CB_QUALIFIERS;
            show_mask2 = CB_QUALIFIERS2;
         } else {
            show_mask1 = f.ctl_class_tree_view.p_user;
            show_mask2 = f.ctl_filter_check_box.p_user;
         }
         // get tag details
         get_user_tag_info(index, cm, true);

         // open the database for business
         status = tag_read_db(cm.tag_database);
         if ( status < 0 ) {
            return;
         }

         gz_class_filter  = f.ctl_class_filter_combo_box.cb_get_filter();
         gz_member_filter = f.ctl_member_filter_combo_box.cb_get_filter();

         count = 0;
         tag_tree_prepare_expand(f, index, p_window_id, gi_in_refresh, gz_class_filter, gz_member_filter, gz_exception_name, show_mask1, gi_pic_access_type, show_mask2);

         CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(cm.category);
         if (ctg) {
            add_members_in_category(index, cm.category, *ctg, letter, count);
         }

         _TreeEndUpdate(index);
         if (ctg && ctg->remove_duplicates) {
            _TreeSortCaption(index,'U');
            //remove_duplicates_under(gtbcbrowser_wid, index);
         }
         _TreeSortCaption(index,'I','N');

         // remove duplicates if there are "EMPTY" or "PARTIAL" items
         if (ctg && ctg->remove_duplicates) {
            _str one_caption='', dup_caption='';
            int dup_index = 0;
            int one_index = _TreeGetFirstChildIndex(index);
            if (one_index > 0) {
               one_caption = _TreeGetCaption(one_index);
               for (;;) {
                  dup_index = _TreeGetNextSiblingIndex(one_index);
                  if (dup_index <= 0) {
                     break;
                  }
                  dup_caption = _TreeGetCaption(dup_index);
                  parse dup_caption with dup_caption CB_delimiter .;
                  if (one_caption == dup_caption) {
                     _TreeDelete(one_index);
                  }
                  one_caption = dup_caption;
                  one_index   = dup_index;
               }
            }
         }

      } else { // list of members of a class/container

         _TreeBeginUpdate(index, CB_delimiter);
         full_caption = _TreeGetCaption(index);
         parse full_caption with caption CB_delimiter .;
         if (full_caption :!= caption) {
            _TreeSetCaption(index, caption);
         }

         // get tag details
         get_user_tag_info(index, cm, false);
         //say("ctl_class_tree_view.on_change: cat="cm.category" cn="cm.class_name" file="cm.file_name" name="cm.member_name" qual="cm.qualified_name" db="cm.tag_database);

         // open the database for business
         status = tag_read_db(cm.tag_database);
         if ( status < 0 ) {
            return;
         }
         _str search_file_name = cm.file_name;
         if (cm.flags & VS_TAGFLAG_partial) {
            search_file_name = '';
         }

         // expanding a package
         boolean remove_duplicates = false;
         if (d == 3 && cm.category :== CB_packages) {
            search_file_name = '';
            remove_duplicates=true;
         } else if (d == 4 && cm.category :== CB_packages &&
                    f.ctl_class_tree_view._TreeGetUserInfo(_TreeGetParentIndex(index)) == '') {
            search_file_name = '';
            d=(d-1);
            remove_duplicates=true;
         } else if (tag_tree_type_is_package(cm.type_name)) {
            search_file_name = '';
            d=3;
            remove_duplicates=true;
         }

         // Check for partial class, remove duplicates under it
         if (tag_tree_type_is_class(cm.type_name) && (cm.flags & VS_TAGFLAG_partial)) {
            search_file_name = '';
            remove_duplicates=true;
         }

         // inheritance make sense at this level
         boolean has_inherited_members=false;
         if ((d==3 && gh_cb_categories:[cm.category].level3_inheritance) ||
             (d==4 && gh_cb_categories:[cm.category].level4_inheritance) || (d >= 5)) {
            has_inherited_members=true;
         }

         // grab bit flags and filtering options
         int show_mask1, show_mask2;
         if (f.ctl_filter_check_box.p_value) {
            show_mask1 = CB_QUALIFIERS;
            show_mask2 = CB_QUALIFIERS2;
         } else {
            show_mask1 = f.ctl_class_tree_view.p_user;
            show_mask2 = f.ctl_filter_check_box.p_user;
         }
         gz_class_filter  = f.ctl_class_filter_combo_box.cb_get_filter();
         gz_member_filter = f.ctl_member_filter_combo_box.cb_get_filter();

         count=0;
         tag_tree_prepare_expand(f, index, p_window_id, gi_in_refresh, gz_class_filter, gz_member_filter, gz_exception_name, show_mask1, gi_pic_access_type, show_mask2);

         // get the inherited class members
         if ((show_mask1 & CB_SHOW_inherited_members) && has_inherited_members) {
            _str lang = _Filename2LangId(cm.file_name);
            typeless tag_files = tags_filenamea(lang);
            int k=add_class_inherited(cm.qualified_name, 0, count, tag_files, 
                                      cm.class_parents, search_file_name, 
                                      auto classes_visited);
         }

         // get the class methods
         if ((show_mask1 & CB_SHOW_class_members) || !has_inherited_members) {
            // get user info indicating tag file name for our parent
            // this takes care of the case that we are inserting children
            // of a structure that was inherited from a different tag file
            int tag_file_id = 0;
            typeless v = _TreeGetUserInfo(index);
            if (v._varformat()==VF_LSTR && isinteger(v)) {
               tag_file_id = (v intdiv (CB_MAX_LINE_NUMBER*CB_MAX_FILE_NUMBER));
            }

            // insert all the tags for this class, applying filtering
            int orig_count=count;
            status = tag_tree_add_members_of(cm.qualified_name, search_file_name, tag_file_id, count);

            // Look for items in slightly altered class name (package vs class separator)
            _str qname = cm.qualified_name;
            while ((status || count==orig_count) && pos(VS_TAGSEPARATOR_package, qname)) {
               int lp = lastpos(VS_TAGSEPARATOR_package, qname);
               qname = substr(qname,1,lp-1):+VS_TAGSEPARATOR_class:+substr(qname,lp+1);
               status = tag_tree_add_members_of(qname, '', tag_file_id, count);
            }

            //say("tag_tree_add_members_of("cm.qualified_name","search_file_name")="status);
            if (status < 0) {
               caption = _TreeGetCaption(index);
               _str rpart;
               parse caption with rpart "\t" rest;
               _TreeSetCaption(index, rpart CB_delimiter CB_partial "\t" rest);
            }
         }

         // remove the unneeded items
         //cb_remove_stale_items(index);
         _TreeEndUpdate(index);
         _str P=(gi_sort_float_to_top)? "P":"";
         if (gi_sort_by_line && search_file_name!='') {
            _TreeSortUserInfo(index,'N'P, 'I');
         } else {
            _TreeSortCaption(index,'I'P,'N');
         }

         // remove duplicates if we are expanding a nested package or namespace
         if (remove_duplicates) {
            _str one_caption='', dup_caption='';
            int dup_index = 0;
            int one_index = _TreeGetFirstChildIndex(index);
            if (one_index > 0) {
               one_caption = _TreeGetCaption(one_index);
               for (;;) {
                  dup_index = _TreeGetNextSiblingIndex(one_index);
                  if (dup_index <= 0) {
                     break;
                  }
                  dup_caption = _TreeGetCaption(dup_index);
                  parse dup_caption with dup_caption CB_delimiter .;
                  if (one_caption == dup_caption) {
                     if (_TreeGetNumChildren(dup_index) == 0) {
                        _TreeDelete(dup_index);
                        continue;
                     }
                     _TreeDelete(one_index);
                  }
                  one_caption = dup_caption;
                  one_index   = dup_index;
               }
            }
         }
      }

      // if after expanding, the item is still empty, then add ...EMPTY to the caption
      // otherwise remove ...EMPTY if present.
      if (d >= 2) {
         caption = _TreeGetCaption(index);
         int child = _TreeGetFirstChildIndex(index);
         if (child <= 0) {
            if (!pos(CB_delimiter:+CB_empty, caption)) {
               parse caption with caption "\t" rest;
               parse caption with caption CB_delimiter . ;
               caption = caption :+ CB_delimiter :+ CB_empty;
               if (rest != '') {
                  caption = caption :+ "\t" rest;
               }
               _TreeSetCaption(index, caption);
            }
         } else if (pos(CB_delimiter:+CB_empty, caption)) {
            parse caption with caption "\t" rest ;
            parse caption with caption CB_delimiter . ;
            if (rest != '') {
               caption = caption :+ "\t" rest;
            }
            _TreeSetCaption(index, caption);
         }
      }

      _TreeSizeColumnToContents(0);
      p_window_id = orig_wid;

      //_message_box("number of items = "_TreeGetNumChildren(index));

   } else if (reason == CHANGE_COLLAPSED) {

      se.util.MousePointerGuard hour_glass;
      int orig_wid = p_window_id;
      p_window_id = f.ctl_class_tree_view;

      // remove the "PARTIAL LIST" from category captions on collapsation
      int d = _TreeGetDepth(index);
      full_caption = _TreeGetCaption(index);
      parse full_caption with caption "\t" rest;
      parse caption      with caption CB_delimiter .;
      if (rest!='') {
         caption = caption"\t"rest;
      }
      if (full_caption :!= caption) {
         _TreeSetCaption(index, caption);
      }
      // remove all leaves under this node
      _TreeDelete(index, 'L');
      p_window_id = orig_wid;

   } else if (reason == CHANGE_LEAF_ENTER) {
      // look up this item and then display in buffer
      f.ctl_class_tree_view.get_user_tag_info(index, cm, false);
      if (push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no)) {
         return;
      }
   }
}

void ctl_class_tree_view.on_highlight(int index, _str caption="")
{
   //say("ctl_class_tree_view.on_highlight: index="index" caption="caption);
   cb_kill_timer();
   if (index < 0 || !def_tag_hover_preview) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   cb_start_timer(_ClassBrowserHighlightCallback, index, def_tag_hover_delay);
}

//////////////////////////////////////////////////////////////////////////////
// set up for an expand operation (external entry point)
//
void cb_prepare_expand(int formWID, int treeWID, int index)
{
   tag_tree_prepare_expand(formWID, index, treeWID, 0, '', '', '', 0, gi_pic_access_type,CB_QUALIFIERS2);
}

//////////////////////////////////////////////////////////////////////////////
// Update other views when viewer gets focus, important because
// inheritance view, call tree, and props can also update the output
// view, so if they return focus to the symbol browser, we need to
// restart the update timer.
//
void _tbcbrowser_form.on_got_focus()
{
   int old_wid;
   if (isEclipsePlugin()) {
      int classesOutputContainer = GetCBViewWid();
      if(!classesOutputContainer) return;
      old_wid = p_window_id;
      p_window_id = classesOutputContainer;
   }
   // refresh tag files
   if (gi_need_refresh) {
      int orig_refresh = gi_in_refresh;
      gi_in_refresh = 1;
      ctl_class_tree_view.refresh_tagfiles();
      ctl_class_tree_view.refresh_dialog_views();
      gi_in_refresh = orig_refresh;
   }

   // kill the existing timer and start a new one
   cb_kill_timer();
   cb_start_timer(_ClassBrowserTimerCallback);
   if (isEclipsePlugin()) {
      p_window_id = old_wid;
   }
}

void _tbcbrowser_form.on_change(int reason)
{
   if (gi_need_refresh && reason == CHANGE_AUTO_SHOW) {
      int orig_refresh = gi_in_refresh;
      gi_in_refresh = 1;
      ctl_class_tree_view.refresh_tagfiles();
      ctl_class_tree_view.refresh_dialog_views();
      gi_in_refresh = orig_refresh;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle spacebar press in class tree.  This is intended to goto the
// exact item at the current index.
//
void ctl_class_tree_view.' '()
{
   int orig_window_id = p_window_id;
   int k = ctl_class_tree_view._TreeCurIndex();
   struct VS_TAG_BROWSE_INFO cm;
   if (ctl_class_tree_view.get_user_tag_info(k, cm, false)) {
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   }
   p_window_id = orig_window_id;
   ctl_class_tree_view._set_focus();
}

//////////////////////////////////////////////////////////////////////////////
// Push a bookmark and open the given file and position the cursor on the
// given line/column
//
int push_pos_in_file(_str file_name, int line_no, int col_no)
{
   // no MDI children?
   int mark = -1;
   if (!_no_child_windows()) {
      // get a bookmark
      mark=_alloc_selection('b');
      if ( mark<0 ) {
         return(mark);
      }
      _mdi.p_child._select_char(mark);
      _mdi.p_child.mark_already_open_destinations();
   }

   // try to open the file
   int status = edit(maybe_quote_filename(file_name),EDIT_DEFAULT_FLAGS);
   if (status) {
      if (mark >= 0) {
         _free_selection(mark);
      }
      return(status);
   }

   // jump to the line
   goto_line(line_no);
   goto_col(0);

   // make sure the line is not hidden
   if (_lineflags() & HIDDEN_LF) {
      expand_line_level();
   }

   // push the bookmark
   if (mark >= 0) {
      _mdi.p_child.push_destination();
      _mdi.p_child.push_bookmark(mark);
   }
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Push a bookmark and delegate to _cb_goto_tag_in_file() to open the given
// file and position the cursor on the given proc/class/type as near to
// the given line number as possible.
//
int push_tag_in_file(_str proc_name, _str file_name, _str class_name, _str type_name, int line_no)
{
   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(file_name)) {
      _message_box(nls('Can not locate source code for %s.',file_name));
      return(1);
   }

   // no MDI children?
   int status=0;
   if (_no_child_windows()) {
      status = _cb_goto_tag_in_file(proc_name, file_name, class_name, type_name, line_no);
      if (!status && (_mdi.p_child._lineflags() & HIDDEN_LF)) {
         _mdi.p_child.expand_line_level();
      }
      return status;
   }

   // get a bookmark
   _mdi.p_child.mark_already_open_destinations();
   int mark=_alloc_selection('b');
   if ( mark<0 ) {
      return(mark);
   }
   _mdi.p_child._select_char(mark);

   // try to open the file
   status=_cb_goto_tag_in_file(proc_name, file_name, class_name, type_name, line_no);
   if (status) {
      _free_selection(mark);
      return status;
   }

   // make sure the line is not hidden
   if (_mdi.p_child._lineflags() & HIDDEN_LF) {
      _mdi.p_child.expand_line_level();
   }

   // push the bookmark
   _mdi.p_child.push_destination();
   return(_mdi.p_child.push_bookmark(mark));
}

//////////////////////////////////////////////////////////////////////////////
// Using up-to-date context info, find the nearest matching tag with the
// given class name and type name as close as possible to the given line
// number.  If no such match is found, relax the search to just the given
// proc_name.  If that match is not found, alert the user that the tag
// was not found.
//
int _cb_goto_tag_in_file(_str proc_name, _str file_name, _str class_name, _str type_name, int line_no,boolean file_already_active=false)
{
   //say("_cb_goto_tag_in_file: proc="proc_name" file="file_name);
   // Note that the [ext]_proc_search code in cparse and dparse always
   // goes to column one for non proc type identifiers.
   int closed_col=1;
   int closest_line_no = CB_MAX_LINE_NUMBER;

   // watch out for non-existent file name
   if (file_name == '') {
      return(FILE_NOT_FOUND_RC);
   }

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(file_name)) {
      message(nls('Can not locate source code for %s.',file_name));
      return(1);
   }
   if (!file_already_active) {
      // try to open the file
      int status = edit(maybe_quote_filename(file_name),EDIT_DEFAULT_FLAGS);
      if (status) {
         return status;
      }
   }

   // check if tagging is even supported for this file
   if (! _istagging_supported(p_LangId) ) {
      // Be lazy and don't close edited buffer
      message(nls("No tagging support function for extension '%s'",p_LangId));
      return(1);
   }

   // update the current context and locals for this file
   save_pos(auto p);
   _UpdateContext(true);
   _UpdateLocals(true,true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   
   int context_id = tag_current_context();
   case_sensitive := p_EmbeddedCaseSensitive;

   // see if it is found in locals
   boolean local_found = false;
   int i,i_class_name,i_type_name,i_line_no,i_seekpos;
   int closest_col=1;
   if (context_id>0) {
      i = tag_find_local_iterator(proc_name, true, case_sensitive);
      while (i > 0) {
         // get class and type for checking
         tag_get_detail2(VS_TAGDETAIL_local_class, i, i_class_name);
         tag_get_detail2(VS_TAGDETAIL_local_type,  i, i_type_name);
         if ((type_name =='' || type_name ==i_type_name) &&
             (class_name=='' || class_name==i_class_name)) {
            // get line number and seekpos
            tag_get_detail2(VS_TAGDETAIL_local_start_linenum, i, i_line_no);
            tag_get_detail2(VS_TAGDETAIL_local_start_seekpos, i, i_seekpos);

            p_RLine=i_line_no;
            _GoToROffset(i_seekpos);
            if (abs(p_RLine-line_no) < abs(closest_line_no-line_no)) {
               closest_line_no = p_RLine;
               closest_col=p_col;
            }
            if (p_RLine == line_no) {
               if (!p_IsTempEditor) {
                  if (_lineflags() & HIDDEN_LF) expand_line_level();
                  center_line();
               }
               return(0);  // got it.
            }
         }
         i = tag_next_local_iterator(proc_name, i, true, case_sensitive);
      }
   }

   // see if it is found in context
   i = tag_find_context_iterator(proc_name, true, case_sensitive);
   while (i > 0) {
      // get class and type for checking
      tag_get_detail2(VS_TAGDETAIL_context_class, i, i_class_name);
      tag_get_detail2(VS_TAGDETAIL_context_type,  i, i_type_name);
      if ((type_name =='' || type_name ==i_type_name) &&
          (class_name=='' || class_name==i_class_name)) {
         // get line number and seekpos
         tag_get_detail2(VS_TAGDETAIL_context_start_linenum, i, i_line_no);
         tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, i, i_seekpos);

         p_RLine=i_line_no;
         _GoToROffset(i_seekpos);
         if (abs(p_RLine-line_no) < abs(closest_line_no-line_no)) {
            closest_line_no = p_RLine;
            closest_col=p_col;
         }
         if (p_RLine == line_no) {
            if (!p_IsTempEditor) {
               if (_lineflags() & HIDDEN_LF) expand_line_level();
               center_line();
            }
            return(0);  // got it.
         }
      }
      i = tag_next_context_iterator(proc_name, i, true, case_sensitive);
   }
   // special case for cobol copy books (.cpy)
   if (type_name=='include' && line_no==1 &&
       closest_line_no==CB_MAX_LINE_NUMBER) {
      closest_line_no=1;
   }

   if (closest_line_no == CB_MAX_LINE_NUMBER) {
      _str long_msg='.";//  'nls('You may want to rebuild the tag file.');
      _message_box(nls("Tag '%s' not found",proc_name)long_msg);
      restore_pos(p);
      return(1);
   }

   restore_pos(p);
   p_col=closest_col;
   goto_line(closest_line_no);
   if (!p_IsTempEditor) {
      if (_lineflags() & HIDDEN_LF) expand_line_level();
      center_line();
   }
   return(0);
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// handlers for symbol browser options form
//
defeventtab _cboptions_form;

//////////////////////////////////////////////////////////////////////////////
// Set p_value for the given check box (as current object) depending on
// the settings of the given big masks.
//
static void set_filter_check_box(int show_mask, int on_bit, int off_bit)
{
   if (show_mask & on_bit) {
      p_value = (show_mask & off_bit)? 2/*don't care*/ : 1/*on*/;
   } else {
      p_value = 0/*off*/;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the symbol browser options view.  Retrieve stored symbol browser
// options and set the controls in the symbol browser options dialog to
// correspond with current operating parameters.
//
static void refresh_filter_options(int show_mask1, int show_mask2)
{
   // bits in first SHOW mask
   ctl_show_static_data.set_filter_check_box(show_mask1, CB_SHOW_class_data, CB_SHOW_instance_data);
   ctl_show_data_members.set_filter_check_box(show_mask1, CB_SHOW_data_members, CB_SHOW_other_members);
   ctl_show_inline.set_filter_check_box(show_mask1, CB_SHOW_inline, CB_SHOW_out_of_line);
   ctl_show_static.set_filter_check_box(show_mask1, CB_SHOW_static, CB_SHOW_non_virtual);
   ctl_show_virtual.set_filter_check_box(show_mask1, CB_SHOW_virtual, CB_SHOW_non_virtual);
   ctl_show_abstract.set_filter_check_box(show_mask1, CB_SHOW_abstract, CB_SHOW_non_abstract);
   ctl_show_operators.set_filter_check_box(show_mask1, CB_SHOW_operators, CB_SHOW_non_special);
   ctl_show_constructors.set_filter_check_box(show_mask1, CB_SHOW_constructors, CB_SHOW_non_special);
   ctl_show_final_members.set_filter_check_box(show_mask1, CB_SHOW_final_members, CB_SHOW_non_final_members);
   ctl_show_const_members.set_filter_check_box(show_mask1, CB_SHOW_const_members, CB_SHOW_non_const_members);
   ctl_show_volatile_members.set_filter_check_box(show_mask1, CB_SHOW_volatile_members, CB_SHOW_non_volatile_members);
   ctl_show_transient_members.set_filter_check_box(show_mask1, CB_SHOW_transient_data, CB_SHOW_persistent_data);
   ctl_show_synchronized_members.set_filter_check_box(show_mask1, CB_SHOW_synchronized, CB_SHOW_non_synchronized);
   ctl_show_template_classes.set_filter_check_box(show_mask1, CB_SHOW_template_classes, CB_SHOW_non_template_classes);
   ctl_show_inherited_members.set_filter_check_box(show_mask1, CB_SHOW_inherited_members, CB_SHOW_class_members);

   // bits in second SHOW mask
   ctl_show_preprocessing.set_filter_check_box(show_mask2, CB_SHOW_macros, CB_SHOW_non_macros);
   ctl_show_native.set_filter_check_box(show_mask2, CB_SHOW_native, CB_SHOW_non_native);
   ctl_show_extern.set_filter_check_box(show_mask2, CB_SHOW_extern, CB_SHOW_non_extern);
   ctl_show_anonymous.set_filter_check_box(show_mask2, CB_SHOW_anonymous, CB_SHOW_non_anonymous);

   // set package, private, public, public members on/off
   ctl_show_package_members.p_value   = (show_mask1 & CB_SHOW_package_members)?   1:0;
   ctl_show_private_members.p_value   = (show_mask1 & CB_SHOW_private_members)?   1:0;
   ctl_show_public_members.p_value    = (show_mask1 & CB_SHOW_public_members)?    1:0;
   ctl_show_protected_members.p_value = (show_mask1 & CB_SHOW_protected_members)? 1:0;
}

//////////////////////////////////////////////////////////////////////////////
// Gets the filtering flags from the options dialog.
//    show_mask1 -- bit mask for show options (see CB_SHOW_*, above)
//    show_mask2 -- more show options
// p_window_id must be the options dialog form window ID.
//
static void get_filter_options(int &show_mask1, int &show_mask2)
{
   show_mask1 = show_mask2 = 0;

   if (ctl_show_static_data.p_value>=1) {          show_mask1 |= CB_SHOW_class_data;           }
   if (ctl_show_static_data.p_value!=1) {          show_mask1 |= CB_SHOW_instance_data;        }
   if (ctl_show_data_members.p_value>=1) {         show_mask1 |= CB_SHOW_data_members;         }
   if (ctl_show_data_members.p_value!=1) {         show_mask1 |= CB_SHOW_other_members;        }
   if (ctl_show_inline.p_value!=1) {               show_mask1 |= CB_SHOW_out_of_line;          }
   if (ctl_show_inline.p_value>=1) {               show_mask1 |= CB_SHOW_inline;               }
   if (ctl_show_static.p_value>=1) {               show_mask1 |= CB_SHOW_static;               }
   if (ctl_show_virtual.p_value>=1) {              show_mask1 |= CB_SHOW_virtual;              }
   if (ctl_show_abstract.p_value>=1) {             show_mask1 |= CB_SHOW_abstract;             }
   if (ctl_show_abstract.p_value!=1) {             show_mask1 |= CB_SHOW_non_abstract;         }
   if (ctl_show_operators.p_value>=1) {            show_mask1 |= CB_SHOW_operators;            }
   if (ctl_show_constructors.p_value>=1) {         show_mask1 |= CB_SHOW_constructors;         }
   if (ctl_show_final_members.p_value!=1) {        show_mask1 |= CB_SHOW_non_final_members;    }
   if (ctl_show_final_members.p_value>=1) {        show_mask1 |= CB_SHOW_final_members;        }
   if (ctl_show_const_members.p_value!=1) {        show_mask1 |= CB_SHOW_non_const_members;    }
   if (ctl_show_const_members.p_value>=1) {        show_mask1 |= CB_SHOW_const_members;        }
   if (ctl_show_volatile_members.p_value!=1) {     show_mask1 |= CB_SHOW_non_volatile_members; }
   if (ctl_show_volatile_members.p_value>=1) {     show_mask1 |= CB_SHOW_volatile_members;     }
   if (ctl_show_synchronized_members.p_value!=1) { show_mask1 |= CB_SHOW_non_synchronized;     }
   if (ctl_show_synchronized_members.p_value>=1) { show_mask1 |= CB_SHOW_synchronized;         }
   if (ctl_show_transient_members.p_value!=1) {    show_mask1 |= CB_SHOW_persistent_data;      }
   if (ctl_show_transient_members.p_value>=1) {    show_mask1 |= CB_SHOW_transient_data;       }
   if (ctl_show_template_classes.p_value!=1) {     show_mask1 |= CB_SHOW_non_template_classes; }
   if (ctl_show_template_classes.p_value>=1) {     show_mask1 |= CB_SHOW_template_classes;     }
   if (ctl_show_package_members.p_value) {         show_mask1 |= CB_SHOW_package_members;      }
   if (ctl_show_private_members.p_value) {         show_mask1 |= CB_SHOW_private_members;      }
   if (ctl_show_protected_members.p_value) {       show_mask1 |= CB_SHOW_protected_members;    }
   if (ctl_show_public_members.p_value) {          show_mask1 |= CB_SHOW_public_members;       }
   if (ctl_show_inherited_members.p_value>=1) {    show_mask1 |= CB_SHOW_inherited_members;    }
   if (ctl_show_inherited_members.p_value!=1) {    show_mask1 |= CB_SHOW_class_members;        }

   if (ctl_show_extern.p_value>=1) {               show_mask2 |= CB_SHOW_extern;               }
   if (ctl_show_extern.p_value!=1) {               show_mask2 |= CB_SHOW_non_extern;           }
   if (ctl_show_native.p_value>=1) {               show_mask2 |= CB_SHOW_native;               }
   if (ctl_show_native.p_value!=1) {               show_mask2 |= CB_SHOW_non_native;           }
   if (ctl_show_preprocessing.p_value>=1) {        show_mask2 |= CB_SHOW_macros;               }
   if (ctl_show_preprocessing.p_value!=1) {        show_mask2 |= CB_SHOW_non_macros;           }
   if (ctl_show_anonymous.p_value>=1) {            show_mask2 |= CB_SHOW_anonymous;            }
   if (ctl_show_anonymous.p_value!=1) {            show_mask2 |= CB_SHOW_non_anonymous;        }

   // Turn on non-virtual provided neither virtual-only or static-only are set
   if (ctl_show_static.p_value!=1 && ctl_show_virtual.p_value!=1) {
       show_mask1 |= CB_SHOW_non_virtual;
   }
   // Turn off virtual/static if the other is set
   if (ctl_show_static.p_value==1 && ctl_show_virtual.p_value==2) {
      show_mask1 &= ~CB_SHOW_virtual;
   }
   if (ctl_show_static.p_value==2 && ctl_show_virtual.p_value==1) {
      show_mask1 &= ~CB_SHOW_static;
   }

   // Turn on non-virtual provided neither virtual-only or static-only are set
   if (ctl_show_operators.p_value!=1 && ctl_show_constructors.p_value!=1) {
       show_mask1 |= CB_SHOW_non_special;
   }
   // Turn off operators/constructors if the other is set
   if (ctl_show_operators.p_value==1 && ctl_show_constructors.p_value==2) {
      show_mask1 &= ~CB_SHOW_constructors;
   }
   if (ctl_show_operators.p_value==2 && ctl_show_constructors.p_value==1) {
      show_mask1 &= ~CB_SHOW_operators;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Apply new option settings from the symbol browser options dialog.
// First step is to reset the global options (see above), then call
// refresh_class_tree_view() and/or checkShowHideControls() if necessary.
//
static void apply_new_options()
{
   int show_mask1, show_mask2;
   get_filter_options(show_mask1, show_mask2);
   int show_class_filter  = ctl_show_class_filter.p_value;
   int show_member_filter = ctl_show_member_filter.p_value;

   _nocheck _control ctl_class_tree_view;
   _nocheck _control ctl_filter_check_box;
   _nocheck _control ctl_class_filter_combo_box;
   _nocheck _control ctl_member_filter_combo_box;
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return;
   }

   if (show_class_filter != f.ctl_class_filter_label.p_visible ||
       show_member_filter != f.ctl_member_filter_label.p_visible) {

      f.ctl_class_filter_label.p_user  = ctl_show_class_filter.p_value;
      f.ctl_member_filter_label.p_user = ctl_show_member_filter.p_value;
      f.checkShowHideControls();
   }

   int orig_show_mask1 = f.ctl_class_tree_view.p_user;
   int orig_show_mask2 = f.ctl_filter_check_box.p_user;
   _str class_filter  = f.ctl_class_filter_combo_box.cb_get_filter();
   _str member_filter = f.ctl_member_filter_combo_box.cb_get_filter();
   if (class_filter  :!= gz_class_filter ||
       member_filter :!= gz_member_filter ||
       (show_mask1 & CB_QUALIFIERS)  != (orig_show_mask1 & CB_QUALIFIERS) ||
       (show_mask2 & CB_QUALIFIERS2) != (orig_show_mask2 & CB_QUALIFIERS2)) {

      f.ctl_class_tree_view.p_user  = show_mask1;
      f.ctl_filter_check_box.p_user = show_mask2;
      f.ctl_filter_check_box.p_value = 0;
      gz_class_filter  = class_filter;
      gz_member_filter = member_filter;
      cb_refresh();
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle user pressing symbol browser options "Apply" button
//
void ctl_apply_button.lbutton_up()
{
   apply_new_options();
}

//////////////////////////////////////////////////////////////////////////////
// Handle user pressing symbol browser options "OK" button, apply the
// options and dismiss the form.
//
void ctl_ok_button.lbutton_up()
{
   _save_form_response();
   apply_new_options();
   p_active_form._delete_window(0);
}

//////////////////////////////////////////////////////////////////////////////
// Special cases to insure that at least one of package, private, protected,
// or public is on.  If all but one is on, and you attempt to toggle that
// one off, turn on the next item.
//
void ctl_show_package_members.lbutton_up()
{
   if (ctl_show_package_members.p_value == 0 && ctl_show_public_members.p_value == 0 && ctl_show_protected_members.p_value == 0 && ctl_show_private_members.p_value == 0) {
      ctl_show_public_members.p_value = 1;
   }
}
void ctl_show_private_members.lbutton_up()
{
   if (ctl_show_package_members.p_value == 0 && ctl_show_public_members.p_value == 0 && ctl_show_protected_members.p_value == 0 && ctl_show_private_members.p_value == 0) {
      ctl_show_package_members.p_value = 1;
   }
}
void ctl_show_protected_members.lbutton_up()
{
   if (ctl_show_package_members.p_value == 0 && ctl_show_public_members.p_value == 0 && ctl_show_protected_members.p_value == 0 && ctl_show_private_members.p_value == 0) {
      ctl_show_private_members.p_value = 1;
   }
}
void ctl_show_public_members.lbutton_up()
{
   if (ctl_show_package_members.p_value == 0 && ctl_show_public_members.p_value == 0 && ctl_show_protected_members.p_value == 0 && ctl_show_private_members.p_value == 0) {
      ctl_show_protected_members.p_value = 1;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Symbol browser options form creation, restore the options and
// refresh the controls as per current settings.
//
void ctl_ok_button.on_create()
{
   gcboptions_wid = p_active_form;
   int f = GetCBViewWid();
   if (!f) {
      return;
   }
   _nocheck _control ctl_class_tree_view;
   _nocheck _control ctl_class_filter_combo_box;
   _nocheck _control ctl_member_filter_combo_box;
   _nocheck _control ctl_filter_check_box;

   int show_mask1 = f.ctl_class_tree_view.p_user;
   int show_mask2 = f.ctl_filter_check_box.p_user;
   refresh_filter_options(show_mask1, show_mask2);

   ctl_show_member_filter.p_value = (f.ctl_member_filter_combo_box.p_visible)? 1:0;
   ctl_show_class_filter.p_value  = (f.ctl_class_filter_combo_box.p_visible )? 1:0;
}

//////////////////////////////////////////////////////////////////////////////
// Handle destroy symbol browser options dialog.  Get rid of cached window ID.
//
void ctl_ok_button.on_destroy()
{
   gcboptions_wid = 0;
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// handlers for class inheritance properties dialog
//
defeventtab _cbparents_form;

//////////////////////////////////////////////////////////////////////////////
// Handle right-mouse button on the inheritance tree dialog
//
void _cbparents_form.rbutton_up()
{
   int f = GetCBViewWid();
   if (!f) return;
   call_event(f.ctl_class_tree_view,RBUTTON_UP,'w');
}

//////////////////////////////////////////////////////////////////////////////
// handle horizontal resize bar
//
ctl_divider.lbutton_down()
{
   int button_width = ctl_ok_button.p_width;
   int border_width = ctl_inheritance_tree_view.p_x;
   int member_width = ctl_member_tree_view.p_x + ctl_member_tree_view.p_width;
   _ul2_image_sizebar_handler((button_width+border_width)*2,member_width);
}

//////////////////////////////////////////////////////////////////////////////
// Handle resize event, distributing available space evenly between the
// inheritance tree side and the member list side.  Do not allow the size
// to go below the minimum required to show classes in the tree and show
// all three buttons.
//
void _cbparents_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok_button.p_width;
   int button_height = ctl_ok_button.p_height;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*5);
   }

   // available space and border usage
   int avail_x, avail_y, border_x, border_y;
   avail_x  = p_width;
   avail_y  = p_height;
   border_x = ctl_inheritance_tree_view.p_x;
   border_y = ctl_inheritance_tree_view.p_y;

   // half the width of the dialog
   int half_x        = ctl_divider.p_x;
   int half_width    = ctl_divider.p_width;
   if (half_x < button_width*2 + border_x*2) {
      half_x = button_width*2 + border_x*2;
   }
   if (half_x > avail_x) {
      half_x = avail_x - ctl_divider.p_width;
      ctl_divider.p_x = half_x;
   }

   // size the tree controls
   ctl_inheritance_tree_view.p_width  = half_x - border_x;
   ctl_inheritance_tree_view.p_height = avail_y - border_y*3 - button_height;
   ctl_member_tree_view.p_x      = half_x + half_width;
   ctl_member_tree_view.p_height = avail_y - border_y*2;
   ctl_member_tree_view.p_width  = avail_x - half_x - border_x - half_width;

   // set the height of the divider
   ctl_divider.p_height = ctl_inheritance_tree_view.p_height;

   // move around the buttons
   int button_y = avail_y - button_height - border_y;
   ctl_ok_button.p_y   = button_y;
   ctl_help_button.p_y = button_y;
   ctl_help_button.p_x = ctl_divider.p_x - button_width;
}

//////////////////////////////////////////////////////////////////////////////
// Get context information for the currently selected member in the class
// inheritance dialog.  Complete context is obtained by looking both at
// the currently selected member, and the currently selected class.
// Final details are obtained from the database.  If (class_only==1),
// then get the tag info for the currently selected class, not member.
// p_window_id must be the inheritance tree window ID.
//
static int get_inheritance_tag_info(struct VS_TAG_BROWSE_INFO &cm, int class_only, boolean no_db_access, int classIndex=-1, int memberIndex=-1)
{
   tag_browse_info_init(cm);

   // check current tree index
   if (classIndex < 0) {
      classIndex = ctl_inheritance_tree_view._TreeCurIndex();
   }
   if (classIndex < 0) {
      return 0;
   }

   // get some more details
   _str ucm = ctl_inheritance_tree_view._TreeGetUserInfo(classIndex);
   _str line_no=0,class_end,caption;
   parse ucm with cm.tag_database ';' cm.class_name ';' cm.type_name ';' cm.file_name ';' line_no ;
   cm.line_no = line_no!=''? (int) line_no : 0;

   // if they are requesting only information on the currently selected class
   if (class_only) {
      cm.qualified_name = cm.class_name;
      cm.member_name = cm.class_name;
      cm.class_name  = '';
      while (pos(VS_TAGSEPARATOR_package, cm.member_name)) {
         parse cm.member_name with class_end VS_TAGSEPARATOR_package cm.member_name;
         if (cm.class_name != '') {
            cm.class_name = cm.class_name:+VS_TAGSEPARATOR_package:+class_end;
         } else {
            cm.class_name = class_end;
         }
      }
      while (pos(VS_TAGSEPARATOR_class, cm.member_name)) {
         parse cm.member_name with class_end VS_TAGSEPARATOR_class cm.member_name;
         if (cm.class_name != '') {
            cm.class_name = cm.class_name:+VS_TAGSEPARATOR_class:+class_end;
         } else {
            cm.class_name = class_end;
         }
      }
   } else {
      // get basic location info for this tag
      if (memberIndex < 0) {
         memberIndex = ctl_member_tree_view._TreeCurIndex();
      }
      if (memberIndex <= 0) {
         return 0;
      }
      int d = ctl_member_tree_view._TreeGetDepth(memberIndex);
      if (d<2) {
         return 0;
      }
      caption = ctl_member_tree_view._TreeGetCaption(memberIndex);
      tag_tree_decompose_caption(caption,cm.member_name);
      cm.line_no = ctl_member_tree_view._TreeGetUserInfo(memberIndex);
      cm.type_name = '';
   }

   // bail out if we were asked not to touch the database
   if (no_db_access) {
      return 1;
   }

   // open the tag database for business
   int status = tag_read_db(cm.tag_database);
   if ( status < 0 ) {
      return(status);
   }

   // find the specific tag in the database
   status = tag_find_closest(cm.member_name, cm.file_name, cm.line_no, 1);
   if (!status) {
      tag_get_detail(VS_TAGDETAIL_type,      cm.type_name);
      tag_get_detail(VS_TAGDETAIL_flags,     cm.flags);
      tag_get_detail(VS_TAGDETAIL_return,    cm.return_type);
      tag_get_detail(VS_TAGDETAIL_arguments, cm.arguments);
      tag_get_detail(VS_TAGDETAIL_throws,    cm.exceptions);
      tag_get_detail(VS_TAGDETAIL_language_id,   cm.language);
      tag_get_detail(VS_TAGDETAIL_class_parents, cm.class_parents);
      tag_get_detail(VS_TAGDETAIL_template_args, cm.template_args);
      if (cm.language=='jar' || cm.language=='zip') {
         cm.language='java';
      }
   }

   // success
   tag_reset_find_tag();
   return 1;
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the inheritance tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _MemberListTimerCallback(int index)
{
   // kill the timer
   cb_kill_timer();

   // bail out if there is no inheritance form
   int f = gcbparents_wid;
   if (!f) return;

   // update the property view, call tree view, and output tab
   struct VS_TAG_BROWSE_INFO cm;
   if (f.get_inheritance_tag_info(cm, 0, false)) {
      f = gtbprops_wid;
      if (f) {
         cb_refresh_property_view(cm);
      }

      // find the output tagwin and update it
      cb_refresh_output_tab(cm, true);
   }
}
static void _MemberListHighlightCallback(int index=-1)
{
   // kill the timer
   cb_kill_timer();

   // bail out if there is no inheritance form
   int f = gcbparents_wid;
   if (!f) return;

   // update the property view, call tree view, and output tab
   struct VS_TAG_BROWSE_INFO cm;
   if (f.get_inheritance_tag_info(cm, 0, false, -1, index)) {
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle on-change event for member list (a tree control) in inheritance
// tree dialog.  The only event handled is CHANGE_LEAF_ENTER, for which
// we utilize push_tag_in_file to push a bookmark and bring up the code in
// the editor.
//
void ctl_member_tree_view.on_change(int reason,int index)
{
   if (reason == CHANGE_LEAF_ENTER) {

      // get the current index and tag details
      int k = index;
      struct VS_TAG_BROWSE_INFO cm;
      if (get_inheritance_tag_info(cm, 0, false)) {
         push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
      }
   } else if (reason == CHANGE_SELECTED) {
      if (_get_focus() == gcbparents_wid.ctl_member_tree_view) {

         // kill the existing timer and start a new one
         cb_kill_timer();
         cb_start_timer(_MemberListTimerCallback);
      }
   }
}

void ctl_member_tree_view.on_highlight(int index, _str caption="")
{
   cb_kill_timer();
   if (index < 0 || !def_tag_hover_preview) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   cb_start_timer(_MemberListHighlightCallback, index, def_tag_hover_delay);
}


//////////////////////////////////////////////////////////////////////////////
// Update other views when viewer gets focus, important because
// inheritance view, call tree, and props can also update the output
// view, so if they return focus to the symbol browser, we need to
// restart the update timer.
//
void ctl_member_tree_view.on_got_focus()
{
   // kill the existing timer and start a new one
   cb_kill_timer();
   cb_start_timer(_MemberListTimerCallback);
}

//////////////////////////////////////////////////////////////////////////////
// If the spacebar is pressed when the focus is on the member list,
// bring the item up in the editor, but retain focus on the member list.
//
void ctl_member_tree_view.' '()
{
   int orig_window_id = p_window_id;
   struct VS_TAG_BROWSE_INFO cm;
   if (get_inheritance_tag_info(cm, 0, false)) {
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   }
   p_window_id = orig_window_id;
   ctl_member_tree_view._set_focus();
}

//////////////////////////////////////////////////////////////////////////////
// Handle double-click (meaning drill-down) on a member in a class.
// This method will attempt to locate the proc that corresponds to any
// prototype that is selected, and position us there.
//
void ctl_member_tree_view.enter,lbutton_double_click()
{
   int k = ctl_member_tree_view._TreeCurIndex();
   int d = (k<0)? 0:ctl_member_tree_view._TreeGetDepth(k);
   if (d > 1) {
      struct VS_TAG_BROWSE_INFO cm;
      if (get_inheritance_tag_info(cm, 0, false)) {
         maybe_convert_proto_to_proc(cm);
         push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
      }
   } else {
      int show_children=0;
      _TreeGetInfo(k,show_children);
      if (show_children == TREE_NODE_LEAF) {
         call_event(CHANGE_LEAF_ENTER,k,p_window_id,ON_CHANGE,'w');
      } else {
         call_event(show_children?CHANGE_COLLAPSED:CHANGE_EXPANDED,k,p_window_id,ON_CHANGE,'w');
         _TreeSetInfo(k,(int)!show_children);
      }
   }
}


//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the inheritance tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _InheritanceTimerCallback()
{
   // kill the timer
   cb_kill_timer();

   // bail out if there is no inheritance form
   int f = gcbparents_wid;
   if (!f) return;

   // update the property view, call tree view, and output tab
   struct VS_TAG_BROWSE_INFO cm;
   if (f.get_inheritance_tag_info(cm, 1, false)) {

      // refresh the list of member functions
      se.util.MousePointerGuard hour_glass;
      _str in_file_name = cm.file_name;
      if (cm.flags & VS_TAGFLAG_partial) {
         in_file_name='';
      }
      f.ctl_member_tree_view.add_members_of(cm.qualified_name, cm.tag_database, in_file_name);
      f.ctl_member_tree_view._TreeRefresh();

      // refresh the properties view
      f = gtbprops_wid;
      if (f) {
         cb_refresh_property_view(cm);
      }

      // find the output tagwin and update it
      cb_refresh_output_tab(cm, true);
   } else {
      f.ctl_member_tree_view._TreeDelete(TREE_ROOT_INDEX,'c');
      f.ctl_member_tree_view._TreeAddItem(TREE_ROOT_INDEX, "CLASS NOT FOUND", TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open);
   }
}
static void _InheritanceHighlightCallback(int index=-1)
{
   // kill the timer
   cb_kill_timer();

   // bail out if there is no inheritance form
   int f = gcbparents_wid;
   if (!f) return;

   // update the property view, call tree view, and output tab
   struct VS_TAG_BROWSE_INFO cm;
   if (f.get_inheritance_tag_info(cm, 1, false, index)) {

      // find the output tagwin and update it
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle on-change for inheritance tree, meaning that a diffenent class
// was selected, so we need to update the list of members.
//
void ctl_inheritance_tree_view.on_change(int reason,int index)
{
   struct VS_TAG_BROWSE_INFO cm;
   if (reason == CHANGE_LEAF_ENTER) {
      if (get_inheritance_tag_info(cm, 1, true)) {
         push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
      }
   } else if (reason == CHANGE_SELECTED) {

      if (_get_focus() == ctl_inheritance_tree_view) {

         // kill the existing timer and start a new one
         cb_kill_timer();
         cb_start_timer(_InheritanceTimerCallback);
      } else {
         if (get_inheritance_tag_info(cm, 1, true)) {
            se.util.MousePointerGuard hour_glass;
            _str in_file_name = cm.file_name;
            if (cm.flags & VS_TAGFLAG_partial) {
               in_file_name='';
            }
            ctl_member_tree_view.add_members_of(cm.qualified_name, cm.tag_database, in_file_name);
            ctl_member_tree_view._TreeRefresh();
         }
      }
   } else if (reason == CHANGE_EXPANDED && ctl_member_tree_view.p_user==1) {

      // already expanded?
      if (ctl_inheritance_tree_view._TreeGetFirstChildIndex(index) > 0) {
         return;
      }
      // still needs to be expanded
      if (!get_inheritance_tag_info(cm, 1, true, index)) {
         return;
      }

      _str lang = _Filename2LangId(cm.file_name);
      typeless tag_files = tags_filenamea(lang);

      se.util.MousePointerGuard hour_glass;
      boolean been_there_done_that:[];
      VS_TAG_RETURN_TYPE visited:[];
      ctl_inheritance_tree_view.add_children_of(index, cm.qualified_name,
                                                cm.type_name,
                                                cm.tag_database, tag_files,
                                                cm.file_name, cm.line_no,
                                                been_there_done_that, visited, 0, 1);
      clear_message();
   }
}

void ctl_inheritance_tree_view.on_highlight(int index, _str caption="")
{
   cb_kill_timer();
   if (index < 0 || !def_tag_hover_preview) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   cb_start_timer(_InheritanceHighlightCallback, index, def_tag_hover_delay);
}

//////////////////////////////////////////////////////////////////////////////
// Update other views when viewer gets focus, important because
// inheritance view, call tree, and props can also update the output
// view, so if they return focus to the symbol browser, we need to
// restart the update timer.
//
void ctl_inheritance_tree_view.on_got_focus()
{
   // kill the existing timer and start a new one
   cb_kill_timer();
   cb_start_timer(_InheritanceTimerCallback);
}

//////////////////////////////////////////////////////////////////////////////
// Handles double-clock/enter in inheritance tree view, pushing a bookmark
// and displaying the class in the editor for editing.
//
void ctl_inheritance_tree_view.enter,lbutton_double_click()
{
   struct VS_TAG_BROWSE_INFO cm;
   int j = ctl_inheritance_tree_view._TreeCurIndex();
   if (get_inheritance_tag_info(cm, 1, true)) {
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handles spacebar in inheritance tree view, pushing a bookmark
// and displaying the class in the editor for editing, but retaining
// focus in the inheritance tree browser.
//
void ctl_inheritance_tree_view.' '()
{
   struct VS_TAG_BROWSE_INFO cm;
   int j = ctl_inheritance_tree_view._TreeCurIndex();
   if (get_inheritance_tag_info(cm, 1, true)) {
      int orig_window_id = p_window_id;
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
      p_window_id = orig_window_id;
      ctl_inheritance_tree_view._set_focus();
   }
}

static int cbrowser_get_class_pic_index(_str class_type, _str parents=null)
{
   switch ( class_type ) {
   case 'interface':
      return gi_pic_access_type[0][CB_type_interface];
   case 'enum':
      return gi_pic_access_type[0][CB_type_enum];
   case 'struct':
      return gi_pic_access_type[0][CB_type_struct];
   case 'class':
   }
   if (parents != null && parents == '') {
      return gi_pic_access_type[0][CB_type_base_class];
   }
   return gi_pic_access_type[0][CB_type_class];
}

//////////////////////////////////////////////////////////////////////////////
// Add the parents (classes that 'class_name' derives from) to the
// inheritance tree browser).  tag databases and file names are resolved
// allowing us to display parents that are in other tag files.
// This function is recursive, but limited to CB_MAX_INHERITANCE_DEPTH levels.
// p_window_id must be the inheritance tree control (left tree of window).
//
int cbrowser_add_parents_of(int j, _str class_name, _str class_parents,
                          _str tag_db_name, typeless &tag_files,
                          _str child_file_name, int child_line_no, 
                          int depth, _str class_type='')
{
   if (depth >= CB_MAX_INHERITANCE_DEPTH) {
      return 0;
   }

   // what tag file is this class really in?
   _str normalized;
   _str tag_file = find_class_in_tag_file(class_name, class_name, normalized, 1, tag_files);
   if (tag_file == '') {
      tag_file = find_class_in_tag_file(class_name, class_name, normalized, 1, tag_files, true);
   }
   if (tag_file != '') {
      tag_db_name = tag_file;
   }
   int pic_class = 0;
   int status = tag_read_db(tag_db_name);
   if (status < 0) {
      pic_class = cbrowser_get_class_pic_index(class_type);
      _TreeAddItem(j, class_name, TREE_ADD_AS_CHILD, pic_class, pic_class, TREE_NODE_EXPANDED);
      return 0;
   }

   // get are parent classes and the tag files they come from
   int result = 0;
   _str tag_dbs = '';
   _str parent_types='';
   _str parents = cb_get_normalized_inheritance(class_name, tag_dbs, tag_files, false, class_parents, child_file_name, parent_types);

   // check if this is a base class
   pic_class = cbrowser_get_class_pic_index(class_type, parents);

   // make sure the right tag file is still open
   status = tag_read_db(tag_db_name);
   if (status < 0) {
      pic_class = cbrowser_get_class_pic_index(class_type);
      _TreeAddItem(j, class_name, TREE_ADD_AS_CHILD, pic_class, pic_class, TREE_NODE_EXPANDED);
      return 0;
   }

   _str file_name='';
   _str type_name='';
   int line_no=0;
   status = find_location_of_parent_class(tag_db_name, class_name, file_name, line_no, type_name);
   if (status < 0 || j<0) {
      file_name = child_file_name;
      line_no   = child_line_no;
   }

   // OK, we are now ready to insert
   int k;
   if (j < 0) {
      k = TREE_ROOT_INDEX;
      _TreeSetCaption(TREE_ROOT_INDEX, class_name);
      _TreeSetInfo(TREE_ROOT_INDEX, TREE_NODE_EXPANDED, pic_class, pic_class);
   } else {
      k = _TreeAddItem(j, class_name, TREE_ADD_AS_CHILD, pic_class, pic_class, TREE_NODE_EXPANDED);
   }
   _str ucm = tag_db_name ';' class_name ';' type_name ';' file_name ';' line_no;
   _TreeSetUserInfo(k, ucm);

   // recursively process parent classes
   _str p1,t1;
   _str orig_tag_file = tag_current_db();
   while (parents != '') {
      parse parents with p1 ';' parents;
      parse tag_dbs with t1 ';' tag_dbs;
      parse parent_types with class_type ';' parent_types;
      parse p1 with p1 '<' .;
      find_location_of_parent_class(t1,p1,file_name,line_no,type_name);
      result = cbrowser_add_parents_of(k, p1, '', t1, tag_files, file_name, line_no, depth+1, class_type);
   }

   tag_read_db(orig_tag_file);
   return k;
}


//////////////////////////////////////////////////////////////////////////////
// Add the children (classes that derive from 'class_name') to the
// inheritance tree browser).
static int add_children_of(int j, _str class_name, _str type_name,
                           _str tag_db_name, typeless &tag_files,
                           _str child_file_name, int child_line_no, 
                           boolean (&been_there_done_that):[], 
                           VS_TAG_RETURN_TYPE (&visited):[],
                           int depth, int max_depth=1)
{
   int pic_class, leaf;
   if (j == TREE_ROOT_INDEX) {
      tag_tree_get_bitmap(0,0,type_name,class_name,0,leaf,pic_class);
      _TreeSetCaption(j, class_name);
      _TreeSetInfo(j, TREE_NODE_EXPANDED, pic_class, pic_class);
      ucm := tag_db_name ';' class_name ';' type_name ';' child_file_name ';' child_line_no;
      _TreeSetUserInfo(j, ucm);
   }

   tag_lock_matches(true);
   tag_push_matches();
   tag_clear_matches();
   tag_find_derived(/*j, */class_name, 
                    tag_db_name, tag_files, 
                    child_file_name, child_line_no, 
                    been_there_done_that, visited, depth, max_depth);
   int num_matches = tag_get_num_of_matches();
   int i;
   VS_TAG_BROWSE_INFO cm;
   for (i = 1; i <= num_matches; i++) {
      tag_get_match_info(i, cm);
      tag_tree_get_bitmap(0,0,cm.type_name,cm.class_name,0,leaf,pic_class);

      int show_children = TREE_NODE_COLLAPSED;//(depth < max_depth)? 1:0;
      if (cm.qualified_name == '') {
         cm.qualified_name = tag_join_class_name(cm.member_name, cm.class_name, tag_files, true);
      }
      ucm := cm.tag_database ';' cm.qualified_name ';' cm.type_name ';' cm.file_name ';' cm.line_no;
      k := _TreeAddItem(j, cm.qualified_name, TREE_ADD_AS_CHILD, pic_class, pic_class, show_children, 0, ucm);
      if (show_children) {
         // still needs to be expanded
         tag_push_matches();
         get_inheritance_tag_info(cm, 1, true, k);
         add_children_of(k, cm.qualified_name,
                         cm.type_name,
                         cm.tag_database, tag_files,
                         cm.file_name, cm.line_no,
                         been_there_done_that, visited, depth+1, max_depth);
         tag_pop_matches();
      }
   }

   tag_pop_matches();
   tag_unlock_matches();
   return(0);
}

//////////////////////////////////////////////////////////////////////////////
// Add the members of the given class to the list of members in the
// inheritance tree view.  As apposed to the class tree view, members are
// not filtered here.  Members are dispersed into four categories, publ// They are then sorted by caption and (secondary) line number.
// p_window_id must be the member tree control (right tree of window).
//
static int add_members_of(_str class_name, _str tag_db_name, _str in_file_name)
{
   // uh-oh
   if (class_name == '') {
      _TreeDelete(TREE_ROOT_INDEX,'c');
      _TreeAddItem(TREE_ROOT_INDEX, "CLASS NOT FOUND", TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open);
      return(-1);
   }

   // open the database for business
   int status = tag_read_db(tag_db_name);
   if ( status < 0 ) {
      _TreeDelete(TREE_ROOT_INDEX,'c');
      _TreeAddItem(TREE_ROOT_INDEX, "CLASS NOT FOUND", TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open);
      return(status);
   }

   // re-use the public, protected, private, package categories
   int j_access[];
   int i_access = 0;
   int i_type = 0;
   int j = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (j>0) {
      j_access[i_access]=j;
      ++i_access;
      _TreeDelete(j,'c');
      j = _TreeGetNextSiblingIndex(j);
   }
   if (i_access != 4) {
      _TreeDelete(TREE_ROOT_INDEX, 'c');
      i_access = 0;
   }

   if (i_access == 0) {
      j_access[CB_access_public]    = _TreeAddItem(TREE_ROOT_INDEX, "PUBLIC",    TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open, TREE_NODE_EXPANDED);
      j_access[CB_access_protected] = _TreeAddItem(TREE_ROOT_INDEX, "PROTECTED", TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open, TREE_NODE_EXPANDED);
      j_access[CB_access_private]   = _TreeAddItem(TREE_ROOT_INDEX, "PRIVATE",   TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open, TREE_NODE_EXPANDED);
      j_access[CB_access_package]   = _TreeAddItem(TREE_ROOT_INDEX, "PACKAGE",   TREE_ADD_AS_CHILD, gi_pic_cat_close, gi_pic_cat_open, TREE_NODE_EXPANDED);
   }

   // insert all the members in class, must be in same file as class, no other filtering
   int flags=0,line_no=0;
   _str member_name,type_name,file_name;
   _str caption;
   status = tag_find_in_class(class_name);
   while (!status) {
      tag_get_detail(VS_TAGDETAIL_flags,flags);
      if ((flags & VS_TAGFLAG_inclass) == 0){
         status = tag_next_in_class();
         continue;
      }
      // kick out if this does not come from the given filename
      tag_get_info(member_name, type_name, file_name, line_no, class_name, flags);
      if (!(flags & VS_TAGFLAG_extern_macro) &&
          in_file_name != '' && !file_eq(file_name, in_file_name)) {
         status = tag_next_in_class();
         continue;
      }

      // function/data, access restrictions and type code for picture selection
      caption = tag_tree_make_caption_fast(VS_TAGMATCH_tag,0,false,true,false);
      tag_tree_filter_member2(0, 0, type_name, ((class_name!='')? 1:0), flags, i_access, i_type);

      // compute file/id / line number code
      int ucm = line_no;

      // get the appropriate bitmap
      int pic_member = gi_pic_access_type[i_access][i_type];
      j = _TreeAddItem(j_access[i_access],caption,TREE_ADD_AS_CHILD,pic_member,pic_member,TREE_NODE_LEAF,0,ucm);
      status = tag_next_in_class();
   }
   tag_reset_find_in_class();

   // sort each of the access categories
   if (gi_sort_by_line) {
      _TreeSortUserInfo(j_access[CB_access_public   ],'N','I');
      _TreeSortUserInfo(j_access[CB_access_protected],'N','I');
      _TreeSortUserInfo(j_access[CB_access_private  ],'N','I');
      _TreeSortUserInfo(j_access[CB_access_package  ],'N','I');
   } else {
      _TreeSortCaption(j_access[CB_access_public   ],'I','N');
      _TreeSortCaption(j_access[CB_access_protected],'I','N');
      _TreeSortCaption(j_access[CB_access_private  ],'I','N');
      _TreeSortCaption(j_access[CB_access_package  ],'I','N');
   }

   // mark the empty categories as EMPTY
   j = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (j>0) {
      caption = _TreeGetCaption(j);
      parse caption with caption CB_delimiter .;
      int child = _TreeGetFirstChildIndex(j);
      if (child <= 0) {
         caption = caption :+ CB_delimiter :+ CB_empty;
      }
      _TreeSetCaption(j, caption);
      j = _TreeGetNextSiblingIndex(j);
   }

   // go to the top of the tree
   _TreeTop();

   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Clear the inheritance view, removing all items in parents tree and
// member list.  p_window_id must be the inheritance tree window ID.
//
static void clear_inheritance_view(_str msg='')
{
   ctl_inheritance_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
   int index = ctl_member_tree_view._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      ctl_member_tree_view._TreeDelete(index, 'c');
      index = ctl_member_tree_view._TreeGetNextSiblingIndex(index);
   }
   ctl_inheritance_tree_view._TreeSetCaption(TREE_ROOT_INDEX, msg);
   refresh();
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the inheritance tree view with the given tag specification
// obtained from get_user_tag_info().  If we can show that the class
// hasn't changed, then break out early.
// p_window_id must be the inheritance tree window ID.
//
static void refresh_inheritance_view(struct VS_TAG_BROWSE_INFO cm, _str show_derived=null, boolean force=false)
{
   if (cm.qualified_name == '') {
      cm.qualified_name = cm.class_name;
   }
   if (cm.type_name :== 'enumc') {
      return;
   }
   if (show_derived==null) {
      show_derived=ctl_member_tree_view.p_user;
   }

   // same inheritance tree as last time?
   struct VS_TAG_BROWSE_INFO cm2=ctl_inheritance_tree_view.p_user;
   if (!force && tag_browse_info_equal(cm,cm2) &&
       show_derived==ctl_member_tree_view.p_user) {
      return;
   }
   ctl_inheritance_tree_view.p_user=cm;
   ctl_member_tree_view.p_user=show_derived;

   // bail out if there is no class involved or if class name hasn't changed
   _str caption;
   _str tag_db_name,class_name,type_name,file_name,line_no;
   int currIndex = ctl_inheritance_tree_view._TreeCurIndex();
   if (currIndex > 0) {
      caption = ctl_inheritance_tree_view._TreeGetCaption(currIndex);
      _str ucm = ctl_inheritance_tree_view._TreeGetUserInfo(currIndex);
      parse ucm with tag_db_name ';' class_name ';' type_name ';' file_name ';' line_no;
      if (caption :== cm.qualified_name && file_eq(tag_db_name, cm.tag_database) && file_eq(file_name, cm.file_name) && type_name :== cm.type_name) {
         return;
      }
   } else {
      if (cm.qualified_name=='') {
         ctl_inheritance_tree_view._TreeSetCaption(TREE_ROOT_INDEX, "No class selected");
         ctl_inheritance_tree_view._TreeSetUserInfo(TREE_ROOT_INDEX, 0);
      }
   }

   // If a file is not selected, clear the tree
   if (cm.qualified_name == '') {
      clear_inheritance_view("No class selected");
      return;
   }

   // check that we are positioned on something class-related
   int f = GetCBViewWid();
   if (!f) {
      clear_inheritance_view("No class selected");
      return;
   }
   int item_depth;
   typeless value;
   currIndex  = f.ctl_class_tree_view._TreeCurIndex();
   item_depth = f.ctl_class_tree_view._TreeGetDepth(currIndex);
   value      = f.ctl_class_tree_view._TreeGetUserInfo(currIndex);

   // If a class is not selected, clear the tree
   if (item_depth <= 2) {
      clear_inheritance_view("No class selected");
      return;
   }
   CB_TAG_CATEGORY *ctg = gh_cb_categories._indexin(cm.category);
   if (item_depth == 3 && (!ctg || !ctg->level3_inheritance)) {
      clear_inheritance_view("No class selected");
      return;
   }
   if (item_depth == 4 && (!ctg || !ctg->level4_inheritance)) {
      clear_inheritance_view("No class selected");
      return;
   }

   // Delete everything in the tree, and insert the new parent hierarchy
   se.util.MousePointerGuard hour_glass;
   ctl_inheritance_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
   //_str ext = _Ext2LangId(get_extension(cm.file_name));
   int j;
   _str lang = _Filename2LangId(cm.file_name);
   typeless tag_files = tags_filenamea(lang);
   if (show_derived) {
      boolean been_there_done_that:[];
      struct VS_TAG_RETURN_TYPE visited:[];
      p_active_form.p_caption=CB_derived;
      ctl_member_tree_view.p_user=1;
      j = ctl_inheritance_tree_view.add_children_of(TREE_ROOT_INDEX, 
                                                    cm.qualified_name,
                                                    cm.type_name,
                                                    cm.tag_database, tag_files,
                                                    cm.file_name, cm.line_no,
                                                    been_there_done_that, visited,
                                                    0, def_cb_max_derived_class_depth);
   } else {
      p_active_form.p_caption=CB_bases;
      ctl_member_tree_view.p_user=0;
      j = ctl_inheritance_tree_view.cbrowser_add_parents_of(-1, cm.qualified_name, cm.class_parents,
                                                   cm.tag_database, tag_files,
                                                   cm.file_name, cm.line_no, 0, cm.type_name);
   }

   // Initialize the member list for this class
   ctl_inheritance_tree_view._TreeSetCurIndex(j);
   call_event(CHANGE_SELECTED,j,ctl_inheritance_tree_view,ON_CHANGE,'w');
   ctl_inheritance_tree_view._TreeRefresh();
   clear_message();
}

//////////////////////////////////////////////////////////////////////////////
// THIS is not used?
//
//void cb_refresh_inheritance_view(struct VS_TAG_BROWSE_INFO &cm)
//{
//   // bail out if there is no inheritance form
//   _nocheck _control ctl_inheritance_tree_view;
//   _nocheck _control ctl_member_tree_view;
//   int f = gcbparents_wid;
//   if (!f) return;
//
//   // bail out if type is a macro defininition
//   if (cm.type_name :== 'define') {
//      return;
//   }
//
//   // try to determine the qualified class name
//   if (cm.qualified_name == '') {
//      cm.qualified_name = cm.class_name;
//   }
//   if (tag_tree_type_is_class(cm.class_name)) {
//      cm.qualified_name = _JoinClassWithOuter(cm.class_name, cm.qualified_name, false);
//   }
//
//   // bail out if there is no class involved or if class name hasn't changed
//   int currIndex = f.ctl_inheritance_tree_view._TreeCurIndex();
//   if (currIndex > 0) {
//      caption = f.ctl_inheritance_tree_view._TreeGetCaption(currIndex);
//      ucm = f.ctl_inheritance_tree_view._TreeGetUserInfo(currIndex);
//      parse ucm with tag_db_name ';' class_name ';' type_name ';' file_name ';' line_no;
//      if (caption :== cm.qualified_name && file_eq(tag_db_name, cm.tag_database) && file_eq(file_name, cm.file_name) && type_name :== cm.type_name) {
//         return;
//      }
//   } else {
//      if (cm.qualified_name=='') {
//         f.clear_inheritance_view('No class selected');
//         return;
//      }
//   }
//
//   // Delete everything in the tree, and insert the new parent hierarchy
//   mou_hour_glass(1);
//   f.ctl_inheritance_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
//   _str lang = _Filename2LangId(cm.file_name);
//   typeless tag_files = tags_filenamea(lang);
//   j = f.ctl_inheritance_tree_view.add_parents_of(-1, cm.qualified_name,
//                                                  cm.tag_database, tag_files,
//                                                  cm.file_name, cm.line_no, 0);
//
//   // Initialize the member list for this class
//   f.ctl_inheritance_tree_view._TreeSetCurIndex(j);
//   f.call_event(CHANGE_SELECTED,j,f.ctl_inheritance_tree_view,ON_CHANGE,'w')
//   //mou_hour_glass(0);
//}

//////////////////////////////////////////////////////////////////////////////
// On form creation, get the argument (tag information), and refresh
// the view, cache the window id.
//
void ctl_ok_button.on_create(struct VS_TAG_BROWSE_INFO cm=null, _str option="")
{
   gcbparents_wid=p_active_form;
   if (cm != null) {
      boolean find_children=(option == "derived");
      if (find_children) {
         //status=_message_box("Computing derived classes may take several minutes.  Continue?");
         //if (status!=IDOK) {
         //   return;
         //}
      }
      refresh_inheritance_view(cm,find_children);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Blow away our cached window ID on form destroy
//
void ctl_ok_button.on_destroy()
{
   gcbparents_wid=0;
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Handlers for item properties dialog
//
defeventtab _cbcalls_form;

//////////////////////////////////////////////////////////////////////////////
// compute name / line number string for sorting, accessing references
//
static _str cb_create_reference_info(_str &file_name, int line_no, int tag_id, _str tag_filename)
{
   //say("cb_create_reference_info: file="file_name" line="line_no" tag="tag_id);
   return file_name ';' line_no ';' tag_id ';' tag_filename;
}

///////////////////////////////////////////////////////////////////////////////
// Return the virtual root index for the calls/uses tree control
//
static int callTreeRootIndex()
{
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index < 0) return TREE_ROOT_INDEX;
   return index;
}

//////////////////////////////////////////////////////////////////////////////
// retrieve information from reference tree or call tree
// p_window_id must be the references or call (uses) tree control.
//
static int get_reference_tag_info(int j, struct VS_TAG_BROWSE_INFO &cm, int &inst_id)
{
   //say("get_reference_tag_info: here, j="j);
   tag_browse_info_init(cm);
   if (j < 0) {
      return 0;
   }

   // open the tag database for business
   int status;
   boolean tag_database=false;
   _str ref_database = refs_filename();
   if (ref_database != '') {
      status = tag_read_db(ref_database);
      if ( status < 0 ) {
         return 0;
      }
   } else {
      tag_database=true;
   }

   // get the file name and line number, tag database, and instance ID
   _str ucm = _TreeGetUserInfo(j);
   _str line_no,iid='';
   parse ucm with cm.file_name ';' line_no ';' iid ';' cm.tag_database;
   if (line_no == '') {
      line_no = 0;
   }
   cm.line_no = (line_no=='')? 1:((int)line_no);
   inst_id    = (iid=='')? 0:((int) iid);
   //say("get_reference_tag_info: file_name="cm.file_name" line_no="line_no" iid="iid);

   // get details about the instance (tag)
   if (inst_id > 0 && !tag_database) {
      typeless df,dl;
      tag_get_instance_info(inst_id, cm.member_name, cm.type_name, cm.flags, cm.class_name, cm.arguments, df, dl);
      //say("get_reference_tag_info(): got here 3, inst_id="inst_id" member_name="cm.member_name" file_name="cm.file_name" line_no="cm.line_no" args="cm.arguments);
   } else {
      // normalize member name
      tag_tree_decompose_caption(_TreeGetCaption(j),cm.member_name,cm.class_name,cm.arguments);
   }

   // try to figure out the type of the item, based
   // on the bitmap used
   int show_children=0;
   int pic_ref1,pic_ref2;
   cm.type_name='';
   _TreeGetInfo(j,show_children,pic_ref1,pic_ref2);
   int i,k;
   for (i=0; i<gi_code_access._length(); ++i) {
      for (k=0; k<gi_code_type._length(); ++k) {
         if (pic_ref1==gi_pic_access_type[i][k]) {
            cm.type_name=gi_code_type[k].type_name;
         }
      }
   }

   // is the given file_name and line number valid?
   if (cm.file_name != '') {
      if (cm.line_no > 0 && (path_search(cm.file_name)!='' || _isfile_loaded(cm.file_name))) {
         if (!_QBinaryLoadTagsSupported(cm.file_name)) {
            return 1;
         }
         /*
      } else if (tag_database && !cm.line_no) {
         // this is where we need to extract more information
         // from the source file, for now, we fake it
         //cm.line_no=1;
         //say("get_reference_tag_info: h3");
         //return 1;
      } else {
         cm.file_name = '';*/
      }
   }

   // count the number of exact matches for this tag
   _str search_file_name  = cm.file_name;
   _str search_type_name  = cm.type_name;
   _str search_class_name = cm.class_name;
   _str search_arguments  = '';//VS_TAGSEPARATOR_args:+cm.arguments;
   if (_QBinaryLoadTagsSupported(search_file_name)) {
      cm.language='java';
      search_file_name='';
   }
   VS_TAG_BROWSE_INFO jar_cm;
   jar_cm=cm;
   jar_cm.member_name='';
   typeless tag_files=tags_filenamea(cm.language);
   i=0;
   _str tag_filename=next_tag_filea(tag_files,i,false,true);
   while (tag_filename != '') {
      // search for exact match
      _str alt_type_name = search_type_name;
      //say("member="cm.member_name" type="search_type_name" class="cm.class_name" args="cm.arguments" file="search_file_name);
      status = tag_find_tag(cm.member_name, search_type_name, search_class_name, search_arguments);
      if (status < 0) {
         if (search_type_name :== 'class') {
            alt_type_name = 'interface';
            status = tag_find_tag(cm.member_name, alt_type_name, search_class_name, search_arguments);
         } else if (search_type_name :== 'func') {
            alt_type_name = 'proto';
            status = tag_find_tag(cm.member_name, alt_type_name, search_class_name, search_arguments);
         } else if (search_type_name :== 'proc') {
            alt_type_name = 'procproto';
            status = tag_find_tag(cm.member_name, alt_type_name, search_class_name, search_arguments);
         }
      }
      while (status == 0) {

         // get basic information for this tag, check type and class
         typeless dm;
         tag_get_info(dm, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
         if (cm.type_name :!= search_type_name && cm.type_name != alt_type_name) {
            break;
         }
         //if (cm.class_name :!= search_class_name) {
         //   break;
         //}
         // file name matches, then we've found our perfect match!!!
         if (search_file_name == '' || file_eq(search_file_name, cm.file_name)) {

            // check if there is a load-tags function, if so, bail out
            //say("get_reference_tag_info: cm.file="cm.file_name);
            //say("get_reference_tag_info: cm.search="search_file_name);
            if (_QBinaryLoadTagsSupported(cm.file_name)) {
               jar_cm=cm;
            } else {
               tag_reset_find_tag();
               cm.tag_database=tag_filename;
               return 1;
            }
         }
         // get next tag
         status = tag_next_equal(1 /*case sensitive*/);
      }
      tag_reset_find_tag();

      // try the next tag file
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }
   if (jar_cm.member_name != '') {
      cm = jar_cm;
      return 1;
   }

   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the call tree view, recursively, this is for when
// the filter flags are changed.
//
static void cb_refresh_calltree_recursive(int index=TREE_ROOT_INDEX)
{
   // check if they hit 'cancel'
   if (cancel_form_cancelled()) {
      return;
   }

   // make sure the root index is adjusted to be the symbol name
   if (index <= TREE_ROOT_INDEX) {
      index = callTreeRootIndex();
   }

   //say("cb_refresh_calltree_recursive: index="index);
   // for each child of this node, go recursive
   int i = _TreeGetFirstChildIndex(index);
   while (i > 0) {
      int show_children=0;
      _TreeGetInfo(i,show_children);
      if (show_children == TREE_NODE_EXPANDED) {
         cb_refresh_calltree_recursive(i);
      }
      i = _TreeGetNextSiblingIndex(i);
   }

   // now do this node
   call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
}

//////////////////////////////////////////////////////////////////////////////
// Refresh the item properities with the given tag information
// Sets all the controls with the appropriate values, and puts the
// member name(type_name) in the caption for the dialog.
//
void cb_refresh_calltree_view(struct VS_TAG_BROWSE_INFO cm)
{
   // get the properties dialog window ID
   int f = gcbcalls_wid;
   if (!f) {
      return;
   }
   _nocheck _control ctl_call_tree_view;

   // just refresh the existing view, recursively, if cm==null
   if (cm==null) {

      int cancel_wid=show_cancel_form("Updating Call Tree...");
      f.ctl_call_tree_view.p_redraw=0;
      f.ctl_call_tree_view.cb_refresh_calltree_recursive();
      f.ctl_call_tree_view.p_redraw=1;
      if (!cancel_form_cancelled()) {
         close_cancel_form(cancel_wid);
      }
      return;
   }

   // bail out if we have no member name
   if (!VF_IS_STRUCT(cm) || cm.member_name=='') {
      return;
   }

   // same call tree as last time?
   struct VS_TAG_BROWSE_INFO cm2=f.ctl_help_button.p_user;
   if (tag_browse_info_equal(cm,cm2)) {
      return;
   }
   f.ctl_help_button.p_user=cm;

   // make sure that cm is totally initialized
   if (cm.tag_database._isempty())   cm.tag_database = '';
   if (cm.category._isempty())       cm.category = '';
   if (cm.class_name._isempty())     cm.class_name = '';
   if (cm.member_name._isempty())    cm.member_name = '';
   if (cm.qualified_name._isempty()) cm.qualified_name = '';
   if (cm.type_name._isempty())      cm.type_name = '';
   if (cm.file_name._isempty())      cm.file_name = '';
   if (cm.return_type._isempty())    cm.return_type = '';
   if (cm.arguments._isempty())      cm.arguments = '';
   if (cm.exceptions._isempty())     cm.exceptions = '';
   if (cm.class_parents._isempty())  cm.class_parents = '';
   if (cm.template_args._isempty())  cm.template_args = '';

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      return;
   }

   // strings for filling in the many text boxes
   _str item_name;
   _str file_name;
   _str caption;

   // construct the item caption
   item_name = tag_tree_make_caption(cm.member_name, cm.type_name, cm.class_name, cm.flags, '', false);

   // refresh the call tree view
   //if (!tag_tree_type_is_func(cm.type_name) || cm.member_name == '') {
   if (cm.member_name == '') {
      f.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      f.ctl_call_tree_view._TreeAddItem(TREE_ROOT_INDEX, "No function selected", TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      return;
   }

   // construct the item caption
   item_name = tag_tree_make_caption(cm.member_name, cm.type_name, cm.class_name, cm.flags, cm.arguments, true);

   _str ref_database = refs_filename();
   int enable_refs = (ref_database == '')? 0:1;
   int inst_id=0;

   // open the tag database for business
   int status;
   _str orig_database = tag_current_db();
   if (ref_database == '') {
      //f.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
      //return;
   } else {
      status = tag_read_db(ref_database);
      if ( status < 0 ) {
         f.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         return;
      }

      // match tag up with instance in refernces database
      inst_id = tag_match_instance(cm.member_name, cm.type_name, 0, cm.class_name, cm.arguments, cm.file_name, cm.line_no, 1);
      //say("member_name="cm.member_name" class="cm.class_name" type="cm.type_name" args="cm.arguments" file="cm.file_name" inst_id="inst_id);

      // close the references database and
      // revert back to the original tag database
      status = tag_close_db(ref_database,1);
      int s2=tag_read_db(orig_database);
      if ( status < 0 ) {
         f.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');
         return;
      }
   }

   // compute name / line number string for sorting
   _str ucm = cb_create_reference_info(cm.file_name, cm.line_no, inst_id, cm.tag_database);

   // clear out the call tree
   f.ctl_call_tree_view._TreeDelete(TREE_ROOT_INDEX, 'c');

   // find the bitmap for this item
   int i_access,i_type;
   tag_tree_filter_member2(0xffffffff,0xffffffff,cm.type_name,(cm.class_name=='')?0:1,cm.flags,i_access,i_type);
   int pic_ref = gi_pic_access_type[i_access][i_type];

   // set up root function
   _str rpart;
   treeRoot := f.ctl_call_tree_view._TreeAddItem(TREE_ROOT_INDEX, item_name, TREE_ADD_AS_CHILD, pic_ref, pic_ref, TREE_NODE_COLLAPSED, 0, ucm);
   f.ctl_call_tree_view._TreeSizeColumnToContents(0);
   //say("cb_refresh_calltree_view: item_name="item_name);

   // look up and insert the items called
   f.ctl_call_tree_view._TreeSetInfo(treeRoot, TREE_NODE_EXPANDED);
   f.ctl_call_tree_view.call_event(CHANGE_EXPANDED,treeRoot,f.ctl_call_tree_view,ON_CHANGE,'w');
}

//////////////////////////////////////////////////////////////////////////////
// On form creation, get argument, and pass to refresh, cache window ID.
//
void ctl_ok_button.on_create(struct VS_TAG_BROWSE_INFO cm=null)
{
   gcbcalls_wid=p_active_form;

   ctl_call_tree_view.p_user = _retrieve_value("_tbprops_form.ctl_call_tree_view.p_user");
   if (ctl_call_tree_view.p_user == "") {
      ctl_call_tree_view.p_user = 0xffffffff;
   }

   // if we were passed a tag argument, display its properties
   if (cm != null) {
      cb_refresh_calltree_view(cm);
      ctl_call_tree_view._TreeTop();
   }
}

//////////////////////////////////////////////////////////////////////////////
// On destroy, blow away the cached window ID
//
void ctl_ok_button.on_destroy()
{
   _append_retrieve(0, ctl_call_tree_view.p_user, "_tbprops_form.ctl_call_tree_view.p_user");
   gcbcalls_wid=0;
   call_event(p_window_id,ON_DESTROY,'2');
}

//////////////////////////////////////////////////////////////////////////////
// expand all items at all depths of the call tree
//
void ctl_expand_button.lbutton_up()
{
   boolean been_there_done_that:[]; 
   been_there_done_that._makeempty();
   int form_wid = p_active_form;
   int cancel_wid=show_cancel_form("Expanding Call Tree...");
   activate_window(form_wid);
   ctl_call_tree_view.p_redraw=false;
   int cur_index = ctl_call_tree_view._TreeCurIndex();
   ctl_call_tree_view.cb_expand_call_tree(cur_index,been_there_done_that);
   if (!cancel_form_cancelled()) {
      close_cancel_form(cancel_wid);
   }
   activate_window(form_wid);
   ctl_call_tree_view._TreeSetCurIndex(cur_index);
   ctl_call_tree_view.p_redraw=true;
   ctl_call_tree_view._TreeRefresh();
}
static int cb_expand_call_tree(int index, 
                               boolean (&been_there_done_that):[],
                               int depth=0)
{
   // check if they hit 'cancel'
   if (cancel_form_cancelled()) {
      return COMMAND_CANCELLED_RC;
   }

   // do not expand beyond 10 levels deep
   if (depth > 8) {
      return 0;
   }

   // return if it is a leaf node
   int show_children=0;
   _TreeGetInfo(index,show_children);
   if (show_children == TREE_NODE_LEAF) {
      return 0;
   }

   // already expanded this item?
   _str caption = _TreeGetCaption(index);
   if (been_there_done_that._indexin(caption)) {
      return 0;
   }
   been_there_done_that:[caption]=true;

   // do not expand classes, interfaces, structs, and package names
   struct VS_TAG_BROWSE_INFO cm;
   int inst_id;
   if (depth > 0 && get_reference_tag_info(index, cm, inst_id)) {
      // do not expand package names
      if (tag_tree_type_is_package(cm.type_name)) {
         //say("cb_expand_call_tree: skip package");
         return 0;
      }
      // expand class names only if the outer item was a class
      if (tag_tree_type_is_class(cm.type_name) || cm.type_name == "enum") {
         parentIndex := _TreeGetParentIndex(index);
         if (parentIndex > 0 && get_reference_tag_info(parentIndex, cm, inst_id)) {
            if (!tag_tree_type_is_class(cm.type_name) && cm.type_name!="enum" ) {
               //say("cb_expand_call_tree: skip class");
               return 0;
            }
         }
      }
   }

   // expand node if it is not already expanded
   if (show_children == TREE_NODE_COLLAPSED) {
      call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
      _TreeSetInfo(index, TREE_NODE_EXPANDED);
   }

   // ok, now expand all the children nodes
   index=_TreeGetFirstChildIndex(index);
   while (index > 0) {
      if (cb_expand_call_tree(index,been_there_done_that,depth+1) < 0) {
         break;
      }
      index=_TreeGetNextSiblingIndex(index);
   }

   // success
   return 0;
}

//////////////////////////////////////////////////////////////////////////////
// handle resize event
//
void _cbcalls_form.on_resize()
{
   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok_button.p_width;
   int button_height = ctl_ok_button.p_height;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*4, button_height*3);
   }

   // available space and border usage
   int avail_x, avail_y, border_x, border_y;
   avail_x  = p_width;
   avail_y  = p_height;
   border_x = ctl_call_tree_view.p_x;
   border_y = ctl_call_tree_view.p_y;

   // size the tree controls
   ctl_call_tree_view.p_width  = avail_x-border_x;
   ctl_call_tree_view.p_height = avail_y-border_y*3 - button_height;

   // move around the buttons
   int button_y = avail_y - button_height - border_y;
   ctl_ok_button.p_y     = button_y;
   ctl_expand_button.p_y = button_y;
   ctl_help_button.p_y   = button_y;
   ctl_help_button.p_x   = avail_x - button_width - border_x;
}

//////////////////////////////////////////////////////////////////////////////
// Handle right-mouse button on the tag references tree control
//
void ctl_call_tree_view.rbutton_up()
{
   int f = gcbcalls_wid;
   if (!f) return;

   // kill the refresh timer, prevents delays before the menu comes
   // while the refreshes are finishing up.
   cb_kill_timer();

   int index=find_index("_tagbookmark_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');

   int flags=f.ctl_call_tree_view.p_user;
   pushTgConfigureMenu(menu_handle, flags, false, false, false, true);

   // Show menu:
   int x,y;
   mou_get_xy(x,y);
   _KillToolButtonTimer();
   _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

//////////////////////////////////////////////////////////////////////////////
// Handle double-click event (opens the file and positions us on the
// line indicated by the reference data), this may or may not be the
// right line to be positioned on.
//
void ctl_call_tree_view.enter,lbutton_double_click()
{
   // get the context information, push book mark, and open file to line
   struct VS_TAG_BROWSE_INFO cm;
   int inst_id;
   if (ctl_call_tree_view.get_reference_tag_info(ctl_call_tree_view._TreeCurIndex(), cm, inst_id)) {
      push_pos_in_file(cm.file_name, cm.line_no, 0);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Handle double-click event (opens the file and positions us on the
// line indicated by the reference data), this may or may not be the
// right line to be positioned on.
//
void ctl_call_tree_view.' '()
{
   // IF this is an item we can go to like a class name
   int orig_window_id = p_window_id;

   // get the context information, push book mark, and open file to line
   struct VS_TAG_BROWSE_INFO cm;
   int inst_id;
   if (ctl_call_tree_view.get_reference_tag_info(ctl_call_tree_view._TreeCurIndex(), cm, inst_id)) {
      push_pos_in_file(cm.file_name, cm.line_no, 0);
   }

   // restore original focus
   p_window_id = orig_window_id;
   ctl_call_tree_view._set_focus();
}

//////////////////////////////////////////////////////////////////////////////
// This is the timer callback.  Whenever the current index (cursor position)
// for the reference tree is changed, a timer is started/reset.  If no
// activity occurs within a set amount of time, this function is called to
// update the properties view, inheritance view, and output window.
//
static void _CallTreeTimerCallback()
{
   // kill the timer
   cb_kill_timer();

   int f = gcbcalls_wid;
   if (!f) {
      return;
   }
   _nocheck _control ctl_call_tree_view;

   // get the current tree index
   int currIndex = f.ctl_call_tree_view._TreeCurIndex();
   if (currIndex<0) {
      return;
   }

   // get the context information, push book mark, and open file to line
   struct VS_TAG_BROWSE_INFO cm;
   int inst_id;
   if (f.ctl_call_tree_view.get_reference_tag_info(currIndex, cm, inst_id)) {
      // find the output tagwin and update it
      cb_refresh_output_tab(cm, true);
      //// find the output references tab and update it
      //refresh_references_tab(cm);
   } else {
      f.ctl_call_tree_view.message_cannot_find_ref(currIndex);
   }
}
static void _CallTreeHighlightCallback(int index=-1)
{
   // kill the timer
   cb_kill_timer();

   int f = gcbcalls_wid;
   if (!f) {
      return;
   }
   _nocheck _control ctl_call_tree_view;

   // get the current tree index
   if (index <= 0) {
      return;
   }

   // get the context information, push book mark, and open file to line
   struct VS_TAG_BROWSE_INFO cm;
   int inst_id;
   if (f.ctl_call_tree_view.get_reference_tag_info(index, cm, inst_id)) {
      // find the output tagwin and update it
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}


static int cb_add_file_uses(_str file_name,
                            _str alt_file_name, int alt_line_no,
                            struct VS_TAG_BROWSE_INFO &cm, int flag_mask,
                            int tree_index, int &num_refs, int max_refs,
                            int start_seekpos=0, int end_seekpos=0)
{
   //say("cb_add_file_uses: here");
   //say("cb_add_file_uses("file_name","alt_file_name","alt_line_no","cm.file_name","cm.line_no);
   //say("cb_add_file_uses("file_name","alt_file_name","alt_line_no","cm.file_name","cm.line_no","cm.seekpos")");
   // open a temporary view of 'file_name'
   int tree_wid=p_window_id;
   int temp_view_id,orig_view_id;
   boolean inmem=false;
   int status=_open_temp_view(file_name,temp_view_id,orig_view_id,'',inmem,false,true);
   if (!status) {

      // delegate the bulk of the work
      _UpdateContext(true);

      // go to where the tag should be at
      p_RLine=cm.line_no;
      if (cm.seekpos != null && cm.seekpos > 0) {
         _GoToROffset(cm.seekpos);
         start_seekpos = cm.seekpos;
         end_seekpos   = cm.end_seekpos;
      } else {
         cm.seekpos=(int)_QROffset();
      }

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      //say("cb_add_file_uses: cm.member_name="cm.member_name);
      _str proc_name,type_name,class_name;
      _str signature,return_type;
      int start_line_no;
      int scope_line_no,scope_seekpos;
      int end_line_no;
      int tag_flags;
      case_sensitive := p_EmbeddedCaseSensitive;
      int context_id = tag_find_context_iterator(cm.member_name,true,case_sensitive);
      while (context_id > 0) {
         tag_get_context(context_id,proc_name,type_name,file_name,
                         start_line_no,start_seekpos,
                         scope_line_no,scope_seekpos,
                         end_line_no,end_seekpos,
                         class_name,tag_flags,signature,return_type);
         if (cm.line_no == start_line_no) {
            break;
         }
         context_id = tag_next_context_iterator(cm.member_name,context_id,true,case_sensitive);
      }

      _str errorArgs[]; errorArgs._makeempty();

      //say("tag_match_uses_in_file(,"tree_wid","tree_index","p_LangCaseSensitive","file_name","start_line_no","alt_file_name","alt_line_no","flag_mask","context_id","start_seekpos","end_seekpos","num_refs","max_refs")");
      status = tag_match_uses_in_file(errorArgs,tree_wid,tree_index,
                                      case_sensitive,file_name,start_line_no,
                                      alt_file_name,alt_line_no,flag_mask,
                                      context_id, start_seekpos, end_seekpos,
                                      num_refs,max_refs);
      tree_wid._TreeSizeColumnToContents(0);

      // close the temporary view
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
   }

   //say("cb_add_file_uses: status="status);
   // that's all folks
   return status;
}


//////////////////////////////////////////////////////////////////////////////
// Insert items called or used by the given tag (tag_id) into the given tree.
// Opens the given database.  Returns the number of items inserted.
// p_window_id must be the call tree control.
//
static int cb_add_uses(int i, struct VS_TAG_BROWSE_INFO cm, int context_id)
{
   // map prototype to proc/func/constr/destr
   int status = 0;
   _str orig_file_name=cm.file_name;
   _str alt_file_name=cm.file_name;
   int  alt_line_no=cm.line_no;
   if (cm.tag_database != '') {
      status = tag_read_db(cm.tag_database);
      if ( status < 0 ) {
         return 0;
      }
      maybe_convert_proto_to_proc(cm);
   }

   //say("cb_add_uses: i="i" member="cm.member_name);
   // compute best width to use for first tab
   // get filtering flags for call tree
   treeRoot := callTreeRootIndex();
   cb_prepare_expand(p_active_form,p_window_id,treeRoot);
   int flag_mask = p_user;
   int count = 0;

   // open the tag database for business
   boolean tag_database=false;
   _str ref_database = refs_filename();
   _str tag_files[]; tag_files._makeempty();
   if (ref_database != '') {
      tag_files._makeempty();
      tag_files[0]=ref_database;
   } else {
      tag_database=true;
      if (cm.language==null || cm.language=='') {
         cm.language=_Filename2LangId(cm.file_name);
         if (cm.language=='jar' || cm.language=='zip') {
            cm.language='java';
         }
      }
      tag_files = tags_filenamea(cm.language);
   }

   if (tag_database) {

      // save the current buffer state
      //say("cb_add_uses: BEFORE, num context="tag_get_num_of_context());
      _str orig_context_file='';
      tag_get_detail2(VS_TAGDETAIL_current_file,0,orig_context_file);
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_push_context();
      int orig_use_timers=_use_timers;
      _use_timers=0;

      // this case doesn't use the database at all
      //say("cb_add_uses: cm.file_name="cm.file_name);
      cb_add_file_uses(cm.file_name,alt_file_name,alt_line_no,cm,flag_mask,i,count,def_cb_max_references);

      // force an update of the previous context
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_pop_context();
#if 0
      if (orig_context_file != '') {
         // open a temporary view of 'orig_context_file'
         int orig_window_id = p_window_id;
         int temp_view_id,orig_view_id;
         int status=_open_temp_view(orig_context_file,temp_view_id,orig_view_id,'+b');
         if (!status) {
            // delegate the bulk of the work
            _UpdateContext(true);
            p_ModifyFlags &= ~MODIFYFLAG_LOCALS_UPDATED;
            p_buf_flags&=~VSBUFFLAG_HIDDEN;
            _delete_window();
            p_window_id=orig_view_id;
         }
         p_window_id=orig_window_id;
      }
#endif
      _use_timers=orig_use_timers;

      // return total number of items inserted
      _TreeRefresh();
      return count;
   }

   int inst_id;
   int ref_type;
   _str file_name,arguments;
   _str member_name,type_name,class_name;
   int line_no,flags;
   _str caption,lcaption,fcaption;
   if (context_id > 0) {
      // for each BSC file to consider
      int t=0;
      ref_database=next_tag_filea(tag_files,t,false,true);
      while (ref_database != '') {

         //say("cb_add_refs: db="ref_database);
         status = tag_read_db(ref_database);
         if ( status < 0 ) {
            break;
         }

         // find references to this instance
         inst_id = tag_find_refer_by(context_id, ref_type, file_name, line_no);

         //say("context_id="context_id" member_name="cm.member_name" class_name="cm.class_name" arguments="cm.arguments);
         count = 0;
         while (count < def_cb_max_references && inst_id >= -1) {

            // if something is going on, get out of here
            if( count % 20 == 0 && _IsKeyPending(false) ) {
               break;
            }

            // full path of file and and line number
            if (line_no != 0) {
               lcaption = file_name ': ' line_no;
            } else {
               lcaption = file_name;
            }

            // compute name / line number string for sorting
            int pic_ref;
            _str ucaption = cb_create_reference_info(file_name, line_no, inst_id, ref_database);

            // by default, insert as a leaf node
            int show_children = TREE_NODE_LEAF;

            // find the context and create caption and icon for it
            if (inst_id > 0) {

               // get details about this tag (for creating caption)
               tag_get_instance_info(inst_id, member_name, type_name, flags, class_name, arguments, file_name, line_no);
               //_message_box("inst_id="inst_id" member_name="member_name" type_name="type_name" class_name="class_name" arguments="arguments" file_name="file_name" line_no="line_no);
            }

            if (inst_id > 0 && member_name != '') {
               // check if this item should be skipped
               if (!tag_filter_type(0,flag_mask,type_name,flags)) {
                  inst_id = tag_next_refer_by(context_id, ref_type, file_name, line_no);
                  continue;
               }

               // create caption for this item
               fcaption = tag_tree_make_caption(member_name, type_name, class_name, flags, '', true);

               // function/data, access restrictions and type code for picture selection
               int i_type, i_access;
               tag_tree_filter_member2(0, 0, type_name, ((class_name!='')? 1:0), flags, i_access, i_type);

               // get the appropriate bitmap
               pic_ref = gi_pic_access_type[i_access][i_type];
               if (i_type >= CB_type_struct || i_type==CB_type_function) {
                  if (i_type != CB_type_destr_proto && 
                      i_type != CB_type_constr_proto &&
                      i_type != CB_type_operator_proto) {
                     show_children=TREE_NODE_COLLAPSED;
                  }
               }
            } else {
               // reference is outside of this tag file, just display filename, line_no
               fcaption = _strip_filename(file_name, 'P');
               pic_ref = _pic_file12;
            }

            // compute name / line number string for sorting
            ucaption = cb_create_reference_info(file_name, line_no, inst_id, ref_database);

            // insert the item and set the user info
            int j = _TreeAddItem(i,fcaption,TREE_ADD_AS_CHILD,pic_ref,pic_ref,show_children,0,ucaption);
            if (j < 0) {
               break;
            }
            ++count;

            // next, please
            inst_id = tag_next_refer_by(context_id, ref_type, file_name, line_no);
         }

         // close the references database
         status = tag_close_db(ref_database,1);
         if ( status ) {
            return 0;
         }
         ref_database=next_tag_filea(tag_files,t,false,true);
      }
   }

   // set the column width
   _TreeSizeColumnToContents(0);
   _TreeRefresh();

   // return total number of items inserted
   return count;
}

//////////////////////////////////////////////////////////////////////////////
// Handle on-change event for member list (a tree control) in inheritance
// tree dialog.  The only event handled is CHANGE_LEAF_ENTER, for which
// we utilize push_tag_in_file to push a bookmark and bring up the code in
// the editor.
//
void ctl_call_tree_view.on_change(int reason,int currIndex)
{
   if (currIndex < 0) return;
   //say("ctl_call_tree_view.on_change: reason="reason" index="currIndex" depth="_TreeGetDepth(currIndex));
   int inst_id;
   _str caption;
   if (reason == CHANGE_LEAF_ENTER) {
      // get the context information, push book mark, and open file to line
      struct VS_TAG_BROWSE_INFO cm;
      if (ctl_call_tree_view.get_reference_tag_info(currIndex, cm, inst_id)) {
         push_pos_in_file(cm.file_name, cm.line_no, 0);
      } else {
         caption = _TreeGetCaption(currIndex);
         parse caption with caption "\t" .;
         message("Could not find tag: " caption);
      }
   } else if (reason == CHANGE_EXPANDED) {

      se.util.MousePointerGuard hour_glass;
      struct VS_TAG_BROWSE_INFO cm;
      if (ctl_call_tree_view.get_reference_tag_info(currIndex, cm, inst_id)) {
         //if (inst_id > 0) {

            //if (currIndex == treeRoot) {
            //   ctl_call_tree_view._TreeDelete(currIndex, 'c');
            //}

            // insert the items we reference into the call tree
            ctl_call_tree_view._TreeBeginUpdate(currIndex);
            int count = ctl_call_tree_view.cb_add_uses(currIndex, cm, inst_id);
            ctl_call_tree_view._TreeEndUpdate(currIndex);

            // sort exactly the way we want things
            ctl_call_tree_view._TreeSortUserInfo(currIndex,'UE','E');
            ctl_call_tree_view._TreeSortCaption(currIndex,'I');
         //}
      }
   } else if (reason == CHANGE_COLLAPSED) {
      ctl_call_tree_view._TreeDelete(currIndex,'c');
   } else if (reason == CHANGE_SELECTED) {
      if (_get_focus() == ctl_call_tree_view) {

         // kill the existing timer and start a new one
         cb_kill_timer();
         cb_start_timer(_CallTreeTimerCallback);
      }
   }
}
void ctl_call_tree_view.on_highlight(int index, _str caption="")
{
   //say("ctl_call_tree_view.on_highlight: index="index" caption="caption);
   cb_kill_timer();
   if (index < 0 || !def_tag_hover_preview) {
      _UpdateTagWindowDelayed(null,0);
      return;
   }
   cb_start_timer(_CallTreeHighlightCallback, index, def_tag_hover_delay);
}


//////////////////////////////////////////////////////////////////////////////
// Update other views when viewer gets focus, important because
// inheritance view, call tree, and props can also update the output
// view, so if they return focus to the symbol browser, we need to
// restart the update timer.
//
void ctl_call_tree_view.on_got_focus()
{
   // kill the existing timer and start a new one
   cb_kill_timer();
   cb_start_timer(_CallTreeTimerCallback);
}

//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Handlers for item properties dialog
//
defeventtab _tbprops_form;

//////////////////////////////////////////////////////////////////////////////
// Refresh the item properities with the given tag information
// Sets all the controls with the appropriate values, and puts the
// member name(type_name) in the caption for the dialog.
//
void cb_refresh_property_view(struct VS_TAG_BROWSE_INFO cm)
{
   //say("cb_refresh_property_view: here 1");
   // bail out if we have no member name
   if (cm.member_name._isempty() || cm.member_name == '') {
      return;
   }

   // get the properties dialog window ID
   int f = _GetCBrowserPropsWID();
   if (!f || !_iswindow_valid(f) || f.p_name!="_tbprops_form") {
      return;
   }

   _nocheck _control ctl_props_sstab;
   _nocheck _control ctl_proto_check_box;
   _nocheck _control ctl_const_check_box;
   _nocheck _control ctl_final_check_box;
   _nocheck _control ctl_inline_check_box;
   _nocheck _control ctl_static_check_box;
   _nocheck _control ctl_virtual_check_box;
   _nocheck _control ctl_abstract_check_box;
   _nocheck _control ctl_access_check_box;
   _nocheck _control ctl_volatile_check_box;
   _nocheck _control ctl_extern_check_box;
   _nocheck _control ctl_native_check_box;
   _nocheck _control ctl_file_text_box;
   _nocheck _control ctl_name_text_box;
   _nocheck _control ctl_aname_text_box;
   _nocheck _control ctl_type_text_box;
   _nocheck _control ctl_template_list_box;
   _nocheck _control ctl_args_list_box;
   _nocheck _control ctl_args_label;
   _nocheck _control ctl_type_label;
   _nocheck _control ctl_template_label;
   _nocheck _control ctl_template_check_box;
   _nocheck _control ctl_synchronized_check_box;
   _nocheck _control ctl_transient_check_box;
   _nocheck _control ctl_mutable_check_box;
   _nocheck _control ctl_partial_check_box;
   _nocheck _control ctl_forward_check_box;

   // make sure that cm is totally initialized
   if (cm.tag_database._isempty())   cm.tag_database = '';
   if (cm.category._isempty())       cm.category = '';
   if (cm.class_name._isempty())     cm.class_name = '';
   if (cm.member_name._isempty())    cm.member_name = '';
   if (cm.qualified_name._isempty()) cm.qualified_name = '';
   if (cm.type_name._isempty())      cm.type_name = '';
   if (cm.file_name._isempty())      cm.file_name = '';
   if (cm.return_type._isempty())    cm.return_type = '';
   if (cm.arguments._isempty())      cm.arguments = '';
   if (cm.exceptions._isempty())     cm.exceptions = '';
   if (cm.class_parents._isempty())  cm.class_parents = '';
   if (cm.template_args._isempty())  cm.template_args = '';

   // construct string containing all tag information
   _str cm_string =     "" :+
      cm.tag_database   :+ "\t" :+
      cm.category       :+ "\t" :+
      cm.class_name     :+ "\t" :+
      cm.member_name    :+ "\t" :+
      cm.qualified_name :+ "\t" :+
      cm.type_name      :+ "\t" :+
      cm.file_name      :+ "\t" :+
      cm.line_no        :+ "\t" :+
      cm.flags          :+ "\t" :+
      cm.return_type    :+ "\t" :+
      cm.arguments      :+ "\t" :+
      cm.exceptions     :+ "\t" :+
      cm.class_parents  :+ "\t" :+
      cm.template_args;

   // blow out of here if tag has not changed
   _str ucm = f.ctl_name_text_box.p_user;
   if (!ucm._isempty() && ucm._varformat()==VF_LSTR && ucm:==cm_string) {
      return;
   }

   // save tag browse info
   f.ctl_name_text_box.p_user = cm_string;

   // strings for filling in the many text boxes
   _str item_name;
   _str file_name;
   _str caption;

   // construct the item caption
   item_name = tag_tree_make_caption(cm.member_name, cm.type_name, cm.class_name, cm.flags, '', false);

   // enable/disable declarations, depending if they are relevent or not
   if (cm.class_name != '' && cm.member_name != '' && cm.type_name :!= 'enumc' && cm.type_name :!= 'typedef' && cm.type_name :!= 'database' && cm.type_name :!='table' && cm.type_name :!= 'column' && cm.type_name :!= 'view' && cm.type_name :!= 'index') {
      f.ctl_const_check_box.p_enabled        = 1;
      f.ctl_static_check_box.p_enabled       = 1;
      f.ctl_final_check_box.p_enabled        = 1;
      f.ctl_access_check_box.p_enabled       = 1;
      f.ctl_volatile_check_box.p_enabled     = 1;
      f.ctl_synchronized_check_box.p_enabled = 1;
      f.ctl_transient_check_box.p_enabled    = 1;
      f.ctl_mutable_check_box.p_enabled      = 1;
   } else {
      f.ctl_const_check_box.p_enabled        = 0;
      f.ctl_static_check_box.p_enabled       = 0;
      f.ctl_final_check_box.p_enabled        = 0;
      f.ctl_volatile_check_box.p_enabled     = 0;
      f.ctl_access_check_box.p_enabled       = 0;
      f.ctl_synchronized_check_box.p_enabled = 0;
      f.ctl_transient_check_box.p_enabled    = 0;
      f.ctl_mutable_check_box.p_enabled      = 0;
   }

   // enable/disable other check-boxes, depending on type of tag
   switch (cm.type_name) {
   case 'proc':
   case 'procproto':
   case 'proto':
   case 'func':
   case 'destr':
   case 'constr':
      f.ctl_inline_check_box.p_enabled   = 1;
      f.ctl_proto_check_box.p_enabled    = 1;
      f.ctl_volatile_check_box.p_enabled = 1;
      f.ctl_const_check_box.p_enabled    = 1;
      f.ctl_static_check_box.p_enabled   = 1;
      f.ctl_final_check_box.p_enabled    = 1;
      f.ctl_mutable_check_box.p_enabled  = 0;
      f.ctl_partial_check_box.p_enabled  = 0;
      f.ctl_forward_check_box.p_enabled  = 0;
      if (cm.class_name == '') {
         f.ctl_abstract_check_box.p_enabled = 0;
         f.ctl_virtual_check_box.p_enabled  = 0;
      } else {
         f.ctl_virtual_check_box.p_enabled  = 1;
         f.ctl_abstract_check_box.p_enabled = 1;
      }
      f.ctl_template_check_box.p_enabled     = 1;
      f.ctl_synchronized_check_box.p_enabled = 1;
      f.ctl_transient_check_box.p_enabled    = 0;
      f.ctl_extern_check_box.p_enabled   = 1;
      f.ctl_native_check_box.p_enabled   = 1;
      break;
   case 'var':
   case 'gvar':
   case 'lvar':
   case 'param':
   case 'prop':
      f.ctl_static_check_box.p_enabled   = 1;
      f.ctl_const_check_box.p_enabled    = 1;
      f.ctl_final_check_box.p_enabled    = 1;
      f.ctl_volatile_check_box.p_enabled = 1;
      f.ctl_inline_check_box.p_enabled   = 0;
      f.ctl_proto_check_box.p_enabled    = 0;
      f.ctl_abstract_check_box.p_enabled = 0;
      f.ctl_virtual_check_box.p_enabled  = 0;
      f.ctl_template_check_box.p_enabled = 1;
      f.ctl_synchronized_check_box.p_enabled = 1;
      f.ctl_transient_check_box.p_enabled = 1;
      f.ctl_extern_check_box.p_enabled   = 1;
      f.ctl_native_check_box.p_enabled   = 0;
      f.ctl_mutable_check_box.p_enabled  = 1;
      f.ctl_partial_check_box.p_enabled  = 0;
      f.ctl_forward_check_box.p_enabled  = 0;
      break;
   case 'class':
   case 'struct':
      f.ctl_final_check_box.p_enabled    = 1;
   case 'interface':
      f.ctl_inline_check_box.p_enabled   = 0;
      f.ctl_virtual_check_box.p_enabled  = 0;
      f.ctl_proto_check_box.p_enabled    = 0;
      f.ctl_abstract_check_box.p_enabled = 1;
      f.ctl_volatile_check_box.p_enabled = 0;
      f.ctl_template_check_box.p_enabled = 1;
      f.ctl_synchronized_check_box.p_enabled = 0;
      f.ctl_transient_check_box.p_enabled = 0;
      f.ctl_extern_check_box.p_enabled   = 1;
      f.ctl_native_check_box.p_enabled   = 1;
      f.ctl_partial_check_box.p_enabled  = 1;
      f.ctl_forward_check_box.p_enabled  = 1;
      break;
   case 'tag':
      f.ctl_final_check_box.p_enabled    = 1;
      f.ctl_inline_check_box.p_enabled   = 0;
      f.ctl_virtual_check_box.p_enabled  = 0;
      f.ctl_proto_check_box.p_enabled    = 0;
      f.ctl_abstract_check_box.p_enabled = 0;
      f.ctl_volatile_check_box.p_enabled = 0;
      f.ctl_template_check_box.p_enabled = 0;
      f.ctl_synchronized_check_box.p_enabled = 0;
      f.ctl_transient_check_box.p_enabled = 0;
      f.ctl_extern_check_box.p_enabled   = 0;
      f.ctl_native_check_box.p_enabled   = 0;
      break;
   case 'import':
      f.ctl_static_check_box.p_enabled   = 1;
      f.ctl_inline_check_box.p_enabled   = 0;
      f.ctl_virtual_check_box.p_enabled  = 0;
      f.ctl_proto_check_box.p_enabled    = 0;
      f.ctl_abstract_check_box.p_enabled = 0;
      f.ctl_volatile_check_box.p_enabled = 0;
      f.ctl_template_check_box.p_enabled = 0;
      f.ctl_synchronized_check_box.p_enabled = 0;
      f.ctl_transient_check_box.p_enabled = 0;
      f.ctl_extern_check_box.p_enabled   = 0;
      f.ctl_native_check_box.p_enabled   = 0;
      break;
   default:
      f.ctl_inline_check_box.p_enabled   = 0;
      f.ctl_virtual_check_box.p_enabled  = 0;
      f.ctl_proto_check_box.p_enabled    = 0;
      f.ctl_abstract_check_box.p_enabled = 0;
      f.ctl_volatile_check_box.p_enabled = 0;
      f.ctl_template_check_box.p_enabled = 0;
      f.ctl_synchronized_check_box.p_enabled = 0;
      f.ctl_transient_check_box.p_enabled = 0;
      f.ctl_extern_check_box.p_enabled   = 0;
      f.ctl_native_check_box.p_enabled   = 0;
      break;
   }

   // append line number to file name
   file_name = cm.file_name ':' cm.line_no;

   // set the text controls, have to toggle p_ReadOnly to do this
   f.ctl_name_text_box.p_ReadOnly = 0;
   f.ctl_file_text_box.p_ReadOnly = 0;
   f.ctl_type_text_box.p_ReadOnly = 0;
   f.ctl_aname_text_box.p_ReadOnly = 0;
   f.ctl_name_text_box._begin_line();
   f.ctl_file_text_box._begin_line();
   f.ctl_type_text_box._begin_line();
   f.ctl_aname_text_box._begin_line();
   if (cm.member_name!='') {
      f.ctl_name_text_box.p_text = item_name;
      f.ctl_aname_text_box.p_text = item_name;
      f.ctl_file_text_box.p_text = file_name;
      if (cm.return_type!='') {
         if (cm.exceptions!='') {
            f.ctl_type_text_box.p_text = cm.return_type:+" throws ":+cm.exceptions;
         } else {
            f.ctl_type_text_box.p_text = cm.return_type;
         }
      } else {
         switch (cm.type_name) {
         case 'enum':
         case 'struct':
         case 'class':
         case 'typedef':
         case 'union':
         case 'label':
         case 'interface':
         case 'constructor':
         case 'destructor':
         case 'annotation':
            f.ctl_type_text_box.p_text = cm.type_name;
            break;
         default:
            f.ctl_type_text_box.p_text = '';
            break;
         }
      }
   } else {
      f.ctl_file_text_box.p_text = '';
      f.ctl_type_text_box.p_text = '';
      f.ctl_name_text_box.p_text = '';
      f.ctl_aname_text_box.p_text = '';
   }
   f.ctl_name_text_box.p_ReadOnly = 1;
   f.ctl_file_text_box.p_ReadOnly = 1;
   f.ctl_type_text_box.p_ReadOnly = 1;
   f.ctl_aname_text_box.p_ReadOnly = 1;

   // select the label for the Type/Return Type
   switch (cm.type_name) {
   case 'func':
   case 'proc':
   case 'proto':
   case 'procproto':
   case 'constr':
   case 'destr':
      f.ctl_type_label.p_caption = "Return type:";
      break;
   case 'define':
   case 'constant':
   case 'enumc':
      f.ctl_type_label.p_caption = "Value:";
      break;
   default:
      f.ctl_type_label.p_caption = "Type:";
      break;
   }
   f.ctl_template_label.p_caption = "Template Arguments:";

   // set some of the simple check boxes, depending on flag values
   f.ctl_inline_check_box.p_value       = (cm.flags & VS_TAGFLAG_inline)?       1:0;
   f.ctl_final_check_box.p_value        = (cm.flags & VS_TAGFLAG_final)?        1:0;
   f.ctl_virtual_check_box.p_value      = (cm.flags & VS_TAGFLAG_virtual)?      1:0;
   f.ctl_const_check_box.p_value        = (cm.flags & VS_TAGFLAG_const)?        1:0;
   f.ctl_static_check_box.p_value       = (cm.flags & VS_TAGFLAG_static)?       1:0;
   f.ctl_mutable_check_box.p_value      = (cm.flags & VS_TAGFLAG_mutable)?      1:0;
   f.ctl_partial_check_box.p_value      = (cm.flags & VS_TAGFLAG_partial)?      1:0;
   f.ctl_forward_check_box.p_value      = (cm.flags & VS_TAGFLAG_forward)?      1:0;
   f.ctl_abstract_check_box.p_value     = (cm.flags & VS_TAGFLAG_abstract)?     1:0;
   f.ctl_volatile_check_box.p_value     = (cm.flags & VS_TAGFLAG_volatile)?     1:0;
   f.ctl_template_check_box.p_value     = (cm.flags & VS_TAGFLAG_template)?     1:0;
   f.ctl_synchronized_check_box.p_value = (cm.flags & VS_TAGFLAG_synchronized)? 1:0;
   f.ctl_transient_check_box.p_value    = (cm.flags & VS_TAGFLAG_transient)?    1:0;
   f.ctl_extern_check_box.p_value       = (cm.flags & VS_TAGFLAG_extern)?       1:0;
   f.ctl_native_check_box.p_value       = (cm.flags & VS_TAGFLAG_native)?       1:0;

   // set captions for public, protected, private, or package
   if (cm.class_name != '' && cm.member_name != '' && cm.type_name :!= 'enumc' && cm.type_name :!= 'database' && cm.type_name :!= 'define' && cm.type_name :!= 'table' && cm.type_name :!= 'view' && cm.type_name :!= 'column' && cm.type_name :!= 'index') {
      f.ctl_access_check_box.p_value = 1;
      f.ctl_access_check_box.p_enabled = 1;
      switch (cm.flags & VS_TAGFLAG_access) {
      case VS_TAGFLAG_protected:
         f.ctl_access_check_box.p_caption = "Protected";
         break;
      case VS_TAGFLAG_private:
         f.ctl_access_check_box.p_caption = "Private";
         break;
      case VS_TAGFLAG_package:
         f.ctl_access_check_box.p_caption = "Package";
         break;
      default: // VS_TAGFLAG_public:
         f.ctl_access_check_box.p_caption = "Public";
         break;
      }
   } else {
      f.ctl_access_check_box.p_caption = "Public";
      f.ctl_access_check_box.p_value = 0;
      f.ctl_access_check_box.p_enabled = 0;
   }

   // disable props by extension
   _str lang = _Filename2LangId(cm.file_name);
   f.cb_default_disable_props(cm.file_name,lang);

   // parse template signature and dump into list box
   f.ctl_template_list_box._lbclear();
   int apos=0;
   _str a = '';
   while (tag_get_next_argument(cm.template_args, apos, a) >= 0) {
      f.ctl_template_list_box._lbadd_item(a);
   }
   f.ctl_template_list_box._lbtop();
   refresh();

   // parse signature and dump into list box
   f.ctl_args_list_box._lbclear();
   apos=0;
   while (tag_get_next_argument(cm.arguments, apos, a) >= 0) {
      f.ctl_args_list_box._lbadd_item(a);
   }
   f.ctl_args_list_box._lbtop();
   refresh();

   // set value for "Prototype" check box
   f.ctl_proto_check_box.p_value = 0;
   if (cm.type_name:=="proto" || cm.type_name:=="procproto") {
      f.ctl_proto_check_box.p_value = 1;
   }
}

// check if there is an extension-specific function
// for enable-disable of check-boxes
static void cb_default_disable_props(_str file_name, _str ext)
{
   int DPindex = _FindLanguageCallbackIndex('_%s_disable_props',ext);
   if (index_callable(DPindex)) {
      call_index(DPindex);
   }
}

//////////////////////////////////////////////////////////////////////////////
// extension-specific disabling of tag properties check-boxes
//
void _ada_disable_props()
{
   ctl_final_check_box.p_enabled        = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _as_disable_props()
{
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_abstract_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_extern_check_box.p_enabled       = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _asm_disable_props()
{
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_abstract_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_extern_check_box.p_enabled       = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _masm_disable_props()
{
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_abstract_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_extern_check_box.p_enabled       = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _asm390_disable_props()
{
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_abstract_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_extern_check_box.p_enabled       = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _s_disable_props()
{
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_abstract_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_extern_check_box.p_enabled       = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _bas_disable_props()
{
   ctl_inline_check_box.p_enabled       = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
}
void _c_disable_props()
{
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _cob_disable_props()
{
   ctl_static_check_box.p_enabled       = 1;
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_const_check_box.p_enabled        = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_abstract_check_box.p_enabled     = 1;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 1;
   ctl_extern_check_box.p_enabled       = 1;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _e_disable_props()
{
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_abstract_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _idl_disable_props()
{
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_abstract_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_extern_check_box.p_enabled       = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _java_disable_props()
{
   ctl_template_check_box.p_enabled     = 1;
   ctl_extern_check_box.p_enabled       = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _d_disable_props()
{
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _cs_disable_props()
{
   ctl_template_check_box.p_enabled     = 0;
   ctl_extern_check_box.p_enabled       = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 1;
}
void _js_disable_props()
{
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _cfscript_disable_props()
{
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _phpscript_disable_props()
{
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _cics_disable_props()
{
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _pas_disable_props()
{
   ctl_static_check_box.p_enabled       = 0;
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _pl_disable_props()
{
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}
void _py_disable_props()
{
   ctl_final_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
   ctl_partial_check_box.p_enabled      = 0;
}

//////////////////////////////////////////////////////////////////////////////
// try to restore property view from previously stored information
//
static void maybe_restore_property_view(typeless ucm)
{
   struct VS_TAG_BROWSE_INFO cm;
   if (!ucm._isempty() && ucm._varformat() == VF_LSTR) {
      _str tb,ln,fl;
      parse ucm with cm.tag_database "\t" cm.category "\t" cm.class_name "\t" cm.member_name "\t" cm.qualified_name "\t" cm.type_name "\t" cm.file_name "\t" ln "\t" fl "\t" cm.return_type "\t" cm.arguments "\t" cm.exceptions "\t" cm.class_parents "\t" cm.template_args;
      cm.line_no = (isinteger(ln))? (int)ln : 0;
      cm.flags   = (isinteger(fl))? (int)fl : 0;
      cb_refresh_property_view(cm);
   }
}

//////////////////////////////////////////////////////////////////////////////
// update the properties tab when they expose the refs or uses tabs
//
void ctl_props_sstab.on_change(int reason)
{
   if (reason == CHANGE_TABACTIVATED) {
      switch (p_ActiveTab) {
      case CB_PROPERTIES_TAB_INDEX:
      case CB_ARGUMENTS_TAB_INDEX:
         break;
      //case CB_REFERENCES_TAB_INDEX:
      //case CB_CALLSUSES_TAB_INDEX:
      //   maybe_restore_property_view(ctl_name_text_box.p_user);
      //   break;
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// On form creation, get argument, and pass to refresh, cache window ID.
//
void ctl_props_sstab.on_create(struct VS_TAG_BROWSE_INFO cm=null, _str activeTab="")
{
   gtbprops_wid=p_active_form;

   // Init vars private to tab control:
   typeless ht:[];
   ht:["_formW"] = p_active_form.p_width;
   ht:["_formH"] = p_active_form.p_height;
   ht:["_output_sstabW"] = p_width;
   ht:["_output_sstabH"] = p_height;
   p_user = ht;

   // If active tab is specified as second argument.
   // Otherwise, use the saved value.
   if (activeTab != "" && isinteger(activeTab)) {
      p_ActiveTab = (int)activeTab;
   } else {
      _retrieve_value();
   }

   // if we were passed a tag argument, display its properties
   if (cm != null) {
      cb_refresh_property_view(cm);
   } else {
      typeless ucm = _retrieve_value("_tbprops_form.ctl_name_text_box.p_user");
      maybe_restore_property_view(ucm);
   }
}

//////////////////////////////////////////////////////////////////////////////
// On destroy, blow away the cached window ID
//
void _tbprops_form.on_destroy()
{
   int value = ctl_props_sstab.p_ActiveTab;
   _append_retrieve(ctl_props_sstab, value );
   _append_retrieve(0, ctl_name_text_box.p_user,  "_tbprops_form.ctl_name_text_box.p_user");
   gtbprops_wid=0;
   call_event(p_window_id,ON_DESTROY,'2');
}

//////////////////////////////////////////////////////////////////////////////
// For any check box on this form, make it behave as read-only by
// resetting it's value in the lbutton_up callback.
//
void ctl_static_check_box.lbutton_up()
{
   p_value = (p_value)? 0:1;
}

//////////////////////////////////////////////////////////////////////////////
// handle resize event
//
void _tbprops_form.on_resize(boolean forcedResize=false)
{
   typeless lastW, lastH;
   typeless ht:[];
   ht = ctl_props_sstab.p_user;
   if (ht._indexin("formWH")) {
      _str text;
      text = ht:["formWH"];
      parse text with lastW lastH;
      if (!forcedResize && lastW == p_width && lastH == p_height) return;
   } else {
      ht:["formWH"] = p_width:+" ":+p_height;
      ctl_props_sstab.p_user = ht;
      return;
   }

   int sstabW = _dx2lx(SM_TWIP,p_client_width)  - 2 * ctl_props_sstab.p_x;
   int sstabH = _dy2ly(SM_TWIP,p_client_height) - 2 * ctl_props_sstab.p_y;

   // size the tab control. This is important because sizing
   // the tab control also reconfigures the tab containers and
   // we use the tab container dimension to do our resize.
   ctl_props_sstab.p_width  = sstabW;
   ctl_props_sstab.p_height = sstabH;

   // available space and border usage
   int avail_x, avail_y;
   avail_x  = ctl_props_sstab.p_child.p_width;
   avail_y  = ctl_props_sstab.p_child.p_height;

   // border size
   int border_x, border_y;
   border_x = ctl_static_check_box.p_x;
   border_y = ctl_name_text_box.p_y;

   // x-position and height of tag name text box
   int name_x  = ctl_name_text_box.p_x;
   int name_y  = ctl_name_text_box.p_height;

   /*
   // Toggle tab control to display tab with text and images or just images:
   if (sstabW < ht:["pictureOnlyW"]) {
      if (ctl_props_sstab.p_PictureOnly != true) {
         ctl_props_sstab.p_PictureOnly = true;
      }
   } else {
      if (ctl_props_sstab.p_PictureOnly != false) {
         ctl_props_sstab.p_PictureOnly = false;
      }
   }
   */

   // adjust the items inside the properties tab
   ctl_name_text_box.p_width = avail_x - name_x - border_x;
   ctl_file_text_box.p_width = avail_x - name_x - border_x;

   _control ctl_static_check_box;
   _control ctl_const_check_box;
   _control ctl_final_check_box;
   _control ctl_proto_check_box;
   _control ctl_inline_check_box;
   _control ctl_volatile_check_box;
   _control ctl_access_check_box;
   _control ctl_abstract_check_box;
   _control ctl_virtual_check_box;
   _control ctl_transient_check_box;
   _control ctl_synchronized_check_box;
   _control ctl_template_check_box;
   _control ctl_native_check_box;
   _control ctl_extern_check_box;
   _control ctl_mutable_check_box;
   _control ctl_partial_check_box;
   _control ctl_forward_check_box;

   int check_box_order[];
   check_box_order._makeempty();
   check_box_order[ 0] = ctl_static_check_box;
   check_box_order[ 1] = ctl_const_check_box;
   check_box_order[ 2] = ctl_final_check_box;
   check_box_order[ 3] = ctl_proto_check_box;
   check_box_order[ 4] = ctl_inline_check_box;
   check_box_order[ 5] = ctl_volatile_check_box;
   check_box_order[ 6] = ctl_access_check_box;
   check_box_order[ 7] = ctl_abstract_check_box;
   check_box_order[ 8] = ctl_virtual_check_box;
   check_box_order[ 9] = ctl_transient_check_box;
   check_box_order[10] = ctl_synchronized_check_box;
   check_box_order[11] = ctl_template_check_box;
   check_box_order[12] = ctl_native_check_box;
   check_box_order[13] = ctl_extern_check_box;
   check_box_order[14] = ctl_mutable_check_box;
   check_box_order[15] = ctl_partial_check_box;
   check_box_order[16] = ctl_forward_check_box;

   // lay out the check boxes in the maximum number of columns that fit.
   int check_x = ctl_static_check_box.p_x;
   int check_y = ctl_static_check_box.p_y;
   int check_w = ctl_static_check_box.p_width;
   int check_h = ctl_static_check_box.p_y - ctl_file_text_box.p_y - border_y;
   int columns = (int) (avail_x / check_w);
   columns = (columns == 0)? 1 : columns;
   columns = (columns >= 8)? 8 : columns;
   int i;
   for (i=0; i<check_box_order._length(); i++) {
      int r,c;
      check_box_order[i].p_x = check_x + check_w*(i % columns);
      check_box_order[i].p_y = check_y + check_h*(i intdiv columns);
   }

   // adjust the items inside the arguments tab
   ctl_aname_text_box.p_width = avail_x - name_x - border_x;
   ctl_type_text_box.p_width = avail_x - name_x - border_x;
   ctl_template_list_box.p_width = avail_x - name_x - border_x;
   ctl_args_list_box.p_width  = avail_x - name_x - border_x;
   ctl_args_list_box.p_height = avail_y - ctl_args_list_box.p_y - ctl_aname_text_box.p_y;
   //ctl_api_button.p_y = ctl_args_list_box.p_y + ctl_args_list_box.p_height - ctl_api_button.p_height;

   // Save form's new XYWH:
   ht:["formWH"] = p_width:+" ":+p_height;
   ctl_props_sstab.p_user = ht;
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Refresh the output symbols tab (peek-a-boo window)
//
void cb_refresh_output_tab(struct VS_TAG_BROWSE_INFO cm, boolean just_go_there,
                           boolean maybeActivateSymbolTab=false,
                           boolean activateHiddenSymbolTab=false,
                           int activateHiddenSymbolTabFromOtherFlag=0)
{
   tagwin_save_tag_info(cm);

   // Activate the symbol tab if it is not currently active
   // Do not activate it if it is auto-hidden or un-docked.
   if(just_go_there && maybeActivateSymbolTab && !_tbIsActive("_tbtagwin_form") && 
      // Preview tool window not visible cases
      (
       // Auto-hidden case
       (activateHiddenSymbolTab && 
        _iswindow_valid(_get_focus()) &&
        !_tbIsAutoShownWid(_get_focus().p_active_form) &&
        _tbIsAuto("_tbtagwin_form",true)
       )

       ||

       // Docked but not active case
       (!activateHiddenSymbolTabFromOtherFlag &&
        !_tbIsAuto("_tbtagwin_form",true) && 
        tbIsDocked("_tbtagwin_form") && 
        !tbIsSameTabGroup("_tbtagwin_form")
       )

       ||

       // Activated from other window or operation (docked or auto)
       (doActivatePreviewToolWindow(activateHiddenSymbolTabFromOtherFlag) &&
        !tbIsSameTabGroup("_tbtagwin_form") && !(_tbIsAuto("_tbtagwin_form",true) && _tbIsAuto(p_active_form.p_name,true)))
      )
     ) {

      activateSymbolWindow(false);
   }

   // check that the output toolbar is visible
   int f = _GetTagwinWID(true);
   if (!f) {
      return;
   }

   // no file name, yikes! 
   if (cm.file_name==null) {
      return;
   }

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      return;
   }

   // if the symbol window has "Prototypes" shut off, display the proc instead
   // if one is found.
   if (!(def_tagwin_flags & VS_TAGFILTER_PROTO)) {
      maybe_convert_proto_to_proc(cm);
   }

   // find the output tagwin and update it
   if (cm.member_name != '' || just_go_there) {
      _UpdateTagWindowDelayed(cm, def_tag_hover_delay);
   }
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// command control / menu entry points
//

//////////////////////////////////////////////////////////////////////////////
// Bring up symbol browser options form
//
_command cb_options() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }
   f.show("-xy _cboptions_form");
}

//////////////////////////////////////////////////////////////////////////////
// Save or print the contents of the symbol browser
//
_command cb_save_print_copy(_str action='') name_info(','VSARG2_EDITORCTL)
{
   // verify the form name
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }

   // get the window ID of the symbol browser tree
   _nocheck _control ctl_class_tree_view;
   int tree_wid=f.ctl_class_tree_view;

   // OK, we have the tree, now let's rock
   switch (action) {
   case 'copy_item':
      tree_wid._TreeCopyContents(tree_wid._TreeCurIndex(), false);
      break;
   // entire tree
   case 'copy':
      tree_wid._TreeCopyContents();
      break;
   case 'save':
      tree_wid._TreeSaveContents();
      break;
   case 'print':
      tree_wid._TreePrintContents();
      break;
   // just the sub tree
   case 'copy_subtree':
      tree_wid._TreeCopyContents(tree_wid._TreeCurIndex(), true);
      break;
   case 'save_subtree':
      tree_wid._TreeSaveContents(tree_wid._TreeCurIndex());
      break;
   case 'print_subtree':
      tree_wid._TreePrintContents(tree_wid._TreeCurIndex());
      break;
   // no argument or bad argument
   default:
      return('');
   }
}

//////////////////////////////////////////////////////////////////////////////
// Bring up tag properties form and hand it the tag information for
// the current tag.
//
_command cb_props() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }
   _nocheck _control ctl_class_tree_view;

   int currIndex = f.ctl_class_tree_view._TreeCurIndex();
   struct VS_TAG_BROWSE_INFO cm;
   f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false);
   if (!gtbprops_wid) {
      tbShow("_tbprops_form");
      cb_refresh_property_view(cm);
   }
   _nocheck _control ctl_props_sstab;
   if (gtbprops_wid) {
      gtbprops_wid.ctl_props_sstab.p_ActiveTab = CB_PROPERTIES_TAB_INDEX;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Bring up tag properties form and hand it the tag information for
// the current tag.
//
_command cb_args() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }
   _nocheck _control ctl_class_tree_view;

   int currIndex = f.ctl_class_tree_view._TreeCurIndex();
   struct VS_TAG_BROWSE_INFO cm;
   f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false);
   if (!gtbprops_wid) {
      tbShow("_tbprops_form");
      cb_refresh_property_view(cm);
   }
   _nocheck _control ctl_props_sstab;
   if (gtbprops_wid) {
      gtbprops_wid.ctl_props_sstab.p_ActiveTab = CB_ARGUMENTS_TAB_INDEX;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Bring up tag properties form and hand it the tag information for
// the current tag.
//
_command cb_references() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }
   _nocheck _control ctl_class_tree_view;

   int currIndex = f.ctl_class_tree_view._TreeCurIndex();
   struct VS_TAG_BROWSE_INFO cm;
   f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false);

   // check if the current workspace tag file or extension specific
   // tag file requires occurrences to be tagged.
   if (_MaybeRetagOccurrences(cm.tag_database) == COMMAND_CANCELLED_RC) {
      return(1);
   }
   if(!isEclipsePlugin()) {
      // If form already exists, reuse it.  Otherwise, create it
      activate_toolbar("_tbtagrefs_form","");
   } else {
      int index=find_index('_refswindow_Activate',PROC_TYPE);
      if (index_callable(index)) {
         (call_index(index));
      }
   }

   // need to populate the form wid here
   // find the output references tab and update it
   refresh_references_tab(cm);
}

//////////////////////////////////////////////////////////////////////////////
// Bring up call tree form and hand it the tag information for
// the current tag.
//
_command cb_calltree() name_info(','VSARG2_EDITORCTL)
{
   struct VS_TAG_BROWSE_INFO cm;
   if (_isEditorCtl()) {
      context_id := tag_get_current_context(cm.member_name, 
                                            cm.flags, 
                                            cm.type_name, 
                                            auto dummy_type_id,
                                            cm.class_name,
                                            auto cur_class,
                                            auto cur_package);
      if (context_id <= 0) {
         _message_box(nls('No symbol under the cursor.'));
         return(1);
      }
      tag_get_context_info(context_id, cm);
      maybe_convert_proto_to_proc(cm);
      show("-xy _cbcalls_form", cm);
      return(0);
   }

   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }
   _nocheck _control ctl_class_tree_view;
   int currIndex   = f.ctl_class_tree_view._TreeCurIndex();
   f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false);

   // check if there is a load-tags function, if so, bail out
   if (_QBinaryLoadTagsSupported(cm.file_name)) {
      _message_box(nls('Can not locate source code for %s.',cm.file_name));
      return(1);
   }

   maybe_convert_proto_to_proc(cm);
   f.show("-xy _cbcalls_form", cm);
}

//////////////////////////////////////////////////////////////////////////////
// Bring up class parents form and hand it the tag information for
// the current tag.
//
_command cb_parents(_str option="") name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }
   _nocheck _control ctl_class_tree_view;

   int currIndex   = f.ctl_class_tree_view._TreeCurIndex();
   int parentIndex = f.ctl_class_tree_view._TreeGetParentIndex(currIndex);
   int show_children=0;
   f.ctl_class_tree_view._TreeGetInfo(currIndex, show_children);
   struct VS_TAG_BROWSE_INFO cm;
   if (show_children == TREE_NODE_LEAF) {
      f.ctl_class_tree_view.get_user_tag_info(parentIndex, cm, false);
   } else {
      f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false);
   }
   f.show("-xy _cbparents_form", cm, option);

   f=gcbparents_wid;
   if (f) {
      boolean find_children=(option=="derived");
      f.refresh_inheritance_view(cm,find_children);
   }
}

_command void cb_jrefactor(_str params = "") name_info(','VSARG2_EDITORCTL)
{
    // get the tag info
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return;
   }
   _nocheck _control ctl_class_tree_view;

   int index = f.ctl_class_tree_view._TreeCurIndex();
   struct VS_TAG_BROWSE_INFO cm;
   f.ctl_class_tree_view.get_user_tag_info(index, cm, false);

   // fill in the browse info for the tag
   int status = tag_complete_browse_info(cm);
   if(status < 0) return;

   // trigger the requested refactoring
   switch(params) {
      case "add_import":
         jrefactor_add_import(false, cm, _mdi.p_child.p_buf_name);
         break;
      case "organize_imports_options" :
         jrefactor_organize_imports_options();
         break;
   }
}

/**
 * Trigger a refactoring operation for the currently
 * selected symbol in the symbol browser
 *
 * @param params The quick refactoring to run
 */
_command void cb_quick_refactor(_str params = "") name_info(','VSARG2_EDITORCTL)
{
   // get the tag info
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return;
   }
   _nocheck _control ctl_class_tree_view;

   int index = f.ctl_class_tree_view._TreeCurIndex();
   struct VS_TAG_BROWSE_INFO cm;
   f.ctl_class_tree_view.get_user_tag_info(index, cm, false);

   // fill in the browse info for the tag
   int status = tag_complete_browse_info(cm);
   if(status < 0) return;

   _str lang=_Filename2LangId(cm.file_name);
   typeless s_syntax_indent;

   // trigger the requested refactoring
   switch(params) {
      case "quick_encapsulate_field" :
         refactor_start_quick_encapsulate(cm);
         break;
      case "quick_rename":
         refactor_quick_rename_symbol(cm);
         break;
      case "quick_modify_params":
         if(cm.type_name == 'proto' || cm.type_name == 'procproto') {
            if(!refactor_convert_proto_to_proc(cm)) {
               _message_box("Cannot perform quick modify parameters refactoring because the function definition could not be found",
                            "Modify Parameters");
               break;
            }
         }

         refactor_start_quick_modify_params(cm);
         break;

      // symbol browser doesn't have any info about local variables
      //case "local_to_field": break;
   }
}

/**
 * Trigger a refactoring operation for the currently
 * selected symbol in the symbol browser
 *
 * @param params The refactoring to run
 */
_command void cb_refactor(_str params = "") name_info(','VSARG2_EDITORCTL)
{
   // get the tag info
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return;
   }
   _nocheck _control ctl_class_tree_view;

   int index = f.ctl_class_tree_view._TreeCurIndex();
   struct VS_TAG_BROWSE_INFO cm;
   f.ctl_class_tree_view.get_user_tag_info(index, cm, false);

   // fill in the browse info for the tag
   int status = tag_complete_browse_info(cm);
   if(status < 0) return;

   // trigger the requested refactoring
   switch(params) {
      case "extract_super_class":
         refactor_extract_class_symbol(cm,true);
         break;
      case "extract_class":
         refactor_extract_class_symbol(cm,false);
         break;
      case "encapsulate" :
         refactor_start_encapsulate(cm);
         break;
      case "move_field":
         refactor_start_move_field(cm);         
         break;
      case "standard_methods" :
         refactor_start_standard_methods(cm);
         break;
      case "rename":
         refactor_rename_symbol(cm);
         break;
      case "global_to_field":
         refactor_global_to_field_symbol(cm);
         break;
      case "static_to_instance_method":
         refactor_static_to_instance_method_symbol(cm);
         break;
      case "move_method":
         refactor_move_method_symbol(cm);
         break;
      case "pull_up":
         refactor_pull_up_symbol(cm);
         break;
      case "push_down":
         refactor_push_down_symbol(cm);
         break;
      case "modify_params":
         if(cm.type_name == 'proto' || cm.type_name == 'procproto') {
            if(!refactor_convert_proto_to_proc(cm)) {
               _message_box("Cannot perform modify parameters refactoring because the function definition could not be found",
                            "Modify Parameters");
               break;
            }
         }

         refactor_start_modify_params(cm);
         break;
      // symbol browser doesn't have any info about local variables
      //case "local_to_field": break;
   }
}


//////////////////////////////////////////////////////////////////////////////
// Callback used by _sellist form when user makes choice of tag
//
static _str _taglist_callback(int reason,var result,typeless key)
{
   _nocheck _control _sellist;
   if (reason==SL_ONDEFAULT) {  // Enter key
      result=_sellist.p_line-1;
      return(1);
   }
   return("");
}

//////////////////////////////////////////////////////////////////////////////
// Returns the number of exact matches for the given tag name
// Returns either 0, 1, or 2, since it short cuts the search after
// it determines that there is more than one match.
//
static int number_of_exact_matches(_str proc_name, _str type_name,
                                   _str class_name, typeless &tag_files)
{
   // count the number of exact matches for this tag
   int i=0,count=0,status=0;
   _str tag_filename=next_tag_filea(tag_files,i,false,true);
   while (tag_filename != '') {
      status = tag_find_equal(proc_name);
      while (status==0) {
         typeless dm,df,dl,flg;
         _str tname,cname;
         tag_get_info(dm, tname, df, dl, cname, flg);
         if (type_name=='' || type_name :== tname) {
            if (class_name=='' || class_name :== cname) {
               ++count;
               if (count >= 2) {
                  tag_reset_find_tag();
                  return 2;
               }
            }
         }
         status = tag_next_equal();
      }
      tag_reset_find_tag();
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   return count;
}

//////////////////////////////////////////////////////////////////////////////
// Returns the number of prefix matches for the given tag name
// Returns either 0, 1, or 2, since it short cuts the search after
// it determines that there is more than one match.
//
static int number_of_prefix_matches(_str proc_name, typeless &tag_files)
{
   // count the number of exact matches for this tag
   int i=0,count=0;
   _str tag_filename=next_tag_filea(tag_files,i,false,true);
   while (tag_filename != '') {
      int status = tag_find_prefix(proc_name);
      if (status==0) {
         ++count;
         status = tag_next_prefix(proc_name);
         if (status==0) {
            ++count;
         }
      }
      tag_reset_find_tag();
      if (count >= 2) {
         return 2;
      }
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   return count;
}

//////////////////////////////////////////////////////////////////////////////
// Map tag types to code categories, see CB_*, top of file
// Since we support class nesting, this function only produces a
// best guess for the category.  For globals, however it produces
// exact results.
//
static _str type_to_category(_str type_name, int tag_flags, boolean containers_only)
{
   typeless ctg_name;
   CB_TAG_CATEGORY ctg;
   for (ctg_name._makeempty();;) {
      gh_cb_categories._nextel(ctg_name);
      if (ctg_name._isempty()) break;
      if (ctg_name._varformat() == VF_LSTR) {
         ctg = gh_cb_categories._el(ctg_name);

         // check presence/absence of tag flags
         boolean nzero;
         nzero = (tag_flags & ctg.flag_mask)? true:false;
         if (ctg.flag_mask & VS_TAGFLAG_static) {
            if (nzero != ctg.mask_nzero) {
               continue;
            }
         }

         // check container criteria
         //if (containers_only == true || ctg.is_container == false) {
         //   continue;
         //}

         // OK, look for a matching type name
         int i;
         for (i=0; i<ctg.tag_types._length(); i++) {
            // get the tag type, has to be either a string or an int
            int t1 = ctg.tag_types[i];
            if (t1._varformat() == VF_LSTR) {
               if (!isinteger(t1)) {
                  t1 = tag_get_type_id(t1);
                  if (t1 < 0) {
                     continue;
                  }
               }
            } else if (!VF_IS_INT(t1)) {
               continue;
            }

            // translate the type id to a type name
            _str tname;
            int status=tag_get_type(t1, tname);
            if (status < 0) {
               continue;
            }

            // try to find the item
            if (tname :== type_name) {
               return ctg_name;
            }
         }
      }
   }

   return CB_misc;
}

/**
 * Activate the symbol browser if necessary and locate the
 * given symbol in the tree.
 * 
 * @param cm  symbol information
 */
int tag_show_in_class_browser(struct VS_TAG_BROWSE_INFO &cm)
{
   if(!isEclipsePlugin())
   {
      // display the symbol browser form if it isn't already there
      if (!gtbcbrowser_wid) {
         tbShow("_tbcbrowser_form");
      }
   }

   // find the symbol browser form
   int f = GetCBViewWid();
   if (!f) {
      f = ActivateClassBrowser();
      if(!f) {
         messageNwait("_tbcbrowser_form " nls("not found"));
         return VSRC_FORM_NOT_FOUND;
      }
   } else {
      activate_cbrowser();
   }

   // DJB - 11/16/2005
   // first make sure the right tag file is open
   tag_get_tagfile_browse_info(cm);
   int status = tag_read_db(cm.tag_database);
   if (status < 0) {
      message(nls(get_message(status),cm.tag_database));
      return status;
   }

   // determine tag category
   _str category;
   if (cm.class_name == '') {
      category = type_to_category(cm.type_name, cm.flags, false);
   } else {
      _str top_name;
      if (pos('/', cm.class_name)) {
         parse cm.class_name with top_name '/' .;
         category = CB_packages; // guess
      } else if (pos(':', cm.class_name)) {
         parse cm.class_name with top_name ':' .;
         category = CB_classes; // guess
      } else {
         top_name = cm.class_name;
         category = CB_classes; // guess
      }

      status = tag_find_equal(top_name, 1/*case_sensitive*/);
      while (status == 0) {
         _str tag,tn,fn,cn;
         int line,flgs;
         tag_get_info(tag, tn, fn, line, cn, flgs);
         if (file_eq(fn, cm.file_name) && cn=='') {
            _str cat = type_to_category(tn, 0, true);
            if (cat != '') {
               category = cat;
               break;
            }
         }
         status = tag_next_equal(1/*case_sensitive*/);
      }
      tag_reset_find_tag();
   }

   // construct the traversal path
   _str path = tag_tree_make_caption(cm.member_name, cm.type_name, '', cm.flags, '', false);
   if (cm.class_name != '') {
      cm.class_name = translate(cm.class_name, ',,', ':/');
      path = cm.class_name ',' path;
   }

   // compute the tag filename path
   _str tag_filename_path='';
   int index = f.ctl_class_tree_view._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      _str filename;
      tag_filename_path = f.ctl_class_tree_view._TreeGetCaption(index);
      parse tag_filename_path with tag_filename_path '(' .;
      parse tag_filename_path with . ': ' filename;
      if (file_eq(strip(filename),cm.tag_database)) {
         break;
      }
      index = f.ctl_class_tree_view._TreeGetNextSiblingIndex(index);
   }
   if (index <= 0) {
      return 1;
   }

   // put together final path and pass to restore_position
   path = tag_filename_path ',' category ',' path;

   //_message_box("Restoring: " path);
   index = f.ctl_class_tree_view.restore_position(TREE_ROOT_INDEX, path);
   if (index > 0) {
      f.ctl_class_tree_view._TreeSetCurIndex(index);
      ActivateClassBrowser();
      f.ctl_class_tree_view._set_focus();
      return 0;
   }
   return 1;
}

//////////////////////////////////////////////////////////////////////////////
// Find a tag in the symbol browser.  This function takes as input a single
// tag argument (optional) and attempts to find a match in some tag database.
// If no argument is given, it attempts to find a tag at the current word.
// If there is no match for the current word, then we use the push tag
// bookmark dialog to dynamically find a tag using prefix matching completion.
// If there are no exact matches for the tag passed in, it will revert to
// the push bookmark dialog.  The result of these operations is a proc_name
// that we need to find.
//
// If the user gave specific information tag(class:type), we first check
// if there is a match for such a beast.  If not, we strip the class and type,
// and attempt to use the proc_name alone and continue.
//
// Once we have a proc_name, we find all matches, and then pop up a selection
// list dialog for the user to select a tag (unless there are no matches,
// or exactly one match).  The user then selects the match of their choice.
//
// At this point, we have a triplet of tag_name, type_name, and class_name.
// We then calcuate a caption path for finding the tag in the class
// browser and pass that on to restore_position().
//
_command cf,cb_find(_str tag_arg="") name_info(TAG_ARG','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI)
{
   _macro_delete_line();

   _nocheck _control ctl_class_tree_view;

   // initialize list of matching tags
   _str taglist[];
   _str filesForTags:[];
   int linesForTags:[];
   boolean IgnoreCase=false;

   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // No argument, grab the current word at the cursor
   //boolean ignore_tcase = (def_ignore_tcase)? true:false;
   boolean ignore_tcase = true;
   boolean context_found = false;
   int num_matches = 0;
   _str database_name = '';
   _str proc_name  = '';
   _str class_name = '';
   _str type_name  = '';
   _str lang = '';
   int tag_flags=0;
   int start_col;
   _str file_name;
   int line_no;
   typeless dt,dflg,ds,dr,dn;
   _str match_type_name,match_class_name;
   if (tag_arg=="" && _isEditorCtl() && !_no_child_windows()) {
      lang = p_LangId;
      _str tagName = '';
      _str errorArgs[];
      tag_clear_matches();
      num_matches = context_match_tags(errorArgs,tagName);
      if (num_matches <= 0) {
         if (tagName != '') {
            _message_box(nls("Could not find declaration of symbol: '%s'.",tagName));
         } else {
            _message_box(nls("No symbol under cursor."));
         }
         return(1);
      }
      // filter out duplicate symbol definitions 
      tag_remove_duplicate_symbol_matches(false, true, true, true, true);
      context_found=true;
      tag_get_match(1, dt, proc_name, type_name, file_name, line_no, class_name, dflg, ds, dr);
      if (type_name!='param' && type_name!='lvar') {
         taglist[taglist._length()] = tag_tree_compose_tag(proc_name, class_name, type_name);
         filesForTags:[taglist[taglist._length()-1]] = file_name;
         linesForTags:[taglist[taglist._length()-1]] = line_no;
         tag_get_detail2(VS_TAGDETAIL_match_flags,1,tag_flags);
      }
      //say("tag_name="proc_name" type="type_name" cls="class_name);
      num_matches = tag_get_num_of_matches();
      for (i:=2; i<=num_matches; i++) {
         tag_get_match(i, dt, dn, match_type_name, file_name, line_no, match_class_name, dflg, ds, dr);
         if (match_type_name!='param' && match_type_name!='lvar') {
            taglist[taglist._length()] = tag_tree_compose_tag(dn, match_class_name, match_type_name);
            filesForTags:[taglist[taglist._length()-1]] = file_name;
            linesForTags:[taglist[taglist._length()-1]] = line_no;
            tag_get_detail2(VS_TAGDETAIL_match_flags,i,tag_flags);
         }
         //say("tag_name="dn" type="match_type_name" cls="match_class_name);
         if (match_type_name != type_name && !(pos('pro',type_name) && pos('pro',match_type_name))) {
            type_name = '';
         }
         if (match_class_name != class_name) {
            class_name == '';
         }
      }
      if (taglist._length() <= 0) {
         _message_box(nls("Tag '%s' can not be found in the symbol browser; it is a local variable.",tagName));
         return(1);
      }
   } else if (tag_arg != "" && tag_arg != "-") {
      // get argument passed by user
      tag_tree_decompose_tag(tag_arg, proc_name, class_name, type_name, tag_flags);

   } else if (p_active_form.p_window_id == _GetCBrowserWID()) {
      // restrict search to current tag file if this is initiated from
      // the Symbols tool window.
      proc_name = "";
      struct VS_TAG_BROWSE_INFO cm;
      int k = ctl_class_tree_view._TreeCurIndex();
      ctl_class_tree_view.get_user_tag_info(k, cm, true);
      database_name = cm.tag_database;
   }

   // massage the tag name slightly
   typeless tag_files = null;
   if (database_name != "") {
      tag_files[0] = database_name;
   } else {
      tag_files = tags_filenamea(lang);
   }
   proc_name = strip(proc_name);
   proc_name = translate(proc_name,'_','-');

   // compute the name of th scope being searched
   scope_name := "";
   scope_name = (lang != "")? _LangId2Modename(lang) : "";
   scope_name = (database_name != "")? _strip_filename(database_name, 'P') : "";
   if (scope_name != "") scope_name = " ("scope_name")";

   // if we still do not have a tag name to search for,
   // then prompt to search for one within the specified langauge
   if (proc_name == '') {
      new_proc_name := show('-modal -reinit _tagbookmark_form', proc_name, "Symbol Browser Find Tag":+scope_name, lang, true, "", database_name);
      if (new_proc_name == '') {
         return(COMMAND_CANCELLED_RC);       
      }
      tag_tree_decompose_tag(new_proc_name,proc_name,class_name,type_name,auto df=0);
   }

   if (!context_found) {
      // count the number of exact matches for this tag
      // intelligently figure out if they gave class_name / type_name
      int count = number_of_exact_matches(proc_name, type_name, class_name, tag_files);
      if (count == 0 && database_name != "") {
         tag_files = tags_filenamea(lang);
         count = number_of_exact_matches(proc_name, type_name, class_name, tag_files);
      }
      if (count == 0 && type_name != '') {
         if (class_name == '') {
            count = number_of_exact_matches(proc_name, '', type_name, tag_files);
            if (count) {
               class_name = type_name;
               type_name = '';
            }
         }
         if (count == 0) {
            count = number_of_exact_matches(proc_name, '', class_name, tag_files);
            if (count) {
               type_name = '';
            }
         }
      }
      if (count==0 && class_name != '') {
         count = number_of_exact_matches(proc_name, type_name, '', tag_files);
         if (count) {
            class_name='';
         }
      }
      if (count==0) {
         type_name='';
         class_name='';
         count = number_of_exact_matches(proc_name, '', '', tag_files);
      }

      // no matches for this symbol, so then, just give up
      if (count==0) {
         _message_box(nls("Could not find declaration of symbol: '%s'.",proc_name));
         return(1);
      }
   }

   // bail out if there aren't any tag files
   _str tag_files_list = tags_filename(lang);
   if (warn_if_no_tag_files(tag_files_list)) {
      return(2);
   }

   _str tag_name,tag_type,tag_class;
   int status;
   if (!context_found) {
      // iterate through each tag file
      i:=0;
      _str tag_filename=next_tag_filea(tag_files,i,false,true);
      while (tag_filename != '') {

         /* Find prefix tag match for proc_name. */
         status = tag_find_equal(proc_name);
         while (! status) {

            tag_get_info(tag_name, tag_type, file_name, line_no, tag_class, dflg);

            if (type_name == '' || type_name :== tag_type) {
               if (class_name == '' || class_name :== tag_class) {
                  //if (tag_class != '') {
                  //   line_item = tag_name "(" tag_class ":" tag_type ")";
                  //} else {
                  //   line_item = tag_name "(" tag_type ")";
                  //}
                  //taglist[taglist._length()]=line_item;
                  taglist[taglist._length()] = tag_tree_compose_tag(tag_name, tag_class, tag_type);
                  filesForTags:[taglist[taglist._length()-1]] = file_name;
                  linesForTags:[taglist[taglist._length()-1]] = line_no;
                  if (ignore_tcase && !IgnoreCase /*&& tag_case(file_name)=="i"*/) {
                     IgnoreCase=true;
                  }
               }
            }

            status = tag_next_equal();
         }
         tag_reset_find_tag();

         tag_filename=next_tag_filea(tag_files,i,false,true);
      }
   }

   // If we found any tags.
   _str tagname=proc_name;

   // If user wants strict language case sensitivity
   if (!ignore_tcase && !IgnoreCase) {
      for (i:=0;i<taglist._length();++i) {
         if (tagname:!=substr(taglist[i],1,length(tagname))) {
            taglist._deleteel(i);
            --i;
         }
      }
   }

   // didn't find the tag?
   if (taglist._length()==0) {
      _str long_msg='.';//  'nls('You may want to rebuild the tag file.');
      _message_box(nls("Tag '%s' not found",proc_name)long_msg);
      return(1);
   }

   // sort the list and remove duplicates
   taglist._sort('I');
   cf_remove_duplicates(taglist);

   //messageNwait("prompt_user: len="taglist._length());
   if (taglist._length()>=2) {
      VS_TAG_BROWSE_INFO cm;
      tag_browse_info_init(cm);
      tag_push_matches();
      foreach (auto taginfo in taglist) {
         tag_tree_decompose_tag(taginfo, cm.member_name, cm.class_name, cm.type_name, cm.flags, cm.arguments, cm.return_type);
         cm.file_name = filesForTags:[taginfo];
         cm.line_no   = linesForTags:[taginfo];
         tag_insert_match_info(cm);
      }

      int match_id = tag_select_match();
      if (match_id < 0) {
         return match_id;
      }
      tag_get_match_info(match_id, cm);
      tagname = tag_tree_compose_tag(cm.member_name, cm.class_name, cm.type_name, cm.flags, cm.arguments, cm.return_type);
   } else {
      tagname=taglist[0];
   }
   if (tagname=='') {
      return(COMMAND_CANCELLED_RC);
   }

   // parse out the tag name, class, and type
   tag_tree_decompose_tag(tagname, proc_name, class_name, type_name, tag_flags);

   // found the tag, type, and class name, now find it in a database
   i:=0;
   _str tag_filename=next_tag_filea(tag_files,i,false,true);
   while ( tag_filename!='' ) {

      // Find tag match for proc_name.
      int found_it=0;
      status = tag_find_tag(proc_name, type_name, class_name);
      while (status==0) {
         _str tag;
         tag_get_detail(VS_TAGDETAIL_name, tag);
         if (proc_name :== tag) {
            found_it=1;
            break;
         }
         status = tag_next_tag(proc_name, type_name, class_name);
      }
      tag_reset_find_tag();
      if (found_it) {
         break;
      }

      // didn't find it, try the next file
      tag_filename=next_tag_filea(tag_files,i,false,true);
   }

   // this should NEVER happen
   if (status) {
      _str long_msg='.';//  'nls('You may want to rebuild the tag file.');
      _message_box(nls("Tag '%s' not found",tagname)long_msg);
      return(1);
   }

   // get the details on the tag we are looking for
   _str tag_database = tag_filename;
   _str member_name;
   int flags;
   tag_get_info(member_name, type_name, file_name, line_no, class_name, flags);

   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   tag_get_tag_info(cm);

   status = tag_show_in_class_browser(cm);
   return status;
}

//////////////////////////////////////////////////////////////////////////////
// Remove duplicates from a list
//
static void cf_remove_duplicates(_str (&list)[])
{
   if (!list._length()) return;
   _str previous_line=list[0];
   int i;
   for (i=1;i<list._length();++i) {
      if ( list[i]:==previous_line ) {
         list._deleteel(i);
         --i;
      } else {
         previous_line=list[i];
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Goto the declaration for the currently selected tag in the symbol browser
// Translates type_name (proc) to (proto).
//
_command cb_goto_decl() name_info(','VSARG2_EDITORCTL)
{
   _nocheck _control ctl_class_tree_view;

   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }

   struct VS_TAG_BROWSE_INFO cm;
   int k = f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, cm, false)) {
      if (cm.type_name!='procproto' && cm.type_name!='proto' && tag_tree_type_is_func(cm.type_name)) {
         _str search_arguments  = VS_TAGSEPARATOR_args:+cm.arguments;
         if (tag_find_tag(cm.member_name, 'proto', cm.class_name, search_arguments)==0) {
            tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
            tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
         } else if (tag_find_tag(cm.member_name, 'procproto', cm.class_name, search_arguments)==0) {
            tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
            tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
         }
      }
      tag_reset_find_tag();
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Goto the definitino of the currently selected tag in the symbol browser
// Translates (proto) to proc, constr, destr, or function, until it
// finds a match.
//
_command cb_goto_proc() name_info(','VSARG2_EDITORCTL)
{
   _nocheck _control ctl_class_tree_view;

   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }

   struct VS_TAG_BROWSE_INFO cm;
   int k = f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, cm, false)) {
      maybe_convert_proto_to_proc(cm);
      push_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no);
   }
}
_command void cb_delete()
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return;
   }

   VS_TAG_BROWSE_INFO cm,proto_cm,def_cm;
   int k = f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, cm, false)) {

      // check if there is a load-tags function, if so, bail out
      if (_QBinaryLoadTagsSupported(cm.file_name)) {
         _message_box(nls('Can not locate source code for %s.',cm.file_name));
         return;
      }

      proto_cm=cm;
      // This should never happen.
      if (!tag_tree_type_is_func(cm.type_name)) {
         return;
      }
      _str search_arguments  = VS_TAGSEPARATOR_args:+cm.arguments;
      boolean found_def=false;
      boolean found_proto=false;
      boolean comment_out_def=true;
      boolean comment_out_proto=true;
      /*
         Because when we see a function definition we don't know whether it is
         a nested class "outerClass::InnerClass::method" or a namespace
         "mynamespace::myclass::method, we look for both here.  This code has
         not been tested for nested namespaces because add member and a lot of
         other code does not work for nested namespaces.
      */
      //say('mem='cm.member_name' class='cm.class_name' s='search_arguments);
      //"member4"  "mynamespace/myclass" "char *psz"
      if (tag_find_tag(cm.member_name, 'proc', cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, 'func', cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, 'constr', cm.class_name, search_arguments)==0 ||
          tag_find_tag(cm.member_name, 'destr', cm.class_name, search_arguments)==0) {
         tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
         tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
         found_def=true;
      }
      if (!found_def) {
         _str temp_class_name=translate(cm.class_name,':','/');
         if (tag_find_tag(cm.member_name, 'proc', temp_class_name, search_arguments)==0 ||
             tag_find_tag(cm.member_name, 'func', temp_class_name, search_arguments)==0 ||
             tag_find_tag(cm.member_name, 'constr', temp_class_name, search_arguments)==0 ||
             tag_find_tag(cm.member_name, 'destr', temp_class_name, search_arguments)==0) {
            tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
            tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
            found_def=true;
         }
      }
      tag_reset_find_tag();
      def_cm=cm;
      cm=proto_cm;
      if (tag_find_tag(cm.member_name, 'proto', cm.class_name, search_arguments)==0) {
         tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
         tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
         found_proto=true;
      } else if (tag_find_tag(cm.member_name, 'procproto', cm.class_name, search_arguments)==0) {
         tag_get_info(cm.member_name, cm.type_name, cm.file_name, cm.line_no, cm.class_name, cm.flags);
         tag_get_detail(VS_TAGDETAIL_language_id,cm.language);
         found_proto=true;
      }
      tag_reset_find_tag();
      proto_cm=cm;
      int temp_view_id=0;
      int temp_view_id2=0;
      int orig_view_id;
      int buf_id2= -1;
      if (!found_proto) {
         comment_out_proto=comment_out_def;
         cm=def_cm;
      }
      int buf_id=_BufEdit(cm.file_name,'',false,'',true);
      if (buf_id<0) {
         if (buf_id==FILE_NOT_FOUND_RC) {
            _message_box(nls("File '%s' not found",cm.file_name));
         } else {
            _message_box(nls("Unable to open '%s'",cm.file_name)'.  'get_message(buf_id));
         }
         if (temp_view_id2) _delete_temp_view(temp_view_id2);
         return;
      }
      _open_temp_view('',temp_view_id,orig_view_id,'+bi 'buf_id);
      if (_QReadOnly()) {
         _message_box(nls("File '%s' is read only",p_buf_name));
         if (temp_view_id2) _delete_temp_view(temp_view_id2);
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return;
      }
      if (found_proto && found_def) {
         buf_id2=_BufEdit(def_cm.file_name,'',false,'',true);
         if (buf_id2<0) {
            if (buf_id2==FILE_NOT_FOUND_RC) {
               _message_box(nls("File '%s' not found",def_cm.file_name));
            } else {
               _message_box(nls("Unable to open '%s'",def_cm.file_name)'.  'get_message(buf_id2));
            }
            if (temp_view_id2) _delete_temp_view(temp_view_id2);
            _delete_temp_view(temp_view_id);activate_window(orig_view_id);
            return;
         }
         int orig_view_id2;
         _open_temp_view('',temp_view_id2,orig_view_id2,'+bi 'buf_id2);
         if (_QReadOnly()) {
            _message_box(nls("File '%s' is read only",p_buf_name));
            if (temp_view_id2) _delete_temp_view(temp_view_id2);
            _delete_temp_view(temp_view_id);activate_window(orig_view_id);
            return;
         }
         //result=_message_box("A prototype and definition of this symbol has been found.  The definition will be commented out.\n\nDo you want to comment out the prototype","Delete "cm.member_name,MB_YESNOCANCEL);
         int result=_message_box("A prototype and definition of this symbol has been found.  The definition will be commented out.\n\nDelete prototype?  Select 'No' to comment out the prototype.","Delete "cm.member_name,MB_YESNOCANCEL,IDNO);
         if (result==IDCANCEL) {
            return;
         }
         comment_out_proto=(result==IDNO);

         activate_window(orig_view_id2);
      }

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      int status=_cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no,true);
      if (status) {
         if (temp_view_id2) _delete_temp_view(temp_view_id2);
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return;
      }

      int context_id = tag_current_context();
      if (context_id<0) {
         if (temp_view_id2) _delete_temp_view(temp_view_id2);
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         _message_box('Unable to find this function');
         return;
      }
      _TagDelayCallList();
      status=_c_delete_tag(context_id,comment_out_proto,!(found_def && found_proto));

      if (!status && !(found_proto && found_def && file_eq(def_cm.file_name,proto_cm.file_name))) {
      //if (!status && (!found_def || !file_eq(def_cm.file_name,proto_cm.file_name))) {
         status=_save_file(build_save_options(p_buf_name));
         if ( status ) {
            _message_box(nls('Unable to save file "%s"',p_buf_name)'.  'get_message(status));
         } else {
            TagFileOnSave();
         }
      }
      if (!status && found_proto && found_def) {
         cm=def_cm;
         activate_window(temp_view_id2);
         status=_cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no,true);
         if (!status) {
            context_id = tag_current_context();
            if (context_id<0) {
               _message_box(nls("Unable to find symbol %s in file '%s'",cm.member_name,cm.file_name));
            } else {
               status=_c_delete_tag(context_id,comment_out_def,true);
            }
         }
      }
      _TagProcessCallList();

      if (temp_view_id2) _delete_temp_view(temp_view_id2);
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
}
_command void cb_override_method()
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return;
   }

   struct VS_TAG_BROWSE_INFO cm;
   int k = f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, cm, false)) {

      // check if there is a load-tags function, if so, bail out
      if (_QBinaryLoadTagsSupported(cm.file_name)) {
         _message_box(nls('Can not locate source code for %s.',cm.file_name));
         return;
      }

      int orig_view_id,temp_view_id=0;
      int buf_id=_BufEdit(cm.file_name,'',false,'',true);
      if (buf_id<0) {
         if (buf_id==FILE_NOT_FOUND_RC) {
            _message_box(nls("File '%s' not found",cm.file_name));
         } else {
            _message_box(nls("Unable to open '%s'",cm.file_name)'.  'get_message(buf_id));
         }
         return;
      }
      _open_temp_view('',temp_view_id,orig_view_id,'+bi 'buf_id);
      if (_QReadOnly()) {
         _message_box(nls("File '%s' is read only",p_buf_name));
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return;
      }
      int status=_cb_goto_tag_in_file(cm.member_name, cm.file_name, cm.class_name, cm.type_name, cm.line_no,true);
      if (status) {
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         return;
      }

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);

      int context_id = tag_current_context();
      if (context_id<0) {
         _delete_temp_view(temp_view_id);activate_window(orig_view_id);
         _message_box('Unable to find this class');
         return;
      }
      int scope_seekpos=0;
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos, context_id, scope_seekpos);
      _GoToROffset(scope_seekpos);
      override_method(false,cm,!_LanguageInheritsFrom('c'));
      if(temp_view_id) {
         _delete_temp_view(temp_view_id);
      }
   }
}
_command void cb_add_member(_str option="")
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return;
   }

   struct VS_TAG_BROWSE_INFO cm;
   int k = f.ctl_class_tree_view._TreeCurIndex();
   if (f.ctl_class_tree_view.get_user_tag_info(k, cm, false)) {
      _c_add_member(cm,option != 0);
   }
}

//////////////////////////////////////////////////////////////////////////////
// Collapse all tree items except for the branch currently having focus
//
_command cb_collapse() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }

   _nocheck _control ctl_class_tree_view;

   se.util.MousePointerGuard hour_glass;
   int i = f.ctl_class_tree_view._TreeCurIndex();
   while (i > 0) {
      int p = f.ctl_class_tree_view._TreeGetParentIndex(i);
      int j = f.ctl_class_tree_view._TreeGetFirstChildIndex(p);
      while (j > 0) {
         if (j!=i) {
            int show_children=0;
            f.ctl_class_tree_view._TreeGetInfo(j, show_children);
            if (show_children != TREE_NODE_LEAF) {
               f.ctl_class_tree_view._TreeDelete(j, 'c');
               if (show_children>0) {
                  f.ctl_class_tree_view._TreeSetInfo(j, TREE_NODE_COLLAPSED);
               }
            }
         }
         j = f.ctl_class_tree_view._TreeGetNextSiblingIndex(j);
      }
      i=p;
   }
}

//////////////////////////////////////////////////////////////////////////////
// Return the number of children under tree index 'i'
//
int cb_tree_count_children(int t, int index)
{
   int count=0;
   int child = t._TreeGetFirstChildIndex(index);
   while (child > 0) {
      ++count;
      child = t._TreeGetNextSiblingIndex(child);
   }
   return count;
}

//////////////////////////////////////////////////////////////////////////////
// Expand the current item and its children
//
_command cb_expand_twolevels() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }
   _nocheck _control ctl_class_tree_view;

   gi_in_refresh=1;
   se.util.MousePointerGuard hour_glass;
   f.ctl_class_tree_view.p_redraw = false;
   int i = f.ctl_class_tree_view._TreeCurIndex();
   if (i >= 0) {

      int show_children;
      f.ctl_class_tree_view._TreeGetInfo(i, show_children);
      if (show_children == TREE_NODE_COLLAPSED) {
         call_event(CHANGE_EXPANDED,i,f.ctl_class_tree_view,ON_CHANGE,'w');
         f.ctl_class_tree_view._TreeSetInfo(i, TREE_NODE_EXPANDED);
      }

      int count = 0;
      int child = f.ctl_class_tree_view._TreeGetFirstChildIndex(i);
      while (child > 0) {
         f.ctl_class_tree_view._TreeGetInfo(child, show_children);
         if (show_children==TREE_NODE_COLLAPSED) {
            call_event(CHANGE_EXPANDED,child,f.ctl_class_tree_view,ON_CHANGE,'w');
            f.ctl_class_tree_view._TreeSetInfo(child, TREE_NODE_EXPANDED);
            int incr = f.ctl_class_tree_view._TreeGetNumChildren(child)+1;
            count += incr;
            if (count % def_cbrowser_flood_refresh < incr) {
               _str caption = f.ctl_class_tree_view._TreeGetCaption(i);
               int r = cb_warn_overflow(f.ctl_class_tree_view, i, caption, count);
               if (r >= CB_NOAHS_WATER_MARK) {
                  break;
               }
            }

         }
         child = f.ctl_class_tree_view._TreeGetNextSiblingIndex(child);
      }
   }
   f.ctl_class_tree_view.p_redraw = true;
   gi_in_refresh=0;
}

/**
 * Recursively expand the current item and its chidren.
 * 
 * @param index    Index of node to expand.
 * @param count    [out]  Number of children expanded.
 * @param onChange true=Call tree's ON_CHANGE event with CHANGE_EXPANDED for reason.
 * 
 * @return 0 on success, 1 if the water mark is hit.
 */
int do_expand_children(int index, int &count, boolean onChange=true)
{
   se.util.MousePointerGuard hour_glass(MP_DEFAULT);
   if (index >= 0) {
      int show_children=0;
      _TreeGetInfo(index, show_children);
      if (show_children==TREE_NODE_COLLAPSED) {
         if( onChange ) {
            call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w');
         }
         _TreeSetInfo(index, TREE_NODE_EXPANDED);
      }

      // check if we need to break out of loop
      int incr = _TreeGetNumChildren(index)+1;
      count+=incr;
      if (count % def_cbrowser_flood_refresh < incr) {
         _str caption = _TreeGetCaption(index);
         hour_glass.setMousePointer(MP_HOUR_GLASS);
         int r = cb_warn_overflow(p_window_id, index, caption, count);
         if (r >= CB_NOAHS_WATER_MARK) {
            return(1);
         }
      }

      int child = _TreeGetFirstChildIndex(index);
      while (child > 0) {
         _TreeGetInfo(child, show_children);
         if (show_children!=TREE_NODE_LEAF) {
            if (do_expand_children(child,count,onChange)) {
               return(1);
            }
         }
         child = _TreeGetNextSiblingIndex(child);
      }
   }
   return(0);
}

/**
 * Recursively collapse the current item and its chidren.
 * 
 * @param index    Index of node to collapse.
 * @param onChange true=Call tree's ON_CHANGE event with CHANGE_COLLAPSED for reason.
 */
void do_collapse_children(int index, boolean onChange=true)
{
   if (index >= 0) {
      int show_children=0;
      _TreeGetInfo(index, show_children);
      if (show_children==TREE_NODE_EXPANDED) {
         _TreeSetInfo(index, TREE_NODE_COLLAPSED);
         if( onChange ) {
            call_event(CHANGE_COLLAPSED,index,p_window_id,ON_CHANGE,'w');
         }
      }

      int child = _TreeGetFirstChildIndex(index);
      while (child > 0) {
         _TreeGetInfo(child, show_children);
         if (show_children!=TREE_NODE_LEAF) {
            do_collapse_children(child,onChange);
         }
         child = _TreeGetNextSiblingIndex(child);
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// Expand the current item and its children
//
_command cb_expand_children() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }
   _nocheck _control ctl_class_tree_view;

   gi_in_refresh=1;
   se.util.MousePointerGuard hour_glass;
   f.ctl_class_tree_view.p_redraw = false;
   int i = f.ctl_class_tree_view._TreeCurIndex();
   if (i >= 0) {
      int count=0;
      f.ctl_class_tree_view.do_expand_children(i,count,true);
   }
   f.ctl_class_tree_view.p_redraw = true;
   gi_in_refresh=0;
}

//////////////////////////////////////////////////////////////////////////////
// Collapse all tree items except list of projects
//
_command cb_crunch() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return('');
   }

   _nocheck _control ctl_class_tree_view;

   se.util.MousePointerGuard hour_glass;
   int j = f.ctl_class_tree_view._TreeGetFirstChildIndex(0);
   while (j > 0) {
      int show_children=0;
      f.ctl_class_tree_view._TreeGetInfo(j, show_children);
      if (show_children!=TREE_NODE_LEAF) {
         f.ctl_class_tree_view._TreeDelete(j, 'c');
         if (show_children==TREE_NODE_EXPANDED) {
            f.ctl_class_tree_view._TreeSetInfo(j, TREE_NODE_COLLAPSED);
         }
      }
      j = f.ctl_class_tree_view._TreeGetNextSiblingIndex(j);
   }
}


//############################################################################
//////////////////////////////////////////////////////////////////////////////
// Skip over the contents of a C style string
//
/*
static int skip_c_string(_str params,int j,_str ch)
{
   _str re='[\\\'ch']';
   for (;;) {
      j=pos(re,params,j,'r');
      if (!j) {
         // String not terminated.
         return(length(params)+1);
      }
      ch=substr(params,j,1);
      if (ch=='\') {
         j+=2;
         continue;
      }
      return(j+1);
   }
}
*/

//////////////////////////////////////////////////////////////////////////////
// Skip over nested parameter sets (parents, <>, [], etc)
//
/*
static int skip_nested(_str params,int j,_str start_ch,_str end_ch)
{
   int nesting=1;
   _str re='[\'start_ch'\'end_ch']';
   for (;;) {
      j=pos(re,params,j,'r');
      //messageNwait('re='re' j='j' end_ch='end_ch);
      if (!j) {
         return(length(params)+1);
      }
      _str ch=substr(params,j,1);
      if (ch==start_ch) {
         ++nesting;
         ++j;
         continue;
      }
      --nesting;
      //messageNwait('nesting='nesting);
      ++j;
      if (nesting<=0) {
         //messageNwait('j='j);
         return(j);
      }
   }
}
*/

//////////////////////////////////////////////////////////////////////////////
// Get the next argument from the given string, pass find_first==1
// to get the first argument.
//
// NOTE:  cb_next_arg() is deprecated.
//        tag_get_next_argument() should be used instead.
//
#define NEXTARG_CHARS1  '[:;,<\[("''\n]'
static int gnext_arg_index;
_str cb_next_arg(_str params,int &arg_pos,int find_first,_str ext=null)
{
   _str argument='';
   if (find_first) gnext_arg_index=1;
   arg_pos = tag_get_next_argument(params, gnext_arg_index, argument, ext);
   return argument;

   /*
   boolean ispascal=((pos(';',params) || pos(':',params)) &&
                     !pos(':[',params) && !pos('::',params))? 1:0;
   if (_LanguageInheritsFrom('verilog',ext)) {
      ispascal=false;
   }

   int next_arg_index = arg_pos;
   if (next_arg_index==0) {
      next_arg_index=1;
   }

   // skip leading spaces
   _str ch=substr(params,next_arg_index,1);
   while ((ch==' ' || ch=="\t") && next_arg_index <= length(params)) {
      next_arg_index++;
      ch=substr(params,next_arg_index,1);
   }
   // pull next argument off of list
   int j=next_arg_index;
outer_loop:
   for (;;) {
      //say('params='substr(params,1,80) ' index=' j);
      j=pos(NEXTARG_CHARS1,params,j,'r');
      if (!j) {
         j=length(params)+1;
         break;
      }
      ch=substr(params,j,1);
      switch (ch) {
      case ':':
         //if (!ispascal) {
            ++j;
         //}
         break;
      case ',':
         if (!ispascal) {
            break outer_loop;
         }
         ++j;
         break;
      case ';':
         break outer_loop;
      case "\n":
         break outer_loop;
      case '<':
         j=skip_nested(params,j+1,ch,'>');
         break;
      case '[':
         j=skip_nested(params,j+1,ch,']');
         break;
      case '(':
         j=skip_nested(params,j+1,ch,')');
         break;
      case '"':
      case "'":
         j=skip_c_string(params,j+1,ch);
         break;
      }
   }
   if (j<next_arg_index) {
      return('');
   }
   arg_pos = j+1;
   _str result=substr(params,next_arg_index,j-next_arg_index);
   return (strip(result));
   */
}

_str getTextSymbolFromBitmapId(int bmid)
{
   if (gmap_bitmapid_to_symbol._indexin(bmid))
      return gmap_bitmapid_to_symbol:[bmid];
   return " ";
}

int _get_cb_pic_index(int nAccessType, int nType)
{
   if( (nAccessType < 0)               ||
       (nAccessType > CB_access_LAST)  ||
       (nType < 0)                     ||
       (nType > CB_type_LAST) ) {
      return -1;
   }

   return gi_pic_access_type[nAccessType][nType];
}

static void doDefLoad()
{
   // project and category open/close pictures
   gi_pic_proj_open  = _pic_fldtags;
   gi_pic_proj_close = _pic_fldctags;
   gi_pic_cat_open   = _pic_fldopen12;
   gi_pic_cat_close  = _pic_fldclos12;

   // pictures we have not yet loaded
   _str pics_not_loaded='';
   int result = 0;

   // loop through all access levels and tag picture types
   // and load the picture.  Substitute _pic_file for any
   // that fail to load.
   int i,j,status;
   for (i=0; i<=CB_access_LAST; ++i) {
      _str zaccess = gi_code_access[i].name;
      _str zdesc   = gi_code_access[i].description;
      for (j=0; j<=CB_type_LAST; ++j) {
         if (i>0 && gi_code_type[j].global_only) {
            status = gi_pic_access_type[0][j];
         } else {
            _str ztype = gi_code_type[j].name;
            _str filename = CB_pic_class_prefix :+ ztype :+ zaccess :+ CB_pic_bitmap;
            status=_update_picture(-1,filename);
            if (status<0) {
               result = status;
               status = _pic_file12;
               if (pics_not_loaded == '') {
                  pics_not_loaded = filename;
               } else {
                  pics_not_loaded = pics_not_loaded ', ' filename;
               }
            } else if (gi_code_type[j].description != '') {
               _str descr;
               if (gi_code_type[j].global_only) {
                  descr = gi_code_type[j].description;
               } else {
                  descr = gi_code_type[j].description ', ' zdesc;
               }
               replace_name(status, filename, descr);
            }
         }
         gi_pic_access_type[i][j] = status;
         // set reverse mapping
         gmap_bitmapid_to_symbol:[status] = gi_code_type[j].text_symbol;
      }
   }

   gmap_bitmapid_to_symbol:[_pic_file]       = "||";
   gmap_bitmapid_to_symbol:[_pic_file_d]     = "||";
   gmap_bitmapid_to_symbol:[_pic_file12]     = "||";
   gmap_bitmapid_to_symbol:[_pic_file_d12]   = "||";
   gmap_bitmapid_to_symbol:[_pic_fldclos]    = "[]";
   gmap_bitmapid_to_symbol:[_pic_fldopen]    = "[]";
   gmap_bitmapid_to_symbol:[_pic_fldclos12]  = "[]";
   gmap_bitmapid_to_symbol:[_pic_fldopen12]  = "[]";
   gmap_bitmapid_to_symbol:[_pic_func]       = "Fn";
   gmap_bitmapid_to_symbol:[_pic_workspace]  = "[W]";

   // report any errors loading pictures.
   if (result) {
      _message_box(nls('Unable to load picture(s) "%s"',pics_not_loaded)'. 'get_message(result));
   }
}

/**
 * Returns a copy of the gi_pic_access_type matrix of picture IDs.  This is 
 * required because gi_pic_access_type is declared static. 
 */
int getAccessPicMatrix() [][]
{
   return gi_pic_access_type;
}

/**
 * Define the container form name for the symbol browser.
 * 
 * @param containerFormName
 *               container form name
 */
_command void cbrowser_setFormName(_str containerFormName=TBCBROWSER_FORM)
{
   // Access the container form in the view.
   int formwid = _find_object(containerFormName,'n');
   if( formwid==0 ) {
      return;
   }
   gtbcbrowser_wid=formwid;

   // Do the remaining defload
   doDefLoad();
}

#define CBROWSER_FORM_NAME_STRING    "_tbcbrowser_form"
#define PROCTREE_FORM_NAME_STRING    "_tbproctree_form"
#define CBPROPS_FORM_NAME_STRING     "_tbprops_form"
#define CBPARENTS_FORM_NAME_STRING   "_cbparents_form"
#define CBCALLS_FORM_NAME_STRING     "_cbcalls_form"
#define FINDSYMBOL_FORM_NAME_STRING  "_tbfind_symbol_form"

/**
 * Used by various tool windows to stay in synch.
 */
int _GetProctreeWID()
{
#if 1
   int wid = _find_formobj(PROCTREE_FORM_NAME_STRING,'n');
#else
   static int proctreeLastFormWID;

   int wid = 0;
   if( _iswindow_valid(proctreeLastFormWID) &&
       proctreeLastFormWID.p_object==OI_FORM &&
       proctreeLastFormWID.p_name==PROCTREE_FORM_NAME_STRING &&
       !proctreeLastFormWID.p_edit){

      wid=proctreeLastFormWID;
   }else{
      wid=_find_formobj(PROCTREE_FORM_NAME_STRING,'N');
      proctreeLastFormWID=wid;
   }
#endif
   return wid;
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetCBrowserWID()
{
#if 1
   int wid = _find_formobj(CBROWSER_FORM_NAME_STRING,'n');
#else
   static int cbLastFormWID;

   int wid = 0;
   if( _iswindow_valid(cbLastFormWID) &&
       cbLastFormWID.p_object==OI_FORM &&
       cbLastFormWID.p_name==CBROWSER_FORM_NAME_STRING &&
       !cbLastFormWID.p_edit){

      wid=cbLastFormWID;
   } else {
      wid=_find_formobj(CBROWSER_FORM_NAME_STRING,'N');
      cbLastFormWID=wid;
   }
#endif
   return wid;
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetCBrowserParentsWID()
{
#if 1
   int wid = _find_formobj(CBPARENTS_FORM_NAME_STRING,'n');
#else
   static int cbpLastFormWID;

   int wid = 0;
   if( _iswindow_valid(cbpLastFormWID ) &&
       cbpLastFormWID.p_object==OI_FORM &&
       cbpLastFormWID.p_name==CBPARENTS_FORM_NAME_STRING &&
       !cbpLastFormWID.p_edit ){

      wid=cbpLastFormWID;
   } else {
      wid=_find_formobj(CBPARENTS_FORM_NAME_STRING,'n');
      cbpLastFormWID=wid;
   }
#endif
   return wid;
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetCBrowserCallTreeWID()
{
#if 1
   int wid = _find_formobj(CBCALLS_FORM_NAME_STRING,'n');
#else
   static int cbctLastFormWID;

   int wid = 0;
   if( _iswindow_valid(cbctLastFormWID) &&
       cbctLastFormWID.p_object==OI_FORM &&
       cbctLastFormWID.p_name==CBCALLS_FORM_NAME_STRING &&
       !cbctLastFormWID.p_edit ){

      wid=cbctLastFormWID;
   } else {
      wid=_find_formobj(CBCALLS_FORM_NAME_STRING,'n');
      cbctLastFormWID=wid;
   }
#endif
   return wid;
}

/**
 * Used by various tool windows to stay in synch.
 */
int _GetCBrowserPropsWID()
{
#if 1
   int wid = _find_formobj(CBPROPS_FORM_NAME_STRING,'N');
#else
   static int cbtLastFormWID;

   int wid = 0;
   if( _iswindow_valid(cbtLastFormWID) &&
       cbtLastFormWID.p_object==OI_FORM &&
       cbtLastFormWID.p_name==CBPROPS_FORM_NAME_STRING &&
       !cbtLastFormWID.p_edit ){

      wid=cbtLastFormWID;
   } else {
      wid=_find_formobj(CBPROPS_FORM_NAME_STRING,'N');
      cbtLastFormWID=wid;
   }
#endif
   return wid;
}

/**
 * Used by various tool windows to stay in synch.
 */
boolean CBrowseFocus()
{
   int FocusWID = _get_focus();
   // try symbol browser tool window
   _nocheck _control ctl_class_tree_view;
   int CBrowserWID = _GetCBrowserWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID.ctl_class_tree_view) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try defs tool window
   _nocheck _control _proc_tree;
   CBrowserWID = _GetProctreeWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID._proc_tree) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try inheritance tree
   _nocheck _control ctl_member_tree_view;
   _nocheck _control ctl_inheritance_tree_view;
   CBrowserWID=_GetCBrowserParentsWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID.ctl_member_tree_view || FocusWID==CBrowserWID.ctl_inheritance_tree_view) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try tag properties tool window
   CBrowserWID=_GetCBrowserPropsWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try call tree tool window
   _nocheck _control ctl_call_tree_view;
   CBrowserWID=_GetCBrowserCallTreeWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID.ctl_call_tree_view) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // try call references tool window
   _nocheck _control ctlreferences;
   CBrowserWID=_GetReferencesWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID || FocusWID==CBrowserWID.ctlreferences) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   _nocheck _control ctl_file_list;
   _nocheck _control ctl_workspace_list;
   _nocheck _control ctl_project_list;
   _nocheck _control ctl_filter;
   CBrowserWID=_GetFilesToolTreeWID();
   if( CBrowserWID>0 && (FocusWID==CBrowserWID
                         || FocusWID==CBrowserWID.ctl_file_list
                         || FocusWID==CBrowserWID.ctl_workspace_list
                         || FocusWID==CBrowserWID.ctl_project_list
                         || FocusWID==CBrowserWID.ctl_filter
                         ) ) {
      CBrowserWID=_GetTagwinWID();
      return true;
   }
   // no tagging window in focus
   return false;
}

/**
 * Set a breakpoint or watchpoing on the current item selected in the
 * symbol browser tool window.
 */
_command int cb_set_breakpoint() name_info(','VSARG2_EDITORCTL)
{
   int f = GetCBViewWid();
   if (!f) {
      messageNwait("_tbcbrowser_form " nls("not found"));
      return 0;
   }
   _nocheck _control ctl_class_tree_view;
   int currIndex = f.ctl_class_tree_view._TreeCurIndex();
   struct VS_TAG_BROWSE_INFO cm;
   f.ctl_class_tree_view.get_user_tag_info(currIndex, cm, false);

   return debug_set_breakpoint_on_tag(cm);
}

/**
 * Kill the symbol browser timer when we reload
 */
void _on_load_module_cbrowser(_str module)
{
   cb_kill_timer();
}

