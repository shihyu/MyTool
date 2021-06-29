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
#include "xml.sh"
#import "files.e"
#import "listproc.e"
#import "stdprocs.e"
#import "util.e"
#endregion


_str cur_el;   // Current element


////////////////////////////////////////////////////////////////////////////
// Represents a production rule node.
// These are chained together to show the unique production rule
// paths for the specified tag.
//
/**
 * Array of element/tag names for a given instance of an element
 * in an XML document
 *
 * Repeated elements will be represented as one element of the array with
 * a '+' at the end of the element/tag name.
 **/
struct contentModel {
   _str  els[];
};

struct attribute {
   _str  name;
   _str  type;
   _str  value;
   int   occurences;
};

/*
struct attribModel {
   attribute attributes:[];
}
*/

/**
 * Represents all the attribute and content samples in an XML
 * document.  These samples are then analyzed to generate a
 * dtd.
 *
 **/
struct elementSample {
   _str           tag;
   bool        isEmpty;
   bool        hasPCDATA;
   int            occurrences;
   attribute      attributes:[];
   contentModel   contentSamples[]; // Unique set of content chains
};

static elementSample els:[];



static bool isArrayEqual(typeless (&a)[], typeless (&b)[])
{
   if (a._length() != b._length()) {
      return false;
   }
   count := a._length();
   int i;
   for (i=0; i<count;i++) {
      if (a[i] != b[i]) {
         return false;
      }
   }
   return true;
}

static bool isContentModelEqual(elementSample * el, int i1, int i2)
{
   return isArrayEqual(el->contentSamples[i1].els, el->contentSamples[i2].els);
}


static bool isContentModelUnique(elementSample * el, int compareIndex)
{
   int i;
   for (i = 0; i < el->contentSamples._length(); i++) {
      if (i != compareIndex) {
         if (isContentModelEqual(el,i,compareIndex)) {
            return false;
         }
      }
   }
   return true;
}



static void takeAttributeSample(elementSample * el, int treeid, int node)
{
   int attrindx;
   int sampleindx;
   _str name;
   _str value;
   int count;
   count = 0;
   for (attrindx = node;attrindx >=0;) {
      attrindx = _xmlcfg_get_next_attribute(treeid, attrindx);
      if (attrindx < 0) {
         break;
      }
      name = _xmlcfg_get_name(treeid, attrindx);
      if (pos("xml:",name) == 1) {
         // Ignore xml: attributes
         continue;
      }
      value = _xmlcfg_get_value(treeid, attrindx);
      if (el->attributes:[name] == null) {
         el->attributes:[name].occurences = 0;
      }
      el->attributes:[name].occurences++;
      el->attributes:[name].name = name;
      el->attributes:[name].value = value;
      el->attributes:[name].type = "CDATA";  // Make them all CDATA for now
      count++;
   }

}

