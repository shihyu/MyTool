//
//      This example shows how to get list of functions.
//

#include <idc.idc>

static main() {
  auto ea,x;

  for ( ea=NextFunction(0); ea != BADADDR; ea=NextFunction(ea) ) {
    Message("Function at %08lX: %s",ea,GetFunctionName(ea));
    x = GetFunctionFlags(ea);
    if ( x & FUNC_NORET ) Message(" Noret");
    if ( x & FUNC_FAR   ) Message(" Far");
    Message("\n");
  }
  ea = ChooseFunction("Please choose a function");
  Message("The user chose function at %08lX\n",ea);
}
