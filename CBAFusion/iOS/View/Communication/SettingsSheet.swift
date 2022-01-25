//
//  SettingsSheet.swift
//  CBAFusion
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI
import FCSDKiOS


enum AudioOptions: String, Equatable, CaseIterable {
    case ear = "Ear Piece"
    case speaker = "Speaker Phone"
}

enum ResolutionOptions: String, Equatable, CaseIterable {
    case auto = "auto"
    case res288p = "288p"
    case res480p = "480p"
    case res720p = "720p"
}

enum FrameRateOptions: String, Equatable, CaseIterable {
    case fro20 = "20fps"
    case fro30 = "30fps"
}


struct SettingsSheet: View {
    
    @AppStorage("AudioOption") var selectedAudio = AudioOptions.ear
    @AppStorage("ResolutionOption") var selectedResolution = ResolutionOptions.auto
    @AppStorage("RateOption") var selectedFrameRate = FrameRateOptions.fro20
    
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var contactService: ContactService
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    
                    if self.contactService.showProgress || self.authenticationService.showProgress {
                     ProgressView()
                         .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                         .scaleEffect(1.5)
                    }
                 
                    
                VStack(alignment: .leading, spacing: 5) {
                    Group {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                        Text("Audio Options")
                            .fontWeight(.light)
                            .multilineTextAlignment(.leading)
                        Picker("", selection: $selectedAudio) {
                            ForEach(AudioOptions.allCases, id: \.self) { item in
                                Text(item.rawValue)
                            }
                        }
                        .onAppear {
                            self.fcsdkCallService.selectAudio(audio: self.selectedAudio)
                        }
                        .onChange(of: self.selectedAudio, perform: { item in
                            self.fcsdkCallService.selectAudio(audio: item)
                        })
                        .pickerStyle(SegmentedPickerStyle())
                        Divider()
                            .padding(.top)
                        }
                        Text("Resolution Options")
                            .fontWeight(.light)
                            .multilineTextAlignment(.leading)
                        Picker("", selection: $selectedResolution) {
                            ForEach(ResolutionOptions.allCases, id: \.self) { item in
                                Text(item.rawValue)
                            }
                        }
                        .onAppear {
                            self.fcsdkCallService.selectResolution(res: self.selectedResolution)
                        }
                        .onChange(of: self.selectedResolution, perform: { item in
                            self.fcsdkCallService.selectResolution(res: item)
                        })
                        .pickerStyle(SegmentedPickerStyle())
                        Divider()
                            .padding(.top)
                        
                        Text("Frame Rate Options")
                            .fontWeight(.light)
                            .multilineTextAlignment(.leading)
                        Picker("", selection: $selectedFrameRate) {
                            ForEach(FrameRateOptions.allCases, id: \.self) { item in
                                Text(item.rawValue)
                            }
                        }
                        .onAppear {
                            self.fcsdkCallService.selectFramerate(rate: self.selectedFrameRate)
                        }
                        .onChange(of: self.selectedFrameRate, perform: { item in
                            self.fcsdkCallService.selectFramerate(rate: item)
                        })
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    Divider()
                    Spacer()
                    Button("Clear Call History", action: {
                        Task {
                        await self.fcsdkCallService.contactService?.deleteCalls()
                        }
                    })
                    Divider()
                    HStack {
                        VStack(alignment: .leading) {
                            Text("User: \(UserDefaults.standard.string(forKey: "Username") ?? "")").bold()
                            Text("App Version: \(FCSDKiOS.Constants.SDK_VERSION_NUMBER)").fontWeight(.light)
                        }
                        Spacer()
                        if self.fcsdkCallService.currentCall?.call == nil {
                        Button {
                            Task {
                                await self.logout()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Logout")
                                    .font(.title2)
                                    .bold()
                            }
                        }
                        }
                        Spacer()
                    }
                }
                }
                .padding()
                .navigationBarTitle("Settings")
            }
        }
        .alert("There was an error deleting Call History", isPresented: self.$contactService.showError) {
            Button("OK", role: .cancel) {
            }
        }
    }
    func logout() async {
        await authenticationService.logout()
    }
}

