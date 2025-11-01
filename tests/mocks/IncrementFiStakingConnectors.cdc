import "FlowToken"
import "FungibleToken"

access(all) contract IncrementFiStakingConnectors {
    
    access(all) struct UserInfo {
        access(all) let stakingAmount: UFix64
        access(all) let unclaimedRewards: {String: UFix64}
        
        init(stakingAmount: UFix64, unclaimedRewards: {String: UFix64}) {
            self.stakingAmount = stakingAmount
            self.unclaimedRewards = unclaimedRewards
        }
    }
    
    access(all) resource Pool {
        access(all) let pid: UInt64
        access(self) var userStakes: {Address: UFix64}
        access(self) var userRewards: {Address: UFix64}
        
        init(pid: UInt64) {
            self.pid = pid
            self.userStakes = {}
            self.userRewards = {}
        }
        
        access(all) fun stake(staker: Address, stakingToken: @FlowToken.Vault) {
            let amount = stakingToken.balance
            destroy stakingToken
            
            let currentStake = self.userStakes[staker] ?? 0.0
            self.userStakes[staker] = currentStake + amount
            
            // Mock some rewards
            let currentRewards = self.userRewards[staker] ?? 0.0
            self.userRewards[staker] = currentRewards + (amount * 0.05) // 5% instant reward for testing
        }
        
        access(all) fun unstake(userCertificate: &AnyResource, amount: UFix64): @{FungibleToken.Vault} {
            // Mock unstaking - just return empty vault for testing
            return <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        }
        
        access(all) fun claimRewards(userCertificate: &AnyResource): @{FungibleToken.Vault} {
            // Mock claiming - just return empty vault for testing
            return <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        }
        
        access(all) fun getUserInfo(address: Address): UserInfo? {
            let stakingAmount = self.userStakes[address] ?? 0.0
            let rewardAmount = self.userRewards[address] ?? 0.0
            
            if stakingAmount == 0.0 && rewardAmount == 0.0 {
                return nil
            }
            
            return UserInfo(
                stakingAmount: stakingAmount,
                unclaimedRewards: {"FLOW": rewardAmount}
            )
        }
    }
    
    access(self) let pools: @{UInt64: Pool}
    
    access(all) fun borrowPool(pid: UInt64): &Pool? {
        return &self.pools[pid]
    }
    
    init() {
        self.pools <- {}
        
        // Create a default pool for testing
        let defaultPool <- create Pool(pid: 0)
        self.pools[0] <-! defaultPool
    }
}