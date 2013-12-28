////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46364 $
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
#ifndef CBROWSER_SH
#define CBROWSER_SH

//////////////////////////////////////////////////////////////////////////////
// Tag file categories, there are two types of tag files, project tag
// files, and global tag files.
//
#define CB_project_tag_file     "Workspace"
#define CB_global_tag_file      "Global"
#define CB_cpp_compiler_tag_file   "C++ Compiler"
#define CB_java_compiler_tag_file  "Java Compiler"
#define CB_autoupdated_tag_file "Auto Updated"

//////////////////////////////////////////////////////////////////////////////
// Code categories, every global tag goes into one of these
// categories.  Tags that are not in the global scope go under
// their respective class (in classes, structures, packages, etc).
//
#define CB_packages    "Packages/Namespaces"
#define CB_classes     "Classes"
#define CB_misc        "Miscellaneous"
#define CB_derived     "Derived Classes"
#define CB_bases       "Base Classes"
#define CB_includesCB  "Includes/Copy Books"
#define CB_includes    "Includes"

//////////////////////////////////////////////////////////////////////////////
// String appended to a category name to indicate that it is only a partial
// list of items.  Delimiter used between category name and "PARTIAL LIST".
#define CB_partial    "PARTIAL LIST"
#define CB_delimiter  "...."
#define CB_empty      "EMPTY"

//////////////////////////////////////////////////////////////////////////////
// Tab indexes of the tabs on the tag properties toolbar
//
#define CB_PROPERTIES_TAB_INDEX 0
#define CB_ARGUMENTS_TAB_INDEX  1
//#define CB_REFERENCES_TAB_INDEX 2
//#define CB_CALLSUSES_TAB_INDEX  3

//////////////////////////////////////////////////////////////////////////////
// Timer used for delaying updates after change-selected events,
// allowing you to quickly scroll through the items in the symbol browser.
// It is safer for this to global instead of static.
//
#define CB_TIMER_DELAY_MS 200

//////////////////////////////////////////////////////////////////////////////
// Bit combinations representing symbol browser options (see options dialog).
// A mask is composed for each tag inserted based on these bit combinations
// and then compared with the filtering options masks.
// If the options do not match up, the tag is filtered out.
//
#define CB_SHOW_class_data           0x00000001
#define CB_SHOW_instance_data        0x00000002
#define CB_SHOW_out_of_line          0x00000004
#define CB_SHOW_inline               0x00000008
#define CB_SHOW_static               0x00000010
#define CB_SHOW_non_virtual          0x00000020
#define CB_SHOW_virtual              0x00000040
#define CB_SHOW_abstract             0x00000080
#define CB_SHOW_operators            0x00000100
#define CB_SHOW_constructors         0x00000200
#define CB_SHOW_final_members        0x00000400
#define CB_SHOW_non_final_members    0x00000800
#define CB_SHOW_const_members        0x00001000
#define CB_SHOW_non_const_members    0x00002000
#define CB_SHOW_volatile_members     0x00004000
#define CB_SHOW_non_volatile_members 0x00008000
#define CB_SHOW_template_classes     0x00010000
#define CB_SHOW_non_template_classes 0x00020000
#define CB_SHOW_package_members      0x00040000
#define CB_SHOW_private_members      0x00080000
#define CB_SHOW_protected_members    0x00100000
#define CB_SHOW_public_members       0x00200000
#define CB_SHOW_inherited_members    0x00400000
#define CB_SHOW_class_members        0x00800000
#define CB_SHOW_data_members         0x01000000
#define CB_SHOW_other_members        0x02000000
#define CB_SHOW_non_abstract         0x04000000
#define CB_SHOW_non_special          0x08000000
#define CB_SHOW_transient_data       0x10000000
#define CB_SHOW_persistent_data      0x20000000
#define CB_SHOW_synchronized         0x40000000
#define CB_SHOW_non_synchronized     0x80000000
#define CB_QUALIFIERS                0xffffffff
#define CB_DEFAULTS                  (CB_QUALIFIERS & ~(CB_SHOW_inherited_members))

