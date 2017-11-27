import 'bootstrap';

$('img[data]').each((i, e) => {
  $(e).attr('src', $(e).attr('data'));
});

$('#twitter').click(evt => {
  window.open('https://twitter.com/intent/follow?ref_src=twsrc%5Etfw&screen_name=bubble_0_&tw_p=followbutton', '_blank', 'width=500,height=550');
  evt.preventDefault();
});
