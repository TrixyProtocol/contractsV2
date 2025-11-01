

import "FlowToken"
import "FungibleToken"
import "Staking"
import "SwapConfig"

access(all) contract IncrementFiStakingConnector {

    /* --- EVENTS --- */

    access(all) event PoolStaked(pid: UInt64, staker: Address, amount: UFix64)
    access(all) event RewardsClaimed(pid: UInt64, staker: Address, amount: UFix64)
    access(all) event PoolUnstaked(pid: UInt64, staker: Address, amount: UFix64)

    /* --- STORAGE PATHS --- */

    access(all) let StakingPositionStoragePath: StoragePath
    access(all) let StakingPositionPublicPath: PublicPath

    /* --- STRUCTS --- */

    access(all) struct PoolInfo {
        access(all) let pid: UInt64
        access(all) let acceptTokenKey: String
        access(all) let rewardTokenKeys: [String]
        access(all) let limitAmount: UFix64
        access(all) let isActive: Bool

        init(
            pid: UInt64,
            acceptTokenKey: String,
            rewardTokenKeys: [String],
            limitAmount: UFix64,
            isActive: Bool
        ) {
            self.pid = pid
            self.acceptTokenKey = acceptTokenKey
            self.rewardTokenKeys = rewardTokenKeys
            self.limitAmount = limitAmount
            self.isActive = isActive
        }
    }

    /* --- PUBLIC FUNCTIONS --- */

    access(all) fun stake(
        pid: UInt64,
        staker: Address,
        stakingVault: @ {FungibleToken.Vault}
    ) {
        let depositAmount = stakingVault.balance

        if depositAmount == 0.0 {
            destroy stakingVault
            return
        }

        let pool = self.borrowPool(pid: pid)
        if pool == nil {
            destroy stakingVault
            return
        }

        pool! .stake(staker: staker, stakingToken: <- stakingVault)

        emit PoolStaked(pid: pid, staker: staker, amount: depositAmount)
    }

    access(all) fun claimRewards(
        pid: UInt64,
        userCertificate: &Staking.UserCertificate
    ): @ {FungibleToken.Vault} {
        let pool = self.borrowPool(pid: pid)
        if pool == nil {
            return <- FlowToken.createEmptyVault(vaultType: Type < @FlowToken.Vault > ())
        }

        let rewardVaults <- pool! .claimRewards(userCertificate: userCertificate)

        let poolInfo = pool! .getPoolInfo()
        let rewardTokenKeys = poolInfo.rewardsInfo.keys

        if rewardTokenKeys.length == 0 {
            destroy rewardVaults
            return <- FlowToken.createEmptyVault(vaultType: Type < @FlowToken.Vault > ())
        }

        let rewardTokenKey = rewardTokenKeys[0]
        let rewardVault <- rewardVaults.remove(key: rewardTokenKey)!
        destroy rewardVaults

        let claimedAmount = rewardVault.balance
        emit RewardsClaimed(pid: pid, staker: userCertificate.owner! .address, amount: claimedAmount)

        return <- rewardVault
    }

    access(all) fun unstake(
        pid: UInt64,
        userCertificate: &Staking.UserCertificate,
        amount: UFix64
    ): @ {FungibleToken.Vault} {
        if amount == 0.0 {
            return <- FlowToken.createEmptyVault(vaultType: Type < @FlowToken.Vault > ())
        }

        let pool = self.borrowPool(pid: pid)
        if pool == nil {
            return <- FlowToken.createEmptyVault(vaultType: Type < @FlowToken.Vault > ())
        }

        let unstaked <- pool! .unstake(userCertificate: userCertificate, amount: amount)

        emit PoolUnstaked(pid: pid, staker: userCertificate.owner! .address, amount: unstaked.balance)

        return <- unstaked
    }

    access(all) fun borrowPool(pid: UInt64): & {Staking.PoolPublic}? {
        let stakingAddress = Type < Staking > ().address!
        let poolCollectionCap = getAccount(stakingAddress)
        .capabilities.get < &Staking.StakingPoolCollection > (Staking.CollectionPublicPath)

        if! poolCollectionCap.check() {
            return nil
        }

        return poolCollectionCap.borrow()?.getPool(pid: pid)
    }

    access(all) fun getStakedAmount(pid: UInt64, staker: Address): UFix64 {
        let pool = self.borrowPool(pid: pid)
        if pool == nil {
            return 0.0
        }

        let userInfo = pool! .getUserInfo(address: staker)
        return userInfo?.stakingAmount ?? 0.0
    }

    access(all) fun getAvailableRewards(pid: UInt64, staker: Address): UFix64 {
        let pool = self.borrowPool(pid: pid)
        if pool == nil {
            return 0.0
        }

        let userInfo = pool! .getUserInfo(address: staker)
        if userInfo == nil {
            return 0.0
        }

        var totalRewards = 0.0
        for rewardTokenKey in userInfo! .unclaimedRewards.keys {
            totalRewards = totalRewards + (userInfo! .unclaimedRewards[rewardTokenKey] ?? 0.0)
        }

        return totalRewards
    }

    access(all) fun getPoolInfo(pid: UInt64): PoolInfo? {
        let pool = self.borrowPool(pid: pid)
        if pool == nil {
            return nil
        }

        let poolData = pool! .getPoolInfo()

        return PoolInfo(
            pid: pid,
            acceptTokenKey: poolData.acceptTokenKey,
            rewardTokenKeys: poolData.rewardsInfo.keys,
            limitAmount: poolData.limitAmount,
            isActive: poolData.status!= "ENDED" && poolData.status!= "CLEARED"
        )
    }

    init() {
        self.StakingPositionStoragePath = /storage/IncrementFiStakingPosition
        self.StakingPositionPublicPath = /public/IncrementFiStakingPosition
    }
}
