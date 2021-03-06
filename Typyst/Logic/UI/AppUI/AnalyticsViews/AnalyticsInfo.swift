//
// Created by Sean Wolford on 3/19/20.
// Copyright (c) 2020 wickedPropeller. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

class AnalyticsInfoView {
    let viewModel = AnalyticsInfoViewModel()
    let view = NSStackView(frame: CGRect(x: 0, y: 0, width: 500, height: 350))

    init() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .left
        view.distribution = .fill
        view.spacing = 8
        setupView()
    }

    func setupView() {

        // Create rows of text
        for item in viewModel.analyticsItems {
            let analyticsLabel = NSTextField(string: formatTextForRowWith(seconds: item.amountOfTime,
                    totalKP: item.totalKeyPresses, averageKP: item.averageKeyPresses))
            analyticsLabel.font = NSMenu().font
            analyticsLabel.isBezeled = false
            analyticsLabel.isBordered = false
            analyticsLabel.isEditable = false
            analyticsLabel.isSelectable = false
            analyticsLabel.backgroundColor = .clear
            analyticsLabel.textColor = .white
            view.addArrangedSubview(analyticsLabel)
        }

        // Update text when the view model updates a row
        viewModel.analyticsItemsUpdated = { [weak self] (index) in
            guard let self = self else { return }

            if let analyticsItem = self.viewModel.analyticsItems[safe: index] {
                DispatchQueue.main.async(execute: {
                    if let textView = self.view.arrangedSubviews[safe: index] as? NSTextField {
                        textView.stringValue = self.formatTextForRowWith(seconds: analyticsItem.amountOfTime,
                            totalKP: analyticsItem.totalKeyPresses, averageKP: analyticsItem.averageKeyPresses)
                    }
                })
            }
        }
    }

    func formatTextForRowWith(seconds: Double, totalKP: Int, averageKP: Double) -> String {
        let time = TimeHelper.daysHoursMinutesSecondsFromTotalSeconds(seconds)

        var secondsString: String = ""
        if time.seconds == 1 { secondsString = "\(time.seconds) second" }
        else if time.seconds > 1 { secondsString = "\(time.seconds) seconds" }

        var minutesString: String = ""
        if time.minutes == 1 { minutesString = "\(time.minutes) minute" }
        else if time.minutes > 1 { minutesString = "\(time.minutes) minutes" }
        if (!minutesString.isEmpty && !secondsString.isEmpty) { minutesString += ": " }

        var hoursString: String =  ""
        if time.hours == 1 { hoursString = "\(time.hours) hour" } 
        else if time.hours > 1 { hoursString = "\(time.hours) hours" }
        if (!hoursString.isEmpty && !minutesString.isEmpty) { hoursString += ": " }

        var daysString: String = ""
        if time.days == 1 { daysString = "\(time.days) day" } 
        else if time.days > 1 { daysString = "\(time.days) days" }
        if (!daysString.isEmpty && !hoursString.isEmpty) { daysString += ": " }

        return
                """
                Past \(daysString)\(hoursString)\(minutesString)\(secondsString)
                    \(totalKP) total key presses
                    \(averageKP) average key presses every second
                """
    }
}

class AnalyticsInfoViewModel {
    var analyticsItems = [AnalyticsInfo]()
    var analyticsItemsUpdated: ((Int) -> Void)? = nil

    let timer = RepeatingTimer(timeInterval: 0.5)

    init() {
        updateItems()
        setup()
    }

    deinit {
        timer.suspend()
    }

    func setup() {
        timer.eventHandler = { [weak self] in
            guard let self = self else { return }
            self.updateItems()
        }

        timer.resume()
    }

    func updateItems() {
        analyticsItems.removeAll()

        let seconds = KeyAnalytics.shared.currentAnalyticsIntervals
        for (index, timeAmount) in seconds.enumerated() {
            pushAnalyticsItemForTime(seconds: timeAmount)
            analyticsItemsUpdated?(index)
        }
    }

    func pushAnalyticsItemForTime(seconds: Double) {
        let analyticsItem = AnalyticsInfo(amountOfTime: seconds,
                totalKeyPresses: KeyAnalytics.shared.totalKeypressesInPastSeconds(seconds),
                averageKeyPresses: KeyAnalytics.shared.averageKeypressesEveryXSecondsForPastSeconds(seconds))
        analyticsItems.append(analyticsItem)
    }
}

struct AnalyticsInfo {
    let amountOfTime: Double
    let totalKeyPresses: Int
    let averageKeyPresses: Double
}
