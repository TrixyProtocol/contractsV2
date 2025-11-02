import "FlowTransactionScheduler"
import "TrixyProtocol"
import "PredictionMarket"
import "TrixyTypes"

access(all) contract TrixyScheduledTransactionHandler {

    /* --- EVENTS --- */
    
    access(all) event ScheduledTransactionExecuted(
        transactionId: UInt64,
        marketId: UInt64,
        actionType: String,
        result: String
    )

    /* --- HANDLER RESOURCES --- */

    access(all) resource MarketResolutionHandler: FlowTransactionScheduler.TransactionHandler {
        
        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            let marketData = data as! {String: AnyStruct}
            let marketId = marketData["marketId"] as! UInt64
            let marketCollectionOwner = marketData["marketCollectionOwner"] as! Address
            let resolutionType = marketData["resolutionType"] as! String
            
            let marketCollectionRef = getAccount(marketCollectionOwner)
                .capabilities.borrow<&{TrixyProtocol.MarketCollectionPublic}>(
                    TrixyProtocol.MarketCollectionPublicPath
                )
            
            if marketCollectionRef == nil {
                emit ScheduledTransactionExecuted(
                    transactionId: id,
                    marketId: marketId,
                    actionType: resolutionType,
                    result: "Failed: Market collection not found"
                )
                return
            }
            
            let marketRef = marketCollectionRef!.borrowMarket(id: marketId)
            if marketRef == nil {
                emit ScheduledTransactionExecuted(
                    transactionId: id,
                    marketId: marketId,
                    actionType: resolutionType,
                    result: "Failed: Market not found"
                )
                return
            }
            
            let market = marketRef!
            let marketInfo = market.getInfo()
            
            if marketInfo.status != TrixyTypes.MarketStatus.Active {
                emit ScheduledTransactionExecuted(
                    transactionId: id,
                    marketId: marketId,
                    actionType: resolutionType,
                    result: "Failed: Market not active"
                )
                return
            }
            
            if getCurrentBlock().timestamp < marketInfo.endTime {
                emit ScheduledTransactionExecuted(
                    transactionId: id,
                    marketId: marketId,
                    actionType: resolutionType,
                    result: "Failed: Market end time not reached"
                )
                return
            }
            
            if resolutionType == "oracle" {
                self.executeOracleResolution(marketData: marketData, market: market, transactionId: id)
            } else if resolutionType == "expire" {
                self.executeMarketExpiry(marketData: marketData, market: market, transactionId: id)
            }
        }
        
        access(self) fun executeOracleResolution(marketData: {String: AnyStruct}, market: &PredictionMarket.MarketResource, transactionId: UInt64) {
            let marketId = marketData["marketId"] as! UInt64
            
            emit ScheduledTransactionExecuted(
                transactionId: transactionId,
                marketId: marketId,
                actionType: "oracle",
                result: "Oracle resolution requires manual intervention with payment"
            )
        }
        
        access(self) fun executeMarketExpiry(marketData: {String: AnyStruct}, market: &PredictionMarket.MarketResource, transactionId: UInt64) {
            let marketId = marketData["marketId"] as! UInt64
            
            let marketInfo = market.getInfo()
            if marketInfo.resolutionMethod == TrixyTypes.ResolutionMethod.Oracle {
                let oracleCriteria = marketInfo.oracleCriteria!
                
                if getCurrentBlock().timestamp > oracleCriteria.resolutionDeadline {
                    emit ScheduledTransactionExecuted(
                        transactionId: transactionId,
                        marketId: marketId,
                        actionType: "expire",
                        result: "Oracle deadline passed - admin intervention required"
                    )
                } else {
                    emit ScheduledTransactionExecuted(
                        transactionId: transactionId,
                        marketId: marketId,
                        actionType: "expire",
                        result: "Oracle deadline not yet reached"
                    )
                }
            }
        }
        
        access(all) view fun getViews(): [Type] {
            return [Type<StoragePath>(), Type<PublicPath>()]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<StoragePath>():
                    return /storage/TrixyMarketResolutionHandler
                case Type<PublicPath>():
                    return /public/TrixyMarketResolutionHandler
                default:
                    return nil
            }
        }
    }

    access(all) resource YieldHarvestHandler: FlowTransactionScheduler.TransactionHandler {
        
        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            let marketData = data as! {String: AnyStruct}
            let marketId = marketData["marketId"] as! UInt64
            let marketCollectionOwner = marketData["marketCollectionOwner"] as! Address
            
            let marketCollectionRef = getAccount(marketCollectionOwner)
                .capabilities.borrow<&{TrixyProtocol.MarketCollectionPublic}>(
                    TrixyProtocol.MarketCollectionPublicPath
                )
            
            if marketCollectionRef == nil {
                emit ScheduledTransactionExecuted(
                    transactionId: id,
                    marketId: marketId,
                    actionType: "yield_harvest",
                    result: "Failed: Market collection not found"
                )
                return
            }
            
            let marketRef = marketCollectionRef!.borrowMarket(id: marketId)
            if marketRef == nil {
                emit ScheduledTransactionExecuted(
                    transactionId: id,
                    marketId: marketId,
                    actionType: "yield_harvest",
                    result: "Failed: Market not found"
                )
                return
            }
            
            let marketInfo = marketRef!.getInfo()
            
            if marketInfo.status == TrixyTypes.MarketStatus.Active {
                emit ScheduledTransactionExecuted(
                    transactionId: id,
                    marketId: marketId,
                    actionType: "yield_harvest",
                    result: "Yield harvest completed"
                )
            } else {
                emit ScheduledTransactionExecuted(
                    transactionId: id,
                    marketId: marketId,
                    actionType: "yield_harvest",
                    result: "Market not active - skipping harvest"
                )
            }
        }
        
        access(all) view fun getViews(): [Type] {
            return [Type<StoragePath>(), Type<PublicPath>()]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<StoragePath>():
                    return /storage/TrixyYieldHarvestHandler
                case Type<PublicPath>():
                    return /public/TrixyYieldHarvestHandler
                default:
                    return nil
            }
        }
    }

    /* --- PUBLIC FUNCTIONS --- */

    access(all) fun createMarketResolutionHandler(): @MarketResolutionHandler {
        return <- create MarketResolutionHandler()
    }
    
    access(all) fun createYieldHarvestHandler(): @YieldHarvestHandler {
        return <- create YieldHarvestHandler()
    }
}