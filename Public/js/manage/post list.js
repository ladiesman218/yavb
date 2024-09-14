'use strict';

let tags = [];

// Set status filters' values, set activate/add values according to URL parameters when page loads.
document.addEventListener('DOMContentLoaded', function () {
    const parameters = new URLSearchParams(window.location.search);
    
    configStatusTabs(parameters);
    
    const authorInput = document.querySelector('#author_name');
    const tagsContainer = document.querySelector('#tags-container');
    const tagInput = document.querySelector('#tag-input');
    
    // Set up author and tags filter values based on URL parameters
    setInitialFilterValues(parameters, authorInput, tagsContainer);
    
    setFiltersEventListeners(parameters, authorInput, tagInput, tagsContainer);
    
    configListStatuses();
    configPagination(parameters);
    configSort(parameters);
});

function configStatusTabs(parameters) {
    // Set status tabs activation based on URL parameters
    const status = parameters.get('status');
    const statusTabs = document.querySelectorAll('.status-tab');
    statusTabs.forEach(tab => {
        const isActive = (tab.id === status) || (status === null && tab.id === 'all');
        tab.classList.toggle('active', isActive);
        tab.setAttribute('aria-selected', isActive);
    });
    
    // Status tab event listeners
    statusTabs.forEach(button => {
        const tab = new bootstrap.Tab(button);
        
        button.addEventListener('click', async event => {
            event.preventDefault();
            tab.show();
            parameters.set('status', button.id);
            parameters.set('page', 1);
            redirectURL(parameters);
        });
    });
}

function configListStatuses() {
    const statusSelects = document.querySelectorAll('.status-selection > select');
    // For posts list, select each post's status according to each element's class name
    statusSelects.forEach(select => {
        const stat = select.classList[0].replace('selection-', '');
        select.value = stat;
    });
    
    // Select change listeners for post status updates
    statusSelects.forEach(selection => {
        selection.addEventListener('change', async function(event) {
            const postId = selection.id.replace('status-options-', '');
            const url = `/api/blog/update/${postId}`;
            const headers = new Headers();
            headers.set('Content-Type', 'application/x-www-form-urlencoded');
            const options = { method: 'POST', headers, body: new URLSearchParams({ status: selection.value }) };
            const result = await makeRequest(url, options);
            handleChangeStatus(result);
        });
    });
}

// Handle initial values for author and tags filter
function setInitialFilterValues(parameters, authorInput, tagsContainer) {
    // Set author name filter from URL
    const currentAuthorName = parameters.get('author');
    if (currentAuthorName) authorInput.value = currentAuthorName;
    
    // Set tags from URL
    const currentTags = parameters.getAll('tag');
    currentTags.forEach(tag => addTag(tagsContainer, null, tag));
}

function setFiltersEventListeners(parameters, authorInput, tagInput, tagsContainer) {
    // Press enter in authorInput to trigger applying filter
    authorInput.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') {
            filterByAuthor(authorInput, parameters);
            parameters.set('page', 1);
            redirectURL(parameters);
        }
    });
    
    // Tag input event listeners for space/comma to add tag and backspace to remove, and enter to trigger applying filter
    tagInput.addEventListener('keydown', function (event) {
        if (event.key === ' ' || event.key === ',') {
            event.preventDefault();
            addTag(tagsContainer, tagInput);
        } else if (event.key === 'Backspace' && tagInput.value === '' && tags.length !== 0) {
            tagsContainer.lastChild.remove();
            tags.pop();
        } else if (event.key === 'Enter') {
            filterByTags(tagsContainer, tagInput, parameters);
            parameters.set('page', 1);
            redirectURL(parameters);
        }
    });
    
    // Apply filters button event listener
    const filterBtn = document.querySelector('#filter-button');
    filterBtn.addEventListener('click', function() {
        filterByAuthor(authorInput, parameters);
        filterByTags(tagsContainer, tagInput, parameters);
        parameters.set('page', 1);
        redirectURL(parameters);
    });
}

function configPagination(parameters) {
    const total = parseInt(document.querySelector('#item-count').innerText);
    const per = parseInt(parameters.get('per') ?? 20);
    if (total <= per) { return };
    
    const currentPage = parseInt(parameters.get('page') ?? 1);
    const totalPages = Math.ceil(total/per);
    
    const currentPageItem = document.querySelector('#current-page');
    const firstBtn = document.querySelector('#first-page');
    const previousBtn = document.querySelector('#previous-page');
    const lastBtn = document.querySelector('#last-page');
    const nextBtn = document.querySelector('#next-page');
    
    currentPageItem.innerText = `${currentPage} of ${totalPages}`;
    
    if (currentPage === 1) {
        firstBtn.classList.add('disabled');
        previousBtn.classList.add('disabled');
    }
    if (totalPages === currentPage) {
        lastBtn.classList.add('disabled');
        nextBtn.classList.add('disabled');
    }
    
    firstBtn.addEventListener('click', function(event) {
        parameters.set('page', 1);
        redirectURL(parameters);
    });
    
    previousBtn.addEventListener('click', function(event) {
        parameters.set('page', currentPage - 1);
        redirectURL(parameters);
    });
    
    lastBtn.addEventListener('click', function(event) {
        parameters.set('page', totalPages);
        redirectURL(parameters);
    });
    
    nextBtn.addEventListener('click', function(event) {
        parameters.set('page', currentPage + 1);
        redirectURL(parameters);
    });
}

