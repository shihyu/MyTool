//
//	This file is executed when a PalmPilot program is loaded.
//	You may customize it as you wish.
//
//	TODO:
//		- decompilation of various resource types
//		  (we don't have any information on the formats)
//

#include <idc.idc>

//-----------------------------------------------------------------------
//
// Process each resource and make some routine tasks
//
static process_segments()
{
  auto ea,segname,prefix;

  for ( ea=FirstSeg(); ea != BADADDR; ea=NextSeg(ea) )
  {
    segname = SegName(ea);
    prefix = substr(segname,0,4);
    if ( segname == "data0000" )
    {
      if ( Dword(ea) == 0xFFFFFFFF )
      {
        MakeDword(ea);
        MakeComm(ea,"Loader stores SysAppInfoPtr here");
      }
      continue;
    }
    if ( prefix == "TRAP" )
    {
      MakeWord(ea);
      OpHex(ea,0);
      MakeComm(ea,"System trap function code");
      continue;
    }
    if ( prefix == "tSTR" )
    {
      MakeStr(ea,SegEnd(ea));
      MakeComm(ea,"String resource");
      continue;
    }
    if ( prefix == "tver" )
    {
      MakeStr(ea,SegEnd(ea));
      MakeComm(ea,"Version number string");
      continue;
    }
    if ( prefix == "tAIN" )
    {
      MakeStr(ea,SegEnd(ea));
      MakeComm(ea,"Application icon name");
      continue;
    }
    if ( prefix == "pref" )
    {
      auto flags,cmt;
      flags = Word(ea);
      MakeWord(ea); OpHex(ea,0); MakeName(ea,"flags");
#define sysAppLaunchFlagNewThread  0x0001
#define sysAppLaunchFlagNewStack   0x0002
#define sysAppLaunchFlagNewGlobals 0x0004
#define sysAppLaunchFlagUIApp      0x0008
#define sysAppLaunchFlagSubCall    0x0010
      cmt = "";
      if ( flags & sysAppLaunchFlagNewThread ) cmt = cmt + "sysAppLaunchFlagNewThread\n";
      if ( flags & sysAppLaunchFlagNewStack  ) cmt = cmt + "sysAppLaunchFlagNewStack\n";
      if ( flags & sysAppLaunchFlagNewGlobals) cmt = cmt + "sysAppLaunchFlagNewGlobals\n";
      if ( flags & sysAppLaunchFlagUIApp     ) cmt = cmt + "sysAppLaunchFlagUIApp\n";
      if ( flags & sysAppLaunchFlagSubCall   ) cmt = cmt + "sysAppLaunchFlagSubCall";
      MakeComm(ea,cmt);
      ea = ea + 2;
      MakeDword(ea); OpHex(ea,0); MakeName(ea,"stack_size");
      ea = ea + 4;
      MakeDword(ea); OpHex(ea,0); MakeName(ea,"heap_size");
    }
  }
}

//-----------------------------------------------------------------------
//
//	Create a enumeration with system action codes
//
static make_actions()
{
  auto id;
  id = AddEnum(-1,"SysAppLaunchCmd",FF_0NUMD);
  if ( id != -1 )
  {
    SetEnumCmt(id,"Action codes",0);
    AddConst(id,"sysAppLaunchCmdNormalLaunch"	,0 );
    AddConst(id,"sysAppLaunchCmdFind"		,1 );
    AddConst(id,"sysAppLaunchCmdGoTo"		,2 );
    AddConst(id,"sysAppLaunchCmdSyncNotify"	,3 );
    AddConst(id,"sysAppLaunchCmdTimeChange"	,4 );
    AddConst(id,"sysAppLaunchCmdSystemReset"	,5 );
    AddConst(id,"sysAppLaunchCmdAlarmTriggered"	,6 );
    AddConst(id,"sysAppLaunchCmdDisplayAlarm"	,7 );
    AddConst(id,"sysAppLaunchCmdCountryChange"	,8 );
    AddConst(id,"sysAppLaunchCmdSyncRequest"	,9 );
    AddConst(id,"sysAppLaunchCmdSaveData"	,10);
    AddConst(id,"sysAppLaunchCmdInitDatabase"	,11);
    AddConst(id,"sysAppLaunchCmdSyncCallApplication",12);
    SetConstCmt(GetConst(id,0,-1),"Normal Launch",1);
    SetConstCmt(GetConst(id,1,-1),"Find string",1);
    SetConstCmt(GetConst(id,2,-1),"Launch and go to a particular record",1);
    SetConstCmt(GetConst(id,3,-1),"Sent to apps whose databases changed\n"
    			       "during HotSync after the sync has\n"
    			       "been completed",1);
    SetConstCmt(GetConst(id,4,-1),"The system time has changed",1);
    SetConstCmt(GetConst(id,5,-1),"Sent after System hard resets",1);
    SetConstCmt(GetConst(id,6,-1),"Schedule next alarm",1);
    SetConstCmt(GetConst(id,7,-1),"Display given alarm dialog",1);
    SetConstCmt(GetConst(id,8,-1),"The country has changed",1);
    SetConstCmt(GetConst(id,9,-1),"The \"HotSync\" button was pressed",1);
    SetConstCmt(GetConst(id,10,-1),"Sent to running app before\n"
    				"sysAppLaunchCmdFind or other\n"
    				"action codes that will cause data\n"
    				"searches or manipulation",1);
    SetConstCmt(GetConst(id,11,-1),"Initialize a database; sent by\n"
    				"DesktopLink server to the app whose\n"
    				"creator ID matches that of the database\n"
    				"created in response to the \"create db\" request",1);
    SetConstCmt(GetConst(id,12,-1),"Used by DesktopLink Server command\n"
    				"\"call application\"",1);
  }
}

