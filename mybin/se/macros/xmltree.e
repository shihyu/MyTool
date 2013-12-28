////////////////////////////////////////////////////////////////////////////////////
// $Revision: 43889 $
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
#import "listproc.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

/**
 * XML Tree Viewer
 *
 * Displays an XML document as a tree.
 *
 * To do:
 *   A. Optimization: Do not update tree unless changed since last tree made
 *   B. Put file name at root node
 *   C. Get line and column info (will need to change xmlcfg) so we can
 *      1. Do jumps
 *      2. High light current tag
 *   D. Put in drag and drop so we drag to XSL ala Sylus studio.  See
 *      Toolbar editing code that allows dragging icons
 *   E. Need to put in DTD element as well
 *
 */

defeventtab _xml_tree_form;
void _xml_tree_form.on_resize()
{
   // available space and border usage
   int avail_x, avail_y, border_x, border_y;
   avail_x  = _dx2lx(SM_TWIP,p_active_form.p_client_width);
   avail_y  = _dy2ly(SM_TWIP,p_active_form.p_client_height);
   border_x = xmlctltree.p_x;
   border_y = xmlctltree.p_y;

   // size the tree controls
   xmlctltree.p_width  = avail_x-border_x;
   xmlctltree.p_height = avail_y-border_y*3;
}

int tagbitmapid;
int attrbitmapid;

void xmlctltree.on_create2()
{
   tagbitmapid = load_picture(-1, "_clstag0.ico");
   attrbitmapid = load_picture(-1, "_clsdat0.ico");
}


static int populate_tree_from_buffer(int wid)
{
   _nocheck _control xmlctltree;

   int treeid,
       rc;

   int formwid = _find_formobj('_xml_tree_form', "n");
   if (!formwid) {
      return -1;
   }
   _str bufname = _build_buf_name();
   int savewid = p_window_id;
   p_window_id = formwid.xmlctltree.p_window_id;
   //p_UTF8 = 1;
   int status=0;
   treeid = _xmlcfg_open_from_buffer(wid, status, VSXMLCFG_OPEN_ADD_PCDATA);
   if (treeid < 0) {
      message("Unable to open buffer");
      return treeid;
   }
   //generate_dtd_from_treeid(treeid);
   _TreeDelete(TREE_ROOT_INDEX,'C');
   int nodeidx = _TreeAddItem(0, bufname, TREE_ADD_AS_CHILD, _pic_file, _pic_file);
   rc = populate_tree_from_id(treeid, nodeidx);
   _xmlcfg_close(treeid);
   p_window_id = savewid;
   return rc;
}

_command void populate_xmltree()
{
   // If current buffer is not XML type then leave
   if (!_LanguageInheritsFrom('xml')) {
      return;
   }

   populate_tree_from_buffer(p_window_id);
}

static void _UpdateXMLTree()
{
   if (_idle_time_elapsed() < 3000) {
      return;
   }
   if ((p_ModifyFlags&MODIFYFLAG_XMLTREE_UPDATED) == MODIFYFLAG_XMLTREE_UPDATED) {
      return;
   }
   populate_xmltree();
   p_ModifyFlags |= MODIFYFLAG_XMLTREE_UPDATED;
}

int populate_tree(_str fn)
{
   int status=0;
   int treeid = _xmlcfg_open(fn, status, VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR | VSXMLCFG_OPEN_ADD_PCDATA);
   if (treeid < 0) {
      message("Unable to open "fn);
      return treeid;
   }
   int rc = populate_tree_from_id(treeid);
   _xmlcfg_close(treeid);
   return rc;
}

static int populate_tree_from_id(int id, int startnode = TREE_ROOT_INDEX)
{
   int curnode = 0;
   while (curnode >= 0) {
      populate_node(id,curnode,startnode);
      curnode = _xmlcfg_get_next_sibling(id, curnode, VSXMLCFG_NODE_ATTRIBUTE | VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }
   return 0;
}

static int display_node(int id, int node, int parentnode)
{
   int nodeindx;
   _str nodename;

   switch (_xmlcfg_get_type(id, node)) {
   case VSXMLCFG_NODE_ATTRIBUTE:
        nodename = _xmlcfg_get_name(id, node);
        nodename = nodename"="_xmlcfg_get_value(id, node);
        _TreeAddItem(parentnode, nodename, TREE_ADD_AS_CHILD, attrbitmapid, attrbitmapid);
        return parentnode;

   case VSXMLCFG_NODE_PCDATA:
   case VSXMLCFG_NODE_ELEMENT_START:
   case VSXMLCFG_NODE_ELEMENT_START_END:
         nodeindx = _TreeAddItem(parentnode,_xmlcfg_get_name(id, node),TREE_ADD_AS_CHILD, tagbitmapid, tagbitmapid);
         return nodeindx;
   }
   return parentnode;
}

static int populate_node(int id, int node, int parentnode)
{
   //say('name='_xmlcfg_get_name(id,node));
   parentnode = display_node(id,node,parentnode);
   node = _xmlcfg_get_first_child(id, node, VSXMLCFG_NODE_ATTRIBUTE | VSXMLCFG_NODE_ELEMENT_START | VSXMLCFG_NODE_ELEMENT_START_END);
   while (node >= 0) {
      populate_node(id,node, parentnode);
      node = _xmlcfg_get_next_sibling(id, node, VSXMLCFG_NODE_ATTRIBUTE | VSXMLCFG_NODE_ELEMENT_START | VSXMLCFG_NODE_ELEMENT_START_END);
   }
   return 0;
}

