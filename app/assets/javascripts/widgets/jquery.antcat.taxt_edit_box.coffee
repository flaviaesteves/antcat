window.AntCat or= {}

$.fn.taxt_edit_box = (options = {}) ->
  return this.each -> new AntCat.TaxtEditBox $(this), options

class AntCat.TaxtEditBox
  constructor: ($control, options = {}) ->
    @control = $control
    @dashboard = new TaxtEditBox.DebugDashboard @ if options.show_debug_dashboard
    @dashboard?.show_status 'before'
    @value @control.val()
    @last_value @control.val()
    @control.bind 'keyup keydown mouseup dblclick', @handle_event
    @

  handle_event: (event) =>
    if not @is_tag_selected() and @is_new_tag_event event
      @tag_start = @start()
      @tag_end = @end()
      @open_reference_editor()
      return false

    if @is_tag_selected() and @is_tag_opening_event event
      @tag_start = @start()
      @tag_end = @end()
      @open_reference_editor()
      return false

    if event.type is 'keyup' or event.type is 'mouseup'
      @dashboard?.show_event event
      @dashboard?.show_status 'before'
      @handle_change()
      @select_tag_if_caret_inside()
      @dashboard?.show_status 'after'

    true

  handle_change: =>
    old_value = @last_value()
    current_value = @value()
    return if old_value is current_value

    current_position = @start()
    new_value = TaxtEditBox.remove_unbalanced_tags current_value
    @last_value new_value
    @value new_value if new_value isnt current_value
    @set_position current_position

  open_reference_editor: =>
    $form = @control.closest('form')
    $form.find('.buttons').hide()
    @replace_text_area_with_simulation()
    $('.antcat-reference-picker').remove()
    id = if @is_tag_selected() then TaxtEditBox.extract_id_from_editable_taxt @selection() else null
    new AntCat.ReferencePicker $form, id, @handle_reference_picker_result

  replace_text_area_with_simulation: =>
    # We need to indicate the selected reference in the taxt edit box event
    # when the focus has moved to the reference picker, so the user can see
    # what they're editing. So replace the text area (and its selection) with
    # a paragraph that has a highlighted span
    text = @control.val()
    before_selection = text[...@start()]
    selection = if @is_tag_selected() then text[@start()...@end()] else ' {Inserting...} '
    selection = '<span class=antcat-taxt-simulated-selection>' +  selection + '</span>'
    after_selection = text[@end()...]
    text = before_selection + selection + after_selection
    simulation = $("<p class=antcat-taxt-simulation>#{text}</p>")
    simulation.height @control.height()
    simulation.insertAfter @control
    @control.hide()
  replace_simulation_with_text_area: =>
    $('.antcat-taxt-simulation').remove()
    @control.show()
 
  handle_reference_picker_result: (taxt) =>
    @control.closest('form').find('.buttons').show()

    if taxt
      new_value = @value()[...@tag_start] + taxt + @value()[@tag_end...]
      @value new_value

    @replace_simulation_with_text_area()

    if taxt
      @set_selection @tag_start, @tag_start + taxt.length - 1
    else
      @set_selection @tag_start, @tag_end

  # this value is duplicated in lib/taxt.rb
  @EDITABLE_ID_DIGITS = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @extract_id_from_editable_taxt: (taxt) ->
    TaxtEditBox.id_from_editable taxt.match("{((.*?)? )?([#{@EDITABLE_ID_DIGITS}]+)}")[3]

  # this code is duplicated in lib/taxt.rb
  @id_from_editable: (id) ->
    result = 0
    base = @EDITABLE_ID_DIGITS.length
    multiplier = 1
    index = 0
    while true
      digit = id.charAt index
      digit_value = @EDITABLE_ID_DIGITS.indexOf digit
      result += digit_value * multiplier
      multiplier *= base
      index += 1
      return result if index >= id.length

  select_tag_if_caret_inside: =>
    tag_indexes = TaxtEditBox.enclosing_tag_indexes @value(), @start()
    return unless tag_indexes
    @set_selection tag_indexes.left, tag_indexes.right
    true

  selection: =>
    @value()[@start()...@end()]

  is_tag_selected: =>
    @value().charAt(@start())   is '{' and
    @value().charAt(@end() - 1) is '}'

  is_tag_opening_event: (event) =>
    @is_new_tag_event(event) or
    event.type is 'keydown' and event.which is @ENTER or
    event.type is 'dblclick'

  is_new_tag_event: (event) =>
    event.type is 'keydown' and
    event.which is @LEFT_BRACKET and
    event.shiftKey

  value:      => @control.val arguments...
  last_value: => @control.data @data_key, arguments...
  start:      => @control.getSelection().start
  end:        => @control.getSelection().end
  focus:      => @control.focus()

  set_position:  (position)    => @control.setCaretPos position + 1
  set_selection: (left, right) => @control.setSelection left, right + 1

  data_key: 'old_value'
  ENTER: 13
  LEFT_BRACKET: 219

  this.enclosing_tag_indexes = (text, position) ->
    opening_bracket_index = position - 1
    while opening_bracket_index >= 0
      break if text.charAt(opening_bracket_index) is '{'
      break if text.charAt(opening_bracket_index) is '}'
      --opening_bracket_index
    opening_bracket_index = undefined if opening_bracket_index < 0 or text.charAt(opening_bracket_index) is '}'

    closing_bracket_index = position
    while closing_bracket_index < text.length
      break if text.charAt(closing_bracket_index) is '}'
      break if text.charAt(closing_bracket_index) is '{'
      ++closing_bracket_index
    closing_bracket_index = undefined if closing_bracket_index >= text.length or text.charAt(closing_bracket_index) is '{'

    return {left: opening_bracket_index, right: closing_bracket_index} if opening_bracket_index or closing_bracket_index

  this.remove_unbalanced_tags = (text) ->
    start = 0
    i = 0
    in_tag = false
    while i < text.length
      if not in_tag
        if text.charAt(i) is '{'
          in_tag = true
          start = i
          ++i
        else
          if text.charAt(i) is '}'
            text = text[...start] + text[i + 1..]
            i = start = 0
            in_tag = false
          else
            ++i
      else
        if text.charAt(i) is '}'
          in_tag = false
          ++i
          start = i
        else
          if text.charAt(i) is '{'
            text = text[...start] + text[i..]
            i = start = 0
            in_tag = false
          else
            ++i
    text = text[0...start] if in_tag
    text

