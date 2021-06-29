////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#import "math.e"
#import "picture.e"
#import "stdprocs.e"
#endregion


_control _dot;

/** 
 * Displays <b>Calculator dialog box</b>.
 * 
 * @example
 * <i>Syntax</i>  void show('_calc_form')
 * @categories Miscellaneous_Functions
 */
defeventtab _calc_form;

static void _display_results(int wid) {
   _control ctldec_result,ctlother_result,ctlcalc_menu_button;
   line:=wid.p_LastModified' 'wid.ctlcalc_menu_button.p_user;
   if (line==wid.p_user) {
      return;
   }
   wid.p_user=line;
   if(!wid._set_results(auto result,true,auto dec_result,auto other_result)) {
      wid.ctldec_result.p_ReadOnly=false;
      wid.ctldec_result.p_text=dec_result;
      wid.ctldec_result.p_ReadOnly=true;
      wid.ctlother_result.p_ReadOnly=false;
      wid.ctlother_result.p_text=other_result;
      wid.ctlother_result.p_ReadOnly=true;
   } else {
      wid.ctldec_result.p_ReadOnly=false;
      wid.ctldec_result.p_text='Error';
      wid.ctldec_result.p_ReadOnly=true;
      wid.ctlother_result.p_ReadOnly=false;
      wid.ctlother_result.p_text='Error';
      wid.ctlother_result.p_ReadOnly=true;
   }
}
/**
 * Displays <b>Calculator dialog box</b>.
 * 
 * 
 * @categories Miscellaneous_Functions
 */
