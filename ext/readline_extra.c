
#include <stdio.h>

#include <readline/readline.h>

#include "ruby.h"
#include "rubyio.h"

#define PRE_INPUT_PROC "pre_input_proc"
static ID pre_input_proc;

#define CHAR_INPUT_PROC "char_input_proc"
static ID char_input_proc;


VALUE mReadlineExtra = Qnil;

void Init_readline_extra();

static VALUE readline_extra_insert_text(int argc, VALUE *argv, VALUE self);
static VALUE readline_extra_line_buffer(VALUE self);
static VALUE readline_extra_parse_and_bind(int argc, VALUE *argv, VALUE self);
static VALUE readline_extra_redisplay(VALUE self);

static VALUE readline_extra_s_set_pre_input_proc(VALUE self, VALUE proc);
static VALUE readline_extra_s_get_pre_input_proc(VALUE self);
static int readline_extra_on_pre_input_hook(void);

int readline_extra_getc(FILE *stream);
static VALUE readline_extra_s_set_char_input_proc(VALUE self, VALUE proc);
static VALUE readline_extra_s_get_char_input_proc(VALUE self);
static int readline_extra_on_char_input_hook(int c);

void Init_readline_extra()
{
    mReadlineExtra = rb_define_module("Readline");

    pre_input_proc = rb_intern(PRE_INPUT_PROC);
    rl_pre_input_hook = readline_extra_on_pre_input_hook;

    rb_define_singleton_method(mReadlineExtra, "pre_input_proc=", readline_extra_s_set_pre_input_proc, 1);
    rb_define_singleton_method(mReadlineExtra, "pre_input_proc", readline_extra_s_get_pre_input_proc, 0);

    rl_getc_function = readline_extra_getc;
    char_input_proc = rb_intern(CHAR_INPUT_PROC);

    rb_define_singleton_method(mReadlineExtra, "char_input_proc=", readline_extra_s_set_char_input_proc, 1);
    rb_define_singleton_method(mReadlineExtra, "char_input_proc", readline_extra_s_get_char_input_proc, 0);

    rb_define_module_function(mReadlineExtra, "line_buffer", readline_extra_line_buffer, -1);
    rb_define_module_function(mReadlineExtra, "insert_text", readline_extra_insert_text, -1);
    rb_define_module_function(mReadlineExtra, "parse_and_bind", readline_extra_parse_and_bind, -1);
    rb_define_module_function(mReadlineExtra, "redisplay", readline_extra_redisplay, -1);

}

static VALUE readline_extra_line_buffer(VALUE self)
{
    if (rl_line_buffer)
       return rb_tainted_str_new2(rl_line_buffer);
    else
       return rb_tainted_str_new2("");
}

static VALUE readline_extra_insert_text(int argc, VALUE *argv, VALUE self)
{
    VALUE tmp;

    if (rb_scan_args(argc, argv, "10", &tmp) > 0) {
        SafeStringValue(tmp);
        rl_insert_text(RSTRING_PTR(tmp));
    }

    return self;
}

// doesn't seem to work
static VALUE readline_extra_parse_and_bind(int argc, VALUE *argv, VALUE self)
{
    VALUE tmp;

    if (rb_scan_args(argc, argv, "10", &tmp) > 0) {
        OutputStringValue(tmp);
        rl_parse_and_bind(RSTRING_PTR(tmp));
    }

    return self;
}

static VALUE readline_extra_redisplay(VALUE self)
{
    rl_redisplay();

    return self;
}

static int
readline_extra_on_pre_input_hook(void)
{
    VALUE proc;

    proc = rb_attr_get(mReadlineExtra, pre_input_proc);

    if (NIL_P(proc))
        return -1;

    rb_funcall(proc, rb_intern("call"), 0);

    return 0;
}

static VALUE
readline_extra_s_set_pre_input_proc(VALUE self, VALUE proc)
{
    rb_secure(4);

    if (!NIL_P(proc) && !rb_respond_to(proc, rb_intern("call")))
        rb_raise(rb_eArgError, "argument must respond to `call'");

    return rb_ivar_set(mReadlineExtra, pre_input_proc, proc);
}

static VALUE
readline_extra_s_get_pre_input_proc(VALUE self)
{
    rb_secure(4);
    return rb_attr_get(mReadlineExtra, pre_input_proc);
}

int readline_extra_getc(FILE *stream)
{
    int c;
    c = rl_getc(stream);
    return readline_extra_on_char_input_hook(c);
}

static int
readline_extra_on_char_input_hook(int c)
{
    VALUE proc, ret;

    proc = rb_attr_get(mReadlineExtra, char_input_proc);

    if (NIL_P(proc))
        return c;

    ret = rb_funcall(proc, rb_intern("call"), 1, INT2FIX(c));

    if(ret == Qnil)
        return 0;

    if(!FIXNUM_P(ret))
        rb_raise(rb_eTypeError, "Readline::char_input_proc must return nil or a Fixnum");

    return (int)FIX2INT(ret);
}

static VALUE
readline_extra_s_set_char_input_proc(VALUE self, VALUE proc)
{
    rb_secure(4);

    if (!NIL_P(proc) && !rb_respond_to(proc, rb_intern("call")))
        rb_raise(rb_eArgError, "argument must respond to `call'");

    return rb_ivar_set(mReadlineExtra, char_input_proc, proc);
}

static VALUE
readline_extra_s_get_char_input_proc(VALUE self)
{
    rb_secure(4);
    return rb_attr_get(mReadlineExtra, char_input_proc);
}

