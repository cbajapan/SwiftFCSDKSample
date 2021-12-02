//
//  SwiftFCSDKSampleApp.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/30/21.
//

import SwiftUI
import UIKit
import AVKit
import NIO
import FCSDKiOS

@main
struct SwiftFCSDKSampleApp: App {
    
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var fcsdkCallService = FCSDKCallService()
    @StateObject private var monitor = NetworkMonitor(type: .all)
    @StateObject private var callKitManager = CallKitManager()
    @StateObject private var contact = ContactService()
    @StateObject private var aedService = AEDService()
    @State var prorviderDelegate: ProviderDelegate?
    @State var exists = SQLiteStore.exists()
    
    init() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Failed to set audioSession category to playback")
        }
    }
    
    func requestMicrophoneAndCameraPermissionFromAppSettings() async {
        let requestMic = AppSettings.perferredAudioDirection() == .sendOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        let requestCam = AppSettings.perferredVideoDirection() == .sendOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        ACBClientPhone.requestMicrophoneAndCameraPermission(requestMic, video: requestCam)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .environmentObject(authenticationService)
                .environmentObject(callKitManager)
                .environmentObject(fcsdkCallService)
                .environmentObject(contact)
                .environmentObject(aedService)
                .onAppear {
                    fcsdkCallService.appDelegate = delegate
                    delegate.providerDelegate = ProviderDelegate(callKitManager: callKitManager, fcsdkCallService: fcsdkCallService)
                    AppSettings.registerDefaults()
                }
        }
        .onChange(of: scenePhase) { (phase) in
            switch phase {
            case .active:
                print("ScenePhase: active")
                Task {
                    await self.requestMicrophoneAndCameraPermissionFromAppSettings()
                // When our scene becomes active if we are not connected to the socket and we have a sessionID we want to connect back to the service, set the UC object and phone delegate
                    if self.authenticationService.acbuc == nil && !self.authenticationService.sessionID.isEmpty {
                        await self.authenticationService.loginUser(networkStatus: monitor.networkStatus())
                        self.fcsdkCallService.acbuc = self.authenticationService.acbuc
                        self.fcsdkCallService.setPhoneDelegate()
                    }
                }
            case .background:
                print("ScenePhase: background")
            case .inactive:
                print("ScenePhase: inactive")
            @unknown default:
                print("ScenePhase: unexpected state")
            }
        }
    }
}
