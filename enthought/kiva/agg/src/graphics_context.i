//---------------------------------------------------------------------------
//
//  Wrapper for graphics_context_base->GraphicsContextArray
//  A derived class called GraphicsContextArray is in the %pythoncode and
//  overrides a large number of functions to handle type conversions in 
//  python instead of having to write them in C/C++.
//
//    Todo:
//        *. Fix dash_type constructor overload for accepting a pattern
//            !! Should we reverse the order of _pattern and phase and
//            !! default the phase to be 0?? (I think so...)
//        *. use properties to replace set/get methods.
//---------------------------------------------------------------------------

// typemaps for many enumerated types used in graphics_contexts
%include "constants.i"

// Language independent exception handler
%include exception.i       

// handle kiva::rect declarations
%include "rect.i"
//%apply kiva::rect_type {kiva::rect_type};

%include "agg_typemaps.i"
%apply (double* point_array, int point_count) {(double* pts, int Npts)};
%apply (double* point_array, int point_count) {(double* start, int Nstart)};
%apply (double* point_array, int point_count) {(double* end, int Nend)};
%apply (double* rect_array, int rect_count) {(double* rects, int Nrects)};
%apply (double* pt_x, double* pt_y) {(double* tx, double* ty)};
%apply (double* array6) {(double* out)};
%apply (double* dash_pattern, int n) { (double* pattern, int n)};
%apply (unsigned char *image_data, int width, int height, int stride) {
            (unsigned char *data, int width, int height, int stride) };
%apply (owned_pointer) { kiva::graphics_context* };

// map string input into standard string and back
%include "agg_std_string.i"

// typemaps for double ary[]
%include "sequence_to_array.i"

%include "rgba_array.i"
%apply rgba_as_array {agg::rgba&};
%{
    agg::rgba _clear_color = agg::rgba(1,1,1,1);
%}

%include "numeric_ext.i"

%typemap(out) PyObject*
{
    $result = $1;
}

%{
#include "kiva_graphics_context.h"

// hack to get around SWIGs typechecking for overloaded constructors
kiva::graphics_context_base* graphics_context_from_array(
       unsigned char *data, int width, int height, int stride,
       kiva::pix_format_e format, 
       kiva::interpolation_e interpolation=kiva::nearest,
       int bottom_up = 1)
{
    if (bottom_up)
    {
        stride *= -1;
    }

    switch (format)
    {

        case kiva::pix_format_rgb24:
        {
            return (kiva::graphics_context_base*) 
                new kiva::graphics_context_rgb24(data,width,height,stride,interpolation);
        }
        case kiva::pix_format_bgr24:
        {
            return (kiva::graphics_context_base*) 
                new kiva::graphics_context_bgr24(data,width,height,stride,interpolation);
        }
        case kiva::pix_format_rgba32:
        {
            return (kiva::graphics_context_base*) 
                new kiva::graphics_context_rgba32(data,width,height,stride,interpolation);
        }
        case kiva::pix_format_bgra32:
        {
            return (kiva::graphics_context_base*) 
                new kiva::graphics_context_bgra32(data,width,height,stride,interpolation);
        }
        case kiva::pix_format_argb32:
        {
            return (kiva::graphics_context_base*) 
                new kiva::graphics_context_argb32(data,width,height,stride,interpolation);
        }
        case kiva::pix_format_abgr32:
        {
            return (kiva::graphics_context_base*) 
                new kiva::graphics_context_abgr32(data,width,height,stride,interpolation);
        }
        case kiva::pix_format_gray8:
        {
            //return (kiva::graphics_context_base*) 
            //    new kiva::graphics_context_gray8(data,width,height,stride,interpolation);
            return (kiva::graphics_context_base*) NULL;   
        }
        case kiva::pix_format_rgb555:
        case kiva::pix_format_rgb565:
        case kiva::end_of_pix_formats:
        default:
        {
            // format not valid.
            return (kiva::graphics_context_base*) NULL;
        }    
    }    
}

int destroy_graphics_context(kiva::graphics_context_base* gc)
{
    switch (gc->format())
    {
        case kiva::pix_format_rgb24:
        {
            delete (kiva::graphics_context_rgb24*) gc;
            break;
        }
        case kiva::pix_format_bgr24:
        {
            delete (kiva::graphics_context_bgr24*) gc;
            break;
        }
        case kiva::pix_format_rgba32:
        {
            delete (kiva::graphics_context_rgba32*) gc;
            break;
        }
        case kiva::pix_format_argb32:
        {
            delete (kiva::graphics_context_argb32*) gc;
            break;
        }
        case kiva::pix_format_abgr32:
        {
            delete (kiva::graphics_context_abgr32*) gc;
            break;
        }
        case kiva::pix_format_bgra32:
        {
            delete (kiva::graphics_context_bgra32*) gc;
            break;
        }
        case kiva::pix_format_gray8:
        {
            // we don't handle this format at the moment.
            return 1;
            //delete (kiva::graphics_context_gray8*) gc;
            //break;
        }
        case kiva::pix_format_rgb555:
        case kiva::pix_format_rgb565:
        case kiva::end_of_pix_formats:
        default:
        {
            // format not valid.
            return 1;
        }    
    }    
    return 0;
}

void graphics_context_multiply_alpha(double alpha,
       unsigned char *data, int width, int height, int stride)
{
    for (int i=3;i<height*stride;i+=4)
    {
        data[i] = (unsigned char)(data[i] * alpha);
    }
}

%}

