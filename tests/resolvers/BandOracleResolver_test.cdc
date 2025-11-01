import Test
import BlockchainHelpers
import "BandOracleResolver"
import "FlowToken"
import "FungibleToken"

access(all) let serviceAccount = Test.serviceAccount()
access(all) var adminAccount: Test.TestAccount? = nil
access(all) var userAccount: Test.TestAccount? = nil

access(all) fun setup() {
    var err = Test.deployContract(
        name: "Burner",
        path: "../mocks/Burner.cdc",
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
    
    adminAccount = Test.createAccount()
    userAccount = Test.createAccount()
}

// Test basic functionality
access(all) fun testGetSupportedSymbols() {
    let symbols = BandOracleResolver.getSupportedSymbols()
    Test.assertEqual(true, symbols.length > 0)
    Test.assertEqual(true, symbols.contains("FLOW"))
}

access(all) fun testGetAssetConfig() {
    let flowConfig = BandOracleResolver.getAssetConfig(symbol: "FLOW")
    Test.assertEqual(true, flowConfig != nil)
    
    if let config = flowConfig {
        Test.assertEqual("FLOW", config.symbol)
        Test.assertEqual(true, config.enabled)
        Test.assertEqual(0.01, config.minPrice)
        Test.assertEqual(1000.0, config.maxPrice)
        Test.assertEqual(8 as UInt8, config.precision)
    }
    
    let invalidConfig = BandOracleResolver.getAssetConfig(symbol: "INVALID")
    Test.assertEqual(nil, invalidConfig)
}

access(all) fun testGetOracleFee() {
    let fee = BandOracleResolver.getOracleFee()
    Test.assertEqual(true, fee > 0.0)
}

access(all) fun testIsPaused() {
    let paused = BandOracleResolver.isPaused()
    Test.assertEqual(false, paused)
}

// Test ResolutionCriteria creation functions
access(all) fun testCreatePriceTargetCriteria() {
    let criteria = BandOracleResolver.createPriceTargetCriteria(
        symbol: "FLOW",
        targetPrice: 2.0
    )
    
    Test.assertEqual("FLOW", criteria.symbol)
    Test.assertEqual(2.0, criteria.targetPrice)
    Test.assertEqual("ABOVE", criteria.comparisonType)
    Test.assertEqual(nil, criteria.targetPrice2)
}

access(all) fun testCreateMinPriceCriteria() {
    let criteria = BandOracleResolver.createMinPriceCriteria(
        symbol: "FLOW",
        minPrice: 1.5
    )
    
    Test.assertEqual("FLOW", criteria.symbol)
    Test.assertEqual(1.5, criteria.targetPrice)
    Test.assertEqual("ABOVE", criteria.comparisonType)
    Test.assertEqual(nil, criteria.targetPrice2)
}

access(all) fun testCreatePriceRangeCriteria() {
    let criteria = BandOracleResolver.createPriceRangeCriteria(
        symbol: "FLOW",
        minPrice: 1.0,
        maxPrice: 3.0
    )
    
    Test.assertEqual("FLOW", criteria.symbol)
    Test.assertEqual(1.0, criteria.targetPrice)
    Test.assertEqual("BETWEEN", criteria.comparisonType)
    Test.assertEqual(3.0, criteria.targetPrice2!)
}

// Test AssetConfig struct methods
access(all) fun testAssetConfigCreation() {
    let config = BandOracleResolver.AssetConfig(
        symbol: "TEST",
        assetType: Type<@FlowToken.Vault>(),
        enabled: true,
        minPrice: 0.1,
        maxPrice: 100.0,
        precision: 6
    )
    
    Test.assertEqual("TEST", config.symbol)
    Test.assertEqual(Type<@FlowToken.Vault>(), config.assetType)
    Test.assertEqual(true, config.enabled)
    Test.assertEqual(0.1, config.minPrice)
    Test.assertEqual(100.0, config.maxPrice)
    Test.assertEqual(6 as UInt8, config.precision)
}

access(all) fun testAssetConfigSetEnabled() {
    let config = BandOracleResolver.AssetConfig(
        symbol: "TEST",
        assetType: Type<@FlowToken.Vault>(),
        enabled: true,
        minPrice: 0.1,
        maxPrice: 100.0,
        precision: 6
    )
    
    Test.assertEqual(true, config.enabled)
    
    config.setEnabled(false)
    Test.assertEqual(false, config.enabled)
    
    config.setEnabled(true)
    Test.assertEqual(true, config.enabled)
}

access(all) fun testAssetConfigUpdatePriceLimits() {
    let config = BandOracleResolver.AssetConfig(
        symbol: "TEST",
        assetType: Type<@FlowToken.Vault>(),
        enabled: true,
        minPrice: 0.1,
        maxPrice: 100.0,
        precision: 6
    )
    
    Test.assertEqual(0.1, config.minPrice)
    Test.assertEqual(100.0, config.maxPrice)
    
    config.updatePriceLimits(minPrice: 0.5, maxPrice: 200.0)
    Test.assertEqual(0.5, config.minPrice)
    Test.assertEqual(200.0, config.maxPrice)
}

// Test ResolutionCriteria validation
access(all) fun testResolutionCriteriaValidation() {
    // Valid ABOVE criteria
    let validAbove = BandOracleResolver.ResolutionCriteria(
        symbol: "FLOW",
        targetPrice: 2.0,
        comparisonType: "ABOVE",
        targetPrice2: nil
    )
    Test.assertEqual("FLOW", validAbove.symbol)
    
    // Valid BELOW criteria
    let validBelow = BandOracleResolver.ResolutionCriteria(
        symbol: "FLOW",
        targetPrice: 2.0,
        comparisonType: "BELOW",
        targetPrice2: nil
    )
    Test.assertEqual("BELOW", validBelow.comparisonType)
    
    // Valid BETWEEN criteria
    let validBetween = BandOracleResolver.ResolutionCriteria(
        symbol: "FLOW",
        targetPrice: 1.0,
        comparisonType: "BETWEEN",
        targetPrice2: 3.0
    )
    Test.assertEqual("BETWEEN", validBetween.comparisonType)
    Test.assertEqual(3.0, validBetween.targetPrice2!)
}

// Test OracleResult creation
access(all) fun testOracleResultCreation() {
    let successResult = BandOracleResolver.OracleResult(
        canResolve: true,
        outcome: true,
        currentPrice: 2.5,
        dataTimestamp: 1234567890.0,
        error: nil
    )
    
    Test.assertEqual(true, successResult.canResolve)
    Test.assertEqual(true, successResult.outcome)
    Test.assertEqual(2.5, successResult.currentPrice!)
    Test.assertEqual(1234567890.0, successResult.dataTimestamp!)
    Test.assertEqual(nil, successResult.error)
    Test.assertEqual(true, successResult.lastUpdate > 0.0)
    
    let errorResult = BandOracleResolver.OracleResult(
        canResolve: false,
        outcome: false,
        currentPrice: nil,
        dataTimestamp: nil,
        error: "Test error"
    )
    
    Test.assertEqual(false, errorResult.canResolve)
    Test.assertEqual(false, errorResult.outcome)
    Test.assertEqual(nil, errorResult.currentPrice)
    Test.assertEqual(nil, errorResult.dataTimestamp)
    Test.assertEqual("Test error", errorResult.error!)
}

// Test isOracleDataRecent function
access(all) fun testIsOracleDataRecent() {
    let flowVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
    
    // Test with supported symbol
    let isRecentFlow = BandOracleResolver.isOracleDataRecent(
        symbol: "FLOW",
        payment: <- flowVault
    )
    // Should be false because fee source is not configured in test environment
    Test.assertEqual(false, isRecentFlow)
    
    // Test with unsupported symbol
    let flowVault2 <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
    let isRecentInvalid = BandOracleResolver.isOracleDataRecent(
        symbol: "INVALID",
        payment: <- flowVault2
    )
    Test.assertEqual(false, isRecentInvalid)
}

// Test admin storage path
access(all) fun testGetAdminStoragePath() {
    let storagePath = BandOracleResolver.getAdminStoragePath()
    Test.assertEqual(/storage/BandOracleResolverAdmin, storagePath)
}
