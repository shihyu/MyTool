////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef TAGS_TREE_H
#define TAGS_TREE_H

#include "vsdecl.h"


//////////////////////////////////////////////////////////////////////////////
// file name and line number limits used for calculating user info
//
#define CB_MAX_LINE_NUMBER       0x100000  // 1048576 -- lines per file
#define CB_MAX_FILE_NUMBER       0x100000  // 1048576 -- file ID, was 65536
#define CB_TAG_FILE_MULT_HIGH    ((CB_MAX_LINE_NUMBER>>16) * (CB_MAX_FILE_NUMBER>>16))
#define CB_TAG_FILE_MULT_LOW     (CB_MAX_FILE_NUMBER / CB_TAG_FILE_MULT_HIGH)

//////////////////////////////////////////////////////////////////////////////
// filtering options
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

#define CB_SHOW_native               0x00000001
#define CB_SHOW_non_native           0x00000002
#define CB_SHOW_extern               0x00000004
#define CB_SHOW_non_extern           0x00000008
#define CB_SHOW_macros               0x00000010
#define CB_SHOW_non_macros           0x00000020
#define CB_SHOW_anonymous            0x00000040
#define CB_SHOW_non_anonymous        0x00000080
#define CB_QUALIFIERS2               0x000000ff

//////////////////////////////////////////////////////////////////////////////
// picture indexes used by class browser
//
#define CB_access_public     0
#define CB_access_protected  1
#define CB_access_private    2
#define CB_access_package    3
#define CB_access_LAST       3

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
#define CB_type_target		    60 
#define CB_type_operator_proto  61
#define CB_type_assign          62
#define CB_type_selector        63
#define CB_type_selector_static 64
#define CB_type_LAST            64
// 63--99 -- reserved for expansion


///////////////////////////////////////////////////////////////////////////
// Class browser related functions

/**
 * Speed-demon way to determine if the given type is a variable type.
 * (var, gvar, lvar, param, prop).
 *
 * @param type_name       string specifying tag's type name (from tag_get_info)
 *
 * @return Returns 1 if the item is a func, 0, otherwise.
 */
EXTERN_C
int VSAPI tag_tree_type_is_data(VSPSZ type_name);

/**
 * Determine whether the type is a statement type.
 *
 * @param type_name        string specifying tag's type name (from tag_get_info)
 *
 * @return 1 if the item is a statement, 0, otherwise.
 */
EXTERN_C
int VSAPI tag_tree_type_is_statement(VSPSZ type_name);

/**
 * Speed-demon way to determine if the given type is a function or
 * procedure type. (proc, proto, func, constr, or destr).
 *
 * @param type_name        string specifying tag's type name (from tag_get_info)
 *
 * @return 1 if the item is a func, 0, otherwise.
 */
EXTERN_C
int VSAPI tag_tree_type_is_func(VSPSZ type_name);

/**
 * Speed-demon way to determine if the given type is a class, struct,
 * or union (class, struct, union).
 *
 * @param type_name        string specifying tag's type name (from tag_get_info)
 *
 * @return 1 if the item is a class, 0, otherwise.
 */
EXTERN_C
int VSAPI tag_tree_type_is_class(VSPSZ type_name);

/**
 * Speed-demon way to determine if the given type is a package,
 * library, or program (package, lib, prog).
 *
 * @param type_name        string specifying tag's type name (from tag_get_info)
 *
 * @return 1 if the item is a package, 0, otherwise.
 */
EXTERN_C
int VSAPI tag_tree_type_is_package(VSPSZ type_name);

/**
 * Encode class name, member name, signature, etc. in order to make
 * caption for tree item very quickly.  Returns the resulting tree caption
 * as a NULL terminated string.
 *
 * The output string is generally formatted as follows:
 * <PRE>
 *    member_name[()] <tab> [class_name::member_name[(arguments)]
 * </PRE>
 * Parenthesis are added only for function types (proc, proto, constr, destr, func).
 * The result is returned as a pointer to a static character array.
 *
 * This function is highly optimized, since it is one of the most
 * critical code paths used by the class browser.
 *
 * @param member_name      tag name
 * @param type_name        tag type (from tag_get_info)
 * @param class_name       enclosing class name for tag (from tag_get_info)
 * @param flags            tag flags (from tag_get_info)
 * @param arguments        tag argumetns (from tag_get_detail)
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 *
 * @return caption as a statically allocated string.
 */
EXTERN_C
VSPSZ VSAPI tag_tree_make_caption(VSPSZ member_name, VSPSZ type_name, VSPSZ class_name,
                                  int flags, VSPSZ arguments, int include_tab);

