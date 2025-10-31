import Test
import TrixyTypes from "../contracts/core/TrixyTypes.cdc"

access(all)
fun setup() {
    let code = Test.readFile("../contracts/core/TrixyTypes.cdc")
    let err = Test.deployContract(
        name: "TrixyTypes",
        code: code,
        arguments: []
    )
    Test.expect(err, Test.beNil())
}

access(all)
fun testMarketStatusEnum() {
    let activeStatus = TrixyTypes.MarketStatus.Active
    let resolvedStatus = TrixyTypes.MarketStatus.Resolved
    let cancelledStatus = TrixyTypes.MarketStatus.Cancelled
    
    Test.assertEqual(TrixyTypes.MarketStatus.Active, activeStatus)
    Test.assertEqual(TrixyTypes.MarketStatus.Resolved, resolvedStatus)
    Test.assertEqual(TrixyTypes.MarketStatus.Cancelled, cancelledStatus)
}

access(all)
fun testBinaryPosition() {
    let position = TrixyTypes.BinaryPosition(
        yesShares: 100.0,
        noShares: 50.0
    )
    
    Test.assertEqual(100.0, position.yesShares)
    Test.assertEqual(50.0, position.noShares)
    Test.assertEqual(false, position.claimed)
    Test.assertEqual(0.0, position.yieldEarned)
}

access(all)
fun testBinaryPositionSetClaimed() {
    var position = TrixyTypes.BinaryPosition(
        yesShares: 100.0,
        noShares: 50.0
    )
    
    Test.assertEqual(false, position.claimed)
    position.setClaimed()
    Test.assertEqual(true, position.claimed)
}

access(all)
fun testProtocolType() {
    let ankrType = TrixyTypes.ProtocolType.Ankr
    let incrementType = TrixyTypes.ProtocolType.Increment
    let figmentType = TrixyTypes.ProtocolType.Figment
    
    Test.assertEqual(TrixyTypes.ProtocolType.Ankr, ankrType)
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, incrementType)
    Test.assertEqual(TrixyTypes.ProtocolType.Figment, figmentType)
}

access(all)
fun testGetProtocolType() {
    let ankr = TrixyTypes.getProtocolType("Ankr")
    Test.assertEqual(TrixyTypes.ProtocolType.Ankr, ankr)
    
    let increment = TrixyTypes.getProtocolType("Increment")
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, increment)
    
    let figment = TrixyTypes.getProtocolType("Figment")
    Test.assertEqual(TrixyTypes.ProtocolType.Figment, figment)
    
    let unknown = TrixyTypes.getProtocolType("Unknown")
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, unknown)
}
