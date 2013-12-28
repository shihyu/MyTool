////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifdef VSUSE_GTK

#ifndef __GTK_VSFORM_H__
#define __GTK_VSFORM_H__

#undef signals
#include <gdk/gdk.h>
#include <gtk/gtkadjustment.h>
#include <gtk/gtkwidget.h>

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#define signals protected

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */


#define GTK_VSFORM(obj)          GTK_CHECK_CAST (obj, gtk_vsform_get_type (), GtkVSForm)
#define GTK_VSFORM_CLASS(klass)  GTK_CHECK_CLASS_CAST (klass, gtk_vsform_get_type (), GtkVSFormClass)
#define GTK_IS_VSFORM(obj)       GTK_CHECK_TYPE (obj, gtk_vsform_get_type ())


typedef struct _GtkVSForm        GtkVSForm;
typedef struct _GtkVSFormClass   GtkVSFormClass;

struct _GtkVSForm
{
  GtkWidget widget;

  /* update policy (GTK_UPDATE_[CONTINUOUS/DELAYED/DISCONTINUOUS]) */
  //guint policy : 2;

  /* Button currently pressed or 0 if none */
  //guint8 button;
  int wid;
  int init_width;
  int init_height;
  int init_BorderStyle;
  int init_reserved1;
};

struct _GtkVSFormClass
{
  GtkWidgetClass parent_class;
};


GtkWidget* gtk_vsform_new(
   int width,int height,
   int BorderStyle=0,
   int reserved1=0,long reserved2=0);
int gtk_vsform_get_wid(GtkVSForm *vsform);
GtkType gtk_vsform_get_type(void);
#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* __GTK_VSFORM_H__ */

#endif
