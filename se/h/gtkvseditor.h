////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifdef VSUSE_GTK

#ifndef __GTK_VSEDITOR_H__
#define __GTK_VSEDITOR_H__

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


#define GTK_VSEDITOR(obj)          GTK_CHECK_CAST (obj, gtk_vseditor_get_type (), GtkVSEditor)
#define GTK_VSEDITOR_CLASS(klass)  GTK_CHECK_CLASS_CAST (klass, gtk_vseditor_get_type (), GtkVSEditorClass)
#define GTK_IS_VSEDITOR(obj)       GTK_CHECK_TYPE (obj, gtk_vseditor_get_type ())


typedef struct _GtkVSEditor        GtkVSEditor;
typedef struct _GtkVSEditorClass   GtkVSEditorClass;

struct _GtkVSEditor
{
  GtkWidget widget;

  /* update policy (GTK_UPDATE_[CONTINUOUS/DELAYED/DISCONTINUOUS]) */
  //guint policy : 2;

  /* Button currently pressed or 0 if none */
  //guint8 button;
  int wid;
  int init_wid;
  int init_width;
  int init_height;
  int init_BorderStyle;
  int init_buf_id;
  void *init_pdata;
  int init_mdi_wid;
  int init_reserved1;
};

struct _GtkVSEditorClass
{
  GtkWidgetClass parent_class;
};


GtkWidget* gtk_vseditor_new(
   int wid,int width,int height,
   int buf_id =-1,void *pdata=0,int mdi_wid=0,int reserved1=0,long reserved2=0);
int gtk_vseditor_get_wid(GtkVSEditor *vseditor);
GtkType gtk_vseditor_get_type(void);
void gtk_vseditor_remove(GtkWidget* widget);
#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* __GTK_VSEDITOR_H__ */

#endif