#define CB_SHOW_native               0x00000001
#define CB_SHOW_non_native           0x00000002
#define CB_SHOW_extern               0x00000004
#define CB_SHOW_non_extern           0x00000008
#define CB_SHOW_macros               0x00000010
#define CB_SHOW_non_macros           0x00000020
#define CB_SHOW_anonymous            0x00000040
#define CB_SHOW_non_anonymous        0x00000080
#define CB_QUALIFIERS2               0x000000ff
#define CB_DEFAULTS2                 (CB_QUALIFIERS2 & ~(CB_SHOW_anonymous))

//////////////////////////////////////////////////////////////////////////////
// Bit combinations representing properties display options for Uses tab
//
#define CBP_SHOW_procs    0x0001
#define CBP_SHOW_classes  0x0002
#define CBP_SHOW_vars     0x0004
#define CBP_SHOW_misc     0x0008

//////////////////////////////////////////////////////////////////////////////
// Access levels for class members.  These constants are used to index into
// the array of pictures.  See gi_pic_access_type[][], below.
//
#define CB_access_public     0
#define CB_access_protected  1
#define CB_access_private    2
#define CB_access_package    3
#define CB_access_LAST       3

//////////////////////////////////////////////////////////////////////////////
// Picture types used for displaying different tag types.  Each tag maps
// on to one of these pictures.  The default picture is 'function', used
// for all un-identified tags.  These constants are used to index into
// the array of pictures.  See gi_pic_access_type[][], below.
//
// anything <= CB_TYPE_miscellaneous is a leaf
#define CB_type_function         0
#define CB_type_prototype        1
#define CB_type_data             2
#define CB_type_operator         3
#define CB_type_constructor      4
#define CB_type_destructor       5
#define CB_type_enumeration      6
#define CB_type_typedef          7
#define CB_type_define           8
#define CB_type_property         9
#define CB_type_constant        10
#define CB_type_label           11
#define CB_type_import          12
#define CB_type_friend          13
#define CB_type_index           14
#define CB_type_trigger         15
#define CB_type_control         16
#define CB_type_menu            17
#define CB_type_param           18
#define CB_type_proc            19
#define CB_type_procproto       20
#define CB_type_include         21
#define CB_type_file            22
#define CB_type_subfunc         23
#define CB_type_subproc         24
#define CB_type_cursor          25
#define CB_type_annotation      26
// 27--27 -- reserved for expansion
#define CB_type_unknown         28
#define CB_type_miscellaneous   29
// anything >= CB_TYPE_struct is a container
#define CB_type_struct          30
#define CB_type_enum            31
#define CB_type_class           32
#define CB_type_template        33
#define CB_type_base_class      34
#define CB_type_package         35
#define CB_type_union           36
#define CB_type_database        37
#define CB_type_table           38
#define CB_type_form            39
#define CB_type_eventtab        40
#define CB_type_task            41
#define CB_type_group           42
#define CB_type_tag             43
#define CB_type_statement       45
#define CB_type_annotype        46
#define CB_type_call            47
#define CB_type_if              48
#define CB_type_misc            49
#define CB_type_loop            50
#define CB_type_break           51
#define CB_type_continue        52
#define CB_type_return          53
#define CB_type_goto            54
#define CB_type_try             55
#define CB_type_preprocessing   56
#define CB_type_interface       57
#define CB_type_constr_proto    58
#define CB_type_destr_proto     59
#define CB_type_target		     60 
#define CB_type_operator_proto  61
#define CB_type_assign          62
#define CB_type_selector        63
#define CB_type_selector_static 64
#define CB_type_LAST            64
// 63--99 -- reserved for expansion

//////////////////////////////////////////////////////////////////////////////
// Strings used in tag bitmap file names.  The naming convention is
// _clsXXXN.bmp, where XXX is the three letter code for this type
// (see gi_code_type), and N is the access level (see gi_code_access).
//
#define CB_pic_class_prefix  '_cls'
#define CB_pic_bitmap        '.bmp'
#define CB_pic_icon          '.ico'

//////////////////////////////////////////////////////////////////////////////
// Fudge factor used when calculating text column widths
//
#define CB_TEXT_WIDTH_MARGIN 200

#endif // CBROWSER_SH
