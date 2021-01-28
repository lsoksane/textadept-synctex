local function forward_search()
  -- Enable backward search (server is started only once)
  os.spawn('synctex_xreader_textadept_backward_search_server'):wait()
  local line = buffer.line_from_position(buffer.current_pos)
  os.spawn(string.format(
    'synctex_xreader_forward_search "%s" %d',
    buffer.filename, line)):wait()
end

local function get_message_buffer()
  local buffer_type = _L['[Message Buffer]']
  local message_buffer
  for i = 1, #_BUFFERS do
    if _BUFFERS[i]._type == buffer_type then
      message_buffer = _BUFFERS[i]
      break
    end
  end
  return message_buffer
end

local function compiled_latex(output, ext)
  if output == '> exit status: 0\n' then
    local message_buffer = get_message_buffer()
    if message_buffer then 
      message_buffer:close()
      forward_search()
    end
  end
end

local function init_latex(lexerName)
  if lexerName == 'latex' then
    textadept.run.run_commands['tex'] = 
        'pdflatex -synctex=1 -file-line-error -halt-on-error "%f"'
    textadept.run.compile_commands['tex'] = 
        'bibtex "%e.aux"'
    events.connect(events.RUN_OUTPUT, compiled_latex)
    
    snippets['latex'] = snippets['latex'] or {}
    snippets.latex['eq'] = 
        '\t\\begin{align*}\n%1\n\t\\end{align*}\n'
    snippets.latex['eql'] = 
        '\t\\begin{align}\\label{%1}\n%2\n\t\\end{align}\n'
    snippets.latex['begin'] = 
        '\\begin{%1}\n%2\n\\end{%1}'    
  end
end
events.connect(events.LEXER_LOADED, init_latex)

-- Adjust the default theme's font and size
if not CURSES then
  view:set_theme('light', {font = 'Roboto Mono', size = 15})
end
-- Always use tabs for indentation.
buffer.use_tabs = false
buffer.tab_width = 4
-- Always strip trailing spaces on save
textadept.editing.strip_trailing_space = true
-- Wrap long lines at word boundaries (ignoring style boundaries)
view.wrap_mode = view.WRAP_WHITESPACE

-- Disable auto-pair and typeover.
textadept.editing.auto_pairs = nil
textadept.editing.typeover_chars = nil
textadept.editing.auto_indent = false

keys['f9'] = textadept.run.run
keys['shift+f9'] = textadept.run.compile
keys['f12'] = textadept.macros.record
keys['shift+f12'] = textadept.macros.play

local function grab_focus()
  os.spawn("wm_focus_class textadept.Textadept"):wait()
end
events.connect(events.BUFFER_NEW, grab_focus)
