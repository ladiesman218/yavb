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
