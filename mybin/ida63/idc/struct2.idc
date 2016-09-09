//
//      This example shows how to use structure manipulation functions.
//

#include <idc.idc>

#define MAXSTRUCT       200

// Create MAXSTRUT structures.
// Each structure will have 3 fields:
//      - a byte array field
//      - a word field
//      - a structure field

static main()
{
  auto i, idx, name, id2;

  for ( i=0; i < MAXSTRUCT; i++ )
  {
    name = form("str_%03d", i);
    idx = AddStruc(-1, name);                   // create a structure
    if ( idx == -1 )                            // if not ok
    {
      Warning("Can't create structure %s, giving up",name);
      break;
    }
    else
    {
      AddStrucMember(idx,
                     "bytemem",
                     GetStrucSize(idx),
                     FF_DATA|FF_BYTE,
                     -1,
                     5*1);                      // char[5]
      AddStrucMember(idx,
                     "wordmem",
                     GetStrucSize(idx),
                     FF_DATA|FF_WORD,
                     -1,
                     1*2);                      // short
      id2 = GetStrucIdByName(form("str_%03d",i-1));
      if ( i != 0 ) AddStrucMember(idx,
                     "inner",
                     GetStrucSize(idx),
                     FF_DATA|FF_STRU,
                     id2,
                     GetStrucSize(id2));        // sizeof(str_...)
      Message("Structure %s is successfully created, idx=%08lX, prev=%08lX\n",
                                                        name, idx, id2);
    }
  }
  Message("Done, total number of structures: %d\n",GetStrucQty());
}
