////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#ifndef QUICK_REFACTOR_SH
#define QUICK_REFACTOR_SH

#include "tagsdb.sh"

struct VS_TAG_LOCAL_INFO
{
   VS_TAG_BROWSE_INFO cm;

   // Name and type of local variable
   _str new_name;

   // Set by local analysis. Is this local a parameter to the extracted function.
   boolean is_param;
   boolean is_ref_param;
   boolean is_return_param;

   // Where the local is declared and used
   int declaration_flags;
   int used_flags;
   int modified_flags;
};

struct EXTRACT_METHOD_INFO
{
   VS_TAG_LOCAL_INFO    params[];
   VS_TAG_LOCAL_INFO    return_type;
   VS_TAG_BROWSE_INFO   function_cm; 
};

EXTRACT_METHOD_INFO gMethodInfo=null;
#endif
