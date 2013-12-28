////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
/*

   Example
      vsDllExport("_command void proc1(int i,VSPSZ i,VSHVAR x)",0,0);

   Syntax:

   [_command] [return-type] func-name([type [var-name] [,type [var-name]...])

   type
      VSPVOID        Pointer to something  Slick-C can't call this.
      VSPSZ          NULL terminated string
      VSPLSTR        See typedef below.
      int
      long
      VSHVAR           Handle to interpreter variable
      VSHREFVAR        Call by reference handle to interpreter variable.
                       This type can be used as input to functions which
                       accept VSHVAR parameters.

   return-type may be one of the following
      VSPSZ
      VSPLSTR
      int
      long
      void

   Performance considerations:

      For best performance, use the VSHVAR or VSREFVAR param-type when
      operating on long strings instead of VSPSZ or VSPLSTR.  Then
      use the "vsHvarGetLstr" function to return a pointer to the
      interpreter variable. WARNING:  Pointers to interpreter variables
      returned by the vsHvarGetLstr function are NOT VALID after any
      interpreter variable is set.  Be sure to reset any pointer after
      setting other interpreter variables or calling other macros.
      You may modify the contents of the VSPLSTR pointer returned by
      vsHvarGetLstr so long as you do not make the string any longer.

      We suspect that using the int and long parameter types are no
      slower than using the VSHVAR type and converting the parameter yourself.
*/
#ifndef VSAPI_H
#define VSAPI_H

#if defined(_WIN32)
   #ifndef _WINDOWS_
      #ifndef STRICT
         #define STRICT
      #endif
      #include <windows.h>
      #include <windowsx.h>
   #endif
#else
   typedef struct _XDisplay Display;
   typedef union _XEvent XEvent;
#endif

#include "vsdecl.h"
//#include "rc.h"
#include "vs.h"

#include "vsheap.h"
#include "tagstree.h"
#include "tagsrefs.h"
#include "vsutf8.h"
#include "breakpt.h"
#include "vsmfundo.h"

#endif
