//
//  ToAsync.swift
//  CombineExt
//
//  Created by Thibault Wittemberg on 2021-06-15.
//  Copyright © 2021 Combine Community. All rights reserved.
//

#if canImport(Combine)
import Combine

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension Future {
    func toAsync() async -> Output where Failure == Never {
        var subscriptions = [AnyCancellable]()

        return await withCheckedContinuation { [weak self] (continuation: CheckedContinuation<Output, Never>) in
            self?
                .sink { output in continuation.resume(returning: output) }
                .store(in: &subscriptions)
        }
    }

    func toAsync() async throws -> Output {
        var subscriptions = [AnyCancellable]()

        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Output, Error>) in
            self?
                .sink(
                    receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                },
                    receiveValue: { output in continuation.resume(returning: output) }
                )
                .store(in: &subscriptions)
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public extension Publisher {
    func toAsync() -> AsyncStream<Output> where Failure == Never {
        AsyncStream(Output.self) { continuation in
            var subscriptions = [AnyCancellable]()

            self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            continuation.finish()
                        case let .failure(error):
                            continuation.yield(with: .failure(error))
                        }
                    },
                    receiveValue: { output in
                        continuation.yield(output)
                    }
                )
                .store(in: &subscriptions)

            let subs = subscriptions

            continuation.onTermination = { @Sendable _ in
                _ = subs
            }
        }
    }
}

#endif
