//
//  Typewriter.swift
//  Typist
//
//  Created by Sean Wolford on 1/14/19.
//  Copyright © 2019 wickedPropeller. All rights reserved.
//

import AppKit
import Foundation
import Files
import HotKey
import SwiftySound

class Typewriter {

    // Typewriter variables / constants
    var model: TypewriterModel?
    var marginWidth = 80
    
    var numberOfNewLines = 0
    var lineIndex = 0

    // Soundsets
    let keySets        = [
        "BackspaceUp", "BackspaceDown",
        "Bell",
        "DoubleLineReturn",
        "KeyUp", "KeyDown",
        "Letters",
        "LidDown", "LidUp",
        "MarginRelease",
        "Numbers",
        "PaperFeed", "PaperLoad", "PaperRelease", "PaperReturn",
        "RibbonSelector",
        "ShiftUp", "ShiftDown", "ShiftLock", "ShiftRelease",
        "SingleLineReturn",
        "SpaceDown", "SpaceUp",
        "Symbols",
        "TabDown", "TabUp",
        "TripleLineReturn"
    ]
    var soundSets      = [String: [Sound]]()
    var keyListenerSet = [Any?]()
    var shiftIsPressed = false
    var capsOn         = false

    init(model: TypewriterModel, marginWidth: Int = 80) {
        self.model = model
        self.marginWidth = marginWidth
        loadSounds()
        createKeyEventListeners()

        if soundSets["LidUp"]?.count ?? 0 > 0 {
            soundSets["LidUp"]?.randomElement()?.play()
        }
    }

    func getSoundset(location: String) -> [Sound] {
        var sounds = [Sound]()
        Bundle.main.urls(forResourcesWithExtension: ".aif", subdirectory: location)?.forEach({
            if let keySound = Sound(url: $0.absoluteURL) {
                keySound.prepare()
                sounds.append(keySound)
            }
        })
        return sounds
    }
    
    func loadSounds() {
        // Load KeyUp sounds
        let model = self.model?.rawValue ?? ""
        let modelLocation = "Soundsets/\(model)/"

        for keySet in keySets {
            soundSets[keySet] = getSoundset(location: modelLocation + keySet)
        }
    }

