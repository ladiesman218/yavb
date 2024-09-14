'use strict';

function handleUpdatePost(form, result) {
    const response = result.response;
    
    if (response.ok) {
        window.location.reload();
        appendAlert(
                    form,
                    'Saved',
                    'success'
                    );
    } else {
        const json = result.data;
        appendAlert(
                    form,
                    json.reason,
                    'danger'
                    );
    }
}

function selectStatus(statusSelects) {
    const prefix = 'selection-';
    statusSelects.forEach(selection => {
        const currentStatus = selection.classList[0].slice(prefix.length);
        selection.value = currentStatus;
    });
}