kiva::graphics_context_base* graphics_context_from_array(
       unsigned char *data, int width, int height, int stride,
       kiva::pix_format_e format, 
       kiva::interpolation_e interpolation=kiva::nearest,
       int bottom_up = 1);

int destroy_graphics_context(kiva::graphics_context_base* gc);

void graphics_context_multiply_alpha(double alpha,
       unsigned char *data, int width, int height, int stride);

namespace kiva {

    %pythoncode
    %{
        # used in GraphicsContextArray constructors
        from numpy import zeros, uint8, fromstring, shape, ndarray, resize, dtype

        # global freetype engine for text rendering.
        #from enthought import freetype
        #ft_engine = freetype.FreeType(dpi=120.0)
        
        from enthought.kiva import fonttools
        
        def handle_unicode(text):
            "Returns a latin1 encoded 8-bit string from 'text'"
            # For now we just deal with unicode by converting to latin1
            # Later we can add full-blown support with wchar_t/Py_UNICODE 
            # typemaps etc.
            try:
                if isinstance(text, unicode):
                    text = text.encode("latin1")
                return text
            except:
                raise UnicodeError, "Error encoding text to latin1."
    %}

    void cleanup_font_threading_primitives();

    %pythoncode
    %{
        # Register module function to clean up mutexes and criticalsection
        # objects when the process quits.

        import atexit
        atexit.register(cleanup_font_threading_primitives)

    %}
    
    %nodefault;
    %rename(GraphicsContextArray) graphics_context_base;
    
