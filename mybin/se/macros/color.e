////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#include "color.sh"
#import "main.e"
#import "stdprocs.e"
#endregion


_str getSystemColorSchemeFile()
{
   return get_env('VSROOT'):+(VSCFGFILE_COLORSCHEMES);
}

_str getUserColorSchemeFile()
{
   file:=usercfg_path_search(VSCFGFILE_USER_COLORSCHEMES);
   if (file=='') {
      _str ini=get_env('VSROOT'):+(VSCFGFILE_USER_COLORSCHEMES);
      if (ini!='') file=ini;
   }
   
   return file;
}


defeventtab _color_picker_form;

int show_color_picker(int color)
{
   typeless new_color = show("-modal _color_picker_form",color);
   if (new_color=='') return COMMAND_CANCELLED_RC;
   return new_color;
}

#define DLGINFO_GRADIENT      0
#define DLGINFO_SLIDER        1
#define DLGINFO_TEXT_BOX      2
#define DLGINFO_COLORSHIFT    3
#define DLGINFO_VALUE         4

void ctl_ok.on_create(int color_value=0)
{
   _SetDialogInfo(DLGINFO_GRADIENT, rgb_gradient1.p_window_id, _control rgb_slider1);
   _SetDialogInfo(DLGINFO_SLIDER, rgb_slider1.p_window_id, _control rgb_slider1);
   _SetDialogInfo(DLGINFO_TEXT_BOX, rgb_text1.p_window_id, _control rgb_slider1);
   _SetDialogInfo(DLGINFO_GRADIENT, rgb_gradient1.p_window_id, _control rgb_gradient1);
   _SetDialogInfo(DLGINFO_SLIDER, rgb_slider1.p_window_id, _control rgb_gradient1);
   _SetDialogInfo(DLGINFO_TEXT_BOX, rgb_text1.p_window_id, _control rgb_gradient1);

   _SetDialogInfo(DLGINFO_GRADIENT, rgb_gradient2.p_window_id, _control rgb_slider2);
   _SetDialogInfo(DLGINFO_SLIDER, rgb_slider2.p_window_id, _control rgb_slider2);
   _SetDialogInfo(DLGINFO_TEXT_BOX, rgb_text2.p_window_id, _control rgb_slider2);
   _SetDialogInfo(DLGINFO_GRADIENT, rgb_gradient2.p_window_id, _control rgb_gradient2);
   _SetDialogInfo(DLGINFO_SLIDER, rgb_slider2.p_window_id, _control rgb_gradient2);
   _SetDialogInfo(DLGINFO_TEXT_BOX, rgb_text2.p_window_id, _control rgb_gradient2);

   _SetDialogInfo(DLGINFO_GRADIENT, rgb_gradient3.p_window_id, _control rgb_slider3);
   _SetDialogInfo(DLGINFO_SLIDER, rgb_slider3.p_window_id, _control rgb_slider3);
   _SetDialogInfo(DLGINFO_TEXT_BOX, rgb_text3.p_window_id, _control rgb_slider3);
   _SetDialogInfo(DLGINFO_GRADIENT, rgb_gradient3.p_window_id, _control rgb_gradient3);
   _SetDialogInfo(DLGINFO_SLIDER, rgb_slider3.p_window_id, _control rgb_gradient3);
   _SetDialogInfo(DLGINFO_TEXT_BOX, rgb_text3.p_window_id, _control rgb_gradient3);

   _SetDialogInfo(DLGINFO_COLORSHIFT, 0, _control rgb_text1);
   _SetDialogInfo(DLGINFO_COLORSHIFT, 8, _control rgb_text2);
   _SetDialogInfo(DLGINFO_COLORSHIFT, 16, _control rgb_text3);

   int ty = _dy2ly(SM_TWIP, 1);
   rgb_gradient1.p_height = 8 * ty;
   rgb_gradient2.p_height = 8 * ty;
   rgb_gradient3.p_height = 8 * ty;
   rgb_slider1.p_y = rgb_gradient1.p_y - 5*ty;
   rgb_slider2.p_y = rgb_gradient2.p_y - 5*ty;
   rgb_slider3.p_y = rgb_gradient3.p_y - 5*ty;

   int tx = _dx2lx(SM_TWIP, 1);
   luminance_gradient.p_width = 8 * tx;
   luminance_slider.p_x = luminance_gradient.p_x - 5*tx;

   _update_rgb_color(color_value, true, true);
   sampler_old.p_backcolor = color_value;
}

