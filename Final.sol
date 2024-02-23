// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserRegistry {
    enum UserType { Manufacturer, RubberTapper, DeliveryRider, CollectionPoint, DistributionCenter, LocalSeller }
    
    struct User {
        address userAddress;
        uint256 personalId;
        string location;
        uint256 businessId;
        string drivingLicenseNumber;
        address manufacturerAddress;
        UserType userType;
    }
    
    mapping(address => User) public users;
    mapping(UserType => address[]) public usersByType;

    event UserCreated(address indexed userAddress, uint256 indexed personalId, UserType userType);
    
    function createUserManufacturer(string memory _location, uint256 _businessId) external {
        address userAddress = address(uint160(uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)))));
        users[userAddress] = User(userAddress,0, _location, _businessId, "", address(0), UserType.Manufacturer);
        usersByType[UserType.Manufacturer].push(userAddress);
        emit UserCreated(userAddress, 0, UserType.Manufacturer);
    }
    
    function createUserRubberTapper(uint256 _personalId, address _collectionPointAddress) external {
        require(users[_collectionPointAddress].userAddress != address(0) && users[_collectionPointAddress].userType == UserType.CollectionPoint, "Invalid collection point address");
        address userAddress = address(uint160(uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)))));
        users[userAddress] = User(userAddress, _personalId, "", 0, "", _collectionPointAddress, UserType.RubberTapper);
        usersByType[UserType.RubberTapper].push(userAddress);
        emit UserCreated(userAddress, _personalId, UserType.RubberTapper);
    }
    
    function createUserDeliveryRider(uint256 _personalId, string memory _drivingLicenseNumber, address _manufacturerAddress) external {
        require(users[_manufacturerAddress].userAddress != address(0) && users[_manufacturerAddress].userType == UserType.Manufacturer, "Invalid manufacturer point address");
        address userAddress = address(uint160(uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)))));
        users[userAddress] = User(userAddress, _personalId, "", 0, _drivingLicenseNumber, _manufacturerAddress, UserType.DeliveryRider);
        usersByType[UserType.DeliveryRider].push(userAddress);
        emit UserCreated(userAddress, _personalId, UserType.DeliveryRider);
    }
    
    function createUserCollectionPoint(string memory _location, address _manufacturerAddress) external {
        require(users[_manufacturerAddress].userAddress != address(0) && users[_manufacturerAddress].userType == UserType.Manufacturer, "Invalid manufacturer point address");
        address userAddress = address(uint160(uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)))));
        users[userAddress] = User(userAddress, 0, _location, 0, "", _manufacturerAddress, UserType.CollectionPoint);
        usersByType[UserType.CollectionPoint].push(userAddress);
        emit UserCreated(userAddress, 0, UserType.CollectionPoint);
    }
    
    function createUserDistributionCenter(string memory _location, address _manufacturerAddress) external {
        require(users[_manufacturerAddress].userAddress != address(0) && users[_manufacturerAddress].userType == UserType.Manufacturer, "Invalid manufacturer point address");
        address userAddress = address(uint160(uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)))));
        users[userAddress] = User(userAddress, 0, _location, 0, "", _manufacturerAddress, UserType.DistributionCenter);
        usersByType[UserType.DistributionCenter].push(userAddress);
        emit UserCreated(userAddress, 0, UserType.DistributionCenter);
    }
    
    function createUserLocalSeller(string memory _location, uint256 _businessId) external {
        address userAddress = address(uint160(uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)))));
        users[userAddress] = User(userAddress, 0, _location, _businessId, "", address(0), UserType.LocalSeller);
        usersByType[UserType.LocalSeller].push(userAddress);
        emit UserCreated(userAddress, 0, UserType.LocalSeller);
    }
    
    function getUsersByType(UserType _userType) external view returns (address[] memory) {
        return usersByType[_userType];
    }
    
    function getUserDetails(address _userAddress) external view returns (User memory) {
        return users[_userAddress];
    }
    
    function isRubberTapper(address _address) public view returns(bool) {
        return users[_address].userAddress != address(0) && users[_address].userType == UserType.RubberTapper;
    }
    
    function isCollector(address _address) public view returns(bool) {
        return users[_address].userAddress != address(0) && users[_address].userType == UserType.CollectionPoint;
    }
    
    function isDeliveryRider(address _address) public view returns(bool) {
        return users[_address].userAddress != address(0) && users[_address].userType == UserType.DeliveryRider;
    }
    
    function isManufacturer(address _address) public view returns(bool) {
        return users[_address].userAddress != address(0) && users[_address].userType == UserType.Manufacturer;
    }

    function isDistributionCenter(address _address) public view returns(bool) {
        return users[_address].userAddress != address(0) && users[_address].userType == UserType.DistributionCenter;
    }

    function isLocalSeller(address _address) public view returns(bool) {
        return users[_address].userAddress != address(0) && users[_address].userType == UserType.LocalSeller;
    }
}

