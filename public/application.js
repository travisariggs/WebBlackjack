$(document).ready(function() {

  //$('#hit_form input').click(function() {

  // Hit Button - AJAX
  //$(document).on('click', '#hit_form input', function() {
  $(document).on('click', '#hit_button', function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/hit'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

  // Stay Button - AJAX
  $(document).on('click', '#stay_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/stay'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

  // See Dealer Card Button - AJAX
  $(document).on('click', '#dealer_hit_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/game/dealer/hit'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });


});