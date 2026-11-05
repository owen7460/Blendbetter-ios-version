//
//  MarkdownTheme+BlendBetter.swift
//  BlendBetter
//

import SwiftUI
import MarkdownUI

extension MarkdownUI.Theme {
    /// Recipe styling: rounded font, green headings, roomier lists.
    static let blendBetter = MarkdownUI.Theme.basic
        .text {
            FontFamily(.system(.rounded))
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.45))
                    ForegroundColor(.brandGreenDeep)
                }
                .markdownMargin(top: .em(0.4), bottom: .em(0.6))
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.2))
                    ForegroundColor(.brandGreenDeep)
                }
                .markdownMargin(top: .em(1.2), bottom: .em(0.5))
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.05))
                }
                .markdownMargin(top: .em(1.0), bottom: .em(0.4))
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.3))
        }
}
