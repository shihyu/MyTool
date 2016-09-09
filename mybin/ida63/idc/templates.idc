/*
 *      This file contains function definitions for wizards.
 *
 *      This file is subject to change without any notice.
 *      Future versions of IDA may use other definitions.
 */

#ifndef _TEMPLATES_IDC
#define _TEMPLATES_IDC

//--------------------------------------------------------------------------
/* setup an event handler to delete all template wizards not corresponding
   to the detected loader once a file has been selected */
static select_wizard(void)
{
  if (GetXML("name(.)") != "template")
    Fatal("A 'template' XML element is required!");
  SetXML(".", "@onFileLoading", "onFileLoading_select_wizard");
}

static onFileLoading_select_wizard(void)
{
  auto name, count;
  name = GetXML("name(/ida/loaders/*[1])");
  if (name != "")
  {
    /* count the number of wizards corresponding to the detected loader */
    count = GetXML("count(wizard[substring-before(@X,'_w') = '" + name + "'])");
    if (count > 1)
      Fatal("A 'template' XML element can't contain more than one 'wizard' XML element corresponding to the '%'s loader!", name);
    /* delete the unnecessary wizards */
    if (count == 0) /* the loader doesn't have a wizard, delete all wizards except the default one */
      DelXML("wizard[@X != 'default_w']");
    else /* the loader has a wizard, delete all wizards except the corresponding one */
      DelXML("wizard[substring-before(@X,'_w') != '" + name + "']");
  }
}

//--------------------------------------------------------------------------
/* setup the captions of a template wizard and its welcome page */
static init_wizard_captions(void)
{
  auto name;
  if (GetXML("name(.)") != "wizard")
    Fatal("A 'wizard' XML element is required!");
  if (GetXML("name(..)") != "template")
    Fatal("A parent 'template' XML element is required!");
  name = GetXML("../@name") + " file loading Wizard";
  SetXML("@caption", "", name);
  if (SetXML("page[1]", "@title", "Welcome to the " + name) == 0)
    Fatal("At least one 'page' XML element is required!");
}

//--------------------------------------------------------------------------

#endif // _TEMPLATES_IDC