static void takeElementSample(elementSample * el, int treeid, int node)
{
   // Make chain of 1st gen child elements, colapsing repeated elements
   _str tagname;
   lasttagname := "";
   int i = el->contentSamples._length();
   curel := 0;

   takeAttributeSample(el, treeid, node);
   el->isEmpty = (_xmlcfg_get_type(treeid, node) & VSXMLCFG_NODE_ELEMENT_START_END) != 0;
   int curnode = _xmlcfg_get_first_child(treeid, node, VSXMLCFG_NODE_ELEMENT_START | VSXMLCFG_NODE_ELEMENT_START_END | VSXMLCFG_NODE_PCDATA);
//say("Looking for content for "el->tag" curnod="curnode);
   if (curnode < 0 && !el->isEmpty) {
      el->contentSamples[i].els[curel] = "#PCDATA";
      el->hasPCDATA = true;
   }
   while (curnode >= 0) {
      //say("---child found");
      //say("type = "_xmlcfg_get_type(treeid, curnode));
      if (_xmlcfg_get_type(treeid, curnode) & VSXMLCFG_NODE_PCDATA) {
         //say("PCDATA");
         _str value = _xmlcfg_get_value(treeid, curnode);
         tagname = "#PCDATA";
         el->hasPCDATA = true;
      } else {
         tagname = _xmlcfg_get_name(treeid, curnode);
      }
      //say("Adding tagname : "tagname" to "el->tag);
      curnode = _xmlcfg_get_next_sibling(treeid, curnode, VSXMLCFG_NODE_ELEMENT_START | VSXMLCFG_NODE_ELEMENT_START_END | VSXMLCFG_NODE_PCDATA);
      lasttagname = tagname;
      el->contentSamples[i].els[curel] = tagname;
      if (curnode >= 0) {
         tagname = _xmlcfg_get_name(treeid, curnode);
         if (tagname==lasttagname) {
            el->contentSamples[i].els[curel] = tagname"+";
            // Skip ahead to next unique element
            while (curnode >= 0 && tagname==lasttagname) {
               curnode = _xmlcfg_get_next_sibling(treeid, curnode, VSXMLCFG_NODE_ELEMENT_START | VSXMLCFG_NODE_ELEMENT_START_END | VSXMLCFG_NODE_PCDATA);
               if (curnode<0) {
                  break;
               }
               tagname = _xmlcfg_get_name(treeid, curnode);
            }
         }
      }
      curel++;
   }
   // Make sure it is unique.  If not unique, then remove it
   if (!isContentModelUnique(el, i)) {
      el->contentSamples._deleteel(i);
   }
}




static int generate_dtd_process_node(int id, int node, int parentnode)
{
   int nodeindx;
   _str nodename;

   switch (_xmlcfg_get_type(id, node)) {
   case VSXMLCFG_NODE_ELEMENT_START:
   case VSXMLCFG_NODE_ELEMENT_START_END:
         cur_el = _xmlcfg_get_name(id, node);
//         say("Current tag = "cur_el);
         if (els:[cur_el] == null) {
            els:[cur_el].occurrences = 0;
            els:[cur_el].hasPCDATA = false;
         }
         els:[cur_el].occurrences++;
         els:[cur_el].tag = cur_el;
         takeElementSample(&(els:[cur_el]), id,node);
         return 0;
   }
   return parentnode;
}

static int generate_dtd_process_branch(int id, int node, int parentnode)
{
   parentnode = generate_dtd_process_node(id,node,parentnode);
   node = _xmlcfg_get_first_child(id, node, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END | VSXMLCFG_NODE_PCDATA);
   while (node >= 0) {
      generate_dtd_process_branch(id,node, parentnode);
      node = _xmlcfg_get_next_sibling(id, node, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END | VSXMLCFG_NODE_PCDATA);
   }
   return 0;
}



static void dtd_write_attributes(elementSample & e)
{
   typeless iAttr;
   iAttr._makeempty();
   e.attributes._nextel(iAttr);
   if (iAttr._isempty()) {
      return;
   }
   insert_line("<!ATTLIST "e.tag" ");
   _end_line();
   for (;;) {
      attribute attr = e.attributes._el(iAttr);
      _insert_text(attr.name" CDATA");
      if (e.occurrences == attr.occurences) {
         _insert_text(" #REQUIRED>");
      } else {
         _insert_text(" #IMPLIED>");
      }
      e.attributes._nextel(iAttr);
      if (iAttr._isempty()) {
         break;
      }
      insert_line(substr(' ',1,length("<!ATTLIST "e.tag" ")));
      _end_line();
   }
   _insert_text('>');
}

static void dtd_write_element(elementSample & e)
{
   insert_line("");
   _insert_text("<!ELEMENT "e.tag" ");
   count := e.contentSamples._length();
   int sample;
   int iter;
   if (e.isEmpty) {
      _insert_text("EMPTY");
   } else if (e.hasPCDATA && count > 1) {
      _insert_text("ANY");
   } else {
      _insert_text("(");
      if (count > 1) {
         _insert_text("(");
      }
      for (sample = 0; sample < count; sample++) {
         int elementsInSample = e.contentSamples[sample].els._length();
         for (iter = 0; iter < elementsInSample; iter++) {
            _insert_text(e.contentSamples[sample].els[iter]);
            if ((iter + 1) < elementsInSample) {
               _insert_text(",");
            }
         }
         if (count > 1) {
            _insert_text(")");
            if ((sample+1) < count) {
               _insert_text("|(");
            }
         }
      }
   }
   if (!e.isEmpty && !(e.hasPCDATA && count > 1)) {
      _insert_text(")");
   }
   _insert_text(">");
   dtd_write_attributes(e);
}


