$ ->
  form = new AntCat.NestedForm $('.antcat_form'), button_container: '> table td.buttons'
  new AntCat.NameField $('#test_name_field'),
    value_id: 'test_name_field_value'
    parent_form: form
    field: true
    on_success: (data) ->
      $('#results').text data.id + ' ' + data.taxt
    on_cancel: ->
      id = $('.antcat_name_field #id').val()
      $('#results').text 'Cancelled: ' + id

  new AntCat.NameField $('#test_allow_blank_name_field'),
    value_id: 'test_allow_blank_name_field_value'
    parent_form: form
    field: true
    allow_blank: true

  new AntCat.NameField $('#test_new_or_homonym_name_field'),
    value_id: 'test_new_or_homonym_name_field_value'
    parent_form: form
    field: true
    new_or_homonym: true

  new AntCat.NameField $('#test_default_name_string_name_field'),
    value_id: 'test_default_name_string_name_field_value'
    parent_form: form
    field: true
