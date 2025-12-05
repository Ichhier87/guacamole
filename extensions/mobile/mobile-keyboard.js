/**
 * Guacamole Mobile Keyboard Enhancement
 * Adds floating keyboard button and improves mobile keyboard handling
 */

(function() {
    'use strict';

    // Wait for Guacamole to fully load
    function initMobileKeyboard() {
        // Check if we're on a mobile device
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
        const isTouch = 'ontouchstart' in window || navigator.maxTouchPoints > 0;

        if (!isMobile && !isTouch) {
            console.log('[Mobile Keyboard] Desktop detected, skipping mobile enhancements');
            return;
        }

        console.log('[Mobile Keyboard] Initializing mobile keyboard enhancements');

        // Create floating keyboard toggle button
        createFloatingKeyboardButton();

        // Enhance existing keyboard functionality
        enhanceKeyboardBehavior();

        // Add touch improvements
        improveTouchHandling();

        // Auto-show keyboard on input fields
        setupAutoKeyboard();
    }

    function createFloatingKeyboardButton() {
        // Check if button already exists
        if (document.getElementById('mobile-keyboard-toggle')) {
            return;
        }

        const button = document.createElement('button');
        button.id = 'mobile-keyboard-toggle';
        button.innerHTML = '⌨️';
        button.title = 'Toggle On-Screen Keyboard';
        button.setAttribute('aria-label', 'Toggle Virtual Keyboard');

        button.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            toggleOnScreenKeyboard();
        });

        // Add button to DOM
        document.body.appendChild(button);
        console.log('[Mobile Keyboard] Floating keyboard button created');
    }

    function toggleOnScreenKeyboard() {
        console.log('[Mobile Keyboard] Toggle keyboard requested');

        // Try multiple methods to find and toggle the keyboard

        // Method 1: Look for Guacamole's keyboard element
        const keyboard = document.querySelector('.guac-keyboard');
        if (keyboard) {
            if (keyboard.style.display === 'none' || !keyboard.style.display) {
                keyboard.style.display = 'block';
                console.log('[Mobile Keyboard] Keyboard shown via .guac-keyboard');
                return;
            } else {
                keyboard.style.display = 'none';
                console.log('[Mobile Keyboard] Keyboard hidden via .guac-keyboard');
                return;
            }
        }

        // Method 2: Look for keyboard toggle button in Guacamole menu
        const keyboardButtons = document.querySelectorAll('button');
        for (let btn of keyboardButtons) {
            const title = (btn.title || '').toLowerCase();
            const text = (btn.textContent || '').toLowerCase();
            if (title.includes('keyboard') || title.includes('tastatur') ||
                text.includes('keyboard') || text.includes('tastatur')) {
                btn.click();
                console.log('[Mobile Keyboard] Keyboard toggled via menu button');
                return;
            }
        }

        // Method 3: Try to open Guacamole menu first
        const menuButtons = document.querySelectorAll('.menu-control, .guac-menu-control, button[title*="Menu"]');
        if (menuButtons.length > 0) {
            menuButtons[0].click();
            console.log('[Mobile Keyboard] Menu opened, please click keyboard button');

            // Try to find keyboard button after menu opens
            setTimeout(() => {
                const keyboardButtons = document.querySelectorAll('button');
                for (let btn of keyboardButtons) {
                    const title = (btn.title || '').toLowerCase();
                    if (title.includes('keyboard') || title.includes('tastatur')) {
                        btn.click();
                        console.log('[Mobile Keyboard] Keyboard toggled after menu open');
                        return;
                    }
                }
            }, 200);
            return;
        }

        // Method 4: Trigger native mobile keyboard
        triggerNativeKeyboard();
    }

    function triggerNativeKeyboard() {
        // Create a temporary input field to trigger native keyboard
        const input = document.createElement('input');
        input.type = 'text';
        input.style.position = 'fixed';
        input.style.top = '-100px';
        input.style.opacity = '0';
        input.id = 'mobile-keyboard-input';

        document.body.appendChild(input);
        input.focus();

        // Forward keyboard input to Guacamole
        input.addEventListener('input', function(e) {
            const text = e.target.value;
            if (text) {
                // Send text to Guacamole client
                const event = new KeyboardEvent('keypress', {
                    key: text[text.length - 1],
                    bubbles: true
                });
                document.dispatchEvent(event);
            }
        });

        console.log('[Mobile Keyboard] Native keyboard triggered with hidden input');
    }

    function enhanceKeyboardBehavior() {
        // Make keyboard draggable on mobile (if keyboard exists)
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                mutation.addedNodes.forEach(function(node) {
                    if (node.classList && (node.classList.contains('guac-keyboard') ||
                        node.classList.contains('keyboard'))) {
                        makeKeyboardDraggable(node);
                        console.log('[Mobile Keyboard] Enhanced keyboard behavior');
                    }
                });
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    function makeKeyboardDraggable(keyboard) {
        let isDragging = false;
        let startY = 0;
        let startHeight = 0;

        const handle = document.createElement('div');
        handle.style.cssText = `
            width: 100%;
            height: 30px;
            background: rgba(255,255,255,0.1);
            cursor: grab;
            display: flex;
            align-items: center;
            justify-content: center;
            border-bottom: 1px solid rgba(255,255,255,0.2);
        `;
        handle.innerHTML = '<span style="color: white;">⋯</span>';

        keyboard.insertBefore(handle, keyboard.firstChild);

        handle.addEventListener('touchstart', function(e) {
            isDragging = true;
            startY = e.touches[0].clientY;
            startHeight = keyboard.offsetHeight;
            handle.style.cursor = 'grabbing';
        });

        document.addEventListener('touchmove', function(e) {
            if (!isDragging) return;
            const deltaY = startY - e.touches[0].clientY;
            const newHeight = Math.max(200, Math.min(window.innerHeight * 0.6, startHeight + deltaY));
            keyboard.style.maxHeight = newHeight + 'px';
        });

        document.addEventListener('touchend', function() {
            if (isDragging) {
                isDragging = false;
                handle.style.cursor = 'grab';
            }
        });
    }

    function improveTouchHandling() {
        // Prevent zoom on double-tap in display area
        document.addEventListener('touchstart', function(e) {
            if (e.touches.length > 1) {
                // Allow pinch zoom
                return;
            }

            const target = e.target;
            if (target.closest('.display') || target.closest('.guac-display')) {
                // Prevent default zoom behavior
                if (e.timeStamp - lastTap < 300) {
                    e.preventDefault();
                }
                lastTap = e.timeStamp;
            }
        }, { passive: false });

        let lastTap = 0;

        console.log('[Mobile Keyboard] Touch handling improved');
    }

    function setupAutoKeyboard() {
        // Show keyboard when clicking on remote desktop
        let clickTimeout;

        document.addEventListener('click', function(e) {
            const display = e.target.closest('.display, .guac-display');
            if (display) {
                // Double-click to show keyboard
                clearTimeout(clickTimeout);
                clickTimeout = setTimeout(function() {
                    // Single click - do nothing
                }, 300);
            }
        });

        document.addEventListener('dblclick', function(e) {
            const display = e.target.closest('.display, .guac-display');
            if (display) {
                clearTimeout(clickTimeout);
                console.log('[Mobile Keyboard] Double-click detected, showing keyboard');
                toggleOnScreenKeyboard();
            }
        });
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initMobileKeyboard);
    } else {
        initMobileKeyboard();
    }

    // Re-initialize if Guacamole reloads
    window.addEventListener('load', function() {
        setTimeout(initMobileKeyboard, 1000);
    });

    console.log('[Mobile Keyboard] Script loaded');
})();
