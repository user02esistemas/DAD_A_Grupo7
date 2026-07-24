document.querySelectorAll('.sidebar .nav-link, .navbar-side .nav-link').forEach(function(l) {
    var h = l.getAttribute('href');
    if (h && window.location.pathname.indexOf(h) !== -1) l.classList.add('active');
    if (l.closest('.navbar-side')) l.addEventListener('click', function() {
        var c = document.getElementById('menuColapsable');
        if (c && c.classList.contains('show')) { var bs = bootstrap.Collapse.getOrCreateInstance(c); bs.hide(); }
    });
});
