class AntCat.ReferencePicker extends AntCat.Panel
  constructor: (@parent_element, @options = {}) ->
    super @parent_element.find('> .antcat_reference_picker'), @options

  create_form: ($element, options) =>
    options.button_container = '.controls'
    new AntCat.NestedForm $element, options

  form: =>
    @_form or= @create_form @expansion,
      on_open:              @on_form_open
      on_close:             @on_form_close
      on_response:          @on_form_response
      on_success:           @on_form_success
      on_cancel:            @on_form_cancel
      on_application_error: @on_application_error
      before_submit:        @before_submit

  initialize: (@element) =>
    super
    @element.addClass 'modal' unless @options.field
    @setup_cached_elements()
    @setup_controls()
    @setup_references()
    @handle_new_selection()

  setup_cached_elements: =>
    @template = @element.find '> .template';              AntCat.check 'ReferencePicker.setup_cached_elements', '@template', @template
    @edit_section = @element.find '> .edit';              AntCat.check 'ReferencePicker.setup_cached_elements', '@edit_section', @edit_section
    @expansion = @element.find '> .edit .expansion';      AntCat.check 'ReferencePicker.setup_cached_elements', '@expansion', @expansion
    @current = @element.find '> .edit table.current';     AntCat.check 'ReferencePicker.setup_cached_elements', '@current', @current
    @search_selector = @expansion.find '.search_selector';AntCat.check 'ReferencePicker.setup_cached_elements', '@search_selector', @search_selector
    @textbox = @expansion.find '.q';                      AntCat.check 'ReferencePicker.setup_cached_elements', '@textbox', @textbox
    @controls = @expansion.find '.controls';              AntCat.check 'ReferencePicker.setup_cached_elements', '@controls', @controls

  search_results: =>
    @expansion.find '> .search_results'

  show_form: =>
    @display_section.hide()
    @edit_section.show()
    @form().open()

  hide_form: =>
    @edit_section.hide()
    @display_section.show()
    @form().close()

  is_editing: =>
    @edit_section.is ':visible'

  start_throbbing: =>
    @element.find('.throbber .shared-spinner').show()
    @element.find('> .expansion > .controls').disable()

  #---------------------------------
  search: =>
    @load @get_search_parameters()

  load_link: (link) =>
    @load $(link).attr('href') + '&' + @get_search_parameters()

  get_search_parameters: =>
    $.param q: @textbox.val(), search_selector: @search_selector.val()

  ok: =>
    @close()

  cancel: =>
    @restore_panel()
    @clear_current()
    @close()

  close: =>
    @hide_form()
    @options.on_close() if @options.on_close

  use_default_reference: =>
    @id = @controls.find('#default_reference_id').val()
    @load()

  setup_controls: =>
    self = @
    @expansion
      .find('.controls')
        .undisable()
        .end()

      .find(':button.ok')
        .click =>
          @ok()
          false
        .end()

      .find(':button.close')
        .click =>
          @cancel()
          false
        .end()

      .find(':button.add')
        .click =>
          @add_reference()
          false
        .end()

      .find(':button.default_reference')
        .click =>
          @use_default_reference()
          false
        .attr('title', @get_default_reference_string())
        .end()

      .find(':button.go')
        .click =>
          @search()
          false
        .end()

      .find('.q')
        .keypress (event) =>
          return true unless event.which is $.ui.keyCode.ENTER
          @search()
          false
        .end()

      .find('.pagination a')
        .click ->
          self.load_link @
          false
        .end()

    @enable_search_author_autocomplete()

  get_default_reference_string: =>
    @controls.find('#default_reference_string').val()

  enable_controls: => @expansion.find('.controls').undisable()
  disable_controls: => @expansion.find('.controls').disable()

  # -----------------------------------------
  add_reference: =>
    @make_current @template.find('.reference'), true

  setup_references: =>
    if @search_results()
      @search_results()
        .find("#reference_#{@id}.reference div.display")
          .addClass('ui-selected')
          .end()

    @element.find('.search_results div.display').bind 'click', (event) => @handle_click(event); false
    @element.find('.search_results div.display').hover(@hover, @unhover)

  hover: (event) =>
    AntCat.deselect()
    $target = $(event.target)
    $target = $target.closest('.display') unless $target.hasClass('display')
    $target.select()
  unhover: (event) =>
    AntCat.deselect()

  handle_click: (event) =>
    @element.find('div.display').removeClass('ui-selected')
    AntCat.deselect()
    $(event.target).addClass('ui-selected')
    @handle_new_selection()

  on_reference_form_open: => @disable_controls()
  on_reference_form_close: => @enable_controls()
  on_reference_form_done: ($panel) =>
    id = $panel.data 'id'
    $("reference_#{id}").each -> $(@).replaceWith $panel.clone()
    @setup_references()

  # 'current' is the reference panel at the top of the field, above the controls
  # too much duplication between this and setup_references
  make_current: ($panel, edit = false) =>
    $current_contents = @current.find '> tbody > tr > td'
    $new_contents = $panel.clone()
    $current_contents.html $new_contents

    @element.find('div.display').bind 'click', (event) => @handle_click(event); false
    @element.find('div.display').hover(@hover, @unhover)
    @element.removeClass 'has_no_current_reference'
    @tell_server_about_the_reference_that_was_chosen()

  tell_server_about_the_reference_that_was_chosen: =>
    url = '/default_reference'
    id = if @current_reference() then @current_reference().data 'id' else null
    if id and id != ''
      data = {id: @current_reference().data 'id'}
      $.ajax url: url, data: data, type: 'put'

  handle_new_selection: =>
    $selected_reference = @selected_reference()
    @make_current $selected_reference if $selected_reference

    @id = if @current_reference() then @current_reference().data 'id' else null
    @element.toggleClass 'has_no_current_reference', not @current_reference()
    @update_help()
    @options.on_change(@value()) if @options.on_change

  value: =>
    $value_field = $('#' + @value_id)
    $value_field.val()

  selected_reference: =>
    results = @search_results().find 'div.display.ui-selected'
    return if results.length is 0
    results.closest '.reference'

  current_reference: =>
    reference = @current.find('.reference')
    return if reference.length is 0
    return unless reference.data 'id'
    reference

  clear_current: =>
    $('.ui-selected').removeClass('ui-selected')
    @current = @element.find '> .edit > table.current'
    @current.find("reference_#{@id} .reference_item").replaceWith('<div class="reference"><table class="reference_table"><tr><td class="reference_item"><div class="display">(none)</div></td></tr></table></div>')

  # -----------------------------------------
  enable_search_author_autocomplete: =>
    return if AntCat.testing
    @enable_browser_autocomplete false
    @textbox.autocomplete
      autoFocus: true
      minLength: 3
      source: (request, result_handler) ->
        search_term = AntCat.ReferencePicker.extract_author_search_term(@element.val(), $(@element).getSelection().start)
        if search_term.length >= 3
          $.getJSON '/authors/autocomplete', term: search_term, result_handler
        else
          result_handler []
      # don't update the search textbox when the autocomplete item changes
      focus: -> false
      select: (event, data) ->
        $this = $(@)
        value_and_position = AntCat.ReferencePicker.insert_author($this.val(), $this.getSelection().start, data.item.value)
        $this.val value_and_position.string
        $this.setCaretPos value_and_position.position + 1
        false

  disable_search_author_autocomplete: =>
    @textbox.autocomplete 'destroy'
    @enable_browser_autocomplete true

  enable_browser_autocomplete: (on_or_off) =>
    @element.closest('form').attr 'autocomplete', if on_or_off then '' else 'off'

  @extract_author_search_term: (string, position) =>
    return ""  if string.length is 0
    before_cursor = string.substring 0, position
    prior_semicolon = before_cursor.lastIndexOf ";"
    $.trim before_cursor.substring prior_semicolon + 1, position

  @insert_author: (string, position, author) ->
    if string.length is 0
      return {string: string, position: 0}
    before_cursor = string.substring 0, position
    prior_semicolon = before_cursor.lastIndexOf ";"

    before_prior_semicolon = string.substring 0, prior_semicolon
    before_prior_semicolon += "; "  if before_prior_semicolon.length > 0

    after_cursor = string.substring position, string.length

    string = before_prior_semicolon + author + "; " + $.trim after_cursor

    after_cursor = string.substring position, string.length
    next_semicolon = after_cursor.indexOf ";"
    position = next_semicolon + position + 2

    {string: string, position: position}

  # -----------------------------------------
  update_help: =>
    any_search_results = @search_results().find('.reference').length > 0
    if @current_reference()
      if any_search_results
        other_verb = 'choose'
      else
        other_verb = 'search for'
      help = "Click OK to use"
      help += " this reference, or add or #{other_verb} a different one"
    else
      if any_search_results
        help = "Choose a reference to use"
      else
        help = "Find a reference to use"
      help += ', or add one'
    @set_help_banner help

  set_help_banner: (text) =>
    @element.find('.help_banner_text').text text
