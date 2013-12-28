////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38889 $
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

/**
 * Displays <b>Calculator dialog box</b>.
 * 
 * 
 * @categories Miscellaneous_Functions
 */
_command void calculator() name_info(','VSARG2_EDITORCTL)
{
   show('-app _calc_form');
}

_calclist.'~','&','|','^','(',')','*','/','+','-','=','a'-'f','0'-'9','PAD-PLUS','PAD-MINUS','PAD-STAR','PAD-SLASH'()
{
   /*Just Makes the Program think that it wasn't the keyboard*/
   _str ch = lowcase(last_event());
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
   int wid=0;
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
   }
   wid.call_event(_calca, LBUTTON_UP);
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

_bin.on_create()
{
   p_user = _control _dec;
   p_active_form._dot.p_user = 0;
   _calclist.p_user = 0;
}

_calclist.'.'()
{
   if (!_dec.p_value) {
      _message_box('Decimal Points are Invalid in this Mode.');
      return('');
   }
   keyin(last_event());
}

_calclist.'='()
{
   int status=0;
   p_window_id=_control _calclist;
   if (p_line==0) {
      status=down();
      if (status) insert_line('');
   }/*User Goes to Top of File line*/
   typeless result='';
   status=_set_results(result);
   if (!status) {
      insert_line(result);
      _str event='';
      _str old_line='';
      parse _calclist.p_user with event','old_line;
      _calclist.p_user = event','result;
      //event_after_total();
   }/*Value of expression on line was successfully evaluated*/
}

_calclist.enter()
{
   _str line='';
   get_line(line);
   if (line == '') {
      return('');
   }
   insert_line('');
}

static int _set_results(var result)
{
   _str line='';
   get_line(line);
   _str input='';
   parse line with input '=';
   if (input=='') return(1);
   int wid=0;
   int base=10;
   _str num_prefix='';
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
      _message_box(status);
      return(1);
   }
   if (result=='') {
      _message_box('Could not calculate result');
      return(1);
   }
   typeless dec_result='';
   typeless hex_result='';
   /* IF base not 10 and result is negative. */
   typeless number=0;
   _str msg='';
   if ( base!=10 && pos('-',result) ) {
      number=_negative2dec(result,base,msg);
      line=input'= 'result' = 'dec2hex(number,base)' ('msg')';
      replace_line(line);
      insert_line(dec2hex(number,base));
      return(1);
   } else {
      if (base!=10) {
         dec_result=' = 'hex2dec(result,base)' (Dec)';
      }
      typeless temp=hex2dec(result,base);
      if ( !pos('.',temp) ) {   /* Can't display float in hex. */
         if ( pos('-',temp) ) {
            number=_negative2dec(temp,10,msg);
            hex_result=' = 'dec2hex(number)' ('msg')';
            //hex_result=' = 'dec2hex(_negative2dec(temp,10,msg))' ('Hex)'
         } else if (base!=16){
            hex_result=' = 'dec2hex(temp)' (Hex)';
         }
      }
   }
   _str negative='';
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
   _str num_prefix = '';
   int i=1;
   _str output='';
   if (num_prefix=='0d') {
      num_prefix='';
   }
   for (;;) {
      int j=pos('[xXoOa-fA-F0-9]',input,i,'r');
      if (!j){
         output=output:+substr(input,i,length(input)+1-i);
         break;
      }
      output=output:+substr(input,i,j-i);
      _str ch1=substr(input,j,1);
      _str ch2=substr(input,j+1,1);
      int end_i=pos('[~xXoOa-fA-F0-9]',input,j,'r');
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
      output=output:+substr(input,j,end_i-j);
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

static boolean isoperator(_str op)
{
   return(op=='+'||op=='-'||op=='*'||op=='/'||op=='&'||op=='|'||op=='^'||op=='~');
}

static boolean isunop(_str op)
{
   return(op=='~'||op=='-'||op=='+');
}

static boolean isparen(_str op)
{
   return(op==')' || op == '(');
}

static void _get_base(_str base_name,var base,var num_prefix)
{
   int wid = 0;
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
   _str num_prefix='';
   _get_base('',base,num_prefix);
   if (num_prefix == '0d') {
      return('');
   }
   _str line='';
   _calclist.get_line(line);
   _calclist.replace_line(line:+num_prefix);
   _calclist.end_line();
}

static boolean should_expand(_str num)
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
   _str rest='';
   if (lowcase(substr(line,1,1)) == 'o' && isdigit(substr(line,2,1))) {
      parse line with 'o','ri' rest;
      line = '0':+rest;
   }
   if (should_expand(line) || (isunop(substr(line, 1, 1)) && should_expand(substr(line, 2))) || (isunop(substr(line, 1, 1)) && substr(line, 2) == ''))
   {
      _str op='';
      if (isunop(substr(line, 1, 1))) {
         op = substr(line, 1, 1);
         line = substr(line, 2);
      }else{
         op = 0;
      }
      typeless base='';
      _str num_prefix='';
      _get_base('', base, num_prefix);
      typeless old_base='';
      _str old_prefix='';
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

_calca.lbutton_up()
{
   _str line='';
   _calclist.get_line(line);
   _str saving='';
   _str junk='';
   parse line with saving '=' junk;
   _calclist.replace_line(saving);
   int status=0;
   if (_calclist.p_line==0) {
      status=_calclist.down();
      if (status) _calclist.insert_line('');
   }
   typeless first, second;
   parse p_caption with first second;
   if ((isnumber(first) || ishexnum(first)) && !isparen(first)) {
      _str calclistline='';
      _calclist.get_line(calclistline);
      _str ch=last_char(calclistline);
      if (ch == '' || ch == ' ' || isoperator(ch)) {
         put_prefix();
      }
   }
   if (length(first) == 1) {
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
   }
   else{
      p_window_id=_control _calclist;
      replace_line('');p_col=1;
      return('');
   }
   if (p_caption == '=') {
      _calclist.call_event(_calclist, '=');
   }
   p_window_id=_control _calclist;
}

static boolean check_valid_begining(_str num, var ending)
{
   /*Made to check everything before the '.'  after the '.'
     and everthing after the 'e'*/
   int strptr = 1;
   _str ch = substr(num, strptr, 1);
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

static boolean isoctalnum(_str num)
{
   if ( lowcase(substr(num, 1, 1)) == 'o' && all_below(7, substr(num,2))) {
      return true;
   }
   return false;
}

static boolean all_below(int bnum, _str num)
{
   int i,len = length(num);
   for (i = 1; i <= len; i++) {
      _str ch = substr(num, i, 1);
      if (! (isdigit(ch) && ch <= bnum) ) {
         return false;
      }
   }
   return true;
}

static boolean isbinarynum(_str num)
{
   if (substr(num, 1, 1) == 0 && lowcase(substr(num, 2, 1)) == 'b' && all_below(1, substr(num, 3))) {
      return true;
   }
   return false;
}
