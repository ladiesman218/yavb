'use strict';

// Customized async function to make a request, will return response, data(json) and error.
async function makeRequest(endPoint, method, encodeType, body) {
    let result = {response: null, data: null, error: null};
    try {
        const response = await fetch(endPoint, {
        method: method,
        headers: { 'Content-Type': encodeType },
        body: body,
        withCredentials: true
        });
        result.response = response;
        // TODO: Test what if no json body is returned, will this throw an error??
        result.data = await response.json();
    } catch (error) {
        result.error = error;
    } finally {
        return result;
    }
}

// extend HTMLButtonElement prototype
HTMLButtonElement.prototype.addSpinner = function() {
    const spinner = document.createElement('span');
    
    spinner.className = 'spinner-border spinner-border-sm';
    spinner.setAttribute('role', 'status');
    spinner.setAttribute('aria-hidden', 'true');
    
    this.insertBefore(spinner, this.firstChild);
    this.disabled = true;
};

// Forms can opt in by calling handleSubmit() method to prevent default submit behavior(dismiss the modal if the form is within one). This also adds a spinner into the submit button after request is submitted for processing, and removes it when it's done.
HTMLFormElement.prototype.handleSubmit = function() {
    this.addEventListener('submit', async function(event) {
        event.preventDefault(); // Prevent the default form submission to close the modal
        
        // Get the submit button and add a spinner in it
        const button = this.querySelector('button[type="submit"]');
        button.addSpinner();
        
        let result = null;
        try {
            result = await makeRequest(this.action, 'POST', button.formEnctype, new URLSearchParams(new FormData(this)));
        } catch (error) {
            console.log(error);
        } finally {
            // Enable the submit button and delete the spinner
            button.disabled = false;
            button.querySelector('.spinner-border').remove();
            // callback method to handle result. Consider the handle method a job dispatcher.
            handle(this, result);
        }
    });
};

// Dispatch response to functions base on form's id
function handle(form, result) {
    switch(form.id) {
        case loginFormID:
            handleLogin(result);
            break;
        case registerFormID:
            handleRegister(result);
            break;
        case requestNewPWFormID:
            handleRequestPWChange(result);
            break;
        case setNewPasswordFormID:
            handleChangePW(result);
            break;
        default:
            break;
    }
}

// Create an alert div and insert it as the first child in the given parent node.
const appendAlert = (parent, message, type) => {
    closeAlertIn(parent);

    // Allowed values for `type` parameter are: info, success, warning, danger
    let icon = null;
    switch (type) {
        case 'info':
            icon = 'info-circle-fill';
            break;
        case 'success':
            icon = 'check-circle-fill';
            break;
        case 'warning':
        case 'danger':
            icon = 'exclamation-triangle-fill';
            break;
        default:
            return
    }
    const wrapper = document.createElement('div');
    wrapper.id = alertID;
    
    wrapper.innerHTML = [
        `<div class="alert alert-${type} alert-dismissible d-flex align-items-center justify-content-center" role="alert">`,
        `<svg class="bi me-2 svg-container"><use href="#${icon}"></use></svg>`,
        `${message}`,
        `<button type="button" class="btn-close" onclick="closeAlertIn(this.parentElement.parentElement.parentElement)" aria-label="Close"></button>`,
        '</div>'
    ].join('');

    parent.insertBefore(wrapper, parent.firstChild);
}

// Multiple alertID may exist at the same time due to all modal's code are loaded. Only remove the one from the given parent element otherwise it may remove the wrong one.
function closeAlertIn(parent) {
    if (parent.querySelector('#' + alertID)) {
        parent.querySelector('#' + alertID).remove();
    }
}

// Validate form fields when each input changes, toggle appearences and submit buttons on/off status accordingly.
function addFormValidation() {
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
}

// Convert unix time to local date, eliminate time part(HH:MM:SS)
function unixToLocal() {
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
}

function popLoginModal(expired = false) {
    const element = document.querySelector('#loginModal');
    const loginModal = new bootstrap.Modal(element);
    if (expired == true) {
        const form = element.querySelector("#" + loginFormID);
        appendAlert(form, 'Login session exipred, please login again', 'warning')
    }
    loginModal.show();
}
