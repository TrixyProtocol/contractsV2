import Test
import "PredictionMarket"
import "TrixyTypes"
import "TrixyEvents"
import "FlowToken"

access(all) fun setup() {
    let err1 = Test.deployContract(
        name: "TrixyTypes",
        path: "../contracts/core/TrixyTypes.cdc",
        arguments: []
    )
    Test.expect(err1, Test.beNil())
    
    let err2 = Test.deployContract(
        name: "TrixyEvents",
        path: "../contracts/core/TrixyEvents.cdc",
        arguments: []
    )
    Test.expect(err2, Test.beNil())
    
    let err3 = Test.deployContract(
        name: "PredictionMarket",
        path: "../contracts/core/PredictionMarket.cdc",
        arguments: []
    )
    Test.expect(err3, Test.beNil())
}

access(all) fun testMarketCreation() {
    let creator = Test.getAccount(0x0000000000000007)
    let currentTime = getCurrentBlock().timestamp
    let endTime = currentTime + 86400.0
    
    let market <- PredictionMarket.createMarket(
        id: 1,
        question: "Will BTC hit $100k?",
        endTime: endTime,
        creator: creator.address,
        yieldProtocol: "aave",
        protocolFee: 0.02
    )
    
    let info = market.getInfo()
    Test.assertEqual(1 as UInt64, info.id)
    Test.assertEqual("Will BTC hit $100k?", info.question)
    Test.assertEqual(TrixyTypes.MarketStatus.Active, info.status)
    
    destroy market
}

access(all) fun testMarketPlaceBet() {
    let creator = Test.getAccount(0x0000000000000007)
    let bettor = Test.getAccount(0x0000000000000008)
    let currentTime = getCurrentBlock().timestamp
    let endTime = currentTime + 86400.0
    
    let market <- PredictionMarket.createMarket(
        id: 2,
        question: "Will ETH hit $5k?",
        endTime: endTime,
        creator: creator.address,
        yieldProtocol: "morpho",
        protocolFee: 0.02
    )
    
    let payment <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
    
    let info = market.getInfo()
    Test.assertEqual(0.0, info.totalYesShares)
    
    destroy market
    destroy payment
}

access(all) fun testMarketResolution() {
    let creator = Test.getAccount(0x0000000000000007)
    let currentTime = getCurrentBlock().timestamp
    let endTime = currentTime + 1.0
    
    let market <- PredictionMarket.createMarket(
        id: 3,
        question: "Test market?",
        endTime: endTime,
        creator: creator.address,
        yieldProtocol: "compound",
        protocolFee: 0.02
    )
    
    destroy market
}