    class graphics_context_base
    {
        public:
            %pythoncode
            %{
            # We define our own constructor AND destructor.
            
            def __init__(self, ary_or_size, pix_format="bgra32",
                         interpolation="nearest",bottom_up = 1):
                """ When specifying size, it must be a two element tuple.
                    Array input is always treated as an image.
                    
                    This class handles the polymorphism of the underlying
                    template classes for individual pixel formats.
                """
                array_locally_allocated = False
                self.corner_pixel_origin = True

                pix_format_id = pix_format_string_map[pix_format]
                img_depth = pix_format_bytes[pix_format]
                interpolation_id = interp_string_map[interpolation]
                
                if type(ary_or_size) is tuple:
                    width,height = ary_or_size
                    # fix me: this is a slow way to create an array.
                    #         the new empty() method in Numeric is much 
                    #         faster because it doesn\'t zero memory.
                    ary = zeros((height,width,img_depth),uint8)
                    array_locally_allocated = True
                else:            
                    ary = ary_or_size
                    sh = shape(ary)        
                    if len(sh) == 2:
                        msg = "2D arrays must use a format that is one byte per pixel"
                        assert img_depth == 1, msg
                    elif len(sh) == 3:
                        msg = "Image depth and format are incompatible"
                        assert img_depth == sh[2], msg
                    else:
                        msg = "only 2 or 3 dimensional arrays are supported as images"
                        msg += " but got sh=%r" % (sh)
                        raise TypeError, msg
                    msg = "Only UnsignedInt8 arrays are supported but got "
                    assert(ary.dtype == dtype('uint8')), msg + repr(ary.dtype)

                obj = graphics_context_from_array(ary,pix_format_id,
                                                  interpolation_id,
                                                  bottom_up)
                    
                _swig_setattr(self, GraphicsContextArray, 'this', obj)
                # swig 1.3.28 does not have real thisown, thisown is mapped
                # to this.own() but with previous 'self.this=obj' an
                # attribute 'own' error is raised. Does this workaround
                # work with pre-1.3.28 swig?
                _swig_setattr(self, GraphicsContextArray, 'thisown2', 1)

                self.bmp_array = ary                
                
                if array_locally_allocated is True:
                    self.clear()

            def __del__(self, destroy=_agg.destroy_graphics_context):
                try:
                    if self.thisown2: destroy(self)
                except: pass
                    
            %}
            
            int bottom_up();
            int width();
            int height();
            int stride();
            
            %feature("shadow") format()
            %{
            def format(self):
                enum = _agg.GraphicsContextArray_format(self)
                return pix_format_enum_map[enum]    
            %}
            kiva::pix_format_e format();
            
            %feature("shadow") get_image_interpolation()
            %{
            def get_image_interpolation(self):
                enum = _agg.GraphicsContextArray_get_image_interpolation(self)
                return interp_enum_map[enum]    
            %}            
            interpolation_e get_image_interpolation();
            
            %feature("shadow") set_image_interpolation(
                                        kiva::interpolation_e interpolation)
            %{
            def set_image_interpolation(self,interp):
                enum = interp_string_map[interp]
                _agg.GraphicsContextArray_set_image_interpolation(self,enum)
            %}            
            void set_image_interpolation(
                    kiva::interpolation_e interpolation);

            %feature("shadow") set_stroke_color(agg::rgba& rgba_in)
            %{
            def set_stroke_color(self,color):
                if is_array(color) and len(color) == 3:
                    ary = color
                    r,g,b = ary
                    color = Rgba(r,g,b)
                elif is_array(color) and len(color) == 4:
                    ary = color
                    r,g,b,a = ary
                    color = Rgba(r,g,b,a)
                _agg.GraphicsContextArray_set_stroke_color(self,color)
            %}            
            void set_stroke_color(agg::rgba& rgba_in);

            agg::rgba& get_stroke_color();
            void set_line_width(double value);
            void set_line_join(kiva::line_join_e value);
            void set_line_cap(kiva::line_cap_e value);
            void set_line_dash(double* pattern, int n, double phase=0);
            void set_blend_mode(kiva::blend_mode_e value);
            kiva::blend_mode_e get_blend_mode();
            
            %feature("shadow") set_fill_color(agg::rgba& rgba_in)
            %{
            def set_fill_color(self,color):
                if is_array(color) and len(color) == 3:
                    ary = color
                    r,g,b = ary
                    color = Rgba(r,g,b)
                elif is_array(color) and len(color) == 4:
                    ary = color
                    r,g,b,a = ary
                    color = Rgba(r,g,b,a)
                _agg.GraphicsContextArray_set_fill_color(self,color)
            %}
            void set_fill_color(agg::rgba& rgba_in);
            
            agg::rgba& get_fill_color();
            void set_alpha(double value);
            double get_alpha();
            void set_antialias(int value);
            int get_antialias();
            void set_miter_limit(double value);
            void set_flatness(double value);
            
            
            void set_text_position(double tx, double ty);
            void get_text_position(double* tx, double* ty);

