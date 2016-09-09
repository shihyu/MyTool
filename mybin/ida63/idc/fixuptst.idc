//
//      This example shows how to get fixup information about the file.
//

#include <idc.idc>

static main() {
  auto ea;
  for ( ea = GetNextFixupEA(MinEA());
        ea != BADADDR;
        ea = GetNextFixupEA(ea) ) {
    auto type,sel,off,dis,x;
    type = GetFixupTgtType(ea);
    sel  = GetFixupTgtSel(ea);
    off  = GetFixupTgtOff(ea);
    dis  = GetFixupTgtDispl(ea);
    Message("%08lX: ",ea);
    x = type & FIXUP_MASK;
         if ( x == FIXUP_BYTE  ) Message("BYTE ");
    else if ( x == FIXUP_OFF16 ) Message("OFF16");
    else if ( x == FIXUP_SEG16 ) Message("SEG16");
    else if ( x == FIXUP_PTR32 ) Message("PTR32");
    else if ( x == FIXUP_OFF32 ) Message("OFF32");
    else if ( x == FIXUP_PTR48 ) Message("PTR48");
    else if ( x == FIXUP_HI8   ) Message("HI8  ");
    else                         Message("?????");
    Message((type & FIXUP_EXTDEF) ? " EXTDEF" : " SEGDEF");
    Message(" [%s,%X]",SegName(SegByBase(sel)),off);
    if ( type & FIXUP_EXTDEF  ) Message(" (%s)",Name([AskSelector(sel),off]));
    if ( type & FIXUP_SELFREL ) Message(" SELF-REL");
    if ( type & FIXUP_UNUSED  ) Message(" UNUSED");
    Message("\n");
  }
}