_command void calculator() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   show('-app -xy _calc_form');
}
void _calc_form.on_resize() {
   int client_width= _dx2lx(SM_TWIP,p_client_width);
   int client_height= _dy2ly(SM_TWIP,p_client_height);

   int dx=_dx2lx(SM_TWIP,_lx2dx(SM_TWIP, _calclist.p_x));
   int dy=_dy2ly(SM_TWIP,_ly2dy(SM_TWIP, _calclist.p_y));
   int bindy=_onescomp.p_y-_bin.p_y;
   int modedy=_onescomp.p_y- ctlmodelabel.p_y;
   _calclist.p_x=dx;
   _calclist.p_width=client_width-2*dx;
   int width=(client_width-4*dx-ctlcalc_menu_button.p_width) intdiv 2;
   ctldec_result.p_x=dx;ctldec_result.p_width=width;
   ctlother_result.p_x=ctldec_result.p_x_extent+dx;
   sizeBrowseButtonToTextBox(ctlother_result.p_window_id,
                             ctlcalc_menu_button.p_window_id, 0,
                             client_width - dx);
   int wid=_control ctlcalc_menu_button;

   int y;
   int ly=_ly2dy(SM_TWIP, dy);
   int below_height=_ly2dy(SM_TWIP,ctldec_result.p_height)+ly+
       _ly2dy(SM_TWIP,_lparen.p_height)+ly+
      _ly2dy(SM_TWIP,_and.p_height)+ly+
      //_ly2dy(SM_TWIP,_or.p_height)+ly+
      _ly2dy(SM_TWIP,_xor.p_height)+ly+
      _ly2dy(SM_TWIP,ctlshift_left.p_height)+ly+
      _ly2dy(SM_TWIP,ctlshift_left.p_height)+ly+
      _ly2dy(SM_TWIP,ctldone.p_height)+ly;
   below_height=_dy2ly(SM_TWIP,below_height);
   
   int height;
   height= client_height -below_height- dy*2;
   _calclist.p_height=height;
   //ctldec_result.p_y=ctlother_result.p_y=ctlcalc_menu_button.p_y;
   y=_calclist.p_height+dy*2;
   ctldec_result.p_y=ctlother_result.p_y=ctlcalc_menu_button.p_y=y;

   y= ctldec_result.p_y_extent+dy;
   _lparen.p_y=_rparen.p_y=_calca.p_y=_b.p_y=_seven.p_y=_eight.p_y=_nine.p_y=_mulop.p_y=_divop.p_y=y;
   y= _lparen.p_y_extent+dy;
   _and.p_y=_or.p_y=_c.p_y=_d.p_y=_four.p_y=_five.p_y=_six.p_y=_addop.p_y=_subop.p_y=y;
   y= _and.p_y_extent+dy;
   _xor.p_y=_onescomp.p_y=_e.p_y=_f.p_y=_one.p_y=_two.p_y=_three.p_y=_eqop.p_y=y;
   y= _xor.p_y_extent+dy;
   ctlshift_left.p_y=ctlshift_right.p_y=_zero.p_y=_dot.p_y=y;

   y= ctlshift_left.p_y_extent+dy+ctlshift_left.p_height+dy;
   y=ctlshift_left.p_y_extent+dy+((ctlshift_left.p_height-ctlmodelabel.p_height) intdiv 2);
   int dy2=abs((ctlmodelabel.p_height-_bin.p_height) intdiv 2);
   ctlmodelabel.p_y=y+dy2;
   //y+=bindy;
   _bin.p_y= _dec.p_y=_hex.p_y=_oct.p_y=y;

   y= ctlshift_left.p_y_extent+dy+ctlshift_left.p_height+dy;;
   ctldone.p_y=ctlbackspace.p_y=ctlclear.p_y=y;

}
void _calclist.BACKSPACE,DEL() {

   orig_col:=p_col;
   save_pos(auto p);
   _begin_line();
   status:=search('=|$','r');
   if (!status && match_length()) {
      _delete_text(-1);
      if ((last_event():==BACKSPACE && orig_col<=p_col) ||
          (last_event():==DEL && orig_col<p_col)
          ) {
      } else {
         if (p_col>_text_colc()) {
            p_col=_text_colc()+1;
         }
         return;
      }

   }
   restore_pos(p);
   call_root_key(last_event());
#if 0
   
   parse line with line '=' auto rest;
   if (rest!='') {
      replace_line(line);
      if (p_col>_text_colc()) {
         p_col=_text_colc()+1;
      }
      return;
   }
   call_root_key(last_event());
#endif
}
void _calclist.'.','~','&','|','^','(',')','*','/','+','-','=','a'-'f','0'-'9','PAD-PLUS','PAD-MINUS','PAD-STAR','PAD-SLASH'()
{
   /*Just Makes the Program think that it wasn't the keyboard*/
   ch := lowcase(last_event());
   if (length(ch)>1) {
      _str EventName=event2name(last_event());
      switch (upcase(EventName)) {
      case 'PAD-PLUS':
         ch='+';
         break;
      case 'PAD-MINUS':
         ch='-';
         break;
      case 'PAD-STAR':
         ch='*';
         break;
      case 'PAD-SLASH':
         ch='/';
         break;
      }
   }
   wid := 0;
   switch (ch) {
   case 1:wid = _control _one;break;
   case 2:wid = _control _two;break;
   case 3:wid = _control _three;break;
   case 4:wid = _control _four;break;
   case 5:wid = _control _five;break;
   case 6:wid = _control _six;break;
   case 7:wid = _control _seven;break;
   case 8:wid = _control _eight;break;
   case 9:wid = _control _nine;break;
   case 0:wid = _control _zero;break;
   case 'a':wid = _control _calca;break;
   case 'b':wid = _control _b;break;
   case 'c':wid = _control _c;break;
   case 'd':wid = _control _d;break;
   case 'e':wid = _control _e;break;
   case 'f':wid = _control _f;break;
   case '~':wid = _control _onescomp;break;
   case '&':wid = _control _and;break;
   case '|':wid = _control _or;break;
   case '^':wid = _control _xor;break;
   case '(':wid = _control _lparen;break;
   case ')':wid = _control _rparen;break;
   case '*':wid = _control _mulop;break;
   case '/':wid = _control _divop;break;
   case '+':wid = _control _addop;break;
   case '-':wid = _control _subop;break;
   case '=':wid = _control _eqop;break;
   case '.':
      if (!_dec.p_value) {
         _message_box('Decimal Points are Invalid in this Mode.');
         return;
      }
      keyin(last_event());
      //display_results();
      return;
   }
   wid.call_event(_calca, LBUTTON_UP);
   //display_results();
}

_calclist.'A-d'()
{
   _dec.p_value = 1;
}
_calclist.'A-h'()
{
   _hex.p_value = 1;
}
_calclist.'A-o'()
{
   _oct.p_value = 1;
}
_calclist.'A-b'()
{
   _bin.p_value = 1;
}

void _bin.on_create() {
   p_user = _control _dec;
   p_active_form._dot.p_user = 0;
}
void _calclist.on_create() {
   p_buf_flags|=VSBUFFLAG_DISABLE_SPELL_CHECK_WHILE_TYPING;
   _calclist.p_user = 0;
   ctlcalc_menu_button.p_user=16;
   ctlmodelabel.p_user=_set_timer(300,_display_results,_calclist);
}
void _calclist.on_destroy() {
   _kill_timer(ctlmodelabel.p_user);
}

