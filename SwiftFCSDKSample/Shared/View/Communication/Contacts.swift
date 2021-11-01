//
//  Contacts.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

struct Contacts: View {
    
    var contacts = [Contact(name: "FCSDK", number: "1002", icon: "sdk"), Contact(name: "FCSDK-SIP", number: "sip:4005@192.168.99.103", icon: "sip")]
    
    @Binding var presentCommunication: ActiveSheet?
    @State var showFullSheet: ActiveSheet?
    @State var callSheet: Bool = false
    @State var destination: String = ""
    @State var hasVideo: Bool = false
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var monitor: NetworkMonitor
    
    var body: some View {
        NavigationView {
            List {
                //                ForEach(contacts, id: \.self) { contact in
                //                    ContactsCell(contact: contact)
                //                        .onTapGesture {
                //                            self.showFullSheet = .communincationSheet
                //                        }
                //                }
                NavigationLink(
                    destination: CallSheet(destination: self.$destination, hasVideo: self.$hasVideo),
                    isActive: $callSheet
                ) {}.ignoresSafeArea()
                    .navigationTitle("Recent Calls")
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.callSheet = true
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.blue)
                    })
                }
            })
        }
        .fullScreenCover(item: self.$showFullSheet) { sheet in
            switch sheet {
            case .communincationSheet:
                Communication(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: .constant(false))
            }
        }
        .onAppear {
            
            
            if !self.authenticationService.connectedToSocket {
                Task {
#if !DEBUG
                    await self.authenticationService.createSession(sessionid: KeychainItem.getSessionID, networkStatus: monitor.networkStatus())
#else
                    await self.authenticationService.createSession(sessionid: UserDefaults.standard.string(forKey: "SessionID") ?? "", networkStatus: monitor.networkStatus())
#endif
                }
                //                 self.fcsdkCallService.connectedToSocket = self.fcsdkCallService.acbuc?.connection != nil
                self.fcsdkCallService.acbuc = self.authenticationService.acbuc
                self.fcsdkCallService.setPhoneDelegate()
            } else {
                self.fcsdkCallService.acbuc = self.authenticationService.acbuc
                self.fcsdkCallService.setPhoneDelegate()
            }
        }
        .onChange(of: self.fcsdkCallService.presentCommunication) { newValue in
            self.showFullSheet = newValue
        }
    }
}

enum ActiveSheet: Identifiable {
    case communincationSheet
    
    var id: Int {
        hashValue
    }
}
