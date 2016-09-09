//
// This file is executed when IDA detects Turbo Pascal DLL
//

#include <idc.idc>

static main()
{
        auto start, init, exit;

        // Set pascal type strings. Just in case
        SetLongPrm(INF_STRTYPE,ASCSTR_PASCAL);

        // System unit used protected commands so
        // set protected mode processor
        SetPrcsr("80386p");

        start = GetLongPrm(INF_BEGIN_EA);

        // Give pascal style name to the entry point
        // and delete the bogus one-instruction function
        // which was created by the startup signature
        MakeName(start,"LIBRARY");
        DelFunction(start);
        
        // Plan to create a good PROGRAM function instead of
        // the deleted one
        AutoMark(start,AU_PROC);

        // Get address of the initialization subrountine
        init  = Rfirst0(start+5);
        MakeName(init,"@__SystemInit$qv");

        // Delete the bogus function which was created by the secondary
        // startup signature.
        DelFunction(init);

        // Create a good initialization function
        MakeFunction(init,BADADDR);
        SetFunctionFlags(init,FUNC_LIB|GetFunctionFlags(init));

        // Check for presence of LibExit() function
        exit = LocByName("@__LibExit$qv");

        // If we have found function then define it
        // with FUNC_NORET attribute
        if ( exit != BADADDR ) {
          MakeFunction(exit,BADADDR);
          SetFunctionFlags(exit,FUNC_NORET|FUNC_LIB|GetFunctionFlags(exit));
        }
}