function configSort(parameters) {
    const orderBy = parameters.get('ordered_by') ?? 'updated_at';
    const order = parameters.get('order') ?? 'desc';
    const targetIcon = (order == 'asc') ? '#bi-caret-up-fill' : '#bi-caret-down-fill';
    
    const titleTH = document.querySelector('#title-table-head');
    const titleSortIcon = titleTH.querySelector('use');
    const updatedTH = document.querySelector('#updated-table-head');
    const updatedSortIcon = updatedTH.querySelector('use');
    const commentsCountTH = document.querySelector('#comment-table-head');
    const commentsCountSortIcon = commentsCountTH.querySelector('use');
    
    if (orderBy === 'updated_at') {
        updatedSortIcon.setAttribute('href', targetIcon);
    } else if (orderBy === 'title') {
        titleSortIcon.setAttribute('href', targetIcon);
    } else {
        commentsCountSortIcon.setAttribute('href', targetIcon);
    }
    
    titleTH.addEventListener('click', () => {
        if (orderBy === 'title') {
            const switchedOrder = (order === 'desc') ? 'asc' : 'desc';
            parameters.set('order', switchedOrder)
        } else {
            parameters.set('ordered_by', 'title');
            parameters.set('order', 'desc');
        }
        redirectURL(parameters);
    });
    
    updatedTH.addEventListener('click', () => {
        if (orderBy === 'updated_at') {
            const switchedOrder = (order === 'desc') ? 'asc' : 'desc';
            parameters.set('order', switchedOrder)
        } else {
            parameters.set('ordered_by', 'updated_at');
            parameters.set('order', 'desc');
        }
        redirectURL(parameters);
    });
    commentsCountTH.addEventListener('click', () => {
        if (orderBy === 'comment_count') {
            const switchedOrder = (order === 'desc') ? 'asc' : 'desc';
            parameters.set('order', switchedOrder)
        } else {
            parameters.set('ordered_by', 'comment_count');
            parameters.set('order', 'desc');
        }
        redirectURL(parameters);
    });
}

// Add a tag to the tag container
function addTag(tagsContainer, tagInput, predefinedTag = null) {
    const tagText = predefinedTag || tagInput.value.trim();
    if (tagText && !tags.includes(tagText)) {
        const tag = document.createElement('span');
        tag.classList.add('ms-1', 'bg-secondary', 'rounded-1', 'py-0', 'px-2', 'd-flex', 'align-items-center');
        tag.setAttribute('role', 'button');
        tag.innerHTML = `${tagText}<i class="remove-tag">&nbsp;&nbsp;&times;</i>`;
        
        tagsContainer.appendChild(tag);
        tags.push(tagText);
        
        // Add event listenter for remove icon
        tag.querySelector('.remove-tag').addEventListener('click', function () {
            tag.remove();
            tags = tags.filter(t => t !== tagText);
        });
    }
    if (tagInput) tagInput.value = '';
}

// Handle status change for posts
function handleChangeStatus(result) {
    const response = result.response;
    if (response.ok) {
        window.location.reload();
    } else {
        const json = result.data;
        createModal('Unable to change status', json.reason, 'window.location.reload();');
    }
}

// Modify value for 'author' parameter
function filterByAuthor(authorInput, parameters) {
    const value = authorInput.value.trim();
    if (value === '') {
        parameters.delete('author');
    } else {
        parameters.set('author', value);
    }
}

// Modify value for 'tag' parameter
function filterByTags(tagsContainer, tagInput, parameters) {
    // Delete previously set tags first
    parameters.delete('tag');
    
    addTag(tagsContainer, tagInput);
    // Add a 'tag' parameter for each of the added value, multiple parameters named 'tag' could exist at the same time.
    if (tagsContainer.childNodes.length !== 0) {
        tagsContainer.childNodes.forEach(element => {
            const tagValue = element.innerText.split('\n')[0];
            parameters.append('tag', tagValue);
        });
    }
}

function redirectURL(parameters) {
    const url = (parameters.size === 0) ? '/manage' : '/manage/?' + parameters;
    window.location.replace(url);
}