void ctl_ok.lbutton_up()
{
   p_active_form._delete_window(sampler.p_backcolor);
}

void sampler_old.lbutton_down()
{
   _update_rgb_color(sampler_old.p_backcolor, true, true);
}
void sampler_old.lbutton_double_click()
{
   _update_rgb_color(sampler_old.p_backcolor, true, true);
   call_event(ctl_ok, LBUTTON_UP, 'W');
}

/*
   RGB textboxes
 */
void rgb_text1.'a'-'z',' '()
{
}

void rgb_text1.on_change()
{
   int value = 0;
   int current_value = _GetDialogInfo(DLGINFO_VALUE, p_window_id);
   if (length(p_text)) {
      if (!isinteger(p_text) || length(p_text) > 3) {
         p_text = current_value;
         return;
      }
      value = (int)p_text;
      if (value < 0 || value > 255) {
         p_text = current_value;
         return;
      }
   }
   if (value != current_value) {
      _SetDialogInfo(DLGINFO_VALUE, value, p_window_id);
   }
   int color_shift = _GetDialogInfo(DLGINFO_COLORSHIFT, p_window_id);
   int current_color = sampler.p_backcolor;
   int new_color = (current_color & ~((0x0ff) << color_shift)) | (value << color_shift);
   _update_rgb_color(new_color, true, false);
}

/*
   Hue Sat picker
 */
void hs_map.lbutton_down()
{
   mou_capture();
   call_event(p_window_id, MOUSE_MOVE, 'w');
}
void hs_map.lbutton_double_click()
{
   mou_capture();
   orig_color := sampler.p_backcolor;
   call_event(p_window_id, MOUSE_MOVE, 'w');
   if (orig_color == sampler.p_backcolor) {
      call_event(ctl_ok, LBUTTON_UP, 'W');
   }
}

void hs_map.lbutton_up()
{
   mou_release();
   ctl_ok._set_focus();
   ctl_ok.p_user=p_window_id;
}

void ctl_ok.up()
{
   _nocheck _control luminance_slider;
   _nocheck _control luminance_gradient;
   int text_wid = 0;
   int incr = _dy2ly(SM_TWIP, 1);
   if (p_user==hs_map) {
      if (hs_picker.p_y-incr+(hs_picker.p_height intdiv 2) >= 0) {
         hs_picker.p_y -= incr;
         _update_hsl_color();
      }
   } else if (p_user==rgb_slider1 || p_user==rgb_gradient1) {
      text_wid=rgb_text1;
   } else if (p_user==rgb_slider2 || p_user==rgb_gradient2) {
      text_wid=rgb_text2;
   } else if (p_user==rgb_slider3 || p_user==rgb_gradient3) {
      text_wid=rgb_text3;
   } else if (p_user==luminance_slider) {
      if (luminance_slider.p_y+(luminance_slider.p_height intdiv 2)-incr >= luminance_gradient.p_y) {
         luminance_slider.p_y -= incr;
         luminance_slider._update_hsl_color();
      }
   }

   if (text_wid && isnumber(text_wid.p_text)) {
      int v = (int) text_wid.p_text;
      if (v > 0) {
         text_wid.p_text = --v;
      }
   }
}
void ctl_ok.down()
{
   _nocheck _control luminance_slider;
   _nocheck _control luminance_gradient;
   int text_wid = 0;
   int incr = _dy2ly(SM_TWIP, 1);
   if (p_user == hs_map) {
      if (hs_picker.p_y+incr+(hs_picker.p_height intdiv 2) <= hs_map.p_height) {
         hs_picker.p_y += incr;
         _update_hsl_color();
      }
   } else if (p_user==rgb_slider1 || p_user==rgb_gradient1) {
      text_wid=rgb_text1;
   } else if (p_user==rgb_slider2 || p_user==rgb_gradient2) {
      text_wid=rgb_text2;
   } else if (p_user==rgb_slider3 || p_user==rgb_gradient3) {
      text_wid=rgb_text3;
   } else if (p_user==luminance_slider) {
      if (luminance_slider.p_y+(luminance_slider.p_height intdiv 2)+incr <= luminance_gradient.p_y+luminance_gradient.p_height) {
         luminance_slider.p_y += incr;
         luminance_slider._update_hsl_color();
      }
   }

   if (text_wid && isnumber(text_wid.p_text)) {
      int v = (int) text_wid.p_text;
      if (v < 255) {
         text_wid.p_text = ++v;
      }
   }
}
void ctl_ok.left()
{
   if (p_user==hs_map) {
      int incr = _dx2lx(SM_TWIP, 1);
      if (hs_picker.p_x-incr+(hs_picker.p_width intdiv 2) >= 0) {
         hs_picker.p_x -= incr;
      } else {
         hs_picker.p_x = hs_map.p_width-(hs_picker.p_width intdiv 2);
      }
      _update_hsl_color();
   } else {
      call_event(ctl_ok, UP);
   }
}
void ctl_ok.right()
{
   if (p_user==hs_map) {
      int incr = _dx2lx(SM_TWIP, 1);
      if (hs_picker.p_x+incr+(hs_picker.p_width intdiv 2) <= hs_map.p_width) {
         hs_picker.p_x += incr;
      } else {
         hs_picker.p_x = -(hs_picker.p_width intdiv 2);
      }
      _update_hsl_color();
   } else {
      call_event(ctl_ok, DOWN);
   }
}