            %rename(show_text_simple) show_text(char *);
            bool show_text(char *text);
            
            %feature("shadow") show_text_at_point(char *text, double dx, double dy)
            %{
            def show_text_at_point(self, text, dx, dy):
                text = handle_unicode(text)
                return _agg.GraphicsContextArray_show_text_at_point(self, text, dx, dy)
            %}            
            bool show_text_at_point(char *text, double dx, double dy);
            
            %pythoncode
            %{
            def show_text(self, text, point = None):
                """Displays text at point, or at the current text pen position
                   if point is None.  Returns true if text displayed properly,
                   false if there was a font issue or a glyph could not be
                   rendered.  Will handle multi-line text separated by backslash-ns"""
                
                text = handle_unicode(text)
                
                linelist = text.split('\n')
                
                if point:
                    savepoint = self.get_text_position()
                    self.set_text_position(*point)
                orig_tm = self.get_text_matrix()
                next_tm = orig_tm
                success = True
                for line in linelist:
                    self.set_text_matrix(next_tm)
                    success = success and self.show_text_simple(line)
                    extent = self.get_text_extent(line)
                    txt_xlat = translation_matrix(0,(extent[1]-extent[3])*1.4)
                    txt_xlat.multiply(next_tm)
                    next_tm = txt_xlat

                if point:
                    self.set_text_position(*savepoint)
                if not success:
                    raise RuntimeError, "Font not loaded/initialized."

            %}                       

            %feature("shadow") get_text_extent(char *text)
            %{
            def get_text_extent(self, text):
                if not self.is_font_initialized():
                    raise RuntimeError, "Font not loaded/initialized."
                else:
                    text = handle_unicode(text)
                    return _agg.GraphicsContextArray_get_text_extent(self, text)
            %}
            kiva::rect_type get_text_extent(char *text);

            bool is_font_initialized();

            void set_text_matrix(agg::trans_affine& value);
            
            agg::trans_affine get_text_matrix();
            void set_character_spacing(double value);
            double get_character_spacing();
            void set_text_drawing_mode(kiva::text_draw_mode_e value);

            %pythoncode
            %{
            # backward compatibility
            # Also, Enable calls get_full_text_extent exclusively; it expects the returned
            # arguments to be in a different order
            def get_full_text_extent(self, text):
                leading, descent, w, h = self.get_text_extent(text)
                return (w, h, descent, leading)
            %}

            %feature("shadow") set_font(kiva::font_type& font)
            %{
            def set_font(self, font):
                retval = False
                if isinstance(font, AggFontType):
                    agg_font = font
                elif isinstance(font, fonttools.Font):
                    cur_font = self.get_font()
                    if cur_font.is_loaded() and (font.face_name == cur_font.name) and \
                        (font.size == cur_font.size) and (font.style == cur_font.style) \
                        and (font.encoding == cur_font.encoding):
                        return
                    else:
                        newfilename = font.findfont()
                        agg_font = AggFontType(font.face_name, font.size, font.family, font.style,
                                               font.encoding, False)
                        agg_font.filename = newfilename
                else:
                    agg_font = AggFontType(font.face_name, font.size, font.family, font.style, font.encoding)
                try:
                    retval = _agg.GraphicsContextArray_set_font(self, agg_font)
                    if not retval:
                        raise RuntimeError, "Unable to load font."
                except:
                    raise RuntimeError, "Unable to load font."
            %}
            bool set_font(kiva::font_type& font);

            %feature("shadow") set_font_size(int size)
            %{
            def set_font_size(self, size):
                if not _agg.GraphicsContextArray_set_font_size(self, size):
                    raise RuntimeError, "Font not loaded/initialized."
            %}
            bool set_font_size(int size);

            kiva::font_type& get_font();

            void save_state();
            void restore_state();
            void translate_ctm(double x, double y);
            void rotate_ctm(double angle);
            void scale_ctm(double sx, double sy);
            void concat_ctm(agg::trans_affine& m);
            void set_ctm(agg::trans_affine& m);
            void get_freetype_text_matrix(double* out);
            agg::trans_affine get_ctm();

