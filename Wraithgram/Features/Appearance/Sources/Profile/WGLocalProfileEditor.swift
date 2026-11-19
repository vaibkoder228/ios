import UIKit

/// Native, device-only editor for the local profile presentation draft.
/// It deliberately edits a preview model and never calls Telegram account APIs.
public enum WGLocalProfileEditor {
    public static func makeController() -> UIAlertController {
        let draft = WGLocalProfileDraftStore.shared.load()
        let alert = UIAlertController(
            title: "Локальный профиль",
            message: "Изменения видны только в этой установке приложения. Профиль Telegram не меняется.",
            preferredStyle: .alert
        )

        let fields: [(String, String)] = [
            ("Имя для предпросмотра", draft.displayName),
            ("Username для предпросмотра", draft.username),
            ("Декоративный номер", draft.decorativePhoneNumber),
            ("О себе для предпросмотра", draft.bio),
            ("Эмодзи оформления", draft.accentEmoji)
        ]

        for (placeholder, value) in fields {
            alert.addTextField { field in
                field.placeholder = placeholder
                field.text = value
                field.clearButtonMode = .whileEditing
                field.autocapitalizationType = .none
            }
        }

        alert.addAction(UIAlertAction(title: "Сбросить", style: .destructive) { _ in
            WGLocalProfileDraftStore.shared.reset()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { _ in
            let values = alert.textFields ?? []
            let updated = WGLocalProfileDraft(
                displayName: values[safe: 0]?.text ?? "",
                username: values[safe: 1]?.text ?? "",
                decorativePhoneNumber: values[safe: 2]?.text ?? "",
                bio: values[safe: 3]?.text ?? "",
                accentEmoji: values[safe: 4]?.text ?? ""
            )
            WGLocalProfileDraftStore.shared.save(updated)
        })
        return alert
    }

    public static func present(from presenter: UIViewController) {
        presenter.present(makeController(), animated: true)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