class AntCat.TaxtEditBox.DebugDashboard
  @dashboard_id: 'antcat-taxteditbox-dashboard'
  constructor: (@taxt_edit_box) ->
    DebugDashboard.add_html()

  @add_html: ->
    return if $("##{@dashboard_id}").size() > 0
    $("
    <style>
      ##{@dashboard_id} {
        margin-bottom: 8px;
        font-family: monospace;
      }
      ##{@dashboard_id} span.small {
        display: inline-block;
        width: 30px;
      }
      ##{@dashboard_id} span.tiny {
        display: inline-block;
        width: 10px;
      }
      ##{@dashboard_id} span.wide {
      }
    </style>
      ").appendTo('head')

    html = "
    <div id='#{@dashboard_id}'>
      <div class='event'>
        <div class='keyup_mouseup'>
          <span class='value small'></span>
          <span class='type small'></span>
        </div>
      </div>
      <div class='status'>"
    for status_when in ['before', 'after']
      html += "
        <div class='#{status_when}'>
          <span class='start_enclosing_tag small'></span>
          <span class='start_selection small'></span>
          <span class='end_selection small'></span>
          <span class='end_enclosing_tag small'></span>
          val:
          [<span class='value'></span>]
          sel:
          [<span class='selection'></span>]
          <span class='is_tag_selected tiny'></span>
        </div>"
    html += "
      </div>
    </div>"
    $(html).prependTo('body')

  show_status: (before_or_after) =>
    $status_panel = $ "##{DebugDashboard.dashboard_id} .status .#{before_or_after}"

    value = @taxt_edit_box.value()
    start_selection = @taxt_edit_box.start()
    end_selection = @taxt_edit_box.end()
    enclosing_tag = AntCat.TaxtEditBox.enclosing_tag_indexes value, start_selection

    $('.value', $status_panel).text value

    text = "{#{enclosing_tag.left}" if enclosing_tag?.left
    $('.start_enclosing_tag', $status_panel).text text ? ''

    text = "#{enclosing_tag.right}}" if enclosing_tag?.right
    $('.end_enclosing_tag', $status_panel).text text ? ''

    $('.start_selection', $status_panel).text start_selection
    $('.end_selection', $status_panel).text end_selection
    $('.selection', $status_panel).text @taxt_edit_box.value()[start_selection...end_selection]
    $('.is_tag_selected', $status_panel).text if @taxt_edit_box.is_tag_selected() then 'T' else 'F'

  show_event: (event) =>
    $event_panel = $ "##{DebugDashboard.dashboard_id} .event .keyup_mouseup"
    $('.type', $event_panel).text event.type
    $('.value', $event_panel).text event.which
