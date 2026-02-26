import Foundation
import Supabase

/// Singleton wrapper around the Supabase client.
/// All services and ViewModels access Supabase through this shared instance.
final class SupabaseService {

    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.supabaseURL,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
}
