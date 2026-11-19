import Foundation
import UIKit
import WGCore
import WGHooks
import WGSettingsUI

/// Local-only profile mockup. These values never update the Telegram account or server.
enum WGLocalProfilePreview {
    private static let nameKey = "wg.localProfilePreview.name"
    private static let noteKey = "wg.localProfilePreview.note"
    private static let numberKey = "wg.localProfilePreview.number"

    static func register() {
        WGPeerInfoHooks.infoRows.register({ info in
            guard info.isSettings || info.peer.id == info.context.account.peerId else {
                return []
            }
            let defaults = UserDefaults.standard
            guard defaults.string(forKey: nameKey) != nil ||
                  defaults.string(forKey: noteKey) != nil ||
                  defaults.string(forKey: numberKey) != nil else {
                return []
            }
            var rows: [WGPeerInfoRow] = [
                WGPeerInfoRow(
                    id: "localProfilePreview.disclaimer",
                    label: "Макет",
                    text: "Локально · не данные Telegram"
                )
            ]
            if let name = defaults.string(forKey: nameKey), !name.isEmpty {
                rows.append(WGPeerInfoRow(id: "localProfilePreview.name", label: "Имя в макете", text: name))
            }
            if let note = defaults.string(forKey: noteKey), !note.isEmpty {
                rows.append(WGPeerInfoRow(id: "localProfilePreview.note", label: "Описание в макете", text: note))
            }
            if let number = defaults.string(forKey: numberKey), !number.isEmpty {
                rows.append(WGPeerInfoRow(id: "localProfilePreview.number", label: "Декоративный номер", text: number))
            }
            return rows
        }, order: 900)
    }

    static func edit(context: WGMenuContext) {
        let defaults = UserDefaults.standard
        let alert = UIAlertController(
            title: "Локальный макет профиля",
            message: "Изменения видны только в этом приложении и не меняют аккаунт Telegram.",
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.placeholder = "Имя для макета"
            field.text = defaults.string(forKey: nameKey)
        }
        alert.addTextField { field in
            field.placeholder = "Описание для макета"
            field.text = defaults.string(forKey: noteKey)
        }
        alert.addTextField { field in
            field.placeholder = "Декоративный номер (не настоящий)"
            field.text = defaults.string(forKey: numberKey)
            field.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { _ in
            let values = alert.textFields ?? []
            defaults.set(values.indices.contains(0) ? values[0].text ?? "" : "", forKey: nameKey)
            defaults.set(values.indices.contains(1) ? values[1].text ?? "" : "", forKey: noteKey)
            defaults.set(values.indices.contains(2) ? values[2].text ?? "" : "", forKey: numberKey)
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        context.presentNative(alert)
    }
}
