� G   101 00modula-keysmodula-spacemodula-entermodula-mode-SetEditorLanguagegeneric-enter-handler-mod-supports-syntax-indent*return-true-if-uses-syntax-indent-propertydoExpandSpace-in-commentmodula-expand-spacecall-root-keymodula-space-words��begin��SYNTAX-EXPANSION-INFOBEGIN ... END��case��SYNTAX-EXPANSION-INFOCASE ... OF ... END (* CASE *);��const��SYNTAX-EXPANSION-INFOCONST��
definition��SYNTAX-EXPANSION-INFO$DEFINITION MODULE ... BEGIN ... END.��else��SYNTAX-EXPANSION-INFOELSE��elsif��SYNTAX-EXPANSION-INFOELSIF ... THEN ...��end��SYNTAX-EXPANSION-INFOEND��export��SYNTAX-EXPANSION-INFOEXPORT��for��SYNTAX-EXPANSION-INFO0FOR ... := ... TO ... BY 1 DO ... END (* FOR *);��from��SYNTAX-EXPANSION-INFOFROM ... IMPORT ...��if��SYNTAX-EXPANSION-INFOIF ... THEN ... END (* IF *);��implementation��SYNTAX-EXPANSION-INFO(IMPLEMENTATION MODULE ... BEGIN ... END.��label��SYNTAX-EXPANSION-INFOLABEL��loop��SYNTAX-EXPANSION-INFOLOOP ... END (* LOOP *);��module��SYNTAX-EXPANSION-INFOMODULE ... BEGIN ... END.��	procedure��SYNTAX-EXPANSION-INFOPROCEDURE ... BEGIN ... END;��repeat��SYNTAX-EXPANSION-INFOREPEAT ... UNTIL ... ;��type��SYNTAX-EXPANSION-INFOTYPE��var��SYNTAX-EXPANSION-INFOVAR��while��SYNTAX-EXPANSION-INFO!WHILE ... DO ... END (* WHILE *);��with��SYNTAX-EXPANSION-INFOWITH ... DO ... END (* WITH *);����-mod-expand-enter updateAdaptiveFormattingSettingssyntax-indentexpand/se.lang.api.LanguageSettings.getSyntaxExpansionstatuslineorig-first-wordrest
first-wordname-on-keybeforeindent-on-enter	next-linekeywordfunction-name-rawTextnotifyUserOfFeatureUseiorigLine	orig-wordaliasfilenamewordmin-abbrev2expandResultmaybe-auto-expand-aliasset-surround-mode-start-linewidth
-rawLengthdoNotifyindent-stringset-surround-mode-end-linenosplit-insert-linenewLinedo-surround-mode-keys-mod-get-syntax-completionswordsprefix
min-abbrevAutoCompleteGetSyntaxSpaceWordsmod-proc-search	proc-name
find-first	extension	-keywords
word-chars-clex-identifier-charscolp-find-matching-parentemp-mod-get-expression-infoPossibleOperator
idexp-infovisiteddepth-pas-get-expression-info-mod-find-context-tags	errorArgs	prefixexplastidlastidstart-offset
info-flags	otherinfofind-parentsmax-matchesexact-matchcase-sensitivefilter-flagscontext-flags	prefix-rt-pas-find-context-tags-mod-fcthelp-get-startOperatorTypedcursorInsideArgumentListFunctionNameOffsetArgumentStartOffsetflags-pas-fcthelp-get-start-mod-fcthelp-getFunctionHelp-listFunctionHelp-list-changedFunctionHelp-cursor-xFunctionHelp-HelpWordFunctionNameStartOffsetsymbol-info-pas-fcthelp-get	modula.ex	modula.exrc.def-cua-select-alt-shift-block,def-block-mode-fill-only-if-line-long-enoughdef-hotfix-auto-promptdef-auto-hotfixes-pathdef-double-click-tab-actiondef-middle-click-tab-actionse.datetime.DateTime.s-months#se.datetime.DateTime.s-monthLengthsse.datetime.DateTime.s-dayNames se.ui.TextChangeNotify.s-buffers se.ui.TextChangeNotify.s-enabled	-argumentdef-pmatch-max-diff-ksize��0� �  �87                   �  ��      8      �-  8   �   : ,:     �	" n� '	 n�:     		   
 �
 &  8 & O    ( �     :  8n�) n� ) :  )   ) �   )   ) 01  10 L) & & * J
