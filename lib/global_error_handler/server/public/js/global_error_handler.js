$(document).ready(function() {
  $('.js-link').unbind('click');
  $('.js-link').bind('click', function(event) {
    event.preventDefault();
    event.stopPropagation();
    var h = document.createElement('input');
    h.type = 'hidden';
    h.name = '_method';
    h.value = this.getAttribute('data-method');
    var f = document.createElement('form');
    f.appendChild(h);
    f.style.display = 'none';

    if(this.getAttribute('data-get-ids')){
      checkboxes = $('.select-exception:checked').clone();
      if(checkboxes.length == 0) {
        alert('Select at least one exception to delete please.');
        return false;
      }
      $(f).append(checkboxes);
    }

    this.parentNode.appendChild(f);
    f.method = 'POST';
    f.action = this.getAttribute('href');
    if(confirm(this.getAttribute('data-confirm'))) {
      f.submit();
    } else {
      f.parentNode.removeChild(f);
    }
    return false;
  });

  $('.select-all-exceptions').click(function() {
    $('.select-exception').attr('checked', $(this).attr('checked'));
  });

  $('.filter-by').change(function() {
    selected = $(this).val();
    field = $(this).attr('data-field');
    if(selected == '')
      window.location = '/resque/exceptions'
    else
      window.location = '/resque/exceptions/filter/' + field + '/' + encodeURIComponent(encodeURIComponent(selected));
  });
})
