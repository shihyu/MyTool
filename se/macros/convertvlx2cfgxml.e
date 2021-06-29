#pragma option(pedantic,on)
#include "slick.sh"
#import "cfg.e"
#import "beautifier.e"
#import "stdprocs.e"
#import "xmldoc.e"

/* 
 
Old format
  [cpp]
  case-sensitive=Y
  idchars=a-zA-Z_$  0-9
  styles=dquote dqbackslash squote sqbackslash xhex dqbackslashml idparenfunction embeddedasm javadoc doxygen xmldoc cpp
  mlcomment=/ ** * / documentation
  mlcomment=/ *! * / documentation
  mlcomment=/ * * /
  linecomment=/// documentation
  linecomment=// continuation
  keywords=property delegate event finally 
  libkeywords=get set interior_ptr pin_ptr
  libkeywords=safe_cast array
  ppkeywords=#define #undef #elif #else #endif #if #ifdef #ifndef #include
  ppkeywords=#pragma #error #import #using #line #warning
  punctuation={ }
  punctuation=[ ]
  ; operators
  operators=! % & * - = + : ; < > ? / * | ^ ~
  mlckeywords=glow shadow move pre
  mlckeywords=/glow /shadow /move /pre
  keywordattrs=glow color strength width

  mlckeywords= /new new new2
  keywordattrs=new a1
  attrvalues=a1(new) v1 v1-a

  keywordattrs=new2 a1 a2
  attrvalues=a2 v2-1 v2-2
 
 
  "SYMBOL1", "PUNCTUATION"
  "SYMBOL2", "LIBKEYWORDS"
  "SYMBOL3", "OPERATORS"
  "SYMBOL4", "USERKEYWORDS"
 
New format 
 
<profile n="something" version="1>
   <p n="case_sensitive" v="1"/>
   <p n="idchars" v="a-zA-Z_$ 0-9"/>
   <p n="styles" v="dquote dqbackslash squote sqbackslash xhex dqbackslashml idparenfunction embeddedasm javadoc doxygen xmldoc cpp"/> 
   <p n="k,struct"/>
   <p n="k,class"/>
   <p n="k,if"/>
   <p n="lib,strcpy"/>
   <p n="op,!"/>
   <p n="op,-"/>
   <p n="op,\"/>
   <p n="op,,"/>  <!-- no escaping needed for ',' right now -->
   <p n="op,`"/>
   <p n="u,whatever"/> 
    
   <!-- IMPORT SPECIAL CASE
        Since this has an attrs sub element, this one is actauly
        an "mlcomment" EVEN if "string" is replaced with "k"!
        It would be a "linecomment" if it was missing the "end" attribute.
   -->
   <p n="string,("> 
      <attrs start="(" end=")" nesting="1">
   </p>
    
   <p n="k,<"/> 
      <attrs start="<" end=">" />
   </p>
   <!--  IMPORT CASE: Put this under one property
      linecomment=* 1 checkfirst
      linecomment=* 7 checkfirst 
   -->
   <p n="line_comment,*">
       tf_color_start_as_keyword only supported with "leading"
       (check_first|leading|lastchar|)|beflags|matchFlags|tokenFlags (tf_charset|tf_first_non_blank|tf_color_start_as_keyword)
      <attrs start="*" start_col="1" flags="checkfirst" match_fun="match_line_comment" />
      <attrs start="*" start_col="7" flags="checkfirst"/>
   </p>
   <!-- Alternate approach for mlckeywords.
      pros: Supports merging HTML mlckeywords and atttributes.
      cons: * Looks a bit hacky
            * When looking "<" when see ",<,body etc.", there can be more than one
              table entry.
   -->
    <p n="block_comment,<"/> 
       <attrs start="<" end=">" />
    </p>
    <!-- escaping needed for ',' in tag/keyword/attribute but no languages use ',' yet -->
    <p n=",<,body," v="a1 a2 a3"/>  
    <p n=",<,body,a1" v="v1 v2 v3"/> 
    <p n=",<,,a1" v="v1a v2a v3a"/> 
</profile>
 
 

   <!-- I think this is the better approach for mlckeywords.
   -->
   <p n="block_comment,<"/> 
      <attrs start="<" end=">" >
           <t n="applet" a="align">
               <a n="align" v="top middle bottom left right"/>
           </t>
           <a n="attr" v="a1 a2 a3"/>
      </attrs>
   </p>

*/


