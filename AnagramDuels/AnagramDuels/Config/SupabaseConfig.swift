import Foundation

/// Supabase connection details.
/// The anon key is safe to commit — it is a public identifier
/// and access is controlled entirely by Row Level Security policies.
enum SupabaseConfig {
    static let supabaseURL = URL(string: "https://xrfmmdinpnsqvtymicio.supabase.co")!
    static let supabaseAnonKey = "sb_publishable_jnSlP6gKATy_qXerOvVTNw_6KeIgSOO"
}
