

import "FlowToken"
import "FungibleToken"

access(all) contract interface IStakingProtocol {

    access(all) fun stake(vault: @FlowToken.Vault): String
    access(all) fun unstake(amount: UFix64, positionId: String): @FlowToken.Vault
    access(all) fun getCurrentAPY(): UFix64
    access(all) fun getBalance(positionId: String): UFix64
    access(all) fun getProtocolName(): String
    access(all) fun getProtocolType(): UInt8
}
