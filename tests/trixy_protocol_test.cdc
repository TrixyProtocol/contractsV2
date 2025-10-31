import Test
import "TrixyProtocol"
import "TrixyTypes"
import "TrixyEvents"
import "PredictionMarket"
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
    
    let err4 = Test.deployContract(
        name: "TrixyProtocol",
        path: "../contracts/TrixyProtocol.cdc",
        arguments: []
    )
    Test.expect(err4, Test.beNil())
}

access(all) fun testProtocolInitialization() {
    let feePercent = TrixyProtocol.getFeePercent()
    Test.assertEqual(0.02, feePercent)
    
    let isPaused = TrixyProtocol.isPaused()
    Test.assertEqual(false, isPaused)
}

access(all) fun testCreateMarketCollection() {
    let collection <- TrixyProtocol.createMarketCollection()
    
    let marketIds = collection.getMarketIds()
    Test.assertEqual(0, marketIds.length)
    
    destroy collection
}

access(all) fun testGetAdminAddress() {
    let adminAddress = TrixyProtocol.getAdminAddress()
    Test.expect(adminAddress, Test.beNil())
}