    func assignKeyPresses(event: NSEvent) {

        // Make sure the event is some kind of key press
        if let keyPressed = Key(carbonKeyCode: UInt32(event.keyCode)) {
            
            // If the current key press is less than the margin width - increment the count
            if lineIndex < marginWidth {
                lineIndex += 1
            }
            else {
                lineIndex = 0
                if UserDefaults.standard.bool(forKey: "simulateNewLine") {
                    let lineReturn = ((self.soundSets["SingleLineReturn"] ?? []) +
                                     (self.soundSets["DoubleLineReturn"] ?? []) +
                                     (self.soundSets["TripleLineReturn"] ?? [])).randomElement()
                    let bell = self.soundSets["Bell"]?.randomElement()
            
                    lineReturn?.play()
                    Timer.scheduledTimer(withTimeInterval: lineReturn?.duration ?? 0, repeats: false, block: {_ in
                        bell?.play()
                    })
                }
            }


            // These should be ordered by likelihood they were the key pressed. The fewer the searches, the faster the
            // sound plays ;)

            if shiftSet.contains(keyPressed) {
                shiftIsPressed == false ?
                    self.soundSets["ShiftDown"]?.randomElement ()?.play () :
                    self.soundSets["ShiftUp"]?.randomElement ()?.play ()

                // Flag key directions aren't tracked - we need to do that.
                shiftIsPressed = !shiftIsPressed
            }
            else if keyPressed == Key.space {
                event.type == NSEvent.EventType.keyUp ?
                    self.soundSets["SpaceUp"]?.randomElement()?.play() :
                    self.soundSets["SpaceDown"]?.randomElement()?.play()
            }
            else if keyPressed == Key.return || keyPressed == Key.keypadEnter {
                let returnSet = (self.soundSets["SingleLineReturn"] ?? []) +
                                (self.soundSets["DoubleLineReturn"] ?? []) +
                                (self.soundSets["TripleLineReturn"] ?? [])

                returnSet.randomElement()?.play()

                if numberOfNewLines == 25 {
                    numberOfNewLines = 0
                    if UserDefaults.standard.bool(forKey: "paperFeedEnabled") {
                        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
                            if let sound = self.soundSets["PaperLoad"]?.randomElement() {
                                sound.play()
                                Timer.scheduledTimer(withTimeInterval: sound.duration, repeats: false, block: {_ in
                                    self.soundSets["PaperFeed"]?.randomElement()?.play()
                                })
                            }
                        })
                    }
                }

                else {
                    // Only count the key press once - not on both up and down
                    if event.type == NSEvent.EventType.keyDown {
                        numberOfNewLines += 1
                    }
                }
            }
            else if keyPressed == Key.delete || keyPressed == Key.forwardDelete {
                event.type == NSEvent.EventType.keyUp ?
                    self.soundSets["BackspaceUp"]?.randomElement()?.play() :
                    self.soundSets["BackspaceDown"]?.randomElement()?.play()
            }
            else if keyPressed == Key.escape && soundSets["PaperRelease"]?.count != 0 && soundSets["PaperReturn"]?.count != 0 {
                event.type == NSEvent.EventType.keyUp ?
                    self.soundSets["PaperRelease"]?.randomElement()?.play() :
                    self.soundSets["PaperReturn"]?.randomElement()?.play()
            }
            else if keyPressed == Key.capsLock {
                capsOn ? self.soundSets["ShiftLock"]?.randomElement()?.play() :
                    self.soundSets["ShiftRelease"]?.randomElement()?.play()
                capsOn = !capsOn
            }
            else if keyPressed == Key.tab && soundSets["TabUp"]?.count != 0 && soundSets["TabDown"]?.count != 0 {
                event.type == NSEvent.EventType.keyUp ?
                    self.soundSets["TabUp"]?.randomElement()?.play() :
                    self.soundSets["TabDown"]?.randomElement()?.play()
            }
            else if bellSet.contains(keyPressed) {
                self.soundSets["Bell"]?.randomElement()?.play()
            }
            else if keyPressed == Key.keypadClear {
                self.soundSets["RibbonSelector"]?.randomElement()?.play()
            }
            else if event.type == NSEvent.EventType.systemDefined {
                // Stop any margin sounds that are already playing
                self.soundSets["MarginRelease"]?.forEach({ $0.stop() })
                self.soundSets["MarginRelease"]?.randomElement ()?.play ()
            }
            else {
                event.type == NSEvent.EventType.keyUp ?
                    self.soundSets["KeyUp"]?.randomElement ()?.play () :
                    self.soundSets["KeyDown"]?.randomElement ()?.play ()
            }
        }
    }
    
    func createKeyEventListeners() {

        let eventTypes: [NSEvent.EventTypeMask] = [.keyUp, .keyDown, .flagsChanged, .systemDefined]

        for eventType in eventTypes {

            // Listen for key presses in Typist
//            keyListenerSet.append(
//                NSEvent.addLocalMonitorForEvents(matching: eventType) { (aEvent) -> NSEvent in
//                    self.assignKeyPresses(event: aEvent)
//                    return aEvent
//                })

            // Listen for key presses in other apps
            keyListenerSet.append(
                NSEvent.addGlobalMonitorForEvents(matching: eventType) { (aEvent) in
                    self.assignKeyPresses(event: aEvent)
                })
        }
    }

    func prepareToRemove() {
        if soundSets["LidDown"]?.count ?? 0 > 0 {
            soundSets["LidDown"]?.randomElement()?.play()
        }

        keyListenerSet.removeAll()
        for keySet in keySets {
            soundSets[keySet] = nil
        }
        soundSets.removeAll()
    }
}