static _str clex_parse_word(_str &line) {
   _str word;
    line=strip(line);
    if (substr(line,1,1)=='"') {
       i := 2;
       for (;;) {
          j := pos('["\\]',line,i,'r');
          if (j<=0) {
             word=substr(line,2);
             line='';
             return word;
          }
          ch := substr(line,j,1);
          if (ch=='"') {
             word=substr(line,2,j-2);
             line=strip(substr(line,j+1));
             return word;
          }
          //if (ch=='\') {
          int len=j-1; // "\"  j=2 want len=j-1=1
          line=substr(line,1,len):+substr(line,len+2);
          i=j+1;
       }
    }
    parse line with word line;
    return word;
}


static bool firstCharIsUpper(_str name) {
   ch := substr(name,1,1);
   if (substr(ch,1,1)=='/') {
      return isupper(substr(name,2,1));
   }
   return isupper(ch);
}
static void  add_attrvalues(int handle,int profileNode,int (&property_to_node):[],bool case_sensitive,_str line,_str last_mlcomment_start,bool lowcase_mlcwords) {
   parse line with auto name line;
   parse name with name '(' auto mlckeyword ')';

   if (lowcase_mlcwords && !pos('jsp:',name) && firstCharIsUpper(name)) {
      name=lowcase(name);
      mlckeyword=lowcase(mlckeyword);
      line=lowcase(line);
   }
   _cc_set_property(handle,profileNode,property_to_node,case_sensitive,','last_mlcomment_start','_plugin_escape_property(mlckeyword)','_plugin_escape_property(name),strip(line));
   //propertyNode:=_xmlcfg_add(handle,profileNode,VSXMLCFG_PROPERTY,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   //_xmlcfg_set_attribute(handle,propertyNode,VSXMLCFG_PROPERTY_NAME,','last_mlcomment_start','_plugin_escape_property(mlckeyword)','_plugin_escape_property(name));
   //_xmlcfg_set_attribute(handle,propertyNode,VSXMLCFG_PROPERTY_VALUE,strip(line));
}