_calclist.'='()
{
   status := 0;
   p_window_id=_control _calclist;
   if (p_line==0) {
      status=down();
      if (status) insert_line('');
   }/*User Goes to Top of File line*/
   typeless result='';
   status=_set_results(result);
   if (!status) {
      insert_line(result);
      event := "";
      old_line := "";
      //parse _calclist.p_user with event','old_line;
      //_calclist.p_user = event','result;
      //event_after_total();
   }/*Value of expression on line was successfully evaluated*/
}

_calclist.enter()
{
   line := "";
   get_line(line);
   if (line == '') {
      return('');
   }
   insert_line('');
}

static int _set_results(var result,bool quiet=false,_str &arg_dec_result=null,_str &arg_other_result=null)
{
   line := "";
   get_line(line);
   input := "";
   parse line with input '=';
   if (input=='') {
      if (quiet) {
         arg_dec_result='';
         arg_other_result='';
         return 0;
      }
      return(1);
   }
   wid := 0;
   base := 10;
   num_prefix := "";
   if (_bin.p_value) {
      wid = _bin;
      base = 2;
      num_prefix = '0b';
   }
   if (_dec.p_value) {
      wid = _dec;
      base = 10;
      num_prefix = '';
   }
   if (_hex.p_value) {
      wid = _hex;
      base = 16;
      num_prefix = '0x';
   }
   if (_oct.p_value) {
      wid = _oct;
      base = 8;
      num_prefix = 'o';
   }
   int status=eval_exp(result,default_mode(input),base);
   if ( status!=0){
      if (!quiet) {
         _message_box(status);
      }
      return(1);
   }
   if (result=='') {
      if (!quiet) {
         _message_box('Could not calculate result');
      }
      return(1);
   }
   msg := "";
   if (quiet) {
      eval_exp(result,default_mode(input),10);
      arg_other_result='';
      typeless temp=result;
      if ( !pos('.',temp) ) {   /* Can't display float in hex. */
         if ( pos('-',temp) ) {
            number:=_negative2dec(temp,10,msg);
            arg_other_result= dec2hex(number,ctlcalc_menu_button.p_user);
            //hex_result=' = 'dec2hex(_negative2dec(temp,10,msg))' ('Hex)'
         } else {
            arg_other_result= dec2hex(temp,ctlcalc_menu_button.p_user);
         }
      }
      arg_dec_result=result;
      return 0;
   }
   typeless dec_result='';
   typeless hex_result='';
   /* IF base not 10 and result is negative. */
   typeless number=0;
   if ( base!=10 && pos('-',result) ) {
      number=_negative2dec(result,base,msg);
      line=input'= 'result' = 'dec2hex(number,base)' ('msg')';
      replace_line(line);
      insert_line(dec2hex(number,base));
      return(1);
   }
   typeless temp=hex2dec(result,base);
   if (base!=10) {
      dec_result=' = 'temp' (Dec)';
   }
   if ( !pos('.',temp) ) {   /* Can't display float in hex. */
      if ( pos('-',temp) ) {
         number=_negative2dec(temp,10,msg);
         hex_result=' = 'dec2hex(number)' ('msg')';
         //hex_result=' = 'dec2hex(_negative2dec(temp,10,msg))' ('Hex)'
      } else if (base!=16){
         hex_result=' = 'dec2hex(temp)' (Hex)';
      }
   }
   if (quiet) {
      return 0;
   }
   negative := "";
   if (substr(result,1,1)=='-') {
      negative='-';result=substr(result,2);
   }

   typeless result2=result;
   if (base==10) {
      result2=''result2;
   } else if (base==8 && result2!='o'){
      result2='o'substr(result2,2);
   }

   if ((base==2 && substr(result,1,2)=='0b') ||
        (base==16 && substr(result,1,2)=='0x') ){
      result=substr(result,3);
   } else if (base==8 && result!='o'){
      result=substr(result,2);
   }

   result2=negative:+result2;
   result=negative:+result;
   result=result2;
   if (!pos(':d', hex_result, 1, 'R')) {
      hex_result = '';
   }
   line=input'= 'result2:+dec_result:+hex_result;
   replace_line(line);
   if (substr(result, 1, 2) == '0d' ||substr(result, 1, 2) == '0D') {
      result = substr(result, 3);
   }
   return(0);
}
static _str default_mode(_str input)
{
   //_get_base('',base,num_prefix)
   num_prefix := "";
   i := 1;
   output := "";
   if (num_prefix=='0d') {
      num_prefix='';
   }
   for (;;) {
      j := pos('[xXoOa-fA-F0-9]',input,i,'r');
      if (!j){
         output :+= substr(input,i,length(input)+1-i);
         break;
      }
      output :+= substr(input,i,j-i);
      ch1 := substr(input,j,1);
      ch2 := substr(input,j+1,1);
      end_i := pos('[~xXoOa-fA-F0-9]',input,j,'r');
      if (!end_i) end_i=length(input)+1;
      if ((ch1=='0' && pos(ch2,'xXoObBdD')) || pos(ch1,'xXoO')){
         // Specific format given. */
         if(ch1=='0' && lowcase(ch2)=='d') {
            input=substr(input,1,j-1):+substr(input,j+2);
            end_i-=2;
         }
      } else if(ch1=='x' || ch1=='o'){
      } else {
         /* messageNwait('num_prefix='num_prefix' input='input' j='j) */
         input=substr(input,1,j-1):+num_prefix:+substr(input,j);
         end_i+=length(num_prefix);
      }
      output :+= substr(input,j,end_i-j);
      i=end_i;
   }
   return(output);
}
#if 0
static void event_after_total()
{
   get_line line;
   p_user=p_line' 'p_col' 'line;
}
#endif

