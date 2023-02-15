//
//  ZcashSDKEnvironmentTestKey.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 13.11.2022.
//

import ComposableArchitecture
import ZcashLightClientKit
import XCTestDynamicOverlay

extension ZcashSDKEnvironment: TestDependencyKey {
    static let testnet = ZcashSDKEnvironment.liveValue

    static let testValue = Self(
        latestCheckpoint: { network in BlockHeight.ofLatestCheckpoint(network: network) },
        endpoint: LightWalletEndpoint(
            address: ZcashSDKConstants.endpointTestnetAddress,
            port: ZcashSDKConstants.endpointPort,
            secure: true,
            streamingCallTimeoutInMillis: ZcashSDKConstants.streamingCallTimeoutInMillis
        ),
        memoCharLimit: MemoBytes.capacity,
        mnemonicWordsMaxCount: ZcashSDKConstants.mnemonicWordsMaxCount,
        network: ZcashNetworkBuilder.network(for: .testnet),
        requiredTransactionConfirmations: ZcashSDKConstants.requiredTransactionConfirmations,
        sdkVersion: "0.18.1-beta"
    )
}
