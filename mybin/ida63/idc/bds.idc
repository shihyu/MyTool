//
// This file is executed when IDA detects Delphi6-7 or BDS2005-BDS2006
// invoked from pe_bds.pat
//
// Feel free to modify this file as you wish.
//

#include <idc.idc>

static main()
{
  // Set Delphi-Style string
  //SetLongPrm(INF_STRTYPE,ASCSTR_LEN4);

  // Set demangled names to display
  //SetCharPrm(INF_DEMNAMES,DEMNAM_NAME);

  // Set compiler to Delphi
  //SetCharPrm(INF_COMPILER,COMP_BP);
}


// Add old borland signatures
static bor32(ea)
{
  AddPlannedSig("bh32rw32");
  AddPlannedSig("b32vcl");
  SetOptionalSigs("bdsext/bh32cls/bh32owl/bh32ocf/b5132mfc/bh32dbe/b532cgw");
  return ea;
}

// Detect the latest version of Borland Cbuilder (Embarcadero)
static emb(ea)
{
  auto x;

  x = ea - 0x1A;
  if ( Byte(x)   == 'E'
    && Byte(x+1) == 'm'
    && Byte(x+2) == 'b' )
  {
    ResetPlannedSigs();
    AddPlannedSig("bds8rw32");
    AddPlannedSig("bds8vcl");
    SetOptionalSigs("bdsboost/bds8ext");
  }
  return ea;
}