/**
 * Accellerated version of tag_tree_make_caption for handling case where
 * you are creating a caption for the current tag, local, context, or
 * match item.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param match_type       VS_TAGMATCH_*
 * @param local_or_ctx_id  local, context, or match ID, 0 for current tag
 * @param include_class    if 0, does not include class name
 * @param include_args     if 0, does not include function signature
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 *
 * @return The result is returned as a pointer to a static character array.
 */
EXTERN_C
VSPSZ VSAPI tag_tree_make_caption_fast(int match_type, int local_or_ctx_id,
                                       int include_class, int include_args, int include_tab);

/**
 * Parse member name out of caption generated using tag_tree_make_caption().
 *
 * @param caption         generated tag caption
 * @param member_name     (reference) tag name only
 * @param class_name      (optional, reference) class name
 * @param arguments       (optional, reference) function arguments
 */
EXTERN_C void VSAPI
tag_tree_decompose_caption(VSPSZ caption, VSHREFVAR member_name);

/**
 * Filter the given item based on the given filtering flags, and
 * determine the access level and member type.
 *
 * @param filter_flags     filtering options flags (see CB_SHOW_*) above
 * @param type_name        tag type (from tag_get_info)
 * @param in_class         if 1, treat as a class member, (class_name != '')
 * @param tag_flags        tag bit flags (from tag_get_info)
 * @param i_access         (reference) access level output
 * @param i_type           (reference) item type for selecting icon
 *
 * @return 0 if the item is filtered out, 1 if it passes the filters.
 */
EXTERN_C
int VSAPI tag_tree_filter_member(int filter_flags, VSPSZ type_name, int in_class,
                                 int tag_flags, VSHREFVAR i_access, VSHREFVAR i_type);
/**
 * Filter the given item based on the given filtering flags, and
 * determine the access level and member type.
 *
 * @param filter_flags_1   filtering options flags, part 1 (see CB_SHOW_*) above
 * @param filter_flags_2   filtering options flags, part 2 (see CB_SHOW_*) above
 * @param type_name        tag type (from tag_get_info)
 * @param in_class         if 1, treat as a class member, (class_name != '')
 * @param tag_flags        tag bit flags (from tag_get_info)
 * @param i_access         (reference) access level output
 * @param i_type           (reference) item type for selecting icon
 *
 * @return 0 if the item is filtered out, 1 if it passes the filters.
 */
EXTERN_C
int VSAPI tag_tree_filter_member2(int filter_flags_1, int filter_flags_2,
                                  VSPSZ type_name, int in_class, int tag_flags,
                                  VSHREFVAR i_access, VSHREFVAR i_type);

/**
 * This function is called to prepare this module for inserting a large
 * number of tags from a common class or category.  It copies a number
 * of options and parameters into globals where they are accessed only
 * by vsTagTreeAddClassMember().  This mitigates the parameter passing
 * overhead normally required by vsTagTreeAddClassMember.
 *
 * @param f                window ID of form containing the class tree view
 * @param i                tree index which items will be inserted under
 * @param t                window ID of class browser tree view
 * @param in_refresh       non-zero if we are in a refresh operation
 * @param class_filter     regular expression for class filtering
 * @param member_filter    regular expression for member filtering
 * @param exception_name   name of tag to be allowed as an exception even
 *                         if class/member/attribute filtration fails.
 * @param filter_flags     attribute (flag-based) filtration flags
 * @param icons            two-dimensional array of tag bitmaps
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_tree_prepare_expand(int f, int i, int t, int in_refresh,
                                  VSPSZ class_filter, VSPSZ member_filter,
                                  VSPSZ exception_name, int filter_flags,
                                  VSHREFVAR icons);

/**
 * This function is used to get the picture indexes of the icons
 * corresponding to the given i_access level and i_type category.
 * You must call tag_tree_prepare_expand() prior to calling this function.
 * i_access and i_type are typically obtained from tag_tree_filter_member.
 *
 * @param i_access         access level
 * @param i_type           item type for selecting icon
 * @param leaf_flag        (reference) is this item a container or leaf?
 * @param pic_member       (reference) picture index for bitmap
 *
 * @return nothing.
 */
EXTERN_C
void VSAPI tag_tree_select_bitmap(int i_access, int i_type,
                                  VSHREFVAR leaf_flag, VSHREFVAR pic_member);

/**
 * Simple to use, but very fast entry point for selecting the bitmap
 * to be displayed in the tree control corresponding to the given
 * tag information.  You must call tag_tree_prepare_expand() prior to
 * calling this function.
 *
 * @param filter_flags_1  first part of class browser filter flags
 * @param filter_flags_2  second part of class browser filter flags
 * @param type_name       tag type name
 * @param class_name      tag class name, just checked for null/empty
 * @param tag_flags       tag flags, bitset of VS_TAGFLAG_*
 * @param leaf_flag       (reference) -1 implies leaf item, 0 or 1 container
 * @param pic_member      (reference) set to picture index of bitmap
 *
 * @return 0 on success, <0 on error, >0 if filtered out.
 */
