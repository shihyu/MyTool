//
//
//      This example shows how to use cross-reference related functions.
//      It displays xrefs to the current location.
//

#include "idc.idc"

static main() {
  auto ea,flag,x,y;
  flag = 1;
  ea = ScreenEA();

//  add_dref(ea,ea1,dr_R);         // set data reference (read)
//  AddCodeXref(ea,ea1,fl_CN);          // set 'call near' reference
//  DelCodeXref(ea,ea1,1);

//
//      Now show all reference relations between ea & ea1.
//
  Message("\n*** Code references from " + atoa(ea) + "\n");
  for ( x=Rfirst(ea); x != BADADDR; x=Rnext(ea,x) )
    Message(atoa(ea) + " refers to " + atoa(x) + xrefchar() + "\n");

  Message("\n*** Code references to " + atoa(ea) + "\n");
  x = ea;
  for ( y=RfirstB(x); y != BADADDR; y=RnextB(x,y) )
    Message(atoa(x) + " is referred from " + atoa(y) + xrefchar() + "\n");

  Message("\n*** Code references from " + atoa(ea) + " (only non-trivial refs)\n");
  for ( x=Rfirst0(ea); x != BADADDR; x=Rnext0(ea,x) )
    Message(atoa(ea) + " refers to " + atoa(x) + xrefchar() + "\n");

  Message("\n*** Code references to " + atoa(ea) + " (only non-trivial refs)\n");
  x = ea;
  for ( y=RfirstB0(x); y != BADADDR; y=RnextB0(x,y) )
    Message(atoa(x) + " is referred from " + atoa(y) + xrefchar() + "\n");

  Message("\n*** Data references from " + atoa(ea) + "\n");
  for ( x=Dfirst(ea); x != BADADDR; x=Dnext(ea,x) )
    Message(atoa(ea) + " accesses " + atoa(x) + xrefchar() + "\n");

  Message("\n*** Data references to " + atoa(ea) + "\n");
  x = ea;
  for ( y=DfirstB(x); y != BADADDR; y=DnextB(x,y) )
    Message(atoa(x) + " is accessed from " + atoa(y) + xrefchar() + "\n");

}

static xrefchar()
{
  auto x, is_user;
  x = XrefType();

  is_user = (x & XREF_USER) ? ", user defined)" : ")";

  if ( x == fl_F )  return " (ordinary flow" + is_user;
  if ( x == fl_CF ) return " (call far"      + is_user;
  if ( x == fl_CN ) return " (call near"     + is_user;
  if ( x == fl_JF ) return " (jump far"      + is_user;
  if ( x == fl_JN ) return " (jump near"     + is_user;
  if ( x == dr_O  ) return " (offset"        + is_user;
  if ( x == dr_W  ) return " (write)"        + is_user;
  if ( x == dr_R  ) return " (read"          + is_user;
  if ( x == dr_T  ) return " (textual"       + is_user;
  return "(?)";
}
