/// A type alias combining the most common protocol conformances for NativeCanvas model types.
///
/// Conforming to `Friendly` makes types serializable, comparable, and safe to use across
/// concurrency boundaries — covering the typical needs of a data model type.
public typealias Friendly = Codable & Hashable & Equatable & Sendable