�� v �  � i })   ) L01 �   .0 D: nm D: Qm. 01 �   .0 Dnm D: Qm	  8>
�  �  � 
 � � �   )   )   ) � L� �  |nm � � � 
 �  01  � .0  01�� � .0 � A) 
�� � 0.: /1 10 
  : D: E& �: � 8   8 �  80 J) : : EGDE� 8 : )    :  8n�) :  )   ) � 1A) AL)  |: nm :   )   ! ) " '
    :  # 8: DDE)  $ $ : 3|: ) : ) 5/ G8�% ?� & 8� : Qm� '
 ��M SG�: Qm� '
 ���  �  � 
 � _ �  GZ)  �  GZ) G�% b��  % � �: ���� / Gh�% y� & 8� : Qm� '
 ���5 G�% ���  ' 8nk: & 8nmQm� '
 ���  G�% �� & 8��/ G��% �� & 8� : Qm� '
 �M� G��: Qm� '
 �*�/ G��% �� & 8� : Qm� '
 �� �/ G��% �� & 8� : Qm� '
 �� �. G�% ��  ' 8nk: & 8nmQm� & & J
0 % G) � 8 :   : ) L & & (J
. % G& ) �� :   : )  : ) :  ) :   ( '
 

    8 �      :  , *  :  ) 5) 
@    " AIY��)   , )  ^f��) 
 � �) 
   
 � �) ��  ) � }) nm) & h& : J:  " � �) ��n: J) 
� : Et"# Qm$. 
 � �) m�$. 8  ) � }) vJ
 � �) @�: : EA) & & RK) : E)  :  � �)  � �	    H:  ,*�'
 :�� 0  ��/    	  9���: H:  H, 	
2  �F   :  , 4  ��
    HH:  , 	
6 V  01,73746mod
,268509206
,268509316 Sw begin case repeat var type const procedure implementation label module if for while with elsif else definition module for"   nosplit-insert-line:=TOimplementation	procedure
definitionmodulebegin([\:\(;])|$r (*  *)END[.;]END;END.syntax expansionTiif  THENEND (* IF *);elsif  then MODULEBEGIN :=  TO  BY 1 DOEND (* FOR *);loopEND (* LOOP *);END while  DOEND (* WHILE *);from	  IMPORT withEND (* WITH *);case  OFEND (* CASE *);repeatUNTIL  ; type var label const else  export end (PROCEDURE)^[ \t]*:b:v[ \t]*[(;:]@rhe@he>w=[][ \t][(;:](forward;	  $     �
$    �
$    �
�    �
�    �    +�    B�    ^� 
   z$    �$    �$    �$    �$    2 �   > #    % �  . �" �� Q #    g " �?  �  P � #    � #     � (   �� #    $     � � �   �#    �#    L#    _#    �#    �#    �#    �#   #     +#    ?#    M#     h#     �#    �" ���#    �" ��2#     (� B  O#    i" ���#    �" �&x	#    �	" �h�	#    
" ���
# 
   �
�   �
�     �              �   " �%   � �  2  ��(P(  %  � (2(  g  � :H � L  �    a+ (-..(0&H8j(  �L � (0*R,,&,,:N%K.,'82&#02&n1A$,,,&/$!'&K$.<$&-!S*n0&$N&2%8N&Lf ��  � ��  �  �  � '�  � ,�  � <�  � A�  � X � o� � y� � �� � �� � � w d(0J,,&42#H,caf8*)G,0R6*4.620.'066V*606&H.626*4.6*6$*6..6*6�626*4.620.626*4.626*4.6*6$*6.+<&.'+%&"'&,lGpF �� �  � � �� � '� � �� � � � � � �$ � %V � 6y � |� � |, � � ��%\ �� �  �� � �� � �4 %5�(,,*0+&.I&P *F.0F,&.*=V!*>(40FP,&.40F%%:H0f �� �  � � � �  � � � � '� � ' � I' � MU � d� � �� � i �!,HZ � �  � � � � � � � ME�?((((((V �E �  �E � �E � �E � 
	E � 	E � 	E � ,	E � 8	E � D	E �	 S	E �
 `	E � �E � �E � n	E � �	 Q��:G �u �  �	u � �	u � �	u � �	u � �	u � �u � 
 ѱ�'$$$$$$(2&
 �� �  "
� � 4
� � N
� � d
� � z
� � �	� � �
� � �� � �� �	 