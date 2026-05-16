/**
 * Frontend enhancements for Severino Labs.
 */

document.addEventListener('DOMContentLoaded', function () {
    var header = document.querySelector('.site-sticky-header');

    if (header) {
        function toggleShadow() {
            if (window.scrollY > 0) {
                header.classList.add('scrolled');
            } else {
                header.classList.remove('scrolled');
            }
        }

        toggleShadow();
        window.addEventListener('scroll', toggleShadow);
    }

    document.querySelectorAll('.featured-projects .wp-block-post').forEach(function (card) {
        var link = card.querySelector('a');

        if (!link) {
            return;
        }

        card.addEventListener('click', function () {
            window.location = link.href;
        });
    });
});