            void flush();
            void synchronize();

            void begin_page();
            void end_page();

            void begin_path();
            void move_to(double x, double y);
            void line_to( double x, double y);
            void curve_to(double cpx1, double cpy1,
                          double cpx2, double cpy2,
                          double x, double y);
            void quad_curve_to(double cpx, double cpy, 
                               double x, double y);
            
            void arc(double x, double y, double radius, double start_angle,
                     double end_angle, bool cw=false);    
            void arc_to(double x1, double y1, double x2, double y2, double radius);
            
            void close_path();
            void add_path(kiva::compiled_path& other_path);
            void lines(double* pts, int Npts);
            void line_set(double* start, int Nstart, double* end, int Nend);
            void rect(kiva::rect_type &rect);
            void rect(double x, double y, double sx, double sy);
            void rects(double* all_rects, int Nrects);
            compiled_path _get_path();
            void clip();
            void even_odd_clip();
            int get_num_clip_regions();
            kiva::rect_type get_clip_region(unsigned int i);

            %exception {
                try 
                {
                    $action
                } 
                catch(int err) 
                {
                    if (err == kiva::ctm_rotation_error) 
                    {
                        PyErr_SetString(PyExc_NotImplementedError,
                                        "clip_to_rect() currently doesn't work if the GraphicsContext coordinate system (ctm) has been rotated.");
                                       
                    }                   
                    else if (err == kiva::not_implemented_error) 
                    {
                        PyErr_SetString(PyExc_NotImplementedError,"not implemented");
                    }
                    else if (err == kiva::bad_clip_state_error) 
                    {
                        PyErr_SetString(PyExc_NotImplementedError,"clip stack is empty in the graphics state -- this should never happen!! submit bug.");
                    }   
                    else if (err == kiva::even_odd_clip_error)
                    {
                        PyErr_SetString(PyExc_NotImplementedError,"even/odd clipping is not implemented");
                    }
                    else if (err == kiva::clipping_path_unsupported)
                    {
                        PyErr_SetString(PyExc_NotImplementedError,"arbitrary clipping paths is not implemented");
                    }
                    else
                    {
                        SWIG_exception(SWIG_UnknownError, "Unknown error occurred");
                    }
                    return NULL;
                }
            }
            
            void clip_to_rect(kiva::rect_type& rect); 
            void clip_to_rect(double x, double y, double sx, double sy);

            %exception;  // clear exception handlers
           
            %exception {
                try 
                {
                    $action
                }
                catch (int err)
                {
                    if (err == kiva::not_implemented_error) 
                    {
                        PyErr_SetString(PyExc_NotImplementedError, "clip_to_rects is unimplemented");
                    }
                    else
                    {
                        SWIG_exception(SWIG_UnknownError, "Unknown error occurred");
                    }
                    return NULL;
                }
            }                        

            void clip_to_rects(double* all_rects, int Nrects);

            %exception;  // clear exception handlers
            
            void clear_clip_path();
            void clear(agg::rgba& value=_clear_color);
            void stroke_path();
            void fill_path();
            void eof_fill_path();
            void draw_path(draw_mode_e mode=FILL_STROKE);
            
            void draw_rect(double rect[4], 
                           draw_mode_e mode=FILL_STROKE);


            %feature("shadow")  draw_image(kiva::graphics_context_base* img, 
                                           double rect[4], bool force_copy=false)
            %{
            def draw_image(self, img, rect=None, force_copy=False):
                if rect is None:
                    rect = array((0,0,img.width(),img.height()),float)
                return _agg.GraphicsContextArray_draw_image(self,img,rect,force_copy)
            %}
          
            int draw_image(kiva::graphics_context_base* img,
                           double rect[4], bool force_copy=false);
//            int draw_image(kiva::graphics_context_base* img);
            
            //int copy_image(kiva::graphics_context_base* img, int tx, int ty);
            
