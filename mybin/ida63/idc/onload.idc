//
//      This IDC file is called after a new file is loaded into IDA
//      database.
//      IDA calls "OnLoad" function from this file.
//
//      You may use this function to read extra information (such as
//      debug information) from the input file, or for anything else.
//

#include <idc.idc>

//      If you want to add your own processing of newly created databases,
//      you may create a file named "userload.idc":
//
//      #define USERLOAD_IDC
//      static userload(input_file,real_file,filetype) {
//              ... your processing here ...
//      }
//

#softinclude <userload.idc>

// Input parameteres:
//      input_file - name of loaded file
//      real_file  - name of actual file that contains the input file.
//                   usually this parameter is equal to input_file,
//                   but is different if the input file is extracted from
//                   an archive.
//      filetype   - type of loaded file. See FT_.. definitions in idc.idc

static OnLoad(input_file, real_file, filetype)
{
#ifdef USERLOAD_IDC             // if user-defined IDC file userload.idc
                                // exists...
  if ( userload(input_file, real_file, filetype) )
    return;
#endif
  if ( filetype == FT_DRV )
    DriverLoaded();
//  Message("File %s is loaded into the database.\n",input_file);
}


//--------------------------------------------------------------------------
//      This function is executed when a new device driver is loaded.
//              Device drivers have extensions DRV or SYS.
//
// History:
//
// 08/12/95 20:16 by Alexey Kulentsov:
// + Check for Device Request Block
// + Kludge with Drv/Com supported
// 04/01/96 04:21 by ig:
// + 0000:0000 means end of devices chain too.
// 16/05/96 16:01 by ig:
// + modified to work with the new version of IDA (separate operand types)

static DriverLoaded(void)
{
  auto x,i,base;
  auto intr,strt;
  auto attr,cmt;
  auto nextbase;
  auto DevReq;

  i = 0;
  x = MinEA();
  base = (x >> 4);   // The segment base

  while ( 1 )
  {
    Message("Device driver block at %04X\n",x);

    MakeName(x,form("NextDevice_%ld",i));
    MakeWord(x);
    OpNumber(x,0);
    if ( Word(x) == 0xFFFF ) {
      MakeComm(x,"The last device");
    } else {
      nextbase = base + Word(x+2);
      OpOff(x,0,nextbase<<4);
      MakeComm(x,"Offset to the next device");
    }

    MakeWord(x+2);
    OpNumber(x+2,0);

    MakeName(x+4,form("DevAttr_%ld",i));
    MakeWord(x+4);
    OpNumber(x+4,0);
    attr = Word(x+4);
    cmt = "";
    if ( attr & (1<< 0) ) cmt = cmt + "stdin device\n";
    if ( attr & (1<< 1) ) cmt = cmt + ((attr & (1<<15)) ? "stdout device\n" : ">32M\n");
    if ( attr & (1<< 2) ) cmt = cmt + "stdnull device\n";
    if ( attr & (1<< 3) ) cmt = cmt + "clock device\n";
    if ( attr & (1<< 6) ) cmt = cmt + "supports logical devices\n";
    if ( attr & (1<<11) ) cmt = cmt + "supports open/close/RM\n";
    if ( attr & (1<<13) ) cmt = cmt + "non-IBM block device\n";
    if ( attr & (1<<14) ) cmt = cmt + "supports IOCTL\n";
    cmt = cmt + ((attr & (1<<15)) ? "character device" : "block device");
    MakeComm(x+4,cmt);

    MakeName(x+6,form("Strategy_%ld",i));
    MakeWord(x+6);
    OpOff(x+6,0,MinEA());

    MakeName(x+8,form("Interrupt_%ld",i));
    MakeWord(x+8);
    OpOffset(x+8,MinEA());

    MakeName(x+0xA,form("DeviceName_%ld",i));
    MakeStr (x+0xA,8);
    MakeComm(x+0xA,"May be device number");

    strt = (base << 4) + Word(x+6);
    intr = (base << 4) + Word(x+8);
    MakeCode( strt );
    MakeCode( intr );
    AutoMark( strt, AU_PROC );
    AutoMark( intr, AU_PROC );
    MakeName( strt, form("Strategy_Routine_%ld",i));
    MakeName( intr, form("Interrupt_Routine_%ld",i));
    MakeComm( strt, "ES:BX -> Device Request Block");
    MakeComm( intr, "Device Request Block:\n"
          "0 db length\n"
      "1 db unit number\n"
      "2 db command code\n"
      "5 d? reserved\n"
      "0D d? command specific data");

    if( Byte( strt )==0x2E && Word(strt+1)==0x1E89
     && Byte(strt+5)==0x2E && Word(strt+6)==0x068C
     && Word(strt+3)==Word(strt+8)-2)
    {
     DevReq=Word(strt+3);
     Message("DevReq at %x\n",DevReq);
     MakeUnkn(x+DevReq,0);MakeUnkn(x+DevReq+2,0);
     MakeDword(x+DevReq);MakeName(x+DevReq,form("DevRequest_%ld",i));
    }

    if ( Word(x) == 0xFFFF ||
       ((Byte(x)==0xE9 || Byte(x)==0xEB) && i==0) ) break;
    if ( Dword(x) == 0 ) break; // 04.01.96
    x = (nextbase << 4) + Word(x);
    i = i + 1;
  }
}
