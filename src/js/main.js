import 'bootstrap';

$('img[data]').each((i, e) => {
  $(e).attr('src', $(e).attr('data'));
});