import Test
import "TrixyTypes"

access(all)
fun setup() {
    let err = Test.deployContract(
        name: "TrixyTypes",
        path: "../contracts/core/TrixyTypes.cdc",
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
    let incrementType = TrixyTypes.ProtocolType.Increment
    
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, incrementType)
}

access(all)
fun testGetProtocolType() {
    let increment = TrixyTypes.getProtocolType("Increment")
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, increment)
    
    let unknown = TrixyTypes.getProtocolType("Unknown")
    Test.assertEqual(TrixyTypes.ProtocolType.Increment, unknown)
}