void hs_map.mouse_move()
{
   if (p_window_id!=mou_has_captured()) {
      return;
   }
   int mx=0, my=0;
   mou_get_xy(mx, my);
   _dxy2lxy(SM_TWIP, mx, my);
   _map_xy(0, hs_map.p_window_id, mx, my, SM_TWIP);
   if (mx < 0) {
      mx = 0;
   } else if (mx > hs_map.p_width) {
      mx = hs_map.p_width;
   }
   if (my < 0) {
      my = 0;
   } else if (my > hs_map.p_height) {
      my = hs_map.p_height;
   }
   hs_picker.p_x = mx - (hs_picker.p_width >> 1);
   hs_picker.p_y = my - (hs_picker.p_height >> 1);
   _update_hsl_color();
}

/*
  Luminance slider
 */
void luminance_slider.lbutton_down()
{
   mou_capture();
   call_event(p_window_id, MOUSE_MOVE, 'w');
}

void luminance_slider.lbutton_up()
{
   mou_release();
   ctl_ok._set_focus();
   ctl_ok.p_user=luminance_slider;
}

void luminance_slider.mouse_move()
{
   if (p_window_id!=mou_has_captured()) {
      return;
   }
   int mx=0, my=0;
   int lx=0, ly;
   mou_get_xy(mx, my);
   ly = _dy2ly(SM_TWIP, my);
   _map_xy(0, luminance_gradient.p_window_id, lx, ly, SM_TWIP);
   if (ly < 0) {
      ly = 0;
   } else if (ly > luminance_gradient.p_height) {
      ly = luminance_gradient.p_height;
   }
   luminance_slider.p_y = luminance_gradient.p_y + ly - (luminance_slider.p_height >> 1);
   _update_hsl_color();
}

/*
   RGB sliders
 */
void rgb_slider1.lbutton_down()
{
   mou_capture();
   call_event(p_window_id, MOUSE_MOVE, 'w');
}

void rgb_slider1.lbutton_up()
{
   mou_release();
   ctl_ok._set_focus();
   ctl_ok.p_user=p_window_id;
}

void rgb_slider1.mouse_move()
{
   if (p_window_id!=mou_has_captured()) {
      return;
   }
   int mx=0, my=0;
   int lx=0, ly=0;
   int gradientID = _GetDialogInfo(DLGINFO_GRADIENT, p_window_id);
   int sliderID = _GetDialogInfo(DLGINFO_SLIDER, p_window_id);
   int textboxID = _GetDialogInfo(DLGINFO_TEXT_BOX, p_window_id);
   mou_get_xy(mx, my);
   lx = _dx2lx(SM_TWIP, mx);
   _map_xy(0, gradientID.p_window_id, lx, ly, SM_TWIP);
   if (lx < 0) {
      lx = 0;
   } else if (lx > gradientID.p_width) {
      lx = gradientID.p_width;
   }
   sliderID.p_x = gradientID.p_x + lx - (sliderID.p_width>>1);
   int value = (255 * lx) / gradientID.p_width;
   int color_shift = _GetDialogInfo(DLGINFO_COLORSHIFT, textboxID.p_window_id);
   int current_color = sampler.p_backcolor;
   int new_color = (current_color & ~((0x0ff) << color_shift)) | (value << color_shift);
   _update_rgb_color(new_color, false, true);
}

