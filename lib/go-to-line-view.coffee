{Point, TextEditor} = require 'atom'

module.exports =
class GoToLineView
  @activate: -> new GoToLineView

  constructor: ->
    @element = document.createElement('div')
    @element.classList.add('go-to-line')

    @miniEditor = new TextEditor
    @miniEditor.element.addEventListener('blur', @close.bind(this))
    @element.appendChild(@miniEditor.element)

    @message = document.createElement('div')
    @message.classList.add('message')
    @element.appendChild(@message)

    atom.commands.add @miniEditor.element, 'core:confirm', => @confirm()
    atom.commands.add @miniEditor.element, 'core:cancel', => @close()
    @panel = atom.workspace.addModalPanel(item: @element, visible: false)

    atom.commands.add 'atom-text-editor', 'go-to-line:toggle', =>
      @toggle()
      false

    @miniEditor.onWillInsertText ({cancel, text}) ->
      cancel() if text.match(/[^0-9:]/)

  toggle: ->
    if @panel.isVisible()
      @close()
    else
      @open()

  close: ->
    return unless @panel.isVisible()

    miniEditorFocused = @miniEditor.element.hasFocus()
    @miniEditor.setText('')
    @panel.hide()
    @restoreFocus() if miniEditorFocused

  confirm: ->
    lineNumber = @miniEditor.getText()
    editor = atom.workspace.getActiveTextEditor()

    @close()

    return unless editor? and lineNumber.length

    currentRow = editor.getCursorBufferPosition().row
    [row, column] = lineNumber.split(/:+/)
    if row?.length > 0
      # Line number was specified
      row = parseInt(row) - 1
    else
      # Line number was not specified, so assume we will be at the same line
      # as where the cursor currently is (no change)
      row = currentRow

    if column?.length > 0
      # Column number was specified
      column = parseInt(column) - 1
    else
      # Column number was not specified, so if the line number was specified,
      # then we should assume that we're navigating to the first character
      # of the specified line.
      column = -1

    position = new Point(row, column)
    editor.setCursorBufferPosition(position)
    editor.unfoldBufferRow(row)
    if column < 0
      editor.moveToFirstCharacterOfLine()
    editor.scrollToBufferPosition(position, center: true)

  storeFocusedElement: ->
    @previouslyFocusedElement = document.activeElement

  restoreFocus: ->
    if @previouslyFocusedElement?.parentElement
      @previouslyFocusedElement.focus()
    else
      atom.views.getView(atom.workspace).focus()

  open: ->
    return if @panel.isVisible()

    if atom.workspace.getActiveTextEditor()
      @storeFocusedElement()
      @panel.show()
      @message.textContent = "Enter a <row> or <row>:<column> to go there. Examples: \"3\" for row 3 or \"2:7\" for row 2 and column 7"
      @miniEditor.element.focus()
