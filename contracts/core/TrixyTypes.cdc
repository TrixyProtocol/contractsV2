access(all) contract TrixyTypes {

    /* --- TYPES --- */

    access(all) enum MarketStatus: UInt8 {
        access(all) case Active
        access(all) case Resolved
        access(all) case Cancelled
    }

    access(all) enum ResolutionMethod: UInt8 {
        access(all) case Manual
        access(all) case Oracle
        access(all) case Automatic
    }

    access(all) struct OracleResolutionCriteria {
        access(all) let symbol: String
        access(all) let targetPrice: UFix64
        access(all) let comparisonType: String // "ABOVE", "BELOW", "BETWEEN"
        access(all) let targetPrice2: UFix64?
        access(all) let resolutionDeadline: UFix64

        init(
            symbol: String,
            targetPrice: UFix64,
            comparisonType: String,
            targetPrice2: UFix64?,
            resolutionDeadline: UFix64
        ) {
            pre {
                comparisonType == "ABOVE" || comparisonType == "BELOW" || comparisonType == "BETWEEN": 
                "Invalid comparison type"
                resolutionDeadline > getCurrentBlock().timestamp: "Resolution deadline must be in the future"
            }
            self.symbol = symbol
            self.targetPrice = targetPrice
            self.comparisonType = comparisonType
            self.targetPrice2 = targetPrice2
            self.resolutionDeadline = resolutionDeadline
        }
    }

    access(all) enum ProtocolType: UInt8 {
        access(all) case Increment
    }

    access(all) struct ProtocolStats {
        access(all) let name: String
        access(all) let protocolType: ProtocolType
        access(all) var totalStaked: UFix64
        access(all) var participantCount: UInt64
        access(all) var currentAPY: UFix64
        access(all) var accumulatedYield: UFix64

        init(name: String, protocolType: ProtocolType) {
            self.name = name
            self.protocolType = protocolType
            self.totalStaked = 0.0
            self.participantCount = 0
            self.currentAPY = 0.0
            self.accumulatedYield = 0.0
        }

        access(all) fun updateStake(amount: UFix64) {
            self.totalStaked = self.totalStaked + amount
            self.participantCount = self.participantCount + 1
        }

        access(all) fun updateAPY(newAPY: UFix64) {
            self.currentAPY = newAPY
        }

        access(all) fun addYield(amount: UFix64) {
            self.accumulatedYield = self.accumulatedYield + amount
        }
    }

    access(all) struct UserPosition {
            access(all) let protocol: String
        access(all) let amount: UFix64
        access(all) let stakeTimestamp: UFix64
        access(all) var claimed: Bool
        access(all) var yieldEarned: UFix64

        init(protocol: String, amount: UFix64) {
            self.protocol = protocol
            self.amount = amount
            self.stakeTimestamp = getCurrentBlock().timestamp
            self.claimed = false
            self.yieldEarned = 0.0
        }

        access(all) fun setClaimed() {
            self.claimed = true
        }

        access(all) fun setYield(amount: UFix64) {
            self.yieldEarned = amount
        }
    }

    access(all) struct MarketInfo {
        access(all) let id: UInt64
        access(all) let question: String
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let protocols: [String]
        access(all) let status: MarketStatus
        access(all) let winningProtocol: String?
        access(all) let totalPool: UFix64
        access(all) let protocolStats: {String: ProtocolStats}
        access(all) let creator: Address

        init(
            id: UInt64,
            question: String,
            startTime: UFix64,
            endTime: UFix64,
            protocols: [String],
            status: MarketStatus,
            winningProtocol: String?,
            totalPool: UFix64,
            protocolStats: {String: ProtocolStats},
            creator: Address
        ) {
            self.id = id
            self.question = question
            self.startTime = startTime
            self.endTime = endTime
            self.protocols = protocols
            self.status = status
            self.winningProtocol = winningProtocol
            self.totalPool = totalPool
            self.protocolStats = protocolStats
            self.creator = creator
        }
    }

    access(all) struct BinaryPosition {
        access(all) var yesShares: UFix64
        access(all) var noShares: UFix64
        access(all) var claimed: Bool
        access(all) var yieldEarned: UFix64

        init(yesShares: UFix64, noShares: UFix64) {
            self.yesShares = yesShares
            self.noShares = noShares
            self.claimed = false
            self.yieldEarned = 0.0
        }

        access(all) fun setClaimed() {
            self.claimed = true
        }

        access(all) fun setYield(amount: UFix64) {
            self.yieldEarned = amount
        }
    }

    access(all) struct PredictionMarketInfo {
        access(all) let id: UInt64
        access(all) let question: String
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let yieldProtocol: String
        access(all) let status: MarketStatus
        access(all) let outcome: Bool?
        access(all) let totalYesShares: UFix64
        access(all) let totalNoShares: UFix64
        access(all) let totalYieldEarned: UFix64
        access(all) let totalPool: UFix64
        access(all) let resolutionMethod: ResolutionMethod
        access(all) let oracleCriteria: OracleResolutionCriteria?

        init(
            id: UInt64,
            question: String,
            startTime: UFix64,
            endTime: UFix64,
            yieldProtocol: String,
            status: MarketStatus,
            outcome: Bool?,
            totalYesShares: UFix64,
            totalNoShares: UFix64,
            totalYieldEarned: UFix64,
            totalPool: UFix64,
            resolutionMethod: ResolutionMethod,
            oracleCriteria: OracleResolutionCriteria?
        ) {
            self.id = id
            self.question = question
            self.startTime = startTime
            self.endTime = endTime
            self.yieldProtocol = yieldProtocol
            self.status = status
            self.outcome = outcome
            self.totalYesShares = totalYesShares
            self.totalNoShares = totalNoShares
            self.totalYieldEarned = totalYieldEarned
            self.totalPool = totalPool
            self.resolutionMethod = resolutionMethod
            self.oracleCriteria = oracleCriteria
        }
    }

    access(all) fun getProtocolType(_ name: String): ProtocolType {
        switch name {
            case "Increment": 
                return ProtocolType.Increment
            default: 
                return ProtocolType.Increment
        }
    }
}
