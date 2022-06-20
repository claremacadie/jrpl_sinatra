$(function() {
  $("form.reset_pword").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    var ok = confirm("Are you sure you want to reset the password? This cannot be undone!");
    if (ok) {
      this.submit();
    }
  });
});

$(function() {
  $("form.signout").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    var ok = confirm("Are you sure you want to sign out?");
    if (ok) {
      this.submit();
    }
  });
});

$(function() {
  $("form.toggle_admin").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    var ok = confirm("Are you sure you want to change admin permissions?");
    if (ok) {
      this.submit();
    }
  });
});

$("form.filter_form").ready(function() {
  $('#select-all').click(function() {
      var checked = this.checked;
      $('input[type="checkbox"]').each(function() {
      this.checked = checked;
  });
  })
});
