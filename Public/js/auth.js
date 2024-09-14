'use strict';

const registerFormID = 'register';
const loginFormID = 'login';
// Form id for type in new passwords, used in checkPasswordsMatch() function.
const setNewPasswordFormID = 'changePW';
// Modal id for request new password, used in FrontendAuthController to allow js script to open the modal programmatically, also in handleChangePW() to remove modal's data-bs-backdrop attribute so users can close the modal when a new password has been updated successfully.
const setNewPasswordModalID = 'newPasswordModal';
// Used to pop loginModal programatically.
const loginModalID = 'loginModal';

function handleLogin(form, result) {
    const response = result.response;
    if (response.ok) {
        const params = new URLSearchParams(window.location.search);
        const next = params.get("next") ?? '/';
        window.location.replace(next);
    } else {
        appendAlert(form, result.data.reason, 'danger');
    }
}

function handleRegister(form, result) {
    const response = result.response;
    
    if (response.ok) {
        appendAlert(
                    form,
                    "An email with account activation link has been sent to you. Follow directions there.",
                    "success"
                    );
    } else {
        const json = result.data;
        appendAlert(form, json.reason, 'danger');
    }
}

// Display a button in the given parent node, which request a new activation email for the given address when clicked. Upon success/failed response, it displays the corresponding response in the same parent node.
async function requestActivation(email, parentElement) {
    let params = new URLSearchParams();
    params.append('email', email);
    const button = document.querySelector('#resendActivation');
    button.addSpinner();
    const headers = new Headers();
    headers.set('Content-Type', 'application/x-www-form-urlencoded');
    const options = {'headers': headers, 'method': 'post', 'body': params};
    const result = await makeRequest('/api/auth/resend-activate', options);
    try {
        const response = result.response;
        if (response.ok) {
            appendAlert(parentElement, `Activation link sent, make sure to use it within 5 minutes`, 'success');
        } else {
            appendAlert(parentElement, `Unable to send email, please try again later`, 'danger');
        }
    } catch (error) {
        appendAlert(parentElement, 'Service unavailable, please try again later', 'warning');
        console.log(error)
    } finally {
        // Enable the submit button and delete the spinner
        button.disabled = false;
        button.querySelector('.spinner-border').remove();
    }
}

// Display an alert in the given parent node, with the given message. It appends a button at the end of the message automatically, which upon click will request a new activation link from server.
function alertNotActivated(email, parentElement, message) {
    const button = document.createElement('button');
    button.id = 'resendActivation';
    button.type = 'button';
    button.classList.add('btn', 'btn-warning');
    button.innerText = 'Resend Activation Email';
    
    appendAlert(parentElement, message + button.outerHTML, 'danger');
    const btn = document.querySelector('#resendActivation');
    btn.onclick = () => requestActivation(email, parentElement);
}

// Request a reset email
function handleRequestPWChange(form, result) {
    const response = result.response;
    
    if (response.ok) {
        appendAlert(
                    form,
                    'Success. Pleas check your mailbox and follow instructions there.',
                    'success'
                    )
    } else {
        const json = result.data;
        appendAlert(
                    form,
                    json.reason,
                    'danger'
                    );
    }
}

// Update new password
function handleChangePW(form, result) {
    const response = result.response;
    
    if (response.ok) {
        appendAlert(
                    form,
                    'New password set, click anywhere outside this pop up window and login again',
                    'success'
                    );
        
        const currentModal = document.querySelector("#" + setNewPasswordModalID);
        // Remove attributes that forbidden users to dismiss the modal
        currentModal.removeAttribute('data-bs-backdrop');
        currentModal.removeAttribute('data-bs-keyboard');
        // Add attribute that enables this behavior
        currentModal.setAttribute('data-bs-dismiss', "modal");
        // Add a button to close the modal so users can click on it.
        const close = document.createElement('button');
        close.type = 'button';
        close.classList.add('btn-close');
        close.setAttribute('data-bs-dismiss', 'modal');
        close.setAttribute('aria-label', 'Close');
        const modalHeader = currentModal.querySelectorAll('.modal-header')[0];
        modalHeader.appendChild(close);
        // When modal is dismissed, replace address to home otherwise reset endpoint will be left over.
        currentModal.addEventListener('hidden.bs.modal', event => {
            window.location.replace('/');
        })
    } else {
        const json = result.data;
        appendAlert(
                    form,
                    json.reason,
                    'danger'
                    );
    }
}

// Validate if password2 is exact match with password1 in registration form and reset password form.
function checkPasswordsMatch(formID) {
    const form = document.getElementById(formID);
    if (form == null) { return }
    const password1 = form.querySelector('#password1');
    const password2 = form.querySelector('#password2');
    const submitButton = form.querySelector(['button[type="submit"]']);
    
    function check() {
        const value1 = password1.value;
        const value2 = password2.value;
        
        if (value1 !== value2) {
            password2.setCustomValidity('Passwords do not match');
            // Call reportValidity() otherwise setCustomValidity has no effect.
            password2.reportValidity();
            // Manually adjust appearances. Call checkValidity() has no effect.
            password2.classList.remove('is-valid');
            password2.classList.add('is-invalid');
            submitButton.disabled = true;
        } else {
            // Pass in empty string means valid.
            password2.setCustomValidity('');
            password2.checkValidity();
        }
    }
    password1.addEventListener('change', check);
    password2.addEventListener('input', check);
}

(() => {
    checkPasswordsMatch(registerFormID);
    checkPasswordsMatch(setNewPasswordFormID);
    checkPasswordsMatch('register-webmaster');
})();