            %feature("shadow") draw_marker_at_points(double* pts,int Npts, int size,
                                       agg::marker_e type = agg::marker_square)
            %{            
            def draw_marker_at_points(self,pts,size,kiva_marker_type):
                marker = kiva_marker_to_agg.get(kiva_marker_type, None)
                if marker is None:
                    success = 0
                else:    
                    args = (self,pts,int(size),marker)    
                    success = apply(_agg.GraphicsContextArray_draw_marker_at_points,args)
                return success
            %}
            int draw_marker_at_points(double* pts,int Npts, int size,
                                       agg::marker_e type = agg::marker_square);
                                       
            void draw_path_at_points(double* pts,int Npts, 
                                  kiva::compiled_path& marker,
                                  kiva::draw_mode_e mode);
            
            // additional methods added as pure python
            %pythoncode
            %{
            def convert_pixel_format(self,pix_format,inplace=0):
                """ Convert gc from one pixel format to another.
                
                    !! This used to be done in C++ code, but difficult-to-find
                    !! memory bugs pushed toward a simpler solution.  
                    !! HACK
                    !! Now we just draw into a new gc and assume its underlying C++ 
                    !! object. We must be careful not to add any attributes in the 
                    !! Python GraphicsContextArray constructor other than the bmp_array.
                    !! if we do, we need to copy them here also.
                """
                # make sure it uses sub-class if needed
                new_img = self.__class__((self.width(),self.height()),
                                          pix_format=pix_format,
                                          interpolation=self.get_image_interpolation(),
                                          bottom_up = self.bottom_up())
                new_img.draw_image(self)
                
                if inplace:
                    """
                    # swap internals with new_self -- it will dealloc our (now unused) C++ 
                    # object and we'll acquire its new one.  We also get a ref to his bmp_array
                    """
                    old_this = self.this 
                    self.this = new_img.this
                    new_img.this = old_this
                    self.bmp_array = new_img.bmp_array
                    return self
                else:    
                    return new_img        

            def get_empty_path(self):
                return CompiledPath()

            def save(self, filename, file_format=None, pil_options=None):
                """ Save the GraphicsContext to a file.  Output files are always
                    saved in RGB or RGBA format; if this GC is not in one of
                    these formats, it is automatically converted.
                    
                    If filename includes an extension, the image format is
                    inferred from it.  file_format is only required if the
                    format can't be inferred from the filename (e.g. if you
                    wanted to save a PNG file as a .dat or .bin).
    
                    filename may also be "file-like" object such as a 
                    StringIO, in which case a file_format must be supplied
                    
                    pil_options is a dict of format-specific options that
                    are passed down to the PIL image file writer.  If a writer
                    doesn't recognize an option, it is silently ignored.
                
                    If the image has an alpha channel and the specified output
                    file format does not support alpha, the image is saved in
                    rgb24 format.
                """
                FmtsWithoutAlpha = ('jpg', 'bmp', 'eps', "jpeg")
                import Image as PilImage
                size = (self.width(), self.height())
                fmt = self.format()

                # determine the output pixel format and PIL format
                if fmt.endswith("32"):
                    pilformat = "RGBA"
                    pixelformat = "rgba32"
                    if (isinstance(filename, basestring) and filename[-3:].lower() in FmtsWithoutAlpha) or \
                       (file_format is not None and file_format.lower() in FmtsWithoutAlpha):
                        pilformat = "RGB"
                        pixelformat = "rgb24"
                elif fmt.endswith("24"):
                    pilformat = "RGB"
                    pixelformat = "rgb24"

                # perform a conversion if necessary
                if fmt != pixelformat:
                    newimg = GraphicsContextArray(size, fmt)
                    newimg.draw_image(self)
                    newimg.convert_pixel_format(pixelformat, 1)
                    bmp = newimg.bmp_array
                else:
                    bmp = self.bmp_array

                img = PilImage.fromstring(pilformat, size, bmp.tostring())
                img.save(filename, format=file_format, options=pil_options)
            %}

    };
}

