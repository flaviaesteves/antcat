$(function() {
  setupHelp();
  setupAuthorAutocomplete();
  setupCloseLinks();
  $("input[type=text]:last").focus();
})

function setupCloseLinks() {
  $('.author_panel .close_link').click(function(){
    $(this).closest('form').submit();
    return false;
  });
}

function setupHelp() {
  setupQtip('.help_icon', "Type some letters in the author's name, then choose the name from the list.")
}

function setupAuthorAutocomplete() {
  if (AntCat.testing)
    return;

  $('.author_panel input[type=text]').autocomplete({
    autoFocus: true,
    minLength: 3,
    source: "/merge_authors/all"
  });
}