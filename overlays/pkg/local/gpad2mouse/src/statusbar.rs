use std::cell::Cell;
use std::rc::Rc;

use objc2::rc::Retained;
use objc2::sel;
use objc2_app_kit::{
    NSImage, NSMenu, NSMenuItem, NSStatusBar, NSStatusItem, NSVariableStatusItemLength,
};
use objc2_foundation::{MainThreadMarker, NSString};

use crate::gamepad::GamepadManager;

pub struct StatusBar {
    _status_item: Retained<NSStatusItem>,
    enabled: Cell<bool>,
}

impl StatusBar {
    pub fn new(mtm: MainThreadMarker, _gamepad: &Rc<GamepadManager>) -> Self {
        let status_bar = NSStatusBar::systemStatusBar();
        let status_item = status_bar.statusItemWithLength(NSVariableStatusItemLength);

        if let Some(button) = status_item.button(mtm) {
            let image = NSImage::imageWithSystemSymbolName_accessibilityDescription(
                &NSString::from_str("gamecontroller.fill"),
                Some(&NSString::from_str("gpad2mouse")),
            );
            if let Some(image) = image {
                button.setImage(Some(&image));
            }
        }

        let menu = NSMenu::new(mtm);

        let controller_item = NSMenuItem::new(mtm);
        controller_item.setTitle(&NSString::from_str("No controller"));
        controller_item.setEnabled(false);
        menu.addItem(&controller_item);
        menu.addItem(&NSMenuItem::separatorItem(mtm));

        let enabled_item = unsafe { NSMenuItem::initWithTitle_action_keyEquivalent(
            mtm.alloc(),
            &NSString::from_str("Enabled"),
            None,
            &NSString::from_str(""),
        ) };
        menu.addItem(&enabled_item);

        let settings_item = unsafe { NSMenuItem::initWithTitle_action_keyEquivalent(
            mtm.alloc(),
            &NSString::from_str("Settings..."),
            None,
            &NSString::from_str(","),
        ) };
        menu.addItem(&settings_item);

        menu.addItem(&NSMenuItem::separatorItem(mtm));

        let quit_item = unsafe { NSMenuItem::initWithTitle_action_keyEquivalent(
            mtm.alloc(),
            &NSString::from_str("Quit"),
            Some(sel!(terminate:)),
            &NSString::from_str("q"),
        ) };
        menu.addItem(&quit_item);

        status_item.setMenu(Some(&menu));

        Self {
            _status_item: status_item,
            enabled: Cell::new(true),
        }
    }

    pub fn is_enabled(&self) -> bool {
        self.enabled.get()
    }
}
