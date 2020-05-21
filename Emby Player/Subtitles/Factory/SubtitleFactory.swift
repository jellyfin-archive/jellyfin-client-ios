/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
//
//  SubtitleFactory.swift
//  Emby Player
//
//  Created by Mats Mollestad on 09/09/2018.
//  Copyright © 2018 Mats Mollestad. All rights reserved.
//

import UIKit

typealias Subtitles = [Subtitle]

struct Subtitle {
    let startTime: TimeInterval
    let endTime: TimeInterval
    var duration: TimeInterval { return endTime - startTime }
    let subtitle: NSAttributedString
}

class SubtitleFactory {

    enum Errors: Error {
        case invalidTimeFormat
        case invalidVTTFormat
    }

    var font: UIFont = UIFont.systemFont(ofSize: 24)
    var textColor: UIColor = .yellow

    func decodeVTTFormate(_ file: String) throws -> Subtitles {

        var subtitles: Subtitles = []

        let numricCharSet = CharacterSet.decimalDigits

        let lines = file.components(separatedBy: "\n\n")
        for line in lines {

            if let char = line.unicodeScalars.first,
                numricCharSet.contains(char) {

                var subLines = line.components(separatedBy: "\n")

                let timeLine = subLines.removeFirst()
                let times = timeLine.components(separatedBy: " --> ")

                let startTime = try decodeTimeStringToSeconds(times[0])
                let endTime = try decodeTimeStringToSeconds(times[1])

                let textSubtitle = subLines.reduce("") { $0 + $1 }
                let attributedSubtitle = styleSubtitle(textSubtitle)
                let subtitle = Subtitle(startTime: startTime, endTime: endTime, subtitle: attributedSubtitle)
                subtitles.append(subtitle)
            }
        }

        return fillEmptyTime(in: subtitles)
    }

    private func fillEmptyTime(in subtitles: Subtitles) -> Subtitles {
        guard subtitles.count != 0 else { return subtitles }

        var fillSubtitles: Subtitles = []
        var startTime: TimeInterval = 0
        var endTime: TimeInterval = 0

        for subtitle in subtitles {
            endTime = subtitle.startTime
            let emptySubtitle = Subtitle(startTime: startTime, endTime: endTime, subtitle: NSAttributedString())
            fillSubtitles.append(emptySubtitle)
            fillSubtitles.append(subtitle)
            startTime = subtitle.endTime
        }
        return fillSubtitles
    }

    private func styleSubtitle(_ subtitle: String) -> NSAttributedString {
        let htmlString =
            subtitle
                + "<style>*{font-family: '\(font.fontName)'; "
                + "font-size:\(font.pointSize)px; "
                + "text-align: center; color: \(textColor.hexCode());}</style>"
        do {
            guard let subtitleData = htmlString.data(using: .utf8) else { throw Errors.invalidVTTFormat }
            return try NSAttributedString(data: subtitleData,
                                          options: [.documentType: NSAttributedString.DocumentType.html],
                                          documentAttributes: nil)
        } catch {
            return NSAttributedString(string: subtitle)
        }
    }

    private func decodeTimeStringToSeconds(_ time: String) throws -> TimeInterval {
        let components = time.components(separatedBy: ":")
        guard let hours = TimeInterval(components[0]),
            let minuts = TimeInterval(components[1]),
            let seconds = TimeInterval(components[2]) else { throw Errors.invalidTimeFormat }
        return hours * 3600 + minuts * 60 + seconds
    }
}
