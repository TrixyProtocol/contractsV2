// Mock FlowTransactionSchedulerUtils contract for testing

import "FlowTransactionScheduler"

access(all) contract FlowTransactionSchedulerUtils {
    
    access(all) let managerStoragePath: StoragePath
    access(all) let managerPublicPath: PublicPath
    access(all) entitlement Owner
    
    access(all) struct HandlerInfo {
        access(all) let typeIdentifier: String
        access(all) let transactionIDs: [UInt64]
        access(contract) let capability: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>
        
        init(typeIdentifier: String, capability: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>) {
            self.typeIdentifier = typeIdentifier
            self.capability = capability
            self.transactionIDs = []
        }
        
        access(contract) fun addTransactionID(id: UInt64) {
            // Mock implementation - in real code this would mutate the array
        }
        
        access(contract) fun removeTransactionID(id: UInt64) {
            // Mock implementation
        }
        
        access(contract) view fun borrow(): &{FlowTransactionScheduler.TransactionHandler}? {
            return self.capability.borrow() as? &{FlowTransactionScheduler.TransactionHandler}
        }
    }
    
    // Mock Vault for this contract
    access(all) resource MockVault {
        access(all) var balance: UFix64
        
        init(balance: UFix64) {
            self.balance = balance
        }
    }
    
    access(all) resource interface Manager {
        access(Owner) fun schedule(
            handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>,
            data: AnyStruct?,
            timestamp: UFix64,
            priority: FlowTransactionScheduler.Priority,
            executionEffort: UInt64,
            fees: @MockVault
        ): UInt64
        
        access(Owner) fun scheduleByHandler(
            handlerTypeIdentifier: String,
            handlerUUID: UInt64?,
            data: AnyStruct?,
            timestamp: UFix64,
            priority: FlowTransactionScheduler.Priority,
            executionEffort: UInt64,
            fees: @MockVault
        ): UInt64
        
        access(Owner) fun cancel(id: UInt64): @MockVault
        access(all) view fun getTransactionData(_ id: UInt64): FlowTransactionScheduler.TransactionData?
        access(all) view fun borrowTransactionHandlerForID(_ id: UInt64): &{FlowTransactionScheduler.TransactionHandler}?
        access(all) fun getHandlerTypeIdentifiers(): {String: [UInt64]}
        access(all) view fun borrowHandler(handlerTypeIdentifier: String, handlerUUID: UInt64?): &{FlowTransactionScheduler.TransactionHandler}?
        access(all) fun getHandlerViews(handlerTypeIdentifier: String, handlerUUID: UInt64?): [Type] 
        access(all) fun resolveHandlerView(handlerTypeIdentifier: String, handlerUUID: UInt64?, viewType: Type): AnyStruct?
        access(all) fun getHandlerViewsFromTransactionID(_ id: UInt64): [Type]
        access(all) fun resolveHandlerViewFromTransactionID(_ id: UInt64, viewType: Type): AnyStruct?
        access(all) view fun getTransactionIDs(): [UInt64]
        access(all) view fun getTransactionIDsByHandler(handlerTypeIdentifier: String, handlerUUID: UInt64?): [UInt64]
        access(all) view fun getTransactionIDsByTimestamp(_ timestamp: UFix64): [UInt64]
        access(all) fun getTransactionIDsByTimestampRange(startTimestamp: UFix64, endTimestamp: UFix64): {UFix64: [UInt64]}
        access(all) view fun getTransactionStatus(id: UInt64): FlowTransactionScheduler.Status?
    }
    
    access(all) resource ManagerV1: Manager {
        init() {
            // Empty init
        }
        
        access(Owner) fun schedule(
            handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>,
            data: AnyStruct?,
            timestamp: UFix64,
            priority: FlowTransactionScheduler.Priority,
            executionEffort: UInt64,
            fees: @MockVault
        ): UInt64 {
            destroy fees
            return 1 // Mock - always return 1
        }
        
        access(Owner) fun scheduleByHandler(
            handlerTypeIdentifier: String,
            handlerUUID: UInt64?,
            data: AnyStruct?,
            timestamp: UFix64,
            priority: FlowTransactionScheduler.Priority,
            executionEffort: UInt64,
            fees: @MockVault
        ): UInt64 {
            destroy fees
            return 1 // Mock - always return 1
        }
        
        access(Owner) fun cancel(id: UInt64): @MockVault {
            return <- create MockVault(balance: 0.0)
        }
        
        access(all) view fun getTransactionData(_ id: UInt64): FlowTransactionScheduler.TransactionData? {
            return nil
        }
        
        access(all) view fun borrowTransactionHandlerForID(_ id: UInt64): &{FlowTransactionScheduler.TransactionHandler}? {
            return nil
        }
        
        access(all) fun getHandlerTypeIdentifiers(): {String: [UInt64]} {
            return {}
        }
        
        access(all) view fun borrowHandler(handlerTypeIdentifier: String, handlerUUID: UInt64?): &{FlowTransactionScheduler.TransactionHandler}? {
            return nil
        }
        
        access(all) fun getHandlerViews(handlerTypeIdentifier: String, handlerUUID: UInt64?): [Type] {
            return []
        }
        
        access(all) fun resolveHandlerView(handlerTypeIdentifier: String, handlerUUID: UInt64?, viewType: Type): AnyStruct? {
            return nil
        }
        
        access(all) fun getHandlerViewsFromTransactionID(_ id: UInt64): [Type] {
            return []
        }
        
        access(all) fun resolveHandlerViewFromTransactionID(_ id: UInt64, viewType: Type): AnyStruct? {
            return nil
        }
        
        access(all) view fun getTransactionIDs(): [UInt64] {
            return []
        }
        
        access(all) view fun getTransactionIDsByHandler(handlerTypeIdentifier: String, handlerUUID: UInt64?): [UInt64] {
            return []
        }
        
        access(all) view fun getTransactionIDsByTimestamp(_ timestamp: UFix64): [UInt64] {
            return []
        }
        
        access(all) fun getTransactionIDsByTimestampRange(startTimestamp: UFix64, endTimestamp: UFix64): {UFix64: [UInt64]} {
            return {}
        }
        
        access(all) view fun getTransactionStatus(id: UInt64): FlowTransactionScheduler.Status? {
            return nil
        }
    }
    
    access(all) fun createManagerV1(): @ManagerV1 {
        return <- create ManagerV1()
    }
    
    init() {
        self.managerStoragePath = /storage/FlowTransactionSchedulerUtils_Manager
        self.managerPublicPath = /public/FlowTransactionSchedulerUtils_Manager
    }
}
