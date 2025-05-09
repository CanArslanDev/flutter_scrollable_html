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
  try {
    if (typeof event.data !== 'string') return;

    const data = JSON.parse(event.data);

    if (data.command === 'mouseEvent') {
      const element = document.elementFromPoint(data.clientX, data.clientY);
      if (element) {
        // Create and send the mouse event
        const eventInit = {
          bubbles: true,
          cancelable: true,
          view: window,
          detail: 1,
          screenX: data.screenX,
          screenY: data.screenY,
          clientX: data.clientX,
          clientY: data.clientY,
          ctrlKey: data.ctrlKey,
          altKey: data.altKey,
          shiftKey: data.shiftKey,
          metaKey: data.metaKey,
          button: data.button,
          buttons: data.buttons,
          relatedTarget: null
        };

        const mouseEvent = new MouseEvent(data.eventType, eventInit);
        element.dispatchEvent(mouseEvent);

        // Text selection logic
        if (data.eventType === 'mousedown') {
          // For initial selection
          if (window.getSelection && document.caretPositionFromPoint) {
            const selection = window.getSelection();
            const range = document.caretRangeFromPoint(data.clientX, data.clientY);
            if (range) {
              selection.removeAllRanges();
              selection.addRange(range);
            }
          }
        } else if (data.eventType === 'mousemove' && data.isPointerDown) {
          // Update selection while dragging
          if (window.getSelection) {
            const selection = window.getSelection();
            if (selection.rangeCount > 0) {
              // Expand current selection
              const newPosition = document.caretRangeFromPoint(data.clientX, data.clientY);
              if (newPosition) {
                try {
                  // Extend selection to new position
                  selection.extend(newPosition.startContainer, newPosition.startOffset);

                  // Make the selected text visible
                  const range = selection.getRangeAt(0);
                  range.startContainer.parentElement?.scrollIntoView({ block: 'nearest' });
                } catch (e) {
                  console.error('Selection error:', e);
                }
              }
            }
          }
        } else if (data.eventType === 'mouseup') {
          // When the mouse is released
          const clickEvent = new MouseEvent('click', eventInit);
          element.dispatchEvent(clickEvent);

          // Focus for special elements
          if (element.tagName === 'TEXTAREA' ||
              element.tagName === 'INPUT' ||
              element.hasAttribute('contenteditable') ||
              element.tagName === 'DIV' && element.id === 'ascii') {
            element.focus();
          }

          // Preserve if selection exists
          const selection = window.getSelection();
          if (selection && selection.toString().length > 0) {
            // If there is a selection, preserve the selection
            document.designMode = 'off';
          }
        }

        // Stop the event to avoid blocking the selection change
        if ((data.eventType === 'mousemove' && data.isPointerDown) ||
            data.eventType === 'mousedown' ||
            data.eventType === 'mouseup') {
          event.stopPropagation();
        }
      }
    } else if (data.command === 'keyboardEvent') {
      const keyboardEvent = new KeyboardEvent(
        data.eventType, {
        key: data.key,
        code: data.code,
        location: 0,
        ctrlKey: data.ctrlKey,
        altKey: data.altKey,
        shiftKey: data.shiftKey,
        metaKey: data.metaKey,
        repeat: false,
        isComposing: false,
        charCode: 0,
        keyCode: data.keyCode,
        which: data.which,
      });

      const activeElement = document.activeElement || document.body;
      activeElement.dispatchEvent(keyboardEvent);

      if (keyboardEvent.type === 'keydown' && activeElement.tagName === 'TEXTAREA') {
        const inputEvent = new InputEvent('input', {
          bubbles: true,
          cancelable: true,
          data: data.character
        });
        activeElement.dispatchEvent(inputEvent);
      }
    }
  } catch (e) {
    console.error('Message handling error:', e);
  }
});

// Initialize when page loads
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeEventListeners);
} else {
    initializeEventListeners();
}