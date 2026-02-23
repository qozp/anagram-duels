import Foundation
import Supabase

/// Shared wrapper around the Supabase SDK client.
/// Access via `SupabaseService.shared.client`.
final class SupabaseService {

    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
}
