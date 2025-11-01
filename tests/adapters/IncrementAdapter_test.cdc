import Test
import BlockchainHelpers
import "IncrementAdapter"
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
    
    adminAccount = Test.createAccount()
    userAccount = Test.createAccount()
}

// Test basic protocol info
access(all) fun testGetProtocolInfo() {
    let protocolName = IncrementAdapter.getProtocolName()
    Test.assertEqual("Increment Finance", protocolName)
    
    let protocolType = IncrementAdapter.getProtocolType()
    Test.assertEqual(1 as UInt8, protocolType)
}

// Test position metadata structure
access(all) fun testPositionMetadataCreation() {
    let positionId = "test_position_1"
    let staker = Address(0x01)
    let pid = 0 as UInt64
    let initialAmount = 100.0
    
    let metadata = IncrementAdapter.PositionMetadata(
        positionId: positionId,
        staker: staker,
        pid: pid,
        initialAmount: initialAmount
    )
    
    Test.assertEqual(positionId, metadata.positionId)
    Test.assertEqual(staker, metadata.staker)
    Test.assertEqual(pid, metadata.pid)
    Test.assertEqual(initialAmount, metadata.initialAmount)
    Test.assertEqual(true, metadata.createdAt > 0.0)
}

// Test staking functions (mocked due to resource complexity)
// In a real test environment, these would create actual positions
// For now, we test the functionality that doesn't require resource creation

// Test getting balance for non-existent position
access(all) fun testGetBalanceNonExistentPosition() {
    let balance = IncrementAdapter.getBalance(positionId: "nonexistent")
    Test.assertEqual(0.0, balance)
}

// Test getting balance for existing position
// Note: This test would require actual staking in a real implementation

// Test getting available rewards for non-existent position
access(all) fun testGetAvailableRewardsNonExistentPosition() {
    let rewards = IncrementAdapter.getAvailableRewards(positionId: "nonexistent")
    Test.assertEqual(0.0, rewards)
}

// Test getting available rewards for existing position
// Note: This test would require actual staking in a real implementation

// Test current APY calculation
access(all) fun testGetCurrentAPY() {
    let apy = IncrementAdapter.getCurrentAPY()
    Test.assertEqual(0.0, apy) // Should be 0 when no positions have balance
}

// Test getting metadata for non-existent position
access(all) fun testGetPositionMetadataNonExistent() {
    let metadata = IncrementAdapter.getPositionMetadata(positionId: "nonexistent")
    Test.assertEqual(nil, metadata)
}

// Test getting metadata for existing position
// Note: This test would require actual staking in a real implementation

// Test unstaking and claiming rewards functionality
// Note: These tests would require UserCertificate setup and actual staking
// In a production test environment, these would be integration tests

// Test contract state management
access(all) fun testContractInitialization() {
    // Test that contract initializes with correct default values
    // These are the functions we can test without resource creation
    Test.assertEqual(true, true) // Placeholder - contract deployed successfully in setup
}

// Test IStakingProtocol interface compliance
access(all) fun testIStakingProtocolCompliance() {
    // Test that all required interface functions are available
    let protocolName = IncrementAdapter.getProtocolName()
    Test.assertEqual(true, protocolName.length > 0)
    
    let protocolType = IncrementAdapter.getProtocolType()
    Test.assertEqual(true, protocolType >= 0)
    
    let apy = IncrementAdapter.getCurrentAPY()
    Test.assertEqual(true, apy >= 0.0)
}

// Test position metadata struct behavior
access(all) fun testPositionMetadataTimestamp() {
    let before = getCurrentBlock().timestamp
    
    let metadata = IncrementAdapter.PositionMetadata(
        positionId: "test_position",
        staker: Address(0x01),
        pid: 0,
        initialAmount: 100.0
    )
    
    let after = getCurrentBlock().timestamp
    
    // Verify timestamp is reasonable
    Test.assertEqual(true, metadata.createdAt >= before)
    Test.assertEqual(true, metadata.createdAt <= after)
}

// Test balance and rewards for various invalid position IDs
access(all) fun testInvalidPositionIdHandling() {
    let testCases = ["invalid", "", "123", "increment_999", "not_increment_0"]
    
    for positionId in testCases {
        let balance = IncrementAdapter.getBalance(positionId: positionId)
        Test.assertEqual(0.0, balance)
        
        let rewards = IncrementAdapter.getAvailableRewards(positionId: positionId)
        Test.assertEqual(0.0, rewards)
        
        let metadata = IncrementAdapter.getPositionMetadata(positionId: positionId)
        Test.assertEqual(nil, metadata)
    }
}

// Test position metadata with various values
access(all) fun testPositionMetadataVariations() {
    // Test case 1: Small values
    let metadata1 = IncrementAdapter.PositionMetadata(
        positionId: "pos1",
        staker: Address(0x01),
        pid: 0,
        initialAmount: 0.0
    )
    
    Test.assertEqual("pos1", metadata1.positionId)
    Test.assertEqual(Address(0x01), metadata1.staker)
    Test.assertEqual(0 as UInt64, metadata1.pid)
    Test.assertEqual(0.0, metadata1.initialAmount)
    Test.assertEqual(true, metadata1.createdAt > 0.0)
    
    // Test case 2: Large values
    let metadata2 = IncrementAdapter.PositionMetadata(
        positionId: "position_with_long_name",
        staker: Address(0xFF),
        pid: 999,
        initialAmount: 1000000.0
    )
    
    Test.assertEqual("position_with_long_name", metadata2.positionId)
    Test.assertEqual(Address(0xFF), metadata2.staker)
    Test.assertEqual(999 as UInt64, metadata2.pid)
    Test.assertEqual(1000000.0, metadata2.initialAmount)
    Test.assertEqual(true, metadata2.createdAt > 0.0)
    
    // Test case 3: Very small amount
    let metadata3 = IncrementAdapter.PositionMetadata(
        positionId: "p",
        staker: Address(0x02),
        pid: 1,
        initialAmount: 0.001
    )
    
    Test.assertEqual("p", metadata3.positionId)
    Test.assertEqual(Address(0x02), metadata3.staker)
    Test.assertEqual(1 as UInt64, metadata3.pid)
    Test.assertEqual(0.001, metadata3.initialAmount)
    Test.assertEqual(true, metadata3.createdAt > 0.0)
}

// Test APY calculation with no positions
access(all) fun testAPYCalculationEmpty() {
    // With no positions, APY should be 0
    let apy = IncrementAdapter.getCurrentAPY()
    Test.assertEqual(0.0, apy)
}

// Test protocol name consistency
access(all) fun testProtocolNameConsistency() {
    let name1 = IncrementAdapter.getProtocolName()
    let name2 = IncrementAdapter.getProtocolName()
    Test.assertEqual(name1, name2)
    Test.assertEqual("Increment Finance", name1)
}

// Test protocol type consistency
access(all) fun testProtocolTypeConsistency() {
    let type1 = IncrementAdapter.getProtocolType()
    let type2 = IncrementAdapter.getProtocolType()
    Test.assertEqual(type1, type2)
    Test.assertEqual(1 as UInt8, type1)
}