EXTERN_C int VSAPI
tag_tree_get_bitmap(int filter_flags_1, int filter_flags_2,
                    VSPSZ type_name, VSPSZ class_name, int tag_flags,
                    VSHREFVAR leaf_flag, VSHREFVAR pic_member);

/**
 * Add the members of the given class to the class browser tree view.
 *
 * @param class_name       name of class to add members of
 * @param in_file_name     only add class members located in given file
 * @param tag_file_id      unique numeric ID for tag file
 * @param in_count         (reference, input, output), number of items inserted
 *
 * @return nothing
 */
EXTERN_C
int VSAPI tag_tree_add_members_of(VSPSZ class_name, VSPSZ in_file_name,
                                  int tag_file_id, VSHREFVAR in_count);

/**
 * Add members with type t1 to the given category where the tag flags and
 * the given mask are either zero or non-zero, as required by nzero.
 *
 * @param t1               tag type ID
 * @param mask             bit mask (see VS_TAGFLAG_*, in tagsdb.h)
 * @param nzero            add member if (mask & tag_flags) is zero or nonzero?
 * @param category_name    tag category to add members from
 * @param in_count         (reference, input, output), number of items inserted
 *
 * @return 0 on error, <0 on error.
 */
EXTERN_C
int VSAPI tag_tree_add_members_in_category(int t1, int mask, int nzero,
                                           VSPSZ category_name,
                                           VSHREFVAR in_count);

/**
 * Add members with type t1 to the given category where the tag flags and
 * the given mask are either zero or non-zero, as required by nzero.
 *
 * @param prefix           tag name prefix to search for
 * @param t1               tag type ID
 * @param mask             bit mask (see VS_TAGFLAG_*, in tagsdb.h)
 * @param nzero            add member if (mask & tag_flags) is zero or nonzero?
 * @param category_name    tag category to add members from
 * @param in_count         (reference, input, output), number of items inserted
 *
 * @return 0 on error, <0 on error.
 */
EXTERN_C
int VSAPI tag_tree_add_members_in_section(VSPSZ prefix, int t1, int mask, int nzero,
                                          VSPSZ category_name, VSHREFVAR in_count);

/**
 * Create the canonical tag display string of the form:
 * <PRE>
 *    tag_name(class_name:type_name)flags
 * </PRE>
 * This is used to speed up find-tag and maketags for languages that
 * do not insert tags from DLLs.
 *
 * @param tag_name         the name of the tag
 * @param class_name       class/container the tag belongs to
 * @param type_name        the tag type, (see VS_TAGTYPE_*)
 *                         (optional) integer tag flags (see VS_TAGFLAG_*)
 *
 * @return The result is returned as a pointer to a statically allocated
 *         character string.
 */
EXTERN_C
VSPSZ VSAPI tag_tree_compose_tag(VSPSZ tag_name,
                                 VSPSZ class_name, VSPSZ type_name);

/**
 * Decompose the canonical tag display string of the form:
 * <PRE>
 *    tag_name(class_name:type_name)flags
 * </PRE>
 * This is used to speed up find-tag and maketags for languages that
 * do not insert tags from DLLs.
 *
 * All output strings are set to the empty string if they do not match,
 * tag_flags is set to 0 if there is no match.
 *
 * @param proc_name        tag display string
 * @param tag_name         (reference) the name of the tag
 * @param class_name       (reference) class/container the tag belongs to
 * @param type_name        (reference) the tag type, (see VS_TAGTYPE_*)
 * @param tag_flags        (reference) integer tag flags (see VS_TAGFLAG_*)
 *
 * @return nothing.
 */
EXTERN_C
void VSAPI tag_tree_decompose_tag(VSPSZ proc_name,
                                  VSHREFVAR tag_name,  VSHREFVAR class_name,
                                  VSHREFVAR type_name, VSHREFVAR tag_flags);

/**
 * Pretty-print function arguments to output buffer
 *
 * @param signature        signature, straight from the database
 *
 * @return The output is returned in a staticly allocated string pointer.
 */
EXTERN_C
VSPSZ VSAPI tag_tree_format_args(VSPSZ signature);

