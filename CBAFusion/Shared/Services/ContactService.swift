//
//  ContactService.swift
//  CBAFusion
//
//  Created by Cole M on 11/17/21.
//

import Foundation
import SwiftUI
import UIKit
import FCSDKiOS
import Logging

protocol FCSDKStore: AnyObject {
    func fetchContacts() async throws -> [ContactModel]?
    func createContact(_ contact: ContactModel) async throws
    func updateContact(_ contact: ContactModel) async throws
    func removeContact(_ contact: ContactModel) async throws
    
    func fetchActiveCalls() async throws -> [FCSDKCall]?
    func fetchCalls() async throws -> [FCSDKCall]?
    func fetchContactCalls(handle: String) async throws -> [FCSDKCall]?
    func createCall(_ contactID: UUID?, call: _CallsModel) async throws
    func updateCall(_ contactID: UUID, call: FCSDKCall) async throws
    func removeCall(_ contactID: UUID, call: FCSDKCall) async throws
    func removeCalls() async throws -> (Bool, [FCSDKCall]?)
}

extension FCSDKStore {
    func fetchContacts() async throws -> [ContactModel]? { return nil }
    func createContact(_ contact: ContactModel) async throws {}
    func updateContact(_ contact: ContactModel) async throws {}
    func removeContact(_ contact: ContactModel) async throws {}
    
    func fetchActiveCalls() async throws -> [FCSDKCall]? { return nil }
    func fetchCalls() async throws -> [FCSDKCall]? { return nil }
    func createCall(_ contactID: UUID?, call: _CallsModel) async throws {}
    func updateCall(_ contactID: UUID, call: FCSDKCall) async throws {}
    func removeCall(_ contactID: UUID, call: FCSDKCall) async throws {}
    func removeCalls() async throws -> (Bool, [FCSDKCall]?) { return (false, nil) }
}


class ContactService: ObservableObject {
    
    
    @Published var username: String = ""
    @Published var number: String = ""
    @Published var delegate: FCSDKStore?
    @Published var contacts: [ContactModel]?
    @Published var alert: Bool = false
    @Published var isEdit: Bool = false
    @Published var contactToEdit: ContactModel?
    @Published var addSheet: Bool = false
    @Published var selectedContact: ContactModel? = nil
    @Published var showProgress: Bool = false
    @Published var showError: Bool = false
    @Published var calls: [FCSDKCall]? = nil
    var logger: Logger
    
    init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Contact Service - ")
    }
    
    
    func addContact(_ contact: ContactModel?, isEdit: Bool) async {
        if !username.isEmpty || !number.isEmpty {
            let createContact = ContactModel(id: contact?.id ?? UUID(), username: username, number: number, calls: nil, blocked: false)
            try? await addContactLogic(createContact)
        } else if username.isEmpty || number.isEmpty {
            guard let contact = contact else {
                return
            }
            try? await addContactLogic(contact)
        } else {
            await MainActor.run {
                self.alert = true
            }
        }
    }
    
    func addContactLogic(_ contact: ContactModel) async throws {
        do {
            if isEdit {
                try await delegate?.updateContact(contact)
            } else {
                try await delegate?.createContact(contact)
            }
            try await self.fetchContacts()
        } catch {
             self.logger.error("\(error)")
        }
    }
    
    
    func clearToDismiss() async {
        username = ""
        number = ""
    }
    
    @MainActor
    func fetchContacts() async throws {
        do {
            self.contacts = try await delegate?.fetchContacts()
        } catch {
             self.logger.error("Error Fetching Contacts: \(error)")
        }
    }
    
    
    func deleteContact(contact: ContactModel) async {
        do {
            try await delegate?.removeContact(contact)
            try await fetchContacts()
        } catch {
             self.logger.error("Error deleting Calls: \(error)")
        }
    }
    
    func editContact(contact: ContactModel, isEdit: Bool) async {
        self.contactToEdit = contact
        self.isEdit = true
        self.addSheet = true
    }
    
    
    func addCall(_ fcsdkCall: FCSDKCall, isEdit: Bool) async throws {
        let contact = self.contacts?.first(where: { $0.number == fcsdkCall.call?.remoteAddress } )
        if contact == nil {
            let createContact = ContactModel(id: UUID(), username: fcsdkCall.handle, number: fcsdkCall.handle, calls: nil, blocked: false)
            try? await addContactLogic(createContact)
        } else {
            try? await addCallLogic(contact!, fcsdkCall: fcsdkCall)
        }
    }
    
    func addCallLogic(_ contact: ContactModel, fcsdkCall: FCSDKCall) async throws {
        do {
            if isEdit {
                try await delegate?.updateCall(contact.id, call: fcsdkCall)
            } else {
                let callModel = _CallsModel(call: fcsdkCall, contactID: contact.id, new: true)
                try await delegate?.createCall(contact.id, call: callModel)
            }
            try await self.fetchContacts()
        } catch {
             self.logger.error("Error adding Call: \(error)")
        }
    }
    
    
    func setCallsForContact(_ contact: ContactModel) async {
        self.calls = contact.calls
    }
    
    @MainActor
    func fetchCalls() async throws {
        do {
            self.calls = try await delegate?.fetchCalls()
        } catch {
             self.logger.error("Error fetching all Calls: \(error)")
        }
    }
    
    @MainActor
    func fetchContactCalls(_ destination: String) async throws {
        do {
            self.calls = try await delegate?.fetchContactCalls(handle: destination)
        } catch {
             self.logger.error("Error fetching Calls: \(error)")
        }
    }
    
    func fetchActiveCall() async throws -> FCSDKCall? {
        var call: FCSDKCall?
        do {
            call = try await self.delegate?.fetchActiveCalls()?.first
        } catch {
             self.logger.error("Error fetching Active Call: \(error)")
        }
        return call
    }
    
    func deleteCall(call: FCSDKCall) async {
        do {
            try await delegate?.removeCall(call.contact!, call: call)
            try await fetchContacts()
        } catch {
            self.logger.info("\(OurErrors.nilDelegate.rawValue)")
        }
    }
    
    func deleteCalls() async {
        self.showProgress = true
        let result = try? await self.delegate?.removeCalls()
        try? await self.fetchContacts()
        await MainActor.run {
            if result?.0 == true {
                self.calls = result?.1
                self.showProgress = false
            } else {
                self.showProgress = false
                self.showError = true
            }
        }
    }
    func editCall(call: FCSDKCall) async {
        do {
            guard let contact = call.contact else { throw OurErrors.noContactID }
            try await self.delegate?.updateCall(contact, call: call)
        } catch {
             self.logger.error("Error Editing Call: \(error)")
        }
    }
}

