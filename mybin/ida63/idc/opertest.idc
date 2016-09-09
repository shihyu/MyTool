//
//      This example shows how to use GetOperandValue() function.
//

#include <idc.idc>

static main() {
  auto ea;

  for ( ea = MinEA(); ea != BADADDR; ea=FindCode(ea,1) ) {
    auto x;
    x = GetOperandValue(ea,0);
    if ( x != -1 ) Message("%08lX: operand 1 = %08lX\n",ea,x);
    x = GetOperandValue(ea,1);
    if ( x != -1 ) Message("%08lX: operand 2 = %08lX\n",ea,x);
    x = GetOperandValue(ea,2);
    if ( x != -1 ) Message("%08lX: operand 3 = %08lX\n",ea,x);
  }
}
