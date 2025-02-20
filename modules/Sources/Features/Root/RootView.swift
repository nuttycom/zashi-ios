import SwiftUI
import StoreKit
import ComposableArchitecture
import Generated
import Models
import RecoveryPhraseDisplay
import Welcome
import ExportLogs
import OnboardingFlow
import Sandbox
import Tabs
import ZcashLightClientKit

public struct RootView: View {
    let store: RootStore
    let tokenName: String
    let networkType: NetworkType

    public init(store: RootStore, tokenName: String, networkType: NetworkType) {
        self.store = store
        self.tokenName = tokenName
        self.networkType = networkType
    }
    
    public var body: some View {
        switchOverDestination()
    }
}

private struct FeatureFlagWrapper: Identifiable, Equatable, Comparable {
    let name: FeatureFlag
    let isEnabled: Bool
    var id: String { name.rawValue }

    static func < (lhs: FeatureFlagWrapper, rhs: FeatureFlagWrapper) -> Bool {
        lhs.name.rawValue < rhs.name.rawValue
    }

    static func == (lhs: FeatureFlagWrapper, rhs: FeatureFlagWrapper) -> Bool {
        lhs.name.rawValue == rhs.name.rawValue
    }
}

private extension RootView {
    @ViewBuilder func switchOverDestination() -> some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Group {
                switch viewStore.destinationState.destination {
                case .tabs:
                    NavigationView {
                        TabsView(
                            store: store.scope(
                                state: \.tabsState,
                                action: RootReducer.Action.tabs
                            ),
                            tokenName: tokenName,
                            networkType: networkType
                        )
                    }
                    .navigationViewStyle(.stack)
                    .overlayedWithSplash(viewStore.splashAppeared) {
                        viewStore.send(.splashRemovalRequested)
                    }
                    
                case .sandbox:
                    NavigationView {
                        SandboxView(
                            store: store.scope(
                                state: \.sandboxState,
                                action: RootReducer.Action.sandbox
                            ),
                            tokenName: tokenName,
                            networkType: networkType
                        )
                    }
                    .navigationViewStyle(.stack)
                    
                case .onboarding:
                    NavigationView {
                        PlainOnboardingView(
                            store: store.scope(
                                state: \.onboardingState,
                                action: RootReducer.Action.onboarding
                            )
                        )
                    }
                    .navigationViewStyle(.stack)
                    .overlayedWithSplash(viewStore.splashAppeared) {
                        viewStore.send(.splashRemovalRequested)
                    }

                case .startup:
                    ZStack(alignment: .topTrailing) {
                        debugView(viewStore)
                            .transition(.opacity)
                    }
                                        
                case .welcome:
                    WelcomeView(
                        store: store.scope(
                            state: \.welcomeState,
                            action: RootReducer.Action.welcome
                        )
                    )
                }
            }
            .onOpenURL(perform: { viewStore.goToDeeplink($0) })
            .alert(store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            ))
            .alert(store: store.scope(
                state: \.exportLogsState.$alert,
                action: { .exportLogs(.alert($0)) }
            ))

            shareLogsView(viewStore)
        }
    }
}

private extension RootView {
    @ViewBuilder func shareLogsView(_ viewStore: RootViewStore) -> some View {
        if viewStore.exportLogsState.isSharingLogs {
            UIShareDialogView(
                activityItems: viewStore.exportLogsState.zippedLogsURLs
            ) {
                viewStore.send(.exportLogs(.shareFinished))
            }
            // UIShareDialogView only wraps UIActivityViewController presentation
            // so frame is set to 0 to not break SwiftUIs layout
            .frame(width: 0, height: 0)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder func debugView(_ viewStore: RootViewStore) -> some View {
        VStack(alignment: .leading) {
            if viewStore.destinationState.previousDestination == .tabs {
                Button(L10n.General.back.uppercased()) {
                    viewStore.goToDestination(.tabs)
                }
                .zcashStyle()
                .frame(width: 150)
                .padding()
            }

            List {
                Section(header: Text(L10n.Root.Debug.title)) {
                    Button(L10n.Root.Debug.Option.exportLogs) {
                        viewStore.send(.exportLogs(.start))
                    }
                    .disabled(viewStore.exportLogsState.exportLogsDisabled)

                    Button(L10n.Root.Debug.Option.testCrashReporter) {
                        viewStore.send(.debug(.testCrashReporter))
                    }

#if DEBUG
                    Button(L10n.Root.Debug.Option.appReview) {
                        viewStore.send(.debug(.rateTheApp))
                        if let currentScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: currentScene)
                        }
                    }
#endif
                    
                    Button(L10n.Root.Debug.Option.rescanBlockchain) {
                        viewStore.send(.debug(.rescanBlockchain))
                    }
                    
                    Button(L10n.Root.Debug.Option.nukeWallet) {
                        viewStore.send(.initialization(.nukeWalletRequest))
                    }
                }
            }
            .confirmationDialog(
              store: self.store.scope(state: \.$confirmationDialog, action: { .confirmationDialog($0) })
            )
        }
        .navigationBarTitle(L10n.Root.Debug.navigationTitle)
    }
}

// MARK: - Previews

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RootView(
                store: RootStore(
                    initialState: .initial
                ) {
                    RootReducer(tokenName: "ZEC", zcashNetwork: ZcashNetworkBuilder.network(for: .testnet))
                },
                tokenName: "ZEC",
                networkType: .testnet
            )
        }
    }
}
