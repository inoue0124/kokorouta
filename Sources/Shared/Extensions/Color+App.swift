import SwiftUI
import UIKit

extension Color {
    /// 背景色: ライト=温かみのある白 / ダーク=深い墨色
    static let appBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
    })

    /// メインテキスト: ライト=墨色 / ダーク=明るい和紙色
    static let appText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.90, blue: 0.88, alpha: 1)
            : UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
    })

    /// サブテキスト: ライト=薄い墨色 / ダーク=やや明るいグレー
    static let appSubText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.60, blue: 0.58, alpha: 1)
            : UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    })

    /// カード背景: ライト=白 / ダーク=少し明るい墨色
    static let appCardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    })

    /// 区切り線: ライト=極薄 / ダーク=暗めの区切り
    static let appDivider = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.24, blue: 0.23, alpha: 1)
            : UIColor(red: 0.9, green: 0.88, blue: 0.86, alpha: 1)
    })
}
