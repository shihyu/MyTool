//
//      This file is executed when a new VxD is loaded.
//
//

#include <idc.idc>

//-----------------------------------------------------------------------
static Describe(ddb, i)
{
  auto next,x,servtab,j;
  auto vxdnum,maxserv;

  x = ddb;
  MakeDword(x);
  MakeComm (x,form("Next_%ld",i));
  next = Dword(x);
  if ( next != 0 ) OpOff(x,0,0);
  x = x + 4;

  MakeWord(x);
  MakeName(x,form("SDK_Version_%ld",i));
  OpNumber(x,0);
  x = x + 2;

  MakeWord(x);
  MakeName(x,form("Req_Device_Number_%ld",i));
  vxdnum = Word(x);
  OpNumber(x,0);
  x = x + 2;

  MakeByte(x);
  MakeName(x,form("Dev_Major_Version_%ld",i));
  OpNumber(x,0);
  MakeComm(x,"Major device number");
  x = x + 1;

  MakeByte(x);
  MakeName(x,form("Dev_Minor_Version_%ld",i));
  OpNumber(x,0);
  MakeComm(x,"Minor device number");
  x = x + 1;

  MakeWord(x);
  MakeName(x,form("Flags_%ld",i));
  OpNumber(x,0);
  MakeComm(x,"Flags for init calls complete");
  x = x + 2;

  MakeStr (x,x+8);
  MakeName(x,form("Name_%ld",i));
  MakeComm(x,"Device name");
  x = x + 8;

  MakeDword(x);
  MakeName(x,form("Init_Order_%ld",i));
  OpNumber(x,0);
  MakeComm(x,"Initialization Order");
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("Control_Proc_%ld",i));
  MakeComm(x,"Offset of control procedure");
  if ( (servtab=Dword(x)) != 0 )
  {
    OpOff(x,0,0);
    AutoMark( servtab, AU_PROC );
    MakeCode( servtab );
    if ( Name(servtab) == "" ) MakeName( servtab, form("Control_%ld",i) );
    if ( BeginEA() == BADADDR )
    {
      set_start_cs(0);
      set_start_ip(servtab);
    }
  }
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("V86_API_Proc_%ld",i));
  MakeComm(x,"Offset of API procedure (or 0)");
  if ( (servtab=Dword(x)) != 0 )
  {
    OpOff(x,0,0);
    AutoMark( servtab, AU_PROC );
    MakeCode( servtab );
    if ( Name(servtab) == "" ) MakeName( servtab, form("V86_%ld",i) );
  }
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("PM_API_Proc_%ld",i));
  MakeComm(x,"Offset of API procedure (or 0)");
  if ( (servtab=Dword(x)) != 0 )
  {
    OpOff(x,0,0);
    AutoMark( servtab, AU_PROC );
    MakeCode( servtab );
    if ( Name(servtab) == "" ) MakeName( servtab, form("PM_%ld",i) );
  }
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("V86_API_CSIP_%ld",i));
  MakeComm(x,"CS:IP of API entry point");
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("PM_API_CSIP_%ld",i));
  MakeComm(x,"CS:IP of API entry point");
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("Reference_Data_%ld",i));
  MakeComm(x,"Reference data from real mode");
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("Service_Table_Ptr_%ld",i));
  MakeComm(x,"Pointer to service table");
  if ( (servtab=Dword(x)) != 0 )
  {
    OpOff(x,0,0);
    if ( Name(servtab) == "" ) MakeName(servtab,form("Service_Table_%ld",i));
    maxserv = Dword(x+4);
    for ( j=0; j < maxserv; j++ ) MakeDword(servtab+j*4);
  }
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("Service_Size_%ld",i));
  MakeComm(x,"Number of services");
  x = x + 4;

  if ( servtab != 0 )
  {
    for ( j=0; j < maxserv; j++ )
    {
      auto fea;
      fea = Dword(servtab);
      if ( fea != 0 )           // service exists
      {
        auto funcname;
        funcname = GetVxdFuncName(vxdnum,j);
        if ( funcname == "" )
          funcname = form("unkserv_%lx",j);
        else
          funcname = substr(funcname, 0, strstr(funcname, ";"));
        if ( Name(fea) == "" ) MakeName(fea,funcname);
        AutoMark(fea,AU_PROC);
        MakeCode(fea);
      }
      servtab = servtab + 4;
    }
  }

  MakeDword(x);
  MakeName(x,form("Win32_Service_Table_%ld",i));
  MakeComm(x,"Pointer to Win32 services");
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("Prev_%ld",i));
  MakeComm(x,"Pointer to previous DDB");
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("Size_%ld",i));
  MakeComm(x,"Size of VxD_Desc_Block");
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("Reserved1_%ld",i));
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("Reserved2_%ld",i));
  x = x + 4;

  MakeDword(x);
  MakeName(x,form("Reserved3_%ld",i));
  x = x + 4;

  return next;
}

//-----------------------------------------------------------------------
static main()
{
  auto ea;
  auto i;

  i  = 0;
  ea = GetEntryPoint(1);        // VDD entry has ordinal 1
  while ( GetFlags(ea) != 0 )   // While ea points to valid address
  {
    ea = Describe(ea,i);
    if ( ea == 0 ) break;
    i = i + 1;
    if ( i >= 16 ) break;       // too many of them, something is wrong?
  }

  // set es=ds=cs for all 16bit segments
  for ( ea=FirstSeg(); ea != BADADDR; ea = NextSeg(ea) )
  {
    if ( GetSegmentAttr(ea, SEGATTR_BITNESS) != 0 ) continue;
    i = GetSegmentAttr(ea, SEGATTR_SEL);
    SegDefReg(ea, "es", i);
    SegDefReg(ea, "ds", i);
  }
  // do the same at the entry point
  ea = BeginEA();
  if ( ea != BADADDR && GetSegmentAttr(ea, SEGATTR_BITNESS) == 0 )
  {
    i = GetSegmentAttr(ea, SEGATTR_SEL);
    SetReg(ea, "ds", i);
    SetReg(ea, "es", i);
  }
}