//-----------------------------------------------------------------------
//
//	Create a enumeration with event codes
//
static make_events()
{
  auto id;
  id = AddEnum(-1,"events",FF_0NUMD);
  if ( id != -1 )
  {
    SetEnumCmt(id,"Event codes",0);
    AddConst(id,"nilEvent",              0);
    AddConst(id,"penDownEvent",          1);
    AddConst(id,"penUpEvent",            2);
    AddConst(id,"penMoveEvent",          3);
    AddConst(id,"keyDownEvent",          4);
    AddConst(id,"winEnterEvent",         5);
    AddConst(id,"winExitEvent",          6);
    AddConst(id,"ctlEnterEvent",         7);
    AddConst(id,"ctlExitEvent",          8);
    AddConst(id,"ctlSelectEvent",        9);
    AddConst(id,"ctlRepeatEvent",        10);
    AddConst(id,"lstEnterEvent",         11);
    AddConst(id,"lstSelectEvent",        12);
    AddConst(id,"lstExitEvent",          13);
    AddConst(id,"popSelectEvent",        14);
    AddConst(id,"fldEnterEvent",         15);
    AddConst(id,"fldHeightChangedEvent", 16);
    AddConst(id,"fldChangedEvent",       17);
    AddConst(id,"tblEnterEvent",         18);
    AddConst(id,"tblSelectEvent",        19);
    AddConst(id,"daySelectEvent",        20);
    AddConst(id,"menuEvent",             21);
    AddConst(id,"appStopEvent",          22);
    AddConst(id,"frmLoadEvent",          23);
    AddConst(id,"frmOpenEvent",          24);
    AddConst(id,"frmGotoEvent",          25);
    AddConst(id,"frmUpdateEvent",        26);
    AddConst(id,"frmSaveEvent",          27);
    AddConst(id,"frmCloseEvent",         28);
    AddConst(id,"tblExitEvent",          29);
  }
}

//-----------------------------------------------------------------------
static main()
{
  process_segments();
  make_actions();
  make_events();
}

//-----------------------------------------------------------------------
#ifdef __undefined_symbol__
	// WE DO NOT USE IDC HOTKEYS, JUST SIMPLE KEYBOARD MACROS
	// (see IDA.CFG, macro Alt-5 for mc68k)
//-----------------------------------------------------------------------
//
//	Register Ctrl-R as a hotkey for "make offset from A5" command
//	(not used, simple keyboard macro is used instead, see IDA.CFG)
//
//	There is another (manual) way to convert an operand to an offset:
//	  - press Ctrl-R
//	  - enter "A5BASE"
//	  - press Enter
//
static setup_pilot()
{
  auto h0,h1;
  h0 = "Alt-1";
  h1 = "Alt-2";
  AddHotkey(h0,"a5offset0");
  AddHotkey(h1,"a5offset1");
  Message("Use %s to convert the first operand to an offset from A5\n",h0);
  Message("Use %s to convert the second operand to an offset from A5\n",h1);
}

static a5offset0(void) { OpOff(ScreenEA(),0,LocByName("A5BASE")); }
static a5offset1(void) { OpOff(ScreenEA(),1,LocByName("A5BASE")); }

#endif // 0
