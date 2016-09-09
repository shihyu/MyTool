//
//      This example shows how to use structure manipulation functions.
//

#include <idc.idc>

static main() {
  auto idx,code;

  idx = AddStruc(-1,"str1_t");          // create a structure
  if ( idx != -1 ) {                    // if ok
    auto id2;
        // add member: offset from struct start 0, type - byte, 5 elements
    AddStrucMember(idx,"bytemem",0,FF_DATA|FF_BYTE,-1,5*1);
    AddStrucMember(idx,"wordmem",5,FF_DATA|FF_WORD,-1,1*2);
    SetMemberComment(idx,0,"This is 5 element byte array",0);
    SetMemberComment(idx,5,"This is 1 word",0);
    id2 = AddStruc(-1,"str2_t");        // create another structure
    AddStrucMember(id2,"first", 0,FF_DATA|FF_BYTE,-1,1*1);
    AddStrucMember(id2,"strmem",1,FF_DATA|FF_STRU,idx,GetStrucSize(idx));
    SetMemberComment(id2,1,"This is structure member",0);
  }

  for ( idx=GetFirstStrucIdx(); idx != -1; idx=GetNextStrucIdx(idx) ) {
    auto id,m;
    id = GetStrucId(idx);
    if ( id == -1 ) Fatal("Internal IDA error, GetStrucId returned -1!");
    Message("Structure %s:\n",GetStrucName(id));
    Message("  Regular    comment: %s\n",GetStrucComment(id,0));
    Message("  Repeatable comment: %s\n",GetStrucComment(id,1));
    Message("  Size              : %d\n",GetStrucSize(id));
    Message("  Number of members : %d\n",GetMemberQty(id));
    for ( m = 0;
          m != GetStrucSize(id);
          m = GetStrucNextOff(id,m) ) {
      auto mname;
      mname = GetMemberName(id,m);
      if ( mname == "" ) {
        Message("  Hole (%d bytes)\n",GetStrucNextOff(id,m)-m);
      } else {
        auto type;
        Message("  Member name   : %s\n",GetMemberName(id,m));
        Message("    Regular cmt : %s\n",GetMemberComment(id,m,0));
        Message("    Rept.   cmt : %s\n",GetMemberComment(id,m,1));
        Message("    Member size : %d\n",GetMemberSize(id,m));
        type = GetMemberFlag(id,m) & DT_TYPE;
             if ( type == FF_BYTE     ) type = "Byte";
        else if ( type == FF_WORD     ) type = "Word";
        else if ( type == FF_DWRD     ) type = "Double word";
        else if ( type == FF_QWRD     ) type = "Quadro word";
        else if ( type == FF_TBYT     ) type = "Ten bytes";
        else if ( type == FF_ASCI     ) type = "ASCII string";
        else if ( type == FF_STRU     ) type = form("Structure '%s'",GetStrucName(GetMemberStrId(id,m)));
        else if ( type == FF_XTRN     ) type = "Unknown external?!"; // should not happen
        else if ( type == FF_FLOAT    ) type = "Float";
        else if ( type == FF_DOUBLE   ) type = "Double";
        else if ( type == FF_PACKREAL ) type = "Packed Real";
        else                            type = form("Unknown type %08X",type);
        Message("    Member type : %s",type);
        type = GetMemberFlag(id,m);
             if ( isOff0(type)  ) Message(" Offset");
        else if ( isChar0(type) ) Message(" Character");
        else if ( isSeg0(type)  ) Message(" Segment");
        else if ( isDec0(type)  ) Message(" Decimal");
        else if ( isHex0(type)  ) Message(" Hex");
        else if ( isOct0(type)  ) Message(" Octal");
        else if ( isBin0(type)  ) Message(" Binary");
        Message("\n");
      }
    }
  }
  Message("Total number of structures: %d\n",GetStrucQty());
}
