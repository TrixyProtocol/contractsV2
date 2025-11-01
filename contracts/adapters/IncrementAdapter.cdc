import "FlowToken"
import "FungibleToken"
import "IStakingProtocol"
import "IncrementFiStakingConnectors"
import "Staking"

access(all) contract IncrementAdapter: IStakingProtocol {

    /* --- EVENTS --- */

    access(all) event PositionCreated(positionId: String, staker: Address, amount: UFix64, pid: UInt64)
    access(all) event PositionUnstaked(positionId: String, amount: UFix64)
    access(all) event RewardsClaimed(positionId: String, amount: UFix64)

    /* --- STORAGE --- */

    access(self) let positionMetadata: {String: PositionMetadata}
    access(self) var nextPositionId: UInt64
    access(self) let defaultPoolId: UInt64

    /* --- STRUCTS --- */

    access(all) struct PositionMetadata {
        access(all) let positionId: String
        access(all) let staker: Address
        access(all) let pid: UInt64
        access(all) let initialAmount: UFix64
        access(all) let createdAt: UFix64

        init(positionId: String, staker: Address, pid: UInt64, initialAmount: UFix64) {
            self.positionId = positionId
            self.staker = staker
            self.pid = pid
            self.initialAmount = initialAmount
            self.createdAt = getCurrentBlock().timestamp
        }
    }

    /* --- PUBLIC FUNCTIONS --- */

    access(all) fun stake(vault: @FlowToken.Vault): String {
        return self.stakeToPool(vault: <- vault, pid: self.defaultPoolId, staker: self.account.address)
    }

    access(all) fun stakeToPool(vault: @FlowToken.Vault, pid: UInt64, staker: Address): String {
        let amount = vault.balance
        let positionId = "increment_".concat(self.nextPositionId.toString())
        self.nextPositionId = self.nextPositionId + 1

        let pool = IncrementFiStakingConnectors.borrowPool(pid: pid)
            ?? panic("Pool with ID \(pid) not found")
        pool.stake(staker: staker, stakingToken: <- vault)

        self.positionMetadata[positionId] = PositionMetadata(
            positionId: positionId,
            staker: staker,
            pid: pid,
            initialAmount: amount
        )

        emit PositionCreated(positionId: positionId, staker: staker, amount: amount, pid: pid)

        return positionId
    }

    access(all) fun unstake(amount: UFix64, positionId: String): @FlowToken.Vault {
        pre {
            self.positionMetadata[positionId] != nil: "Position not found"
            amount > 0.0: "Amount must be greater than 0"
        }

        let metadata = self.positionMetadata[positionId]!

        let userCertificate = self.account.storage.borrow < &Staking.UserCertificate > (
            from: Staking.UserCertificateStoragePath
        ) ?? panic("User certificate not found")

        let pool = IncrementFiStakingConnectors.borrowPool(pid: metadata.pid)
            ?? panic("Pool with ID \(metadata.pid) not found")
        let unstakedVault <- pool.unstake(userCertificate: userCertificate, amount: amount)

        let unstaked <- unstakedVault as! @FlowToken.Vault

        emit PositionUnstaked(positionId: positionId, amount: unstaked.balance)

        return <- unstaked
    }

    access(all) fun claimRewards(positionId: String): @FlowToken.Vault {
        pre {
            self.positionMetadata[positionId] != nil: "Position not found"
        }

        let metadata = self.positionMetadata[positionId]!

        let userCertificate = self.account.storage.borrow < &Staking.UserCertificate > (
            from: Staking.UserCertificateStoragePath
        ) ?? panic("User certificate not found")

        let pool = IncrementFiStakingConnectors.borrowPool(pid: metadata.pid)
            ?? panic("Pool with ID \(metadata.pid) not found")
        let rewardsVault <- pool.claimRewards(userCertificate: userCertificate)

        let rewards <- rewardsVault as! @FlowToken.Vault

        emit RewardsClaimed(positionId: positionId, amount: rewards.balance)

        return <- rewards
    }

    access(all) fun getCurrentAPY(): UFix64 {
        var totalStaked = 0.0
        var totalRewards = 0.0
        
        for positionId in self.positionMetadata.keys {
            let metadata = self.positionMetadata[positionId]!
            let pool = IncrementFiStakingConnectors.borrowPool(pid: metadata.pid)
            if pool == nil { continue }
            let userInfo = pool!.getUserInfo(address: metadata.staker)
            let staked = userInfo?.stakingAmount ?? 0.0
            var rewards = 0.0
            if let unclaimedRewards = userInfo?.unclaimedRewards {
                for tokenType in unclaimedRewards.keys {
                    rewards = rewards + (unclaimedRewards[tokenType] ?? 0.0)
                }
            }
            
            totalStaked = totalStaked + staked
            totalRewards = totalRewards + rewards
        }
        
        if totalStaked == 0.0 {
            return 0.0
        }
        
        let apy = (totalRewards / totalStaked) * 100.0
        
        return apy
    }

    access(all) fun getBalance(positionId: String): UFix64 {
        if self.positionMetadata[positionId] == nil {
            return 0.0
        }

        let metadata = self.positionMetadata[positionId]!
        let pool = IncrementFiStakingConnectors.borrowPool(pid: metadata.pid)
        if pool == nil { return 0.0 }
        let userInfo = pool!.getUserInfo(address: metadata.staker)
        return userInfo?.stakingAmount ?? 0.0
    }

    access(all) fun getAvailableRewards(positionId: String): UFix64 {
        if self.positionMetadata[positionId] == nil {
            return 0.0
        }

        let metadata = self.positionMetadata[positionId]!
        let pool = IncrementFiStakingConnectors.borrowPool(pid: metadata.pid)
        if pool == nil { return 0.0 }
        let userInfo = pool!.getUserInfo(address: metadata.staker)
        var rewards = 0.0
        if let unclaimedRewards = userInfo?.unclaimedRewards {
            for tokenType in unclaimedRewards.keys {
                rewards = rewards + (unclaimedRewards[tokenType] ?? 0.0)
            }
        }
        return rewards
    }

    access(all) fun getPositionMetadata(positionId: String): PositionMetadata? {
        return self.positionMetadata[positionId]
    }

    access(all) fun getProtocolName(): String {
        return "Increment Finance"
    }

    access(all) fun getProtocolType(): UInt8 {
        return 1
    }


    init() {
        self.positionMetadata = {}
        self.nextPositionId = 0
        self.defaultPoolId = 0
    }
}