contract BatchRegistry {
    mapping(uint => bool) public batchExists;

    function registerBatch(uint _batchId) external {
        require(!batchExists[_batchId], "Batch already exists");
        batchExists[_batchId] = true;
    }

    function unregisterBatch(uint _batchId) external {
        require(batchExists[_batchId], "Batch does not exist");
        delete batchExists[_batchId];
    }
}

contract RubberTapperToCollector {
    struct LatexDelivery {
        uint quantity;
        uint timestamp;
        address rubberTapper;
        address collector;
    }
    
    mapping(uint => LatexDelivery) public deliveries;
    uint public deliveryCount;
    
    UserRegistry public userRegistry;
    
    event LatexDelivered(uint deliveryId, uint quantity, uint timestamp, address indexed rubberTapper, address indexed collector);
    
    constructor(address _userRegistryAddress) {
        userRegistry = UserRegistry(_userRegistryAddress);
    }
    
    function deliverLatex(uint _quantity, address _rubberTapper, address _collector) public {
        require(userRegistry.isRubberTapper(_rubberTapper), "Invalid rubber tapper address");
        require(userRegistry.isCollector(_collector), "Invalid collector address");
        
        deliveries[deliveryCount] = LatexDelivery(_quantity, block.timestamp, _rubberTapper, _collector);
        emit LatexDelivered(deliveryCount, _quantity, block.timestamp, _rubberTapper, _collector);
        deliveryCount++;
    }
}

contract CollectionPointToDeliveryRider {
    struct LatexCollection {
        uint batchId;
        uint timestamp;
        address collectionPoint;
        address deliveryRider;
    }
    
    mapping(uint => LatexCollection) public collections;
    uint public collectionCount;
    
    UserRegistry public userRegistry;
    BatchRegistry public batchRegistry;
    
    event LatexCollected(uint batchId, uint timestamp, address indexed collectionPoint, address indexed deliveryRider);
    
    constructor(address _userRegistryAddress, address _batchRegistryAddress) {
        userRegistry = UserRegistry(_userRegistryAddress);
        batchRegistry = BatchRegistry(_batchRegistryAddress);
    }
    
    function collectLatex(uint _batchId, address collectionPoint, address _deliveryRider) public {
        require(userRegistry.isDeliveryRider(_deliveryRider), "Invalid delivery rider address");
        require(userRegistry.isCollector(collectionPoint), "Invalid collection point address");
        
        collections[collectionCount] = LatexCollection(_batchId, block.timestamp, collectionPoint, _deliveryRider);
        batchRegistry.registerBatch(_batchId); // Registering the batch
        emit LatexCollected(_batchId, block.timestamp, collectionPoint, _deliveryRider);
        collectionCount++;
    }
}

contract DeliveryRiderToManufacturer {
    struct LatexDelivery {
        uint batchId;
        uint timestamp;
        address deliveryRider;
    }
    
    mapping(uint => LatexDelivery) public deliveries;
    uint public deliveryCount;
    
    UserRegistry public userRegistry;
    BatchRegistry public batchRegistry;
    
    event LatexDelivered(uint batchId, uint timestamp, address indexed deliveryRider);
    
    constructor(address _userRegistryAddress, address _batchRegistryAddress) {
        userRegistry = UserRegistry(_userRegistryAddress);
        batchRegistry = BatchRegistry(_batchRegistryAddress);
    }
    
    function deliverToManufacturer(uint _batchId, address deliveryRider) public {
        require(userRegistry.isDeliveryRider(deliveryRider), "Invalid delivery rider address");
        require(batchRegistry.batchExists(_batchId), "Batch does not exist");
        
        deliveries[deliveryCount] = LatexDelivery(_batchId, block.timestamp, deliveryRider);
        batchRegistry.unregisterBatch(_batchId); // unregistering the batch
        emit LatexDelivered(_batchId, block.timestamp, deliveryRider);
        deliveryCount++;
    }
}

contract ManufacturerToDeliveryRider {
    struct Lot {
        uint batchId;
        uint timestamp;
        address distributionCenter;
        address rider;
    }
    
    mapping(uint => Lot) public lots;
    uint public ItemCount;
    BatchRegistry public batchRegistry;
    
    UserRegistry public userRegistry;
    
    event ItemReceived(uint batchId, uint timestamp, address indexed distributionCenter, address indexed rider);
    
    constructor(address _userRegistryAddress, address _batchRegistryAddress) {
        userRegistry = UserRegistry(_userRegistryAddress);
        batchRegistry = BatchRegistry(_batchRegistryAddress);
    }
    
    function handOverItem(uint _batchId, address _distributionCenter, address deliveryRider) public {
        require(userRegistry.isDeliveryRider(deliveryRider), "Invalid delivery rider address");
        
        lots[ItemCount] = Lot(_batchId, block.timestamp, _distributionCenter, deliveryRider);
        batchRegistry.registerBatch(_batchId); // Registering the batch
        emit ItemReceived(_batchId, block.timestamp, _distributionCenter, deliveryRider);
        ItemCount++;
    }
}

