//
// This file is executed when IDA detects Turbo Pascal DOS application.
//

#include <idc.idc>

static main()
{
        auto start, init, halt;

        // Set pascal type strings. Just in case
        SetLongPrm(INF_STRTYPE,ASCSTR_PASCAL);

        start = GetLongPrm(INF_BEGIN_EA);

        // Give pascal style name to the entry point
        // and delete the bogus one-instruction function
        // which was created by the startup signature
        MakeName(start,"PROGRAM");
        DelFunction(start);

        // Plan to create a good PROGRAM function instead of
        // the deleted one
        AutoMark(start,AU_PROC);

        // Get address of the initialization subrountine
        init  = Rfirst0(start);
        MakeName(init,"@__SystemInit$qv");

        // Delete the bogus function which was created by the secondary
        // startup signature.
        DelFunction(init);

        // Create a good initialization function
        MakeFunction(init,BADADDR);
        SetFunctionFlags(init,FUNC_LIB|GetFunctionFlags(init));

        // find sequence of
        //      xor     cx, cx
        //      xor     bx, bx
        // usually Halt() starts with these instructions

        halt  = FindBinary(init,1,"33 c9 33 db");

        // If we have found the sequence then define Halt() function
        // with FUNC_NORET attribute
        if ( halt != BADADDR ) {
          MakeName(halt,"@Halt$q4Word");
          MakeFunction(halt,BADADDR);
          SetFunctionFlags(halt,FUNC_NORET|FUNC_LIB|GetFunctionFlags(halt));
        }
}
