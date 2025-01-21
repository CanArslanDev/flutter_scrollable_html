function initializeEventListeners() {
    // Keyboard events
    document.addEventListener('keydown', handleKeyboardEvent);
    document.addEventListener('keyup', handleKeyboardEvent);

    // Mouse events
    document.addEventListener('mousedown', handleMouseEvent);
    document.addEventListener('mouseup', handleMouseEvent);
    document.addEventListener('mousemove', handleMouseEvent);
    document.addEventListener('click', handleMouseEvent);

    // Selection events
    document.addEventListener('selectionchange', handleSelectionChange);

    // Initialize button handlers
    const buttons = document.querySelectorAll('.button');
    buttons.forEach(button => {
        button.addEventListener('click', handleButtonClick);
    });


    const textArea = document.getElementById('textArea');
    if (textArea) {
        enableTextSelection(textArea);

        textArea.addEventListener('mousedown', function (e) {
            e.stopPropagation();
        });

        textArea.addEventListener('mousemove', function (e) {
            e.stopPropagation();
        });

        textArea.addEventListener('select', function (e) {
            const eventData = {
                type: 'selectionEvent',
                text: this.value.substring(this.selectionStart, this.selectionEnd),
                selectionStart: this.selectionStart,
                selectionEnd: this.selectionEnd
            };
            sendToFlutter(eventData);
        });
    }

    console.log('Event listeners initialized');
}
// Selection için yeni bir fonksiyon ekleyelim
function enableTextSelection(element) {
    element.style.webkitUserSelect = 'text';
    element.style.mozUserSelect = 'text';
    element.style.msUserSelect = 'text';
    element.style.userSelect = 'text';
}


function handleMouseEvent(event) {
    const targetInfo = {
        id: event.target.id || '',
        tagName: event.target.tagName.toLowerCase(),
        className: event.target.className || ''
    };

    const eventData = {
        type: 'mouseEvent',
        eventType: event.type,
        x: event.clientX,
        y: event.clientY,
        button: event.button,
        buttons: event.buttons,
        target: targetInfo
    };

    sendToFlutter(eventData);
}

function handleKeyboardEvent(event) {
    const eventData = {
        type: 'keyboardEvent',
        eventType: event.type,
        key: event.key,
        code: event.code,
        keyCode: event.keyCode,
        ctrlKey: event.ctrlKey,
        altKey: event.altKey,
        shiftKey: event.shiftKey,
        metaKey: event.metaKey
    };

    sendToFlutter(eventData);
}

function handleSelectionChange() {
    const selection = window.getSelection();
    if (selection) {
        const eventData = {
            type: 'selectionEvent',
            text: selection.toString(),
            rangeCount: selection.rangeCount
        };
        sendToFlutter(eventData);
    }
}

function handleButtonClick(event) {
    const button = event.currentTarget;
    button.classList.toggle('active');

    const eventData = {
        type: 'buttonEvent',
        eventType: 'toggle',
        isActive: button.classList.contains('active')
    };

    sendToFlutter(eventData);
}

function sendToFlutter(data) {
    if (window.parent) {
        window.parent.postMessage(JSON.stringify(data), '*');
    }
}

// Handle messages from Flutter
window.addEventListener('message', function (event) {
    if (typeof event.data === 'string') {
        try {
            eval(event.data);
        } catch (e) {
            console.error('Script execution error:', e);
        }
    }
});

// Initialize when page loads
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeEventListeners);
} else {
    initializeEventListeners();
}