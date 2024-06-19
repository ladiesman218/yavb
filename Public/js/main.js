'use strict';


// Validate form fields when each input changes, toggle appearences and submit buttons on/off status accordingly.
(() => {
    const forms = document.querySelectorAll('form.needs-validation');
    
    forms.forEach(function(form) {
        form.handleSubmit();
        
        // Disable button to gray it out and prevent being clicked.
        const button = form.querySelector('button[type="submit"]');
        button.disabled = true;
        
        // Get all input field in the form
        const inputs = form.querySelectorAll('input');
        // When input value changes, check validity and adjust appearances
        inputs.forEach(function (input) {
            input.addEventListener('input', function () {
                if (input.checkValidity()) {
                    input.classList.remove('is-invalid');
                    input.classList.add('is-valid');
                } else {
                    input.classList.remove('is-valid');
                    input.classList.add('is-invalid');
                }
                // Check if all input fields in a form are validated.
                const allValid = Array.prototype.slice.call(inputs).every(function (input) {
                    return input.checkValidity();
                });
                
                // If yes, mark form is validated and enable submit button.
                if (allValid) {
                    form.classList.add('was-validated');
                    button.disabled = false
                } else {
                    form.classList.remove('was-validated');
                    button.disabled = true;
                }
            });
        });
    });
})();

// Convert unix time to local date, eliminate time part(HH:MM:SS)
(() => {
    const timeElements = document.querySelectorAll(".unixTime");
    timeElements.forEach(node => {
        // Swift returns unix time with float point number(in milli-seconds), convert it to seconds by * 1000, but remove white spaces first.
        const unixSeconds = node.textContent.trim() * 1000;
        // Still may contain float point number(decimal part longer than 3 digits), convert it to int.
        const int = Math.floor(unixSeconds);
        const unixTime = new Date(int);
        const localDateString = unixTime.toLocaleDateString();
        node.textContent = localDateString;
    });
})();

// Get Login status
(() => {
    getLoginStatus();
})();

function getLoginStatus() {
    if (getSessionCookie('yavb-session') === null) {
        // Not logged in
        console.log('not logged in');
        document.querySelector('#authButtons').style.display = 'block';
        document.querySelector('#manageLink').style.display = 'none';
    } else {
        // Logged in
        console.log('logged in');
        document.querySelector('#manageLink').style.display = 'block';
        document.querySelector('#authButtons').style.display = 'none';
    }
}

function getSessionCookie(cookieName) {
    const cookies = document.cookie.split(';');
    for (let i = 0; i < cookies.length; i++) {
        let cookie = cookies[i].trim();
        // Check if cookie starts with cookieName and a '=' sign
        if (cookie.startsWith(cookieName + '=')) {
            // return cookie's value
            return cookie.substring(cookieName.length + 1);
        }
    }
    return null;
}

// There is no direct approach to delete a cookie, set the cookie's expiration time to past time will make browser to delete it.
function deleteCookie(name) {
    document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
}
