////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once

#include "vsdecl.h"


//////////////////////////////////////////////////////////////////////
// "C" style API for creating and accessing BTREE references database.
//

//////////////////////////////////////////////////////////////////////
// Flags associated with tags, denoting access restrictions and
// and other attributes of class members (proc's, proto's, and var's)
//    NOT virtual and NOT static implies normal class method
//    NOT const implies normal read/write access
//    NOT volatile implies normal optimizations are safe
//
#define VS_INSTFLAG_static       0x01
#define VS_INSTFLAG_virtual      0x02
#define VS_INSTFLAG_volatile     0x04
#define VS_INSTFLAG_const        0x08

//////////////////////////////////////////////////////////////////////
// Standard reference types
//
#define VS_REFTYPE_unknown    0     // unspecified type of reference
#define VS_REFTYPE_macro      1     // use of #define'd macro
#define VS_REFTYPE_call       2     // function or procedure call
#define VS_REFTYPE_var        3     // use of a variable
#define VS_REFTYPE_import     4     // use of a package
#define VS_REFTYPE_derive     5     // class derivation
#define VS_REFTYPE_type       6     // use of abstract type
#define VS_REFTYPE_class      7     // instantiation of class
#define VS_REFTYPE_constant   8     // use of constant value or enum value
#define VS_REFTYPE_label      9     // use of label for goto


///////////////////////////////////////////////////////////////////////////
// Functions for tracking tag instances
  
/**
 * Add a new tag instance and return the unique tag ID associated
 * with this new instance.  If an exact match already exists in the
 * database, then just return the existing ID.
 * 
 * @param inst_name        name of tag instance (case insensitive)
 * @param inst_type        type of tag instance (see SETagTypes.h, SE_TAG_TYPE_*)
 * @param inst_flags       reference attributes (see VS_REFFLAG_*)
 * @param inst_class       class associated with tag (zero for global)
 * @param inst_args        arguments associated with tag (eg. function args)
 * @param file_name        name of file where tag instance is located
 * @param line_no          line which tag instace is on
 *
 * @return tag instance ID on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_insert_instance(VSPSZ inst_name, VSPSZ inst_type, int inst_flags,
                              VSPSZ inst_class, VSPSZ inst_args,
                              VSPSZ file_name, int line_no);

/**
 * Extract the supplementary information associated with a tag instance.
 * 
 * @param inst_id          unique ID of instance to get info about
 *                         (use tag_match_instance() to get this ID)
 * @param inst_name        (reference) name of tag instance (case insensitive)
 * @param inst_type        (reference) type of tag instance (see SETagTypes.h, SE_TAG_TYPE_*)
 * @param inst_flags       (reference) reference attributes (see VS_REFFLAG_*)
 * @param inst_class       (reference) class associated with tag (zero for global)
 * @param inst_args        (reference) arguments associated with tag (eg. function args)
 * @param file_name        (reference) name of file where tag instance is located
 * @param line_no          (reference) line which tag instace is on
 */
EXTERN_C
void VSAPI tag_get_instance_info(int inst_id, VSHREFVAR inst_name,
                                 VSHREFVAR inst_type,  VSHREFVAR inst_flags,
                                 VSHREFVAR inst_class, VSHREFVAR inst_args,
                                 VSHREFVAR file_name,  VSHREFVAR line_no);

/**
 * Locate the tag instance matching the given parameters.
 * Instances are matched by tag name first (which must match),
 * then class, type, flags, arguments, and finally file and
 * line proximity.
 * 
 * @param inst_name        name of tag instance (case insensitive)
 * @param inst_type        type of tag instance (see SETagTypes.h, SE_TAG_TYPE_*)
 * @param inst_flags       reference attributes (see VS_REFFLAG_*)
 * @param inst_class       class associated with tag (zero for global)
 * @param inst_args        arguments associated with tag (eg. function args)
 * @param file_name        name of file where tag instance is located
 * @param line_no          line which tag instace is on
 * @param case_sensitive   case sensitive name/class/args comparison
 *
 * @return The ID of the the most exact match available, or <0 on error.
 */
EXTERN_C
int VSAPI tag_match_instance(VSPSZ inst_name, VSPSZ inst_type, int inst_flags,
                             VSPSZ inst_class, VSPSZ inst_args,
                             VSPSZ file_name, int line_no, int case_sensitive);


///////////////////////////////////////////////////////////////////////////
// Functions for tracking tag references
  
/**
 * Add a tag reference located in the given file name and line number
 * showing the tag instance (refto_id) used within the context
 * (refby_id), also a tag instance.  refby_id==0 implies the tag
 * was used as a global or the context is unknown.
 * 
 * @param refto_id         unique ID of tag referenced (from tag_insert_instance)
 * @param refby_id         unique ID of tag context (from tag_insert_instance)
 * @param ref_file         name of references (browse db or object) file
 * @param ref_type         type of reference (see VS_REFTYPE_*)
 * @param file_name        name of file where reference occurs
 * @param line_no          line where reference occurs
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_insert_reference(int refto_id, int refby_id, VSPSZ ref_file,
                               int ref_type, VSPSZ file_name, int line_no);

/**
 * Find the first tag instance referenced by the given tag instance.
 * The tag is identified by its unique ID, see tag_match_instance().
 * This is typically used with functions (caller/callee relationship)
 * or structures (container/item relationships).
 * 
 * @param inst_id          unique identifier of calling function.
 * @param ref_type         (reference) reference type (see VS_REFTYPE_*)
 * @param file_name        (reference) full path of file the tag is located in
 * @param line_no          (reference) line number of tag within file
 *
 * @return instance ID on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_find_refer_to(int inst_id, VSHREFVAR ref_type,
                            VSHREFVAR file_name, VSHREFVAR line_no);

/**
 * Find the next tag instance referenced by the given tag instance.
 * The tag is identified by its unique ID, see tag_match_instance().
 * This is typically used with functions (caller/callee relationship).
 * 
 * @param inst_id          unique identifier of calling function.
 * @param ref_type         (reference) reference type (see VS_REFTYPE_*)
 * @param file_name        (reference) full path of file the tag is located in
 * @param line_no          (reference) line number of tag within file
 *
 * @return instance ID on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_next_refer_to(int inst_id, VSHREFVAR ref_type,
                            VSHREFVAR file_name, VSHREFVAR line_no);

/**
 * Find the first location in which the given tag is referenced.
 * The tag is identified by its unique ID, see tag_match_instance().
 * 
 * @param inst_id          unique identifier of calling function.
 * @param ref_type         (reference) reference type (see VS_REFTYPE_*)
 * @param file_name        (reference) full path of file the tag is located in
 * @param line_no          (reference) line number of tag within file
 *
 * @return instance ID on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_find_refer_by(int inst_id, VSHREFVAR ref_type,
                            VSHREFVAR file_name, VSHREFVAR line_no);

/**
 * Find the next location in which the given tag is referenced.
 * The tag is identified by its unique ID, see ref_match_instance().
 * 
 * @param inst_id         unique identifier of calling function.
 * @param ref_type        (reference) reference type (see VS_REFTYPE_*)
 * @param file_name       (reference) full path of file the tag is located in
 * @param line_no         (reference) line number of tag within file
 *
 * @return instance ID on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_next_refer_by(int inst_id, VSHREFVAR ref_type,
                            VSHREFVAR file_name, VSHREFVAR line_no);


// TAGS_REF_H