static void generate_dtd_from_treeid(int id)
{
   // Make sure document is well-formed
   els._makeempty();
   curnode := 0;
   while (curnode >= 0) {
      generate_dtd_process_branch(id,curnode, id);
      curnode = _xmlcfg_get_next_sibling(id, curnode, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }


   //workspace_new_file('0','','','DTD','','');
   edit('+T');
   select_mode("DTD");
//   _switch_to_xml_output(true);
   _insert_text("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
//   insert_line("");


   typeless i;
   i._makeempty();
   els._nextel(i);
   j := 0;
   while (!i._isempty()) {
      dtd_write_element(els._el(i));
      els._nextel(i);
   }
}


int _OnUpdate_generate_dtd(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   lang := target_wid.p_LangId;
   return _LanguageInheritsFrom('xml',lang)? MF_ENABLED:MF_GRAYED;
}

/**
 * Generate DTD from XML file
 *
 * Algorithm
 *    Make sure the document is well formed
 *    Read document as tree using xmlcfg
 *       1st Pass
 *          Keep mapping of elements.
 *             For each element
 *                Note the attribute set and type on the values (use for ATTR)
 *                Note which elements are 1st generation children
 *       2nd Pass
 *          For each element
 *             Note pattern of first generation children for each instance
 *             Make a tree of sub element combinations
 *             Perform pattern matching to determine 0 or 1, 1, 0 or etc. occurences
 *
 *    &lt;!ATTLIST release version CDATA #REQUIRED
 *                      date    CDATA #IMPLIED&gt;
 *
 **/
_command generate_dtd() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // Make sure document is well-formed
   els._makeempty();
   status := 0;
   wid := 0;
   int treeid = _xmlcfg_open_from_buffer(wid, status, VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR | VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
   if (treeid < 0) {
      message("Unable to open buffer");
      return treeid;
   }
   generate_dtd_from_treeid(treeid);
   _xmlcfg_close(treeid);
}

//////////////////////////////////////////////////////////////////////////////// 
// XML Schema generation 
////////////////////////////////////////////////////////////////////////////////
/** 
 * Generate attribute for the given sample element
 *  
 * <pre> 
 * &lt;xs:attribute name="Name" type="xs:string" use="required" /&gt;
 * </pre> 
 *  
 * @param e    sample XML element
 */
static void schema_write_attributes(elementSample & e)
{
   typeless iAttr;
   iAttr._makeempty();
   e.attributes._nextel(iAttr);
   if (iAttr._isempty()) {
      return;
   }
   for (;;) {
      attribute attr = e.attributes._el(iAttr);

      // determine type name based on content of attribute
      type_name := "xs:string";
      if (isnumber(attr.value)) {
         type_name = "xs:number";
      }

      // determine if this attribute is always present or only sometimes
      required := "optional";
      if (e.occurrences == attr.occurences) {
         required = "required";
      }
      insert_line("    <xs:attribute name=\""attr.name"\" type=\""type_name"\" use=\""required"\" />");

      // next please
      e.attributes._nextel(iAttr);
      if (iAttr._isempty()) {
         break;
      }
      _end_line();
   }
}

/**
 * Generate schema definition for one element
 * 
 * <pre> 
 * &lt;xs:element name="ErrorExpressions"&gt;
 * </pre> 
 *  
 * @param e    sample XML element
 */
static void schema_write_element(elementSample & e)
{
   insert_line("");

   count := e.contentSamples._length();
   int sample;
   int iter;
   if (e.isEmpty) {
      insert_line("  <xs:element name=\""e.tag"\">");
   } else if (e.hasPCDATA && count >= 1) {
      insert_line("  <xs:element name=\""e.tag"\" type=\"xs:string\">");
   } else {
      insert_line("  <xs:element name=\""e.tag"\">");
      insert_line("    <xs:complexType>");
      space_choice := "";
      if (count > 1) {
         insert_line("      <xs:choice>");
         space_choice = "  ";
      }
      for (sample = 0; sample < count; sample++) {
         space_seq := "";
         int elementsInSample = e.contentSamples[sample].els._length();
         if (elementsInSample > 1) {
            insert_line(space_choice"      <xs:sequence>");
            space_seq = "  ";
         }
         for (iter = 0; iter < elementsInSample; iter++) {
            nested_tag := (e.contentSamples[sample].els[iter]);
            insert_line(space_choice:+space_seq:+"      <xs:element name=\""nested_tag"\"/>");
         }
         if (elementsInSample > 1) {
            insert_line(space_choice"      </xs:sequence>");
         }
      }
      if (count > 1) {
         insert_line("      </xs:choice>");
      }
      insert_line("    </xs:complexType>");
   }

   schema_write_attributes(e);
   insert_line("  </xs:element>");
}

/*

<?xml version="1.0" encoding="utf-16"?>
<xs:schema targetNamespace="http://www.slickedit.com/schema/11.0/ErrorRE.xsd" attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="ErrorExpressions">
    <xs:complexType>
      <xs:sequence>
        <xs:element maxOccurs="unbounded" name="Tool">
          <xs:complexType>
            <xs:sequence>
              <xs:element maxOccurs="unbounded" name="Expression">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element name="RE" type="xs:string" />
                    <xs:element name="Matches" />
                  </xs:sequence>
                  <xs:attribute name="Name" type="xs:string" use="required" />
                  <xs:attribute name="OldName" type="xs:string" use="optional" />
                  <xs:attribute name="Priority" type="xs:unsignedByte" use="required" />
                  <xs:attribute name="Enabled" type="xs:unsignedByte" use="optional" />
                  <xs:attribute name="Macro" type="xs:string" use="optional"/>
                </xs:complexType>
              </xs:element>
            </xs:sequence>
            <xs:attribute name="Name" type="xs:string" use="required" />
            <xs:attribute name="Priority" type="xs:unsignedByte" use="required" />
            <xs:attribute name="Enabled" type="xs:unsignedByte" use="optional" />
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>

*/

static void generate_schema_from_treeid(int id)
{
   // Make sure document is well-formed
   els._makeempty();
   curnode := 0;
   while (curnode >= 0) {
      generate_dtd_process_branch(id,curnode, id);
      curnode = _xmlcfg_get_next_sibling(id, curnode, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }


   //workspace_new_file('0','','','DTD','','');
   edit('+T');
   select_mode("XSD");
   _insert_text("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
   insert_line("<xs:schema elementFormDefault=\"qualified\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">");

   typeless i;
   i._makeempty();
   els._nextel(i);
   j := 0;
   while (!i._isempty()) {
      schema_write_element(els._el(i));
      els._nextel(i);
   }

   insert_line("</xs:schema>");
}

/**
 * Generate an XML Schema from XML file
 *
 * Algorithm
 *    Make sure the document is well formed
 *    Read document as tree using xmlcfg
 *       1st Pass
 *          Keep mapping of elements.
 *             For each element
 *                Note the attribute set and type on the values (use for ATTR)
 *                Note which elements are 1st generation children
 *       2nd Pass
 *          For each element
 *             Note pattern of first generation children for each instance
 *             Make a tree of sub element combinations
 *             Perform pattern matching to determine 0 or 1, 1, 0 or etc. occurences
 *
 */
_command generate_schema() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // Make sure document is well-formed
   els._makeempty();
   status := 0;
   wid := 0;
   int treeid = _xmlcfg_open_from_buffer(wid, status, VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR | VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
   if (treeid < 0) {
      message("Unable to open buffer");
      return treeid;
   }
   generate_schema_from_treeid(treeid);
   _xmlcfg_close(treeid);
}