/*
   Color swatches
*/
void foreground.lbutton_down()
{
   _update_rgb_color(p_backcolor, true, true);
}
void foreground.lbutton_double_click()
{
   _update_rgb_color(p_backcolor, true, true);
   call_event(ctl_ok, LBUTTON_UP, 'W');
}

/*
   Update code, using HSL color space [0-240] to RGB color space [0-255]
*/
#define HSLMAX 240
#define RGBMAX 255

static int _clamp(int& v, int v0, int v1)
{
   if (v < v0) {
      v = v0;
   } else if (v > v1) {
      v = v1;
   }
   return v;
}

static int _h2rgb(int h, int v1, int v2)
{
   if (h < 0) {
      h += HSLMAX;
   }
   if (h > HSLMAX) {
      h -= HSLMAX;
   }
   if (h < (HSLMAX/6)) {
      return (v1+(((v2-v1)*h+(HSLMAX/12))/(HSLMAX/6)));
   }
   if (h < (HSLMAX/2)) {
      return (v2);
   }
   if (h < ((HSLMAX*2)/3)) {
      return (v1+(((v2-v1)*(((HSLMAX*2)/3)-h)+(HSLMAX/12))/(HSLMAX/6)));
   }
   return (v1);
}

static void _hsl2rgb(int h, int s, int l, int& r, int& g, int &b)
{
   if (s == 0) {
      r = g = b = (l * RGBMAX) / HSLMAX;
   } else {
      int v1, v2;
      if (l <= (HSLMAX / 2)) {
         v2 = (l*(HSLMAX + s)+(HSLMAX / 2)) / HSLMAX;
      } else {
         v2 = l + s - ((l * s)+(HSLMAX / 2)) / HSLMAX;
      }
      v1 = 2 * l - v2;
      r = (_h2rgb(h + (HSLMAX/3), v1, v2) * RGBMAX + (HSLMAX / 2)) / HSLMAX;
      g = (_h2rgb(h, v1, v2) * RGBMAX + (HSLMAX / 2)) / HSLMAX;
      b = (_h2rgb(h - (HSLMAX / 3), v1, v2) * RGBMAX +(HSLMAX / 2)) / HSLMAX;
   }
   _clamp(r, 0, RGBMAX); _clamp(g, 0, RGBMAX); _clamp(b, 0, RGBMAX);
}

static void _rgb2hsl(int r, int g, int b, int& h, int& s, int &l)
{
   int c_max = max(max(r, g), b);
   int c_min = min(min(r, g), b);
   int diff = c_max - c_min;
   int sum = c_max + c_min;
   l = ((sum * HSLMAX) + RGBMAX)/(2*RGBMAX);
   if (c_max == c_min) {
      h = 0;
      s = 0;
   } else {
      if (l < (HSLMAX/2)) {
          s = ((diff * HSLMAX) + (sum / 2)) / sum;
      } else {
          s = ((diff * HSLMAX) + ((2 * RGBMAX - sum) / 2)) / (2 * RGBMAX - sum);
      }
      int r_delta = (((c_max - r) * (HSLMAX / 6)) + (diff / 2) ) / diff;
      int g_delta = (((c_max - g) * (HSLMAX / 6)) + (diff / 2) ) / diff;
      int b_delta = (((c_max - b) * (HSLMAX / 6)) + (diff / 2) ) / diff;
      if (r == c_max)
         h = b_delta - g_delta;
      else if (g == c_max)
         h = (HSLMAX/3) + r_delta - b_delta;
      else /* b == c_max */
         h = ((2*HSLMAX)/3) + g_delta - r_delta;
      if (h < 0)
         h += HSLMAX;
      if (h > HSLMAX)
         h -= HSLMAX;
   }
   _clamp(h, 0, HSLMAX); _clamp(s, 0, HSLMAX); _clamp(l, 0, HSLMAX);
}

