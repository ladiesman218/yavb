'use strict';

const alertID = 'alertDiv';
const registerFormID = 'register';
const loginFormID = 'login';
// Modal id for request new password, used in FrontendAuthController to allow js script to open the modal programmatically.
const setNewPasswordModalID = 'newPasswordModal';
// Form id for request new password, used to handle response.
const requestNewPWFormID = 'PWchange';
// Form id for type in new passwords
const setNewPasswordFormID = 'changePW';

function handleLogin(result) {
    const response = result.response;
    if (response.ok) {
        location.reload(true);
    } else {
        const loginForm = document.getElementById(loginFormID);
        appendAlert(loginForm, result.data.reason, 'danger');
    }
}

function handleRegister(result) {
    const response = result.response;
    const registerForm = document.getElementById(registerFormID);
    
    if (response.ok) {
        appendAlert(
                    registerForm,
                    "An email with account activation link has been sent to you. Follow directions there.",
                    "success"
                    );
    } else {
        const json = result.data;
        appendAlert(registerForm, json.reason, 'danger');
    }
}

// Request a reset email
function handleRequestPWChange(result) {
    const response = result.response;
    const form = document.getElementById(requestNewPWFormID);
    
    if (response.ok) {
        appendAlert(
                    form,
                    'Email Sent. Visit the link in your email to set a new password',
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
function handleChangePW(result) {
    const response = result.response;
    const form = document.getElementById(setNewPasswordFormID);
    
    if (response.ok) {
        appendAlert(
                    form,
                    'New password set, login again',
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

// Validate if password2 is exact match with password1 in registration form and reset password form.
function checkPasswordsMatch(formID) {
    const form = document.getElementById(formID);
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
})();