/**
 * API function for inserting a tag entry with supporting info into
 * the given tree control.
 *
 * @param tree_wid         window ID of the tree control
 * @param tree_index       parent index to insert item under
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 * @param force_leaf       if < 0, force leaf node, otherwise choose by type
 * @param tree_flags       flags passed to vsTreeAddItem
 * @param tag_name         name of entry
 * @param type_name        type of tag, (see VS_TAGTYPE_*)
 * @param file_name        path to file that is located in
 * @param line_no          line number that tag is positioned on
 * @param class_name       name of class that tag belongs to
 * @param tag_flags        tag attributes (see VS_TAGFLAG_*)
 * @param signature        arguments and return type 
 * @param user_info        per node user data for tree control 
 *
 * @return tree index on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_tree_insert_tag(int tree_wid, int tree_index,
                              int include_tab, int force_leaf,
                              int tree_flags,
                              VSPSZ tag_name, VSPSZ type_name,
                              VSPSZ file_name, int line_no,
                              VSPSZ class_name, int tag_flags,
                              VSPSZ signature /*, VSHVAR user_info=0*/ );

/**
 * Insert the given context, local, match, or current tag
 * into the given tree.
 *
 * @param tree_id          tree widget to load info into
 * @param tree_index       tree index to insert into
 * @param match_type       VS_TAGMATCH_*
 * @param local_or_ctx_id  local, context, or match ID, 0 for current tag
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 * @param force_leaf       force item to be inserted as a leaf item
 * @param tree_flags       tree flags to set for this item
 * @param include_sig      include function/define/template signature
 * @param include_class    include class name
 * @param user_info        per node user data for tree control 
 *
 * @return tree index on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_tree_insert_fast(int tree_id, int tree_index,
                               int match_type, int local_or_ctx_id,
                               int include_tab, int force_leaf, int tree_flags,
                               int include_sig, int include_class
                               /*, VSHVAR user_info=0*/ );

/**
 * API function for inserting a tag entry with supporting info into
 * the given list control.
 *
 * @param list_wid         window ID of the list control
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 * @param indent_x         indent after bitmap, if 0, use default of 60 (TWIPS)
 * @param tag_name         name of entry
 * @param type_name        type of tag, (see VS_TAGTYPE_*)
 * @param file_name        path to file that is located in
 * @param line_no          line number that tag is positioned on
 * @param class_name       name of class that tag belongs to
 * @param tag_flags        tag attributes (see VS_TAGFLAG_*)
 * @param signature        arguments and return type
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_list_insert_tag(int list_wid, int include_tab, int indent_x,
                              VSPSZ tag_name, VSPSZ type_name,
                              VSPSZ file_name, int line_no,
                              VSPSZ class_name, int tag_flags,
                              VSPSZ signature);

/**
 * Compare the two argument lists, this method works for both
 * Delphi/Pascal/Ada style arguments and C/C++/Java style arguments.
 *
 * @param arg_list1        argument list number 1
 * @param arg_list2        argument list number 2
 * @param unqualify        loose comparison, peel off class qualifications
 *
 * @return 0 if they match, nonzero otherwise.
 */
EXTERN_C
int VSAPI tag_tree_compare_args(VSPSZ arg_list1, VSPSZ arg_list2, int unqualify VSDEFAULT(0));

/**
 * This function sets the user data for the given node in the given tree
 * calculated using the algorithm designed for the class browser, creating
 * a (potentially) large integer that may be decomposed to reveal a
 * tag file ID, file ID, and line number.
 *
 * @param tree_wid         tree control to set user info for
 * @param tree_index       index of node in tree to set info at
 * @param tag_file_id      integer assigned to tag file that node comes from
 * @param file_id          file ID of item being added to tree (0 for current)
 * @param line_no          line number at which tag occurs
 *
 * @return nothing.
 */
EXTERN_C
void VSAPI tag_tree_set_user_info(int tree_wid, int tree_index,
                                  int tag_file_id, int file_id, int line_no);

/**
 * Register a new OEM-defined CB type for given type ID.
 *
 * @param type_id              Tag type ID, in range VS_TAGTYPE_OEM <= type_id <= VS_TAGTYPE_MAXIMUM
 * @param cb_type              Class browser type index for picture indices, in range CB_type_LAST+1 ...
 * @param pic_member_public    Picture index of bitmap for public scope symbol
 * @param pic_member_protected Picture index of bitmap for protected scope symbol
 * @param pic_member_private   Picture index of bitmap for private scope symbol
 * @param pic_member_package   Picture index of bitmap for package scope symbol
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_tree_register_cb_type(int type_id, int cb_type,
                                    int pic_member_public VSDEFAULT(-1), int pic_member_protected VSDEFAULT(-1),
                                    int pic_member_private VSDEFAULT(-1), int pic_member_package VSDEFAULT(-1));

/**
 * Unregister a OEM-defined CB type.
 *
 * @param type_id Tag type ID, in range VS_TAGTYPE_OEM <= type_id <= VS_TAGTYPE_MAXIMUM
 */
EXTERN_C
void VSAPI tag_tree_unregister_cb_type(int type_id);

#endif
// TAGS_TREE_H

