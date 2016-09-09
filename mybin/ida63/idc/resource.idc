//
//      This is an example how New Executable Format resources can be
//      analyzed. In this example we analyze Version Information resource
//      type only.
//      It is possible to write functions to analyze other types too.
//
//

//-------------------------------------------------------------------
static nextResource(ea) {       // find next resource
  auto next;
  auto name;

  next = ea;
  while ( (next=NextSeg(next)) != -1 ) {
    name = SegName(next);
    if ( substr(name,0,3) == "res" ) break;     // Yes, this is a resource
  }
  return next;
}

//-------------------------------------------------------------------
static getResourceType(cmt) {
  auto i;
  i = strstr(cmt,"(");
  if ( i != -1 ) {
    i = i + 1;
    return xtol(substr(cmt,i,i+4));     // get type of the resource
  }
  return 0;                             // couldn't determine rsc type
}

//-------------------------------------------------------------------
static getResourceID(cmt) {
  auto i;
  i = strstr(cmt,":");
  if ( i != -1 ) {
    i = i + 1;
    return long(substr(cmt,i,-1));      // get ID of the resource
  }
  return 0;                             // couldn't determine rsc ID
}

//-------------------------------------------------------------------
static ResourceCursor(ea,id) {
  Message("Cursor, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceBitmap(ea,id) {
  Message("Bitmap, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceIcon(ea,id) {
  Message("Icon, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceMenu(ea,id) {
  Message("Menu, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceDbox(ea,id) {
  Message("Dbox, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceStrT(ea,id) {
  Message("String Table, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceFontDir(ea,id) {
  Message("FontDir, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceFont(ea,id) {
  Message("Font, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceAccl(ea,id) {
  Message("Accelerator, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceData(ea,id) {
  Message("Resource Data, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceCurDir(ea,id) {
  Message("Cursor Dir, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceIconDir(ea,id) {
  Message("Icon Dir, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceName(ea,id) {
  Message("Cursor, id: %ld\n",id);
}

//-------------------------------------------------------------------
static ResourceVersion(ea,id) {

  Message("Version info, id: %ld\n",id);

  ea = AnalyzeVBlock(ea,0);
}

//-------------------------------------------------------------------
static ConvertToStr(vea,len) {
  auto ea;
  auto slen;
  ea = vea;
  for ( ea=vea; len > 0; vea = ea ) {
    while ( Byte(ea) != 0 ) ea = ea + 1;
    ea = ea + 1;
    slen = ea - vea;
    MakeStr(vea,slen);
    len = len - slen;
  }
}

//-------------------------------------------------------------------
static Pad32(ea) {
  auto vea;
  vea = (ea + 3) & ~3;                  // align to 32-bit boundary
  if ( vea != ea ) {                    // extra bytes found
    MakeArray(ea,vea-ea);
    MakeComm(ea,"Padding bytes");
  }
  return vea;
}

//-------------------------------------------------------------------
static AnalyzeVBlock(ea,blnum) {
  auto key,block,vsize,x,vea,keyea;
  auto blstart,blend;

  blstart = ea;                         // save block start

  block = Word(ea);
  MakeName(ea,form("rscVinfoBlSize_%ld",blnum));
  MakeWord(ea);
  OpNumber(ea,0);

  ea = ea + 2;
  vsize = Word(ea);
  MakeName(ea,form("rscVinfoValSize_%ld",blnum));
  MakeWord(ea);
  OpNumber(ea,0);

  ea = ea + 2;
  keyea = ea;
  MakeName(key,form("rscVinfoKey_%ld",blnum));
  key = "";
  while ( Byte(ea) != 0 ) {
    key = key + char(Byte(ea));
    ea = ea + 1;
  }
  ea = ea + 1;
  MakeStr(keyea,ea-keyea);

  vea = Pad32(ea);

  MakeName(vea, form("rscVinfoValue_%ld",blnum));

  blend = vea + vsize;                  // find block end

//  Message("At %lX key is: %s\n",keyea,key);

  if      ( key == "VS_VERSION_INFO" ) {

        ;       // nothing to do

  } else if ( key == "VarFileInfo"     ) {

        ;       // nothing to do

  } else if ( key == "Translation"     ) {

    for ( ea=vea; ea < blend; ea=ea+4 ) {
      auto lang,charset;

      lang = Word(ea);
      charset = Word(ea+2);

        if      ( lang == 0x0401 ) lang = "Arabic";
        else if ( lang == 0x0402 ) lang = "Bulgarian";
        else if ( lang == 0x0403 ) lang = "Catalan";
        else if ( lang == 0x0404 ) lang = "Traditional Chinese";
        else if ( lang == 0x0405 ) lang = "Czech";
        else if ( lang == 0x0406 ) lang = "Danish";
        else if ( lang == 0x0407 ) lang = "German";
        else if ( lang == 0x0408 ) lang = "Greek";
        else if ( lang == 0x0409 ) lang = "U.S. English";
        else if ( lang == 0x040A ) lang = "Castilian Spanish";
        else if ( lang == 0x040B ) lang = "Finnish";
        else if ( lang == 0x040C ) lang = "French";
        else if ( lang == 0x040D ) lang = "Hebrew";
        else if ( lang == 0x040E ) lang = "Hungarian";
        else if ( lang == 0x040F ) lang = "Icelandic";
        else if ( lang == 0x0410 ) lang = "Italian";
        else if ( lang == 0x0411 ) lang = "Japanese";
        else if ( lang == 0x0412 ) lang = "Korean";
        else if ( lang == 0x0413 ) lang = "Dutch";
        else if ( lang == 0x0414 ) lang = "Norwegian - Bokmal";
        else if ( lang == 0x0415 ) lang = "Polish";
        else if ( lang == 0x0416 ) lang = "Brazilian Portuguese";
        else if ( lang == 0x0417 ) lang = "Rhaeto-Romanic";
        else if ( lang == 0x0418 ) lang = "Romanian";
        else if ( lang == 0x0419 ) lang = "Russian";
        else if ( lang == 0x041A ) lang = "Croato-Serbian (Latin)";
        else if ( lang == 0x041B ) lang = "Slovak";
        else if ( lang == 0x041C ) lang = "Albanian";
        else if ( lang == 0x041D ) lang = "Swedish";
        else if ( lang == 0x041E ) lang = "Thai";
        else if ( lang == 0x041F ) lang = "Turkish";
        else if ( lang == 0x0420 ) lang = "Urdu";
        else if ( lang == 0x0421 ) lang = "Bahasa";
        else if ( lang == 0x0804 ) lang = "Simplified Chinese";
        else if ( lang == 0x0807 ) lang = "Swiss German";
        else if ( lang == 0x0809 ) lang = "U.K. English";
        else if ( lang == 0x080A ) lang = "Mexican Spanish";
        else if ( lang == 0x080C ) lang = "Belgian French";
        else if ( lang == 0x0810 ) lang = "Swiss Italian";
        else if ( lang == 0x0813 ) lang = "Belgian Dutch";
        else if ( lang == 0x0814 ) lang = "Norwegian - Nynorsk";
        else if ( lang == 0x0816 ) lang = "Portuguese";
        else if ( lang == 0x081A ) lang = "Serbo-Croatian (Cyrillic)";
        else if ( lang == 0x0C0C ) lang = "Canadian French";
        else if ( lang == 0x100C ) lang = "Swiss French";

        if      ( charset == 0    ) charset = "7-bit ASCII";
        else if ( charset == 932  ) charset = "Windows, Japan (Shift - JIS X-0208)";
        else if ( charset == 949  ) charset = "Windows, Korea (Shift - KSC 5601)";
        else if ( charset == 950  ) charset = "Windows, Taiwan (GB5)";
        else if ( charset == 1200 ) charset = "Unicode";
        else if ( charset == 1250 ) charset = "Windows, Latin-2 (Eastern European)";
        else if ( charset == 1251 ) charset = "Windows, Cyrillic";
        else if ( charset == 1252 ) charset = "Windows, Multilingual";
        else if ( charset == 1253 ) charset = "Windows, Greek";
        else if ( charset == 1254 ) charset = "Windows, Turkish";
        else if ( charset == 1255 ) charset = "Windows, Hebrew";
        else if ( charset == 1256 ) charset = "Windows, Arabic";

        MakeComm(ea,"Language: " + lang);
        MakeWord(ea);
        OpNumber(ea,0);
        MakeComm(ea+2,"Character set: " + charset);
        MakeWord(ea+2);
        OpNumber(ea+2,0);

    }
  } else if ( key == "StringFileInfo"  ) {

        ConvertToStr(vea,vsize);

  } else {
        ConvertToStr(vea,vsize);
  }

  blend = Pad32(blend);
  ExtLinB(blend,0,";------------------------------------------------------");
  blnum = (blnum+1) * 10;               // nested block number
  while ( (blend-blstart) < block ) {   // nested block exist
    Message("Nested block at %lX\n",blend);
    MakeComm(blend,form("Nested block...%ld",blnum));
    blend = AnalyzeVBlock(blend,blnum);
    blnum = blnum + 1;
  }
  return blend;
}

//-------------------------------------------------------------------
static main(void) {
  auto ea;
  auto type,id;

  Message("Searching for resources...\n");
  ea = FirstSeg();
  while ( (ea=nextResource(ea)) != -1 ) {
    Message("Found a resource at %08lX, name: %s\n",ea,SegName(ea));
    type = getResourceType(LineA(ea,0));        // get rsc type
    id   = getResourceID(LineA(ea,3));          // get rsc id
    if      ( type == 0x8001 )  ResourceCursor(ea,id);
    else if ( type == 0x8002 )  ResourceBitmap(ea,id);
    else if ( type == 0x8003 )  ResourceIcon(ea,id);
    else if ( type == 0x8004 )  ResourceMenu(ea,id);
    else if ( type == 0x8005 )  ResourceDbox(ea,id);
    else if ( type == 0x8006 )  ResourceStrT(ea,id);
    else if ( type == 0x8007 )  ResourceFontDir(ea,id);
    else if ( type == 0x8008 )  ResourceFont(ea,id);
    else if ( type == 0x8009 )  ResourceAccl(ea,id);
    else if ( type == 0x800A )  ResourceData(ea,id);

    else if ( type == 0x800C )  ResourceCurDir(ea,id);

    else if ( type == 0x800E )  ResourceIconDir(ea,id);
    else if ( type == 0x800F )  ResourceName(ea,id);
    else if ( type == 0x8010 )  ResourceVersion(ea,id);
    else Message("Unknown resource type %04lX\n",type);
  }
  Message("Done.\n");
}