static void _cc_set_property(int handle,int profileNode,int (&propery_to_node):[],bool case_sensitive,_str name,_str value) {
   int *pnode;
   _str key=name;
   if (!case_sensitive) key=lowcase(key);
   pnode=propery_to_node._indexin(key);
   int propertyNode;
   if (!pnode) {
      propertyNode=_xmlcfg_add_property(handle,profileNode,name);
      propery_to_node:[key]=propertyNode;
   } else {
      propertyNode=*pnode;
      if (value==null) {
         child:=_xmlcfg_get_first_child(handle,propertyNode,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         if (child>=0) {
            _xmlcfg_add(handle,propertyNode,VSXMLCFG_ATTRS,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
            return;
         }
      }
   }
   if (value!=null) {
      _xmlcfg_set_attribute(handle,propertyNode,VSXMLCFG_PROPERTY_VALUE,value);
   }
}
static void  add_mlckeywords(int handle,int profileNode,int (&property_to_node):[],bool case_sensitive,_str line,_str last_mlcomment_start,_str (&keyword_attrs):[],bool lowcase_mlcwords) {
   for (;;) {
      word:=clex_parse_word(line);
      if (word=='' && line=='') {
         return;
      }
      if (word=='') continue;
      value := "";
      if (word=='!notation' || word=='!doctype') {
         word=upcase(word);
      }
      if (lowcase_mlcwords && !pos('jsp:',word) && firstCharIsUpper(word) && word!='!NOTATION' && word!='!DOCTYPE' && word!='![CDATA[') {
         value=lowcase(value);
         word=lowcase(word);
      }
      if (!case_sensitive) {
         _str *pattrs=keyword_attrs._indexin(lowcase(word));
         if (pattrs) {
            value=*pattrs;
         }
      } else {
         _str *pattrs=keyword_attrs._indexin(word);
         if (pattrs) {
            value=*pattrs;
         }
      }
      _cc_set_property(handle,profileNode,property_to_node,case_sensitive,','last_mlcomment_start','_plugin_escape_property(word)',',value);
      //propertyNode:=_xmlcfg_add(handle,profileNode,VSXMLCFG_PROPERTY,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      //_xmlcfg_set_attribute(handle,propertyNode,VSXMLCFG_PROPERTY_NAME,
      //_xmlcfg_set_attribute(handle,propertyNode,VSXMLCFG_PROPERTY_VALUE,value);
   }
}
static void  add_keywords(int handle,int profileNode,int (&property_to_node):[],bool case_sensitive,_str color,_str line) {
   for (;;) {
      word:=clex_parse_word(line);
      if (word=='' && line=='') {
         return;
      }
      if (word=='') continue;
      _cc_set_property(handle,profileNode,property_to_node,case_sensitive,color','word,null);
   }
}
struct MLCOMMENT_INFO {
   _str start;
   _str sstart_col;
   _str send_col;
   _str scheckfirst;
   _str echeckfirst;
   _str end_word;
   _str colori;
    _str followed_by; 
    int docComment;
    _str nest_start;
    _str nest_end;
    bool continuation;
    bool precededByBlank;
    bool isKeyword;
};

static void add_mlcomment(int handle,int profileNode,int (&property_to_node):[],bool case_sensitive,MLCOMMENT_INFO &info) {
   /*
      options
        start_col  end_col end  options match_fun nest_start nest_end followed_by 
    
        scheckfirst= check_first|leading|
        echeckfirst=end_trailing|
    
        match_fun='match_comment'
    
        color='string'
    
   */

   int *pnode;
   name := info.colori','info.start;
   _str key=name;

   if (!case_sensitive) key=lowcase(key);
   pnode=property_to_node._indexin(key);
   int propertyNode;
   if (!pnode) {
      propertyNode=_xmlcfg_add_property(handle,profileNode,name);
      property_to_node:[key]=propertyNode;
   } else {
      propertyNode=*pnode;
   }
   attrNode:=_xmlcfg_add(handle,propertyNode,VSXMLCFG_ATTRS,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   if (info.sstart_col>1 || (info.sstart_col==1 && info.send_col>=1)) {
      _xmlcfg_set_attribute(handle,attrNode,'start_col',info.sstart_col);
   }
   if (info.send_col>=1) {
      _xmlcfg_set_attribute(handle,attrNode,'end_col',info.send_col);
   }
   if (info.end_word:!='') {
      _xmlcfg_set_attribute(handle,attrNode,'end',info.end_word);
   }
   flags:=info.scheckfirst;   // leading|trailing|
   if (info.echeckfirst!='') {
      if (flags!='') {
         strappend(flags,' ');
      }
      strappend(flags,info.echeckfirst);
   }
   
   // Line comments only
   if (info.precededByBlank) {
      if (flags!='') {
         strappend(flags,' ');
      }
      strappend(flags,'preceded_by_blank');
   }
   if (info.docComment) {
      if (flags!='') {
         strappend(flags,' ');
      }
      strappend(flags,'mc_doc_comments');
   }
   // Line comments only with leading or checkfirst
   if (info.isKeyword) {
      if (flags!='') {
         strappend(flags,' ');
      }
      strappend(flags,'mc_color_start_as_keyword');
   }
   // Line comments only
   if (info.continuation) {
      if (flags!='') {
         strappend(flags,' ');
      }
      strappend(flags,'mc_backslashml');
   }
   if (flags!='') {
      _xmlcfg_set_attribute(handle,attrNode,'flags',flags);
   }
   _xmlcfg_set_attribute(handle,attrNode,'match_fun','match_comment');
   if (info.nest_start!='' && info.nest_end!='') {
      _xmlcfg_set_attribute(handle,attrNode,'nest_start',info.nest_start);
      _xmlcfg_set_attribute(handle,attrNode,'nest_end',info.nest_end);
   }
   if (info.followed_by!='') {
      _xmlcfg_set_attribute(handle,attrNode,'followed_by',info.followed_by);
   }

}
static void convert_vlx_entry(_str profileName,int handle,int profileNode,int (&propery_to_node):[],_str name,_str value,_str &last_mlcomment_start,_str (&keyword_attrs):[],bool case_sensitive,bool lowcase_mlcwords) {

    //_message_box('n='name' v='value);
    for (;;) {
        _str value_iter_p = value;
        _str orig_value=value;
        name=upcase(name);
        if ( name:=="IDCHARS") {
           // normalize to one space
           parse strip(value) with auto start auto follow;
           _cc_set_property(handle,profileNode,propery_to_node,case_sensitive,'idchars',strip(start' 'follow));
           return;
        } else if ( name:=="CASE-SENSITIVE") {
           _cc_set_property(handle,profileNode,propery_to_node,case_sensitive,'case_sensitive',case_sensitive);
           return;
        } else if ( name:=="KEYWORDS" ) {
           add_keywords(handle,profileNode,propery_to_node,case_sensitive,'k',value);
           return;
        } else if ( name:=="CSKEYWORDS"  ) {
           add_keywords(handle,profileNode,propery_to_node,case_sensitive,'csk',value);
           return;
        } else if (name:=="PPKEYWORDS") {
           add_keywords(handle,profileNode,propery_to_node,case_sensitive,'pp',value);
           return;
        } else if ( name:=="SYMBOL1" || name:=='PUNCTUATION') {
           add_keywords(handle,profileNode,propery_to_node,case_sensitive,'pu',value);
           return;
        } else if ( name:=="SYMBOL2" || name:=='LIBKEYWORDS') {
           add_keywords(handle,profileNode,propery_to_node,case_sensitive,'lib',value);
           return;
        } else if ( name:=="SYMBOL3" || name:=='OPERATORS') {
           add_keywords(handle,profileNode,propery_to_node,case_sensitive,'op',value);
           return;
        } else if ( name:=="SYMBOL4" || name:=='USERKEYWORDS' ) {
           add_keywords(handle,profileNode,propery_to_node,case_sensitive,'user',value);
           return;
        } else if ( name:=="MLCKEYWORDS") {
           if (last_mlcomment_start!='') {
              add_mlckeywords(handle,profileNode,propery_to_node,case_sensitive,value,last_mlcomment_start,keyword_attrs,lowcase_mlcwords);
           }
           return;
        } else if ( name:=="KEYWORDATTRS") {
           return;
        } else if ( name:=="ATTRVALUES" ) {
           if (last_mlcomment_start!='') {
              add_attrvalues(handle,profileNode,propery_to_node,case_sensitive,value,last_mlcomment_start,lowcase_mlcwords);
           }
           return;
        } else if ( name:=="STYLES" ) {
           if (strieq(profileName,'cpp') && !pos('zerobbinary',value)) {
              value=strip(value)' cpp14digit zerobbinary cpp11rawstrings';
           }
           _cc_set_property(handle,profileNode,propery_to_node,case_sensitive,'styles',strip(value));
           return;
        } else if ( name:=="MLCOMMENT" ) {
            docComment := 0;
            int sstart_col = -1, send_col = -1; 
            colori := "comment";
            followed_by := "";
            _str  nest_start; nest_start = '';
            _str nest_end; nest_end = '';
            scheckfirst := "";
            echeckfirst := "";

            _str start_word;
            _str end_word;
            _str word;

            parse value_iter_p with start_word value_iter_p;
            parse value_iter_p with end_word value_iter_p;
            if ( isdigit(substr(end_word,1,1)) ) {
                if ( _last_char(end_word) == '+' ) {
                    send_col = -1;
                    end_word=substr(end_word,1,length(end_word)-1);
                    if (isinteger(end_word)) {
                       sstart_col = (int)end_word;
                    } else {
                       sstart_col=1;
                    }
                } else {
                   if (isinteger(end_word)) {
                      send_col = sstart_col = (int)end_word;
                   } else {
                      send_col = sstart_col = 1;
                   }
                }
                parse value_iter_p with end_word value_iter_p;
                if ( strieq(end_word, "LEADING") ) {
                    scheckfirst = 'leading';
                } else if ( strieq(end_word, "CHECKFIRST") ) {
                    scheckfirst = 'check_first';
                } else {
                   return;
                }
                parse value_iter_p with end_word value_iter_p;
                if ( end_word=='') {
                   return ;
                }
                parse value_iter_p with word value_iter_p;
                if ( strieq(word, "LASTCHAR") ) {
                    echeckfirst = 'end_trailing';
                    parse value_iter_p with word value_iter_p;
                }
                if ( word!='' ) {
                   return;
                }
            } else {
                for (;;) {
                   parse value_iter_p with word value_iter_p;
                   word=upcase(word);
                    if ( word=='' ) {
                        break;
                    }
                    if ( word:=="NESTING") {
                        nest_start=start_word;
                        nest_end=end_word;
                    } else if (word:=="NESTINGWITH") {
                        parse value_iter_p with nest_start value_iter_p;
                        parse value_iter_p with nest_end value_iter_p;
                        if (nest_end=='') {
                           return ;
                        }
                    } else if ( word:=="DOCUMENTATION") {
                        docComment = 1;
                        colori = 'doc_comment';
                    } else if ( word:=="KEYWORDCOLOR") {
                        colori = 'k';
                    } else if ( word:== "NUMBERCOLOR" ) {
                        colori = 'number';
                    } else if ( word:== "STRINGCOLOR" ) {
                        colori = 'string';
                    } else if ( word:== "COMMENTCOLOR" ) {
                        colori = 'comment';
                    } else if ( word:== "PPKEYWORDCOLOR" ) {
                        colori = 'pp';
                    } else if ( word:== "LINENUMCOLOR" ) {
                        colori = 'linenum';
                    } else if ( word:== "SYMBOL1COLOR" || word:== "PUNCTUATIONCOLOR" ) {
                        colori = 'pu';
                    } else if ( word:== "SYMBOL2COLOR" || word:== "LIBKEYWORDCOLOR" ) {
                       colori = 'lib';
                    } else if ( word:== "SYMBOL3COLOR" || word:== "OPERATORCOLOR" ) {
                       colori = 'op';
                    } else if ( word:== "SYMBOL4COLOR" || word:== "USERKEYWORDCOLOR" ) {
                       colori = 'user';
                    } else if ( word:== "MODIFIEDCOLOR" ) {
                       colori = 'modified_line';
                    } else if ( word:== "DELETEDCOLOR" ) {
                       colori = 'deleted_line';
                    } else if ( word:== "INSERTEDCOLOR" ) {
                       colori = 'inserted_line';
                    } else if ( word:== "FOLLOWEDBY" ) {
                        parse value_iter_p with followed_by value_iter_p;
                        if ( followed_by=='' ) {
                           return;
                        }
                    } else {
                       return;
                    }
                }
            }
            /* printf("MLCOMMENT: <%s> <%s> nesting=%d\n",start_word,end_word,nesting); */
            MLCOMMENT_INFO info;
            info.start=start_word;
            info.sstart_col=sstart_col;
            info.send_col=send_col;
            info.scheckfirst=scheckfirst;
            info.echeckfirst=echeckfirst;
            info.end_word=end_word;
            info.colori=colori;
            info.followed_by=followed_by; 
            info.docComment=docComment;
            info.nest_start=nest_start;
            info.nest_end=nest_end;
            info.isKeyword=false;
            info.precededByBlank=false; 
            info.continuation=false;
            if (info.start!='') {
               last_mlcomment_start=info.start;
            }
            add_mlcomment(handle,profileNode,propery_to_node,case_sensitive,info);
            return;
        } else if ( strcmp(name, "LINECOMMENT") == 0 ) {
            start_col := -1;
            end_col := -1;
            scheckfirst := "";
            docComment := 0;
            isKeyword := false;
            colori := "comment";
            precededByBlank := false;
            _str start_word;
            _str word;
            continuation := false;


            /* string */
            /* char start-end [checkfirst]*/
            /* char col+ [checkfirst]*/
            /* char col [checkfirst] */
            /* col  */ /* checkfirst and leading not supported */
            quotedString := substr(value,1,1)=='"';
            start_word=clex_parse_word(value);
            value_iter_p = value;

            // if this was quoted, then it should be interpreted as a delimiter
            if ( isdigit(substr(start_word,1,1)) && !quotedString ) {
                _maybe_strip(start_word, '+');
                if (!isinteger(start_word)) {
                   return;
                }
                start_col = (int)start_word;
                start_word='';
                parse value_iter_p with auto word2 value_iter_p;
                if ( strieq(word2, "PRECEDEDBYBLANK") ) {
                    precededByBlank = true;
                }
            } else {
                add_idchars:=value;
                p := pos('-',value);
                range := false;
                if ( p ) {
                   range = true;
                   add_idchars=substr(add_idchars,1,p-1);
                   value_iter_p = substr(add_idchars,1,p + 1);
                } else {
                   parse value_iter_p with add_idchars value_iter_p;
                }

                if ( !isdigit(substr(add_idchars,1,1))) {
                    word=add_idchars;
                    add_idchars="1+";
                } else {
                    parse value_iter_p with word value_iter_p;
                }
                if ( range ) {
                   if (!isinteger(add_idchars)) {
                      return;
                   }
                    start_col = (int)add_idchars;
                    if (!isinteger(word)) {
                       return;
                    }
                    end_col = (int)word;
                    parse value_iter_p with word value_iter_p;
                } else {
                    if ( _last_char(add_idchars) == '+' ) {
                       add_idchars=substr(add_idchars,1,length(add_idchars)-1);
                       if (!isinteger(add_idchars)) {
                       }
                       start_col = (int)add_idchars;
                    } else if (isdigit(substr(add_idchars,1,1))) {
                       if (!isinteger(add_idchars)) {
                       }
                       end_col = start_col = (int)add_idchars;
                    }
                }
                for (;;) {
                    if ( word=='') break;
                    word=strip(upcase(word));
                    if ( word:== "CHECKFIRST") {
                        scheckfirst = 'check_first';
                    } else if ( word:== "LEADING" ) {
                        scheckfirst = 'leading';
                    } else if ( word:== "PRECEDEDBYBLANK" ) {
                        precededByBlank = true;
                    } else if ( word:=="DOCUMENTATION") {
                        docComment = 1;
                        colori = 'doc_comment';
                    } else if ( word:=="KEYWORDCOLOR") {
                        colori = 'k';
                    } else if ( word:== "NUMBERCOLOR" ) {
                        colori = 'number';
                    } else if ( word:== "STRINGCOLOR" ) {
                        colori = 'string';
                    } else if ( word:== "COMMENTCOLOR" ) {
                        colori = 'comment';
                    } else if ( word:== "PPKEYWORDCOLOR" ) {
                        colori = 'pp';
                    } else if ( word:== "LINENUMCOLOR" ) {
                        colori = 'linenum';
                    } else if ( word:== "SYMBOL1COLOR" || word:== "PUNCTUATIONCOLOR" ) {
                        colori = 'pu';
                    } else if ( word:== "SYMBOL2COLOR" || word:== "LIBKEYWORDCOLOR" ) {
                       colori = 'lib';
                    } else if ( word:== "SYMBOL3COLOR" || word:== "OPERATORCOLOR" ) {
                       colori = 'op';
                    } else if ( word:== "SYMBOL4COLOR" || word:== "USERKEYWORDCOLOR" ) {
                       colori = 'user';
                    } else if ( word:== "MODIFIEDCOLOR" ) {
                        colori = 'modified_line';
                    } else if ( word:== "DELETEDCOLOR" ) {
                       colori = 'deleted_line';
                    } else if ( word:== "INSERTEDCOLOR" ) {
                       colori = 'inserted_line';
                    } else if ( word:== "CONTINUATION" ) {
                       continuation = true;
                    } else if ( word:== "ISKEYWORD" ) {
                        isKeyword = true;
                    } else {
                       break;
                    }
                    parse value_iter_p with word value_iter_p;
                }
            }
            MLCOMMENT_INFO info;
            info.start=start_word;
            info.sstart_col=start_col;
            info.send_col=end_col;
            info.scheckfirst=scheckfirst;
            info.echeckfirst='';
            info.end_word=''; //end_word;
            info.colori=colori;
            info.followed_by=''; //followed_by; 
            info.docComment=docComment;
            info.nest_start=''; //nest_start;
            info.nest_end=''; //nest_end;
            info.isKeyword=isKeyword;
            info.precededByBlank=precededByBlank; 
            info.continuation=continuation;
            add_mlcomment(handle,profileNode,propery_to_node,case_sensitive,info);

            //xprintf("LINECOMMENT: <%s> %d %d check=%d doc=%d\n",start_word,start_col,end_col,checkfirst,docComment);
            return;
        } else {
            return;
        }
    }
}
static void _get_all_keyword_attrs(_str profileName,_str (&keyword_attrs):[], bool case_sensitive) {
   save_pos(auto p);
   while (!down()) {
      get_line(auto line);line=strip(line);
      if (substr(line,1,1)=='[') {
         break;
      }
      if (line=='') {
         continue;
      }
      if (substr(strip(line),1,1)==';') {
         continue;
      }
      parse line with auto name '=' auto value;
      if (name=='keywordattrs') {
         parse value with auto keyword value;
         if (keyword!='') {
            if (keyword=='!notation' || keyword=='!doctype') {
               keyword_attrs:[lowcase(keyword)]=value;
            } else if (!case_sensitive) {
               if (strieq(profileName,'PL/SQL')) {
                  // Docs seems to show stuff in upper case.
                  // PL/SQL doesn't have any keywordattrs but this is here
                  // for completeness.
                  keyword_attrs:[lowcase(keyword)]=value;
               } else {
                  keyword_attrs:[lowcase(keyword)]=lowcase(value);
               }
            } else {
               keyword_attrs:[keyword]=value;
            }
         }
      }
   }
   restore_pos(p);
}
static void _get_case_sensitive_property(bool &case_sensitive) {
   case_sensitive=false;
   save_pos(auto p);
   while (!down()) {
      get_line(auto line);line=strip(line);
      if (substr(line,1,1)=='[') {
         break;
      }
      if (line=='') {
         continue;
      }
      if (substr(strip(line),1,1)==';') {
         continue;
      }
      parse line with auto name '=' auto value;
      if (name=='case-sensitive') {
         case_sensitive=(value=='y' || value=='Y');
         break;
      }
   }
   restore_pos(p);
}
static void convert_vlx_file_2_profiles(_str filename,_str only_convert_profile_name) {
   status:=_open_temp_view(filename,auto temp_wid,auto orig_wid);
   if (status) {
      return;
   }
   top();up();
   status=search('^\[','@r');
   _str last_mlcomment_start;
   while (!status) {
      get_line(auto line);line=strip(line);
      parse line with '[' auto profileName']';
      if (strieq(profileName,'Postscript')) {
         profileName='PostScript';
      }
      if (only_convert_profile_name!='' &&
          !strieq(profileName,only_convert_profile_name)) {
         status=repeat_search();
         continue;
      }
      last_mlcomment_start='';

      handle:=_xmlcfg_create('',VSENCODING_UTF8);
      optionsNode := 0;
      profileNode:=_xmlcfg_add(handle,optionsNode,VSXMLCFG_PROFILE,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      profilePath:=_plugin_append_profile_name(VSCFGPACKAGE_COLORCODING_PROFILES, profileName);
      _xmlcfg_set_attribute(handle,profileNode,VSXMLCFG_PROFILE_NAME,profilePath);
      _xmlcfg_set_attribute(handle,profileNode,VSXMLCFG_PROFILE_VERSION,1 /*Convert to v1 color coding format*/);
      
      bool case_sensitive;
      _get_case_sensitive_property(case_sensitive);
      _str keyword_attrs:[];
      _get_all_keyword_attrs(profileName,keyword_attrs,case_sensitive);
      int propery_to_node:[];
      lowcase_mlcword := strieq(profileName,'XHTML') || (!case_sensitive && !strieq(profileName,'PL/SQL'));
      comments := "";
      for (;;) {
         if (down()) {
            status=repeat_search();
            break;
         }
         get_line(line);line=strip(line);
         if (substr(line,1,1)=='[') {
            up();_end_line();
            status=repeat_search();
            break; 
         }
         if (substr(line,1,1)==';' && (substr(line,2)!='' || comments!='')) {
/*
<options>
   <profile>
      <p>
 
*/
            if (comments=='') {
               strappend(comments,substr(line,2));
            } else {
               comments :+= "\n\t\t";
               strappend(comments,substr(line,2));
            }
            continue;
         }
         parse line with auto name '=' auto value;
         name=strip(name);
         value=strip(value);
         if (name=='' || value=='') {
            continue;
         }
         if (comments!='') {
            commentNode:=_xmlcfg_add(handle,profileNode,'',VSXMLCFG_NODE_COMMENT,VSXMLCFG_ADD_AS_CHILD);
            // IF this is a multi-line comment
            removed_newline := false;
            tcomments:=strip(comments,'T');
            while (_last_char(tcomments):=="\n") {
               tcomments=substr(tcomments,1,length(tcomments)-1);
               removed_newline=true;
            }
            if (removed_newline) {
               comments=tcomments;
            }
            if (pos("\n",comments)) {
               comments="\n\t\t":+comments"\n\t\t";
            } else {
               comments=' 'strip(comments)' ';
            }
            _xmlcfg_set_value(handle,commentNode,comments);
            comments='';
         }
         convert_vlx_entry(profileName,handle,profileNode,propery_to_node,name,value,last_mlcomment_start,keyword_attrs,case_sensitive,lowcase_mlcword);
      }
      //_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL, 
      //             'F:\temp\output.xml');

      _plugin_set_profile(handle);

      _xmlcfg_close(handle);
   }
   _delete_temp_view(temp_wid);
   p_window_id=orig_wid;
}

defmain()
{
   args:=arg(1);
   filename:=parse_file(args,false);
   only_convert_profile_name:=parse_file(args,false);
   if (filename=='') {
      filename=p_buf_name;
   }
   convert_vlx_file_2_profiles(filename,only_convert_profile_name);
}
