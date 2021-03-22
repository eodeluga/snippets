// Loads js dependencies in a way compatible with all
// modern (and most old) browsers
[
    './dep-01.js',
    './dep-02.js',
    './dep-03.js'
].forEach(function (src) {
    var script = document.createElement('script');
    script.src = src;
    script.async = false;
    document.body.appendChild(script);
});

// Wait on event for all loaded then execute main
document.body.onload = _main;

function _main() {
    // Do stuff here
}
