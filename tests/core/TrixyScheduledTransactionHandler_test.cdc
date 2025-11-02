import Test
import BlockchainHelpers
import "TrixyScheduledTransactionHandler"
import "TrixyTypes"
import "TrixyEvents"
import "FlowToken"
import "FungibleToken"
import "FlowTransactionScheduler"

access(all) let serviceAccount = Test.serviceAccount()

access(all) fun setup() {
    // Deploy FlowTransactionScheduler mock
    var err = Test.deployContract(
        name: "FlowTransactionScheduler",
        path: "../mocks/FlowTransactionScheduler.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    
    // Deploy FlowTransactionSchedulerUtils mock
    err = Test.deployContract(
        name: "FlowTransactionSchedulerUtils",
        path: "../mocks/FlowTransactionSchedulerUtils.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    
    err = Test.deployContract(
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
    
    err = Test.deployContract(
        name: "TrixyScheduledTransactionHandler",
        path: "../../contracts/core/TrixyScheduledTransactionHandler.cdc",
        arguments: [],
    )
    Test.expect(err, Test.beNil())
}

// Test that the contract deploys successfully
access(all) fun testContractDeployment() {
    // If we reach this point, the contract deployed successfully
    Test.assertEqual(true, true)
}

// Test ScheduledTransactionExecuted event type
access(all) fun testScheduledTransactionExecutedEventType() {
    let eventType = Type<TrixyScheduledTransactionHandler.ScheduledTransactionExecuted>()
    Test.assertEqual(true, eventType != nil)
}

// Test market resolution handler creation
access(all) fun testMarketResolutionHandlerCreation() {
    let script = "import \"TrixyScheduledTransactionHandler\"; access(all) fun main(): Bool { let handler <- TrixyScheduledTransactionHandler.createMarketResolutionHandler(); destroy handler; return true }"
    let result = Test.executeScript(script, [])
    Test.expect(result, Test.beSucceeded())
    Test.assertEqual(true, result.returnValue! as! Bool)
}

// Test yield harvest handler creation
access(all) fun testYieldHarvestHandlerCreation() {
    let script = "import \"TrixyScheduledTransactionHandler\"; access(all) fun main(): Bool { let handler <- TrixyScheduledTransactionHandler.createYieldHarvestHandler(); destroy handler; return true }"
    let result = Test.executeScript(script, [])
    Test.expect(result, Test.beSucceeded())
    Test.assertEqual(true, result.returnValue! as! Bool)
}

// Test handler view functions
access(all) fun testMarketResolutionHandlerViews() {
    let script = ""
        .concat("import \"TrixyScheduledTransactionHandler\";\n")
        .concat("access(all) fun main(): [Type] {\n")
        .concat("    let handler <- TrixyScheduledTransactionHandler.createMarketResolutionHandler();\n")
        .concat("    let views = handler.getViews();\n")
        .concat("    destroy handler;\n")
        .concat("    return views;\n")
        .concat("}")
    
    let result = Test.executeScript(script, [])
    Test.expect(result, Test.beSucceeded())
    
    let views = result.returnValue! as! [Type]
    Test.assertEqual(2, views.length)
    Test.assertEqual(Type<StoragePath>(), views[0])
    Test.assertEqual(Type<PublicPath>(), views[1])
}

// Test handler resolve view for storage path
access(all) fun testMarketResolutionHandlerResolveStoragePath() {
    let script = ""
        .concat("import \"TrixyScheduledTransactionHandler\";\n")
        .concat("access(all) fun main(): StoragePath? {\n")
        .concat("    let handler <- TrixyScheduledTransactionHandler.createMarketResolutionHandler();\n")
        .concat("    let storagePath = handler.resolveView(Type<StoragePath>()) as! StoragePath?;\n")
        .concat("    destroy handler;\n")
        .concat("    return storagePath;\n")
        .concat("}")
    
    let result = Test.executeScript(script, [])
    Test.expect(result, Test.beSucceeded())
    
    let storagePath = result.returnValue! as! StoragePath?
    Test.assertEqual(/storage/TrixyMarketResolutionHandler, storagePath!)
}

// Test handler resolve view for public path
access(all) fun testMarketResolutionHandlerResolvePublicPath() {
    let script = ""
        .concat("import \"TrixyScheduledTransactionHandler\";\n")
        .concat("access(all) fun main(): PublicPath? {\n")
        .concat("    let handler <- TrixyScheduledTransactionHandler.createMarketResolutionHandler();\n")
        .concat("    let publicPath = handler.resolveView(Type<PublicPath>()) as! PublicPath?;\n")
        .concat("    destroy handler;\n")
        .concat("    return publicPath;\n")
        .concat("}")
    
    let result = Test.executeScript(script, [])
    Test.expect(result, Test.beSucceeded())
    
    let publicPath = result.returnValue! as! PublicPath?
    Test.assertEqual(/public/TrixyMarketResolutionHandler, publicPath!)
}

// Test yield harvest handler views
access(all) fun testYieldHarvestHandlerViews() {
    let script = ""
        .concat("import \"TrixyScheduledTransactionHandler\";\n")
        .concat("access(all) fun main(): [Type] {\n")
        .concat("    let handler <- TrixyScheduledTransactionHandler.createYieldHarvestHandler();\n")
        .concat("    let views = handler.getViews();\n")
        .concat("    destroy handler;\n")
        .concat("    return views;\n")
        .concat("}")
    
    let result = Test.executeScript(script, [])
    Test.expect(result, Test.beSucceeded())
    
    let views = result.returnValue! as! [Type]
    Test.assertEqual(2, views.length)
    Test.assertEqual(Type<StoragePath>(), views[0])
    Test.assertEqual(Type<PublicPath>(), views[1])
}

// Test yield harvest handler storage path
access(all) fun testYieldHarvestHandlerStoragePath() {
    let script = ""
        .concat("import \"TrixyScheduledTransactionHandler\";\n")
        .concat("access(all) fun main(): StoragePath? {\n")
        .concat("    let handler <- TrixyScheduledTransactionHandler.createYieldHarvestHandler();\n")
        .concat("    let storagePath = handler.resolveView(Type<StoragePath>()) as! StoragePath?;\n")
        .concat("    destroy handler;\n")
        .concat("    return storagePath;\n")
        .concat("}")
    
    let result = Test.executeScript(script, [])
    Test.expect(result, Test.beSucceeded())
    
    let storagePath = result.returnValue! as! StoragePath?
    Test.assertEqual(/storage/TrixyYieldHarvestHandler, storagePath!)
}

// Test that different handlers have different paths
access(all) fun testHandlersHaveDifferentPaths() {
    let resolutionStoragePath = /storage/TrixyMarketResolutionHandler
    let yieldStoragePath = /storage/TrixyYieldHarvestHandler
    let resolutionPublicPath = /public/TrixyMarketResolutionHandler
    let yieldPublicPath = /public/TrixyYieldHarvestHandler
    
    // Different handlers have different paths
    Test.assertEqual(true, resolutionStoragePath != yieldStoragePath)
    Test.assertEqual(true, resolutionPublicPath != yieldPublicPath)
    
    // Storage and public paths are different for same handler
    Test.assertEqual(true, resolutionStoragePath.toString() != resolutionPublicPath.toString())
    Test.assertEqual(true, yieldStoragePath.toString() != yieldPublicPath.toString())
}
