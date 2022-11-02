var lastScrollY = window.scrollY;

function onScroll() {
  var newScrollY = window.scrollY;
  var header = document.getElementById("sticky-header");
  var delta = 2 * header.offsetHeight;
  if (newScrollY <= header.offsetHeight || newScrollY + delta < lastScrollY) {
    header.style.top = '0';
    lastScrollY = newScrollY;
  } else if (newScrollY - delta > lastScrollY) {
    header.style.top = '-' + String(header.offsetHeight) + 'px';
    lastScrollY = newScrollY;
  }
}

window.addEventListener('scroll', onScroll);

function onTagSearchChange(event) {
  var tagButtons = document.querySelectorAll('[id^="btag-"');
  var tagText = String(event.target.value).replace(/[^a-zA-Z0-9-]+/, '');
  event.target.value = tagText

  for (var i = 0; i < tagButtons.length; i++) {
    var tb = tagButtons[i];
    tb.style.display = tb.id.substr(5).includes(tagText) ? "initial" : "none";
    console.log(tb.id.substr(5), tb.style.visibility);
  }
}

function onLoad() {
  var tagSearch = document.getElementById("searchinput-tags");
  if (tagSearch) {
    tagSearch.addEventListener('input', onTagSearchChange);
  }
}

window.addEventListener('load', onLoad);
