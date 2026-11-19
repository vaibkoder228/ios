import Foundation

/// User-owned presentation data for the current device only.
/// These values never update Telegram's account, contact, or server-side profile.
public struct WGLocalProfileDraft: Codable, Equatable {
    public var displayName: String
    public var username: String
    public var decorativePhoneNumber: String
    public var bio: String
    public var accentEmoji: String

    public init(
        displayName: String = "",
        username: String = "",
        decorativePhoneNumber: String = "",
        bio: String = "",
        accentEmoji: String = ""
    ) {
        self.displayName = displayName
        self.username = Self.normalizedUsername(username)
        self.decorativePhoneNumber = decorativePhoneNumber
        self.bio = bio
        self.accentEmoji = accentEmoji
    }

    /// Accepts a username with or without @ and stores it without the prefix.
    public static func normalizedUsername(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.drop(while: { $0 == "@" }))
    }
}

/// Small persistence layer for a local profile preview/editor.
/// UserDefaults is scoped to this app installation; nothing is sent to Telegram.
public final class WGLocalProfileDraftStore {
    public static let shared = WGLocalProfileDraftStore()

    private let defaults: UserDefaults
    private let storageKey = "wraithgram.localProfileDraft.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> WGLocalProfileDraft {
        guard
            let data = defaults.data(forKey: storageKey),
            let draft = try? JSONDecoder().decode(WGLocalProfileDraft.self, from: data)
        else {
            return WGLocalProfileDraft()
        }
        return draft
    }

    public func save(_ draft: WGLocalProfileDraft) {
        var normalized = draft
        normalized.username = WGLocalProfileDraft.normalizedUsername(draft.username)
        guard let data = try? JSONEncoder().encode(normalized) else {
            return
        }
        defaults.set(data, forKey: storageKey)
    }

    public func reset() {
        defaults.removeObject(forKey: storageKey)
    }
}