static void _update_hsl_markers(int h, int s, int l)
{
   int x, y, width, height;
   //update luminance marker
   height = luminance_gradient.p_height;
   y = ((HSLMAX - l) * height) / HSLMAX;
   luminance_slider.p_y = luminance_gradient.p_y + y - (luminance_slider.p_height >> 1);

   //update hue/sat marker
   width = hs_map.p_width;
   height = hs_map.p_height;
   x = (h * width) / HSLMAX;
   y = ((HSLMAX - s) * height) / HSLMAX;
   hs_picker.p_x = x - (hs_picker.p_width >> 1);
   hs_picker.p_y = y - (hs_picker.p_height >> 1);
}

static void _update_rgb_markers(int r, int g, int b)
{
   int tx = _dx2lx(SM_TWIP, 1);
   rgb_slider1.p_x = rgb_gradient1.p_x + tx + ((r * (rgb_gradient1.p_width) - tx*2) / 255) - (rgb_slider1.p_width>>1);
   rgb_slider2.p_x = rgb_gradient2.p_x + tx + ((g * (rgb_gradient2.p_width) - tx*2) / 255) - (rgb_slider2.p_width>>1);
   rgb_slider3.p_x = rgb_gradient3.p_x + tx + ((b * (rgb_gradient3.p_width) - tx*2) / 255) - (rgb_slider3.p_width>>1);
}

static void _update_background_colors(int h, int s, int l, int r, int g, int b)
{
   int dr, dg, db;
   _hsl2rgb(h, s, HSLMAX/2, dr, dg, db);
   int hs_value = (db << 16) | (dg << 8) | dr;
   luminance_hi.p_forecolor = hs_value;
   luminance_lo.p_backcolor = hs_value;
   int color_value = (b << 16) | (g << 8) | r;
   rgb_gradient1.p_backcolor = (color_value & 0xffff00);
   rgb_gradient1.p_forecolor = (color_value | 0x0000ff);
   rgb_gradient2.p_backcolor = (color_value & 0xff00ff);
   rgb_gradient2.p_forecolor = (color_value | 0x00ff00);
   rgb_gradient3.p_backcolor = (color_value & 0x00ffff);
   rgb_gradient3.p_forecolor = (color_value | 0xff0000);
   sampler.p_backcolor = color_value;
/*
   _str name = "(" :+ h :+ ", " :+ s ", " :+ l ") : (" :+ r :+ ", " :+ g ", " :+ b ")";
   p_active_form.p_caption = name;
*/
}

static boolean _ignore_update = false;
static void _update_hsl_color()
{
   int r, g, b, h, s, l;
   h = (HSLMAX * (hs_picker.p_x + (hs_picker.p_width >> 1)))/hs_map.p_width;
   s = HSLMAX - (HSLMAX * (hs_picker.p_y + (hs_picker.p_height >> 1)))/hs_map.p_height;
   l = HSLMAX - (HSLMAX * (luminance_slider.p_y - luminance_gradient.p_y + (luminance_slider.p_height >> 1)))/(luminance_gradient.p_height);
   _hsl2rgb(h, s, l, r, g, b);
   _ignore_update = true;
   rgb_text1.p_text = r;
   rgb_text2.p_text = g;
   rgb_text3.p_text = b;
   _ignore_update = false;
   _update_rgb_markers(r, g, b);
   _update_background_colors(h, s, l, r, g, b);
}

static void _update_rgb_color(int color_value, boolean rgb_update, boolean text_update)
{
   if (_ignore_update) {
      return;
   }
   int h, s, l;
   int r = color_value & 0x0ff;
   int g = (color_value >> 8) & 0x0ff;
   int b = (color_value >> 16) & 0x0ff;
   _rgb2hsl(r, g, b, h, s, l);
   _ignore_update = true;
   if (text_update) {
      rgb_text1.p_text = r;
      rgb_text2.p_text = g;
      rgb_text3.p_text = b;
   }
   _ignore_update = false;
   if (rgb_update) {
      _update_rgb_markers(r, g, b);
   }
   _update_hsl_markers(h, s, l);
   _update_background_colors(h, s, l, r, g, b);
}


