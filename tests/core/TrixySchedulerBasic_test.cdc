import Test
import "TrixyTypes"
import "TrixyProtocol"

access(all) fun setup() {
    var err = Test.deployContract(
        name: "Burner",
        path: "../mocks/Burner.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "TrixyTypes",
        path: "../../contracts/core/TrixyTypes.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "TrixyEvents",
        path: "../../contracts/core/TrixyEvents.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "IStakingProtocol",
        path: "../../contracts/interfaces/IStakingProtocol.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "Staking",
        path: "../mocks/Staking.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "IncrementFiStakingConnectors",
        path: "../mocks/IncrementFiStakingConnectors.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "IncrementAdapter",
        path: "../../contracts/adapters/IncrementAdapter.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "DeFiActions",
        path: "../mocks/DeFiActions.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "BandOracle",
        path: "../mocks/BandOracle.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "BandOracleConnectors",
        path: "../mocks/BandOracleConnectors.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "BandOracleResolver",
        path: "../../contracts/resolvers/BandOracleResolver.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "PredictionMarket",
        path: "../../contracts/core/PredictionMarket.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
        name: "TrixyProtocol",
        path: "../../contracts/core/TrixyProtocol.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
}

// Test that scheduler-related paths are added to TrixyProtocol
access(all) fun testSchedulerPathsExist() {
    let schedulerStoragePath = TrixyProtocol.SchedulerManagerStoragePath
    let schedulerPublicPath = TrixyProtocol.SchedulerManagerPublicPath
    
    Test.assertEqual(/storage/TrixySchedulerManager, schedulerStoragePath)
    Test.assertEqual(/public/TrixySchedulerManager, schedulerPublicPath)
}

// Test that protocol still functions normally
access(all) fun testProtocolBasicFunctionality() {
    Test.assertEqual(false, TrixyProtocol.isPaused())
    Test.assertEqual(0.02, TrixyProtocol.getFeePercent())
    
    let adminAddress = TrixyProtocol.getAdminAddress()
    Test.assertEqual(true, adminAddress != nil)
}

// Test that the new events are defined
access(all) fun testNewEventsExist() {
    let marketResolutionScheduledType = Type<TrixyProtocol.MarketResolutionScheduled>()
    let yieldHarvestScheduledType = Type<TrixyProtocol.YieldHarvestScheduled>()
    
    Test.assertEqual(true, marketResolutionScheduledType != nil)
    Test.assertEqual(true, yieldHarvestScheduledType != nil)
}

// Test that createMarketCollection still works
access(all) fun testCreateMarketCollection() {
    let script = "import \"TrixyProtocol\"; access(all) fun main(): Bool { let collection <- TrixyProtocol.createMarketCollection(); destroy collection; return true }"
    let result = Test.executeScript(script, [])
    Test.expect(result, Test.beSucceeded())
    Test.assertEqual(true, result.returnValue! as! Bool)
}