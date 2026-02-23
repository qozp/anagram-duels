import Foundation

/// Supabase project credentials.
///
/// **Setup:** Replace the placeholder strings below with your actual values
/// from the Supabase dashboard → Project Settings → API.
///
/// For production, consider loading these from a secrets file
/// that is excluded from version control (.gitignore).
enum SupabaseConfig {

    // swiftlint:disable line_length
    static let projectURL: URL = {
        guard let url = URL(string: "https://ypxisuybstcrdedyvhwu.supabase.co") else {
            fatalError("SupabaseConfig: projectURL is invalid. Update SupabaseConfig.swift.")
        }
        return url
    }()

    /// The public anon key (safe to ship in the client).
    static let anonKey: String = "sb_publishable_85_t0pYMFRwaAs5azhHj-Q__xHmG0El"
    // swiftlint:enable line_length
}
