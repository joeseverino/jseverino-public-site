/**
 * Secure Contact Intake frontend behavior.
 */

(function () {
    'use strict';

    document.addEventListener('DOMContentLoaded', function () {
        var forms = document.querySelectorAll('.sl-contact-intake__form');

        forms.forEach(function (form) {
            form.addEventListener('submit', function () {
                var submitButton = form.querySelector('.sl-contact-intake__submit');

                if (!submitButton) {
                    return;
                }

                submitButton.disabled = true;
                submitButton.textContent = 'Sending...';
                submitButton.classList.add('sl-contact-intake__submit--disabled');
            });
        });
    });
})();