contract DeliveryRiderToDistributionCenter {
    struct Lot {
        uint batchId;
        uint timestamp;
        address distributionCenter;
        address rider;
    }
    
    mapping(uint => Lot) public lots;
    uint public lotCount;
    BatchRegistry public batchRegistry;
    
    UserRegistry public userRegistry;
    
    event LotReceived(uint batchId, uint timestamp, address indexed distributionCenter, address indexed rider);
    
    constructor(address _userRegistryAddress, address _batchRegistryAddress) {
        userRegistry = UserRegistry(_userRegistryAddress);
        batchRegistry = BatchRegistry(_batchRegistryAddress);
    }
    
    function receiveLot(uint _batchId, address distributionCenter, address rider ) public {
        require(userRegistry.isDeliveryRider(rider), "Only delivery riders can deliver lots");
        require(userRegistry.isDistributionCenter(distributionCenter), "Invalid distribution center address");
        require(batchRegistry.batchExists(_batchId), "Batch does not exist");
        
        lots[lotCount] = Lot(_batchId, block.timestamp, distributionCenter, rider);
        emit LotReceived(_batchId, block.timestamp, distributionCenter, rider);
        lotCount++;
    }
}

contract DistributionCenterToDeliveryRider {
    struct StoreDelivery {
        uint batchId;
        uint timestamp;
        address distributionCenter;
        address store;
        address rider;
    }
    
    mapping(uint => StoreDelivery) public deliveries;
    uint public deliveryCount;
    BatchRegistry public batchRegistry;
    
    UserRegistry public userRegistry;
    
    event DeliveryMade(uint batchId, uint timestamp, address indexed distributionCenter, address indexed store, address indexed rider);
    
    constructor(address _userRegistryAddress, address _batchRegistryAddress) {
        userRegistry = UserRegistry(_userRegistryAddress);
        batchRegistry = BatchRegistry(_batchRegistryAddress);
    }
    
    function makeDelivery(uint _batchId, address _store,address distributionCenter, address rider) public {
        require(userRegistry.isDeliveryRider(rider), "Only delivery riders can make deliveries");
        require(userRegistry.isDistributionCenter(distributionCenter), "Invalid Distribution center address");
        require(userRegistry.isLocalSeller(_store), "Invalid store address");
        require(batchRegistry.batchExists(_batchId), "Batch does not exist");

        deliveries[deliveryCount] = StoreDelivery(_batchId, block.timestamp, distributionCenter, _store, rider);
        emit DeliveryMade(_batchId, block.timestamp, distributionCenter, _store, rider);
        deliveryCount++;
    }
}

contract DeliveryRiderToStore {
    struct Delivery {
        uint batchId;
        uint timestamp;
        address deliveryRider;
        address localStore;
    }
    
    mapping(uint => Delivery) public deliveries;
    uint public deliveryCount;
    BatchRegistry public batchRegistry;
    
    UserRegistry public userRegistry;
    
    event DeliveryMade(uint indexed batchId, uint timestamp, address indexed deliveryRider, address indexed localStore);
    
    constructor(address _userRegistryAddress, address _batchRegistryAddress) {
        userRegistry = UserRegistry(_userRegistryAddress);
        batchRegistry = BatchRegistry(_batchRegistryAddress);
    }
    
    function makeDelivery(uint _batchId, address _localStore,  address deliveryRider) public {
        require(userRegistry.isDeliveryRider(deliveryRider), "Only delivery riders can make deliveries");
        require(userRegistry.isLocalSeller(_localStore), "Invalid store address");
        require(batchRegistry.batchExists(_batchId), "Batch does not exist");
        
        deliveries[deliveryCount] = Delivery(_batchId, block.timestamp, deliveryRider, _localStore);
        batchRegistry.unregisterBatch(_batchId); // unregistering the batch
        emit DeliveryMade(_batchId, block.timestamp, deliveryRider, _localStore);
        deliveryCount++;
    }
}

contract EndUserPurchase {
    struct Purchase {
        uint productId;
        uint batchId;
        uint timestamp;
        address store;
    }
    
    mapping(uint => Purchase) public purchases;
    uint public purchaseCount;
    
    UserRegistry public userRegistry;
    
    event ProductPurchased(uint productId, uint batchId, uint timestamp, address indexed store);
    
    constructor(address _userRegistryAddress) {
        userRegistry = UserRegistry(_userRegistryAddress);
    }
    
    function purchaseProduct(uint _productId, uint _batchId, address store) public {
        require(userRegistry.isLocalSeller(store), "Only stores can make purchases");
        
        purchases[purchaseCount] = Purchase(_productId, _batchId, block.timestamp, store);
        emit ProductPurchased(_productId, _batchId, block.timestamp, store);
        purchaseCount++;
    }
}