%pythoncode
%{
# constructors for GraphicsContextArray and Image

# !! Temporary until we get the __init__ code in swig fixed.
def init(self, ary_or_size, pix_format="bgra32",
             interpolation="nearest",bottom_up = 1):
    """ When specifying size, it must be a two element tuple.
        Array input is always treated as an image.
        
        This class handles the polymorphism of the underlying
        template classes for individual pixel formats.
    """
    
    pix_format_id = pix_format_string_map[pix_format]
    img_depth = pix_format_bytes[pix_format]
    interpolation_id = interp_string_map[interpolation]
    if type(ary_or_size) is tuple:
        width,height = ary_or_size
        ary = zeros((height,width,img_depth),uint8)
        ary[:] = 255
    else:            
        ary = ary_or_size
        sh = shape(ary)        
        if len(sh) == 2:
            msg = "2D arrays must use a format that is one byte per pixel"
            assert img_depth == 1, msg
        elif len(sh) == 3:
            msg = "Image depth and format are incompatible"
            assert img_depth == sh[2], msg
        else:
            msg = "only 2 or 3 dimensional arrays are supported as images"
            msg += " but got sh=%r" % (sh)
            raise TypeError, msg
        msg = "Only UnsignedInt8 arrays are supported but got "    
        assert ary.dtype == dtype('uint8'), msg + repr(ary.dtype)
        
    obj = graphics_context_from_array(ary,pix_format_id,interpolation_id,
                                      bottom_up)
        
    _swig_setattr(self, GraphicsContextArray, 'this', obj)
    # swig 1.3.28 does not have real thisown, thisown is mapped
    # to this.own() but with previous 'self.this=obj' an
    # attribute 'own' error is raised. Does this workaround
    # work with pre-1.3.28 swig?       	 
    _swig_setattr(self, GraphicsContextArray, 'thisown2', 1)

    self.bmp_array = ary

GraphicsContextArray.__init__ = init

pil_format_map = {}
pil_format_map["RGB"] = "rgb24"
pil_format_map["RGBA"] = "rgba32"

pil_depth_map = {}
pil_depth_map["RGB"] = 3
pil_depth_map["RGBA"] = 4

class Image(GraphicsContextArray):
    """ Image is a GraphicsContextArray sub-class created from an image file.
    """
    def __init__(self, file, interpolation="nearest", bottom_up=1):
        """ Create an Image object (GraphicsContextArray) from a file.
            
            file can either be a file name or an open file object.
            interpolation -- specifies the type of filter used when putting
                             the image into another GraphicsContextArray.
        """
        # read the file using PIL
        import Image as PilImage
        pil_img = PilImage.open(file)
        
        # Convert image to a numeric array
        if pil_img.mode not in ["RGB","RGBA"]:
            pil_img = pil_img.convert(mode="RGBA")
        depth = pil_depth_map[pil_img.mode]
        img = fromstring(pil_img.tostring(),uint8)
        img = resize(img, (pil_img.size[1],pil_img.size[0],depth))    
        format = pil_format_map[pil_img.mode]
        
        GraphicsContextArray.__init__(self, img, pix_format=format,
                                      interpolation=interpolation,
                                      bottom_up = bottom_up)

    def convert_pixel_format(self,pix_format,inplace=0):
        "Convert gc from one pixel format to another."
        # We override the one in the base GraphicsContextArray because that
        # one calls our __init__, which is not really the behavior we want.
        #
        # This problem can be avoided altogether down the road when the
        # Image subclass is turned into a factory function.
        new_img = GraphicsContextArray((self.width(),self.height()),
                                  pix_format=pix_format,
                                  interpolation=self.get_image_interpolation(),
                                  bottom_up = self.bottom_up())
        new_img.draw_image(self)
        
        if inplace:
            old_this = self.this 
            self.this = new_img.this
            new_img.this = old_this
            self.bmp_array = new_img.bmp_array
            return self
        else:    
            return new_img        


%}