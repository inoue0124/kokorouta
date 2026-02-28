import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("アカウント") {
                NavigationLink(value: SettingsRoute.blockList) {
                    Label("ブロックリスト", systemImage: "person.slash")
                }

                NavigationLink(value: SettingsRoute.accountDelete) {
                    Label("アカウントを削除", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }
            .listRowBackground(Color.appCardBackground)

            Section("情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
                        .foregroundStyle(Color.appSubText)
                }
            }
            .listRowBackground(Color.appCardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