/*New Stuff Starts Here*/

static bool isoperator(_str op)
{
   return(op=='+'||op=='-'||op=='*'||op=='/'||op=='&'||op=='|'||op=='^'||op=='~');
}

static bool isunop(_str op)
{
   return(op=='~'||op=='-'||op=='+');
}

static bool isparen(_str op)
{
   return(op==')' || op == '(');
}

static void _get_base(_str base_name,var base,var num_prefix)
{
   wid := 0;
   if (base_name == '') {
      if (_bin.p_value) {
         wid = _bin;
         base = 2;
         num_prefix = '0b';
      }
      if (_dec.p_value) {
         wid = _dec;
         base = 10;
         num_prefix = '0d';
      }
      if (_hex.p_value) {
         wid = _hex;
         base = 16;
         num_prefix = '0x';
      }
      if (_oct.p_value) {
         wid = _oct;
         base = 8;
         num_prefix = 'o';
      }
      return;
   }
   switch (lowcase(base_name)) {
   case 'dec':
      base=10;
      num_prefix='';
      break;
   case 'hex':
      base=16;
      num_prefix='0x';
      break;
   case 'bin':
      base=2;
      num_prefix='0b';
      break;
   case 'oct':
      base=8;
      num_prefix='o';
      break;
   }
}
static put_prefix()
{
   typeless base='';
   num_prefix := "";
   _get_base('',base,num_prefix);
   if (num_prefix == '0d') {
      return('');
   }
   line := "";
   _calclist.get_line(line);
   _calclist.replace_line(line:+num_prefix);
   _calclist.end_line();
}

static bool should_expand(_str num)
{
   return(isinteger(num)||ishexnum(num)||isoctalnum(num)||isbinarynum(num));
}

_bin.lbutton_up()
{
   if (p_window_id == _bin.p_user) {
      p_window_id = _calclist;
      return('');
   }
   typeless line='';
   _calclist.get_line(line);
   if (substr(line, 1, 2) == '0d') {
      line = substr(line, 3);
   }
   rest := "";
   if (lowcase(substr(line,1,1)) == 'o' && isdigit(substr(line,2,1))) {
      parse line with 'o','ri' rest;
      line = '0':+rest;
   }
   if (should_expand(line) || (isunop(substr(line, 1, 1)) && should_expand(substr(line, 2))) || (isunop(substr(line, 1, 1)) && substr(line, 2) == ''))
   {
      op := "";
      if (isunop(substr(line, 1, 1))) {
         op = substr(line, 1, 1);
         line = substr(line, 2);
      }else{
         op = 0;
      }
      typeless base='';
      num_prefix := "";
      _get_base('', base, num_prefix);
      typeless old_base='';
      old_prefix := "";
      _get_base(substr(_bin.p_user.p_name, 2), old_base, old_prefix);

      if (base_prefix(line)) {
         old_base = base_prefix(line);
      }
      line = hex2dec(line, old_base);
      if (base != 10) {
         line = dec2hex(line, base);
      }
#if 0
      if (lowcase(substr(line,1,1))=='0' && isdigit(substr(line,2,1))) {
         parse line with '0' rest;
         line = 'o':+rest;
      }
#endif
      if (op) {
         line = op:+line;
      }
      _calclist.replace_line(line);
      _calclist.end_line();
   }
   _bin.p_user = p_window_id;
   p_window_id = _calclist;
}

