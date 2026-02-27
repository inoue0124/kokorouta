import SwiftUI

struct ReportSheet: View {
    let tanka: Tanka
    let onSubmit: (ReportReason) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var isSubmitting = false
    @State private var error: AppError?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("通報する理由を選んでください")
                    .font(.appBody())
                    .foregroundStyle(Color.appText)

                VStack(spacing: 12) {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Image(
                                    systemName: selectedReason == reason
                                        ? "circle.inset.filled" : "circle"
                                )
                                .foregroundStyle(Color.appText)

                                Text(reason.displayName)
                                    .font(.appBody())
                                    .foregroundStyle(Color.appText)

                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let error {
                    Text(error.localizedDescription)
                        .font(.appCaption())
                        .foregroundStyle(Color.red)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .font(.appBody())
                    .foregroundStyle(Color.appSubText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )

                    Button {
                        guard let reason = selectedReason else { return }
                        error = nil
                        isSubmitting = true
                        Task {
                            do {
                                try await onSubmit(reason)
                                dismiss()
                            } catch {
                                self.error = AppError(error)
                            }
                            isSubmitting = false
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .tint(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            Text("送信")
                                .font(.appBody())
                                .foregroundStyle(
                                    selectedReason != nil ? Color.white : Color.appSubText
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .background(
                        selectedReason != nil ? Color.appText : Color.appDivider,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .disabled(selectedReason == nil || isSubmitting)
                }
            }
            .padding(24)
            .background(Color.appBackground)
            .navigationTitle("通報")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
