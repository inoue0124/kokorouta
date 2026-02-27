import SwiftUI

extension Font {
    /// 短歌表示用: 明朝体
    static func tankaFont(size: CGFloat) -> Font {
        .custom("HiraMinProN-W3", size: size)
    }

    /// 見出し用: システムフォント（軽め）
    static func appTitle(size: CGFloat = 20) -> Font {
        .system(size: size, weight: .light)
    }

    /// 本文用: システムフォント
    static func appBody(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular)
    }

    /// キャプション用
    static func appCaption(size: CGFloat = 12) -> Font {
        .system(size: size, weight: .light)
    }
}