static int base_prefix(_str num)
{
   if ((lowcase(substr(num, 1, 1)) == '0' ||lowcase(substr(num, 1, 1)) == 'o') && isdigit(substr(num, 2, 1))) {
      return(8);
   }
   if (lowcase(substr(num, 1, 2)) == '0x' || lowcase(substr(num, 1, 1)) == 'x') {
      return(16);
   }
   if (lowcase(substr(num, 1, 1)) == '0b') {
      return(2);
   }
   if (lowcase(substr(num, 1, 2)) == '0d') {
      return(10);
   }
   return(0);
}
void ctlclear.lbutton_up() {
   p_window_id.call_event(_calca, LBUTTON_UP);
   _calclist._set_focus();
}
void ctlbackspace.lbutton_up() {
   _calclist.call_event(_calclist, BACKSPACE);
   //_calclist._set_focus();
}

_calca.lbutton_up()
{
   line := "";
   _calclist.get_line(line);
   saving := "";
   junk := "";
   parse line with saving '=' junk;
   _calclist.replace_line(saving);
   status := 0;
   if (_calclist.p_line==0) {
      status=_calclist.down();
      if (status) _calclist.insert_line('');
   }
   typeless first, second;
   parse p_caption with first second;
   if (first=='&&') first='&';
   if ((isnumber(first) || ishexnum(first)) && !isparen(first)) {
      calclistline := "";
      _calclist.get_line(calclistline);
      _str ch=_last_char(calclistline);
      if (ch == '' || ch == ' ' || isoperator(ch)) {
         put_prefix();
      }
   }
   
   if (length(first) == 1 || length(first)==2) {
      if (first == 'X') {
         first = '*';
      }
      if (first!='=') {
         _calclist.keyin(first);
      }
   }else if(second != ''){
      second = substr(second, 1, 1);
      _calclist.keyin(second);
   }else if(lowcase(p_caption) == 'backspace'){
      p_window_id=_control _calclist;
      _rubout();
      return('');
   }  else{
      p_window_id=_control _calclist;
      replace_line('');p_col=1;
      return('');
   }
   if (p_caption == '=') {
      _calclist.call_event(_calclist, '=');
   }
   p_window_id=_control _calclist;
}

static bool check_valid_beginning(_str num, var ending)
{
   /*Made to check everything before the '.'  after the '.'
     and everthing after the 'e'*/
   strptr := 1;
   ch := substr(num, strptr, 1);
   if (ch != '.' && ch != '+' && ch != '-' && !(isdigit(ch))) {
      //_message_box('So Called Invalid First Digit');
      return false;//First Character is not a digit, '+', '.', or '-'
                //and is thefore invalid
   }
   if (ch == '.') {
      ending = strptr;
      return true;
   }
   if (ch == '-' || ch == '+') {
      strptr++;
   }//Advance String Pointer Past Valid Special Characters
   while (substr(num, strptr, 1) == ' ') {
      strptr++;
   }
   while (isdigit(substr(num, strptr, 1))  && length(num) >= strptr) {
      strptr++;
   }
   ending = strptr;
   return true;
}

static bool isoctalnum(_str num)
{
   if ( lowcase(substr(num, 1, 1)) == 'o' && all_below(7, substr(num,2))) {
      return true;
   }
   return false;
}

static bool all_below(int bnum, _str num)
{
   int i,len = length(num);
   for (i = 1; i <= len; i++) {
      ch := substr(num, i, 1);
      if (! (isdigit(ch) && ch <= bnum) ) {
         return false;
      }
   }
   return true;
}

static bool isbinarynum(_str num)
{
   if (substr(num, 1, 1) == 0 && lowcase(substr(num, 2, 1)) == 'b' && all_below(1, substr(num, 3))) {
      return true;
   }
   return false;
}
int _OnUpdate_menucalccmd(CMDUI& cmdui, int target_wid, _str command) {
   int form_wid=_find_formobj('_calc_form','N');
   if (!form_wid) return MF_ENABLED|MF_UNCHECKED;
   parse command with . auto option;
   if (option=='h' && ctlcalc_menu_button.p_user==16) {
      return MF_ENABLED|MF_CHECKED;
   }
   if (option=='o' && ctlcalc_menu_button.p_user==8) {
      return MF_ENABLED|MF_CHECKED;
   }
   if (option=='b' && ctlcalc_menu_button.p_user==2) {
      return MF_ENABLED|MF_CHECKED;
   }
   return MF_ENABLED|MF_UNCHECKED;
}

_command void menucalccmd() name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   int form_wid=_find_formobj('_calc_form','N');
   if (!form_wid) return;
   if (arg(1)=='h') {
      form_wid.ctlcalc_menu_button.p_user=16;
      return;
   }
   if (arg(1)=='o') {
      form_wid.ctlcalc_menu_button.p_user=8;
      return;
   }
   if (arg(1)=='b') {
      form_wid.ctlcalc_menu_button.p_user=2;
      return;
   }
}
