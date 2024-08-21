'use strict';

function handleImport(form, result) {
    const response = result.response;
    
    if (response.ok) {
        window.location.replace('/install/finished');
    } else {
        const json = result.data;
        appendAlert(form, json.reason, 'danger');
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const button = document.querySelector('#import');
    button.disabled = false;
});
