
//
//      Redefine the predefined bits for 8051 processor.
//      Before using the script you need to create
//      a enum called "BitFlags" and enter the bit
//      definitions there.
//
//      This file is provided by an IDA user.
//-------
//      By just defining the bits I want
//      in "BitFlags", only those have the operand overriden.
//      Cross references even work for the new names.  Life is good!
//      I do have to re-run this every time I add a new bit
//      to the enumeration.


#include <idc.idc>

static main() {
  auto ea, enumID, constID;

  enumID = GetEnum("BitFlags");
  if ( enumID == -1 )
        return;
  for ( ea = MinEA(); ea != BADADDR; ea=FindCode(ea,1) ) {
    auto x;

    x = GetOpType(ea,0);
    if ( x != 8 ) continue;

    Message("addr %x\n",ea);
    x = Byte(ea+1);
    constID = GetConst(enumID,x,-1);
    if ( constID != -1 ){
        OpAlt(ea,0,GetConstName(constID));
    }
  }
}

