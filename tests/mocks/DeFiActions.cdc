import "FlowToken"
import "FungibleToken"

access(all) contract DeFiActions {
    access(all) var currentID: UInt64
    
    access(all) entitlement Identify
    
    access(all) resource AuthenticationToken {}
    
    access(all) struct UniqueIdentifier {
        access(all) let id: UInt64
        access(self) let authCap: Capability<auth(Identify) &AuthenticationToken>
        
        access(contract) view init(_ id: UInt64, _ authCap: Capability<auth(Identify) &AuthenticationToken>) {
            self.id = id
            self.authCap = authCap
        }
    }
    
    access(all) struct ComponentInfo {
        access(all) let type: Type
        access(all) let id: UInt64?
        access(all) let innerComponents: [ComponentInfo]
        
        init(type: Type, id: UInt64?, innerComponents: [ComponentInfo]) {
            self.type = type
            self.id = id
            self.innerComponents = innerComponents
        }
    }
    
    access(all) struct interface IdentifiableStruct {
        access(contract) var uniqueID: UniqueIdentifier?
        
        access(all) view fun id(): UInt64? {
            return self.uniqueID?.id
        }
        
        access(all) fun getComponentInfo(): ComponentInfo
        access(contract) view fun copyID(): UniqueIdentifier?
        access(contract) fun setID(_ id: UniqueIdentifier?)
    }
    
    access(all) struct interface Source : IdentifiableStruct {
        access(all) view fun getSourceType(): Type
        access(all) fun minimumAvailable(): UFix64
        access(FungibleToken.Withdraw) fun withdrawAvailable(maxAmount: UFix64): @{FungibleToken.Vault}
    }
    
    access(all) struct MockFlowTokenSource : Source {
        access(contract) var uniqueID: UniqueIdentifier?
        
        init() {
            self.uniqueID = nil
        }
        
        access(all) view fun getSourceType(): Type {
            return Type<@FlowToken.Vault>()
        }
        
        access(all) fun minimumAvailable(): UFix64 {
            return 1.0
        }
        
        access(FungibleToken.Withdraw) fun withdrawAvailable(maxAmount: UFix64): @{FungibleToken.Vault} {
            return <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        }
        
        access(all) fun getComponentInfo(): ComponentInfo {
            return ComponentInfo(type: self.getType(), id: self.id(), innerComponents: [])
        }
        
        access(contract) view fun copyID(): UniqueIdentifier? {
            return self.uniqueID
        }
        
        access(contract) fun setID(_ id: UniqueIdentifier?) {
            self.uniqueID = id
        }
    }
    
    init() {
        self.currentID = 0
    }
}