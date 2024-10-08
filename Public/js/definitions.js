'use strict';

const alertID = 'alertDiv';

// Customized async function to make a request, will return response, data(json) and error.
async function makeRequest(endPoint, options = null) {
    let result = {response: null, data: null, error: null};
    try {
        const response = await fetch(endPoint, options);
        result.response = response;
        try {
            result.data = await response.json();
        } catch (jsonError) {
            result.error = new Error("Failed to parse JSON response: " + jsonError.message);
        }
    } catch (error) {
        // Server received request, but thrown or responded an error. Caller needs to handle connection error themselves, when server is un-reachable.
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

// Multiple alertID may exist at the same time due to all modal's code are loaded. Only remove the one from the given parent element otherwise it may remove the wrong one.
function closeAlertIn(parent) {
    if (parent.querySelector('#' + alertID)) {
        parent.querySelector('#' + alertID).remove();
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
    
    wrapper.innerHTML = `<div class="alert alert-${type} alert-dismissible d-flex align-items-center justify-content-center" role="alert">
        <svg class="bi me-2 svg-container"><use href="#${icon}"></use></svg>
        ${message}
        <button type="button" class="btn-close" onclick="closeAlertIn(this.parentElement.parentElement.parentElement)" aria-label="Close"></button>
        </div>`;

    parent.insertBefore(wrapper, parent.firstChild);
}

// Create a static modal(can't be closed by clicking outside the modal or by pressing ESC) and show it in current page.
function createModal(title, body, closeAction = null) {
    const modalHTML = `
        <div class="modal fade" id="staticModal" data-bs-backdrop="static" data-bs-keyboard="false" tabindex="-1" aria-labelledby="exampleModalLabel" aria-hidden="true">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title" id="exampleModalLabel">${title}</h5>
              </div>
              <div class="modal-body">
                ${body}
              </div>
              <div class="modal-footer">
                <button type="button" "class="btn btn-primary" data-bs-dismiss="modal" onclick="${closeAction}">Dismiss</button>
              </div>
            </div>
          </div>
        </div>
      `;
    
    document.body.insertAdjacentHTML('beforeend', modalHTML);
    const node = document.getElementById('staticModal');
    // Bootstrap's modal instance has the show() method to display the modal.
    const staticModal = new bootstrap.Modal(node);
    staticModal.show();
    // When modal is dismissed, remove the node from DOM
    node.addEventListener('hidden.bs.modal', function () {
        node.remove();
    });
}

// Validate form fields when each input changes, toggle appearences and submit buttons on/off status accordingly.
function addFormValidation() {
    const forms = document.querySelectorAll('form.needs-validation');
    
    forms.forEach(function(form) {
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

function submitForm() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(form => {
        form.addEventListener('submit', async function(e) {
            e.preventDefault(); // Prevent the default form submission
            
            // Get the submit button and add a spinner in it
            const button = form.querySelector('button[type="submit"]');
            button.addSpinner();
            
            const headers = new Headers();
            headers.set('Content-Type', form.enctype);
            const options = {'method': form.method, 'headers': headers, 'body': new URLSearchParams(new FormData(form))};
            
            let result = null;
            try {
                const result = await makeRequest(form.action, options);
                
                const callbackName = form.getAttribute('data-callback');
                if (typeof window[callbackName] === 'function') {
                    window[callbackName](form, result);
                } else {
                    return result;
                }
            } catch (error) {
                // Server is un-reachable.
                appendAlert(form, 'Service unavailable, please try again later', 'warning');
            } finally {
                // Enable the submit button and delete the spinner
                button.disabled = false;
                button.querySelector('.spinner-border').remove();
            }
        });
    });
}

function popLoginModal(expired = false) {
    const element = document.querySelector('#' + loginModalID);
    const loginModal = new bootstrap.Modal(element);
    if (expired == true) {
        const form = element.querySelector("#" + loginFormID);
        appendAlert(form, 'Login session exipred, please login again', 'warning')
    }
    loginModal.show();
}

function handleRegisterWebmaster(form, result) {
    const response = result.response;
    if (response.ok) {
        window.location.replace('/install/import');
    } else {
        const json = result.data;
        appendAlert(form, json.reason, 'danger');
    }
}
