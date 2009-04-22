# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

$headers = ["stdio.h", "readline/readline.h"]

exit unless have_library("readline", "readline")

$headers.each { |h| exit unless have_header(h) }

%w{"rl_line_buffer"
   "rl_insert_text"
   "rl_parse_and_bind"
   "rl_redisplay"}.each { |f| exit unless have_func(f, $headers) }

%w{"rl_pre_input_hook"
   "rl_getc_function"}.each { |f| exit unless have_var(f, $headers) }

create_makefile("readlinep")
