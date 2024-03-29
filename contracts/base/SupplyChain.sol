// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

// Import all RoleContracts
import '../access/FarmerRole.sol';
import '../access/ManufacturerRole.sol';
import '../access/DistributorRole.sol';
import '../access/RetailerRole.sol';
import '../access/ConsumerRole.sol';

// Define a contract 'Supplychain'
contract SupplyChain is FarmerRole, ManufacturerRole, DistributorRole, RetailerRole, ConsumerRole {

  // Define a struct 'Item' with the following fields:
  struct Item {
    uint    sku;  // Stock Keeping Unit (SKU)
    uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    address payable ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address payable farmerID; // Metamask-Ethereum address of the Farmer
    string  farmName; // Farmer Name
    string  farmCountry; // Farm Location
    string  farmInformation;  // Farmer Information
    uint    productID;  // Product ID potentially a combination of upc + sku
    uint    productPrice; // Product Price
    string  productNotes; // Product Notes
    ProductMarket  productMarketType; // Domestic or International
    State   itemState;  // Product State as represented in the enum above
    address payable manufacturerID; // Metamask-Ethereum address of the Manufacturer
    address payable distributorID;  // Metamask-Ethereum address of the Distributor
    address payable retailerID; // Metamask-Ethereum address of the Retailer
    address payable consumerID; // Metamask-Ethereum address of the Consumer
  }

  // Define 'owner'
  address owner;

  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint  upc;

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
  uint  sku;

  // Define a public mapping 'items' that maps the UPC to an Item.
  mapping (uint => Item) items;

  // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash,
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (uint => string[]) itemsHistory;

  // Define enum 'State' with the following values:
  enum State
  {
    Harvested,  // 0
    RawCottonForSale, // 1
    RawCottonAcquired, // 2
    GinnedAndSpinned, // 3
    RawFabricForSale, // 4
    RawFabricAcquired, // 5
    FinishedGoodForSale, // 6
    FinishedGoodAcquired, // 7
    PackedForExport, // 8
    PackedForRetail, // 9
    PurchasedRetailGoods, // 11
    RetailGoodsForSale, // 12
    ReachedConsumer //13
  }

  State constant defaultState = State.Harvested;

  enum ProductMarket
  {
    ToBeDetermined,
    International,
    Domestic
  }

  ProductMarket constant defaultProductMarket = ProductMarket.ToBeDetermined;

  // Define events
  event Harvested(uint _upc);
  event RawCottonForSale(uint _upc);
  event RawCottonAcquired(uint _upc);
  event GinnedAndSpinned(uint _upc);
  event RawFabricForSale(uint _upc);
  event RawFabricAcquired(uint _upc);
  event FinishedGoodsMade(uint _upc);
  event FinishedGoodsForSale(uint _upc);
  event FinishedGoodsAcquired(uint _upc);
  event PackedForExport(uint _upc);
  event PackedForRetail(uint _upc);
  event PurchasedRetailGoods(uint _upc);
  event RetailGoodsForSale(uint _upc);
  event ReachedConsumer(uint _upc);

  // In the constructor set 'owner' to the address that instantiated the contract
  // Set 'sku' to 1 and set 'upc' to 1
  constructor() payable {
    owner = msg.sender;
    sku = 1;
    upc = 1;
  }

  // Define a modifer that checks to see if msg.sender == owner of the contract
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Define a modifier that checks if an item.state of a upc
  modifier verifyProductState(uint _upc, State _state) {
    require(items[_upc].itemState == _state);
    _;
  }

  // Define a modifer that verifies the Caller
  modifier verifyCallerOwnsProduct (uint _upc) {
    require(msg.sender == items[_upc].ownerID);
    _;
  }

  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnoughForProduct(uint _upc) {
    require(msg.value >= items[_upc].productPrice);
    _;
  }

  // Define a modifier that checks the price and refunds the remaining balance
  modifier returnChange(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    items[_upc].ownerID.transfer(amountToReturn);
  }

  // Define a function 'kill' if required
  function kill() public {
    if (msg.sender == owner) {
      selfdestruct(owner);
    }
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  function harvestCotton(uint _upc,
    address payable _farmerID,
    string memory _farmName,
    string memory _farmCountry,
    string memory _farmInformation,
    string memory _productNotes)
    public
    onlyFarmer {
    // Add the new item as part of Harvest
    Item memory newItem = Item(sku,
                        _upc,
                        msg.sender,
                        _farmerID,
                        _farmName,
                        _farmCountry,
                        _farmInformation,
                        _upc+'-'+sku,
                        0,
                        _productNotes,
                        defaultProductMarket,
                        defaultState,
                        address(0),
                        address(0),
                        address(0),
                        address(0));

    items[_upc] = newItem;
    // Increment sku
    sku = sku + 1;
    // Emit the appropriate event
    emit Harvested(_upc);
  }

  function sellRawCotton(uint _upc, uint _price)
    public
    verifyProductState(_upc, State.Harvested)
    verifyCallerOwnsProduct(_upc)
    onlyFarmer {
    // Update the appropriate fields
    items[_upc].productPrice = _price;
    items[_upc].itemState = State.RawCottonForSale;
    // Emit the appropriate event
    emit RawCottonForSale(_upc);
  }

  function acqireRawCotton(uint _upc)
    public
    payable
    verifyProductState(_upc, State.RawCottonForSale)
    paidEnoughForProduct(_upc)
    returnChange(_upc)
    onlyManufacturer {

    // Transfer money to farmer
    items[_upc].farmerID.transfer(items[_upc].productPrice);

    // Update the appropriate fields - ownerID, distributorID, itemState
    items[_upc].ownerID = msg.sender;
    items[_upc].manufacturerID = msg.sender;
    items[_upc].itemState = State.RawCottonAcquired;

    // emit the appropriate event
    emit RawCottonAcquired(_upc);
  }

  function ginAndSpinCotton(uint _upc)
    public
    verifyProductState(_upc, State.RawCottonAcquired)
    verifyCallerOwnsProduct(_upc)
    onlyManufacturer {
    // Update the appropriate fields
    items[_upc].itemState = State.GinnedAndSpinned;
    // Emit the appropriate event
    emit GinnedAndSpinned(_upc);
  }

  function sellRawFabric(uint _upc, uint _price)
    public
    verifyProductState(_upc, State.GinnedAndSpinned)
    verifyCallerOwnsProduct(_upc)
    onlyManufacturer {
    // Update the appropriate fields
    items[_upc].productPrice = _price;
    items[_upc].itemState = State.RawFabricForSale;
    // Emit the appropriate event
    emit RawFabricForSale(_upc);
  }

  function acqireRawFabric(uint _upc)
    public
    payable
    verifyProductState(_upc, State.RawFabricForSale)
    paidEnoughForProduct(_upc)
    returnChange(_upc)
    onlyDistributor {

    // Transfer money to farmer
    items[_upc].manufacturerID.transfer(items[_upc].productPrice);

    // Update the appropriate fields - ownerID, distributorID, itemState
    items[_upc].ownerID = msg.sender;
    items[_upc].distributorID = msg.sender;
    items[_upc].itemState = State.RawFabricAcquired;
    items[_upc].productMarketType = ProductMarket.International;

    // emit the appropriate event
    emit RawFabricAcquired(_upc);
  }

  function makeFinishedGoods(uint _upc)
    public
    verifyProductState(_upc, State.GinnedAndSpinned)
    verifyCallerOwnsProduct(_upc)
    onlyManufacturer {
    // Update the appropriate fields
    items[_upc].itemState = State.FinishedGoodsMade;
    // Emit the appropriate event
    emit FinishedGoodsMade(_upc);
  }

  function sellFinishedGoods(uint _upc, uint _price)
    public
    verifyProductState(_upc, State.FinishedGoodsMade)
    verifyCallerOwnsProduct(_upc)
    onlyManufacturer {
    // Update the appropriate fields
    items[_upc].productPrice = _price;
    items[_upc].itemState = State.FinishedGoodsForSale;
    // Emit the appropriate event
    emit FinishedGoodsForSale(_upc);
  }

  function acqireFinishedGoods(uint _upc)
    public
    payable
    verifyProductState(_upc, State.FinishedGoodsForSale)
    paidEnoughForProduct(_upc)
    returnChange(_upc)
    onlyDistributor {

    // Transfer money to Manufacturer
    items[_upc].manufacturerID.transfer(items[_upc].productPrice);

    // Update the appropriate fields - ownerID, distributorID, itemState
    items[_upc].ownerID = msg.sender;
    items[_upc].distributorID = msg.sender;
    items[_upc].itemState = State.FinishedGoodsAcquired;

    // emit the appropriate event
    emit FinishedGoodsAcquired(_upc);
  }

  function packForExport(uint _upc, uint _price)
    public
    verifyProductState(_upc, State.FinishedGoodsAcquired)
    verifyCallerOwnsProduct(_upc)
    onlyDistributor {
    // Update the appropriate fields
    items[_upc].itemState = State.PackedForExport;
    items[_upc].productPrice = _price;
    items[_upc].productMarketType = ProductMarket.International;
    // Emit the appropriate event
    emit PackedForExport(_upc);
  }

  function packForRetail(uint _upc, uint _price)
    public
    verifyProductState(_upc, State.FinishedGoodsAcquired)
    verifyCallerOwnsProduct(_upc)
    onlyDistributor {
    // Update the appropriate fields
    items[_upc].itemState = State.PackedForRetail;
    items[_upc].productPrice = _price;
    items[_upc].productMarketType = ProductMarket.Domestic;
    // Emit the appropriate event
    emit PackedForRetail(_upc);
  }

  function buyExportedProduct(uint _upc)
    public
    verifyProductState(_upc, State.PackedForExport)
    paidEnoughForProduct(_upc)
    returnChange(_upc)
    onlyConsumer {
    // Update the appropriate fields
    items[_upc].ownerID = msg.sender;
    items[_upc].consumerID = msg.sender;
    items[_upc].itemState = State.ReachedConsumer;
    // Emit the appropriate event
    emit ReachedConsumer(_upc);
  }

  function buyProductForRetail(uint _upc)
    public
    verifyProductState(_upc, State.PackedForRetail)
    paidEnoughForProduct(_upc)
    returnChange(_upc)
    onlyRetailer {
    // Update the appropriate fields
    items[_upc].ownerID = msg.sender;
    items[_upc].retailerID = msg.sender;
    items[_upc].itemState = State.PurchasedRetailGoods;
    // Emit the appropriate event
    emit PurchasedRetailGoods(_upc);
  }

  function sellRetailGoods(uint _upc, uint _price)
    public
    verifyProductState(_upc, State.PurchasedRetailGoods)
    verifyCallerOwnsProduct(_upc)
    onlyRetailer {
    // Update the appropriate fields
    items[_upc].productPrice = _price;
    items[_upc].itemState = State.RetailGoodsForSale;
    // Emit the appropriate event
    emit RetailGoodsForSale(_upc);
  }

  function buyRetailProduct(uint _upc)
    public
    verifyProductState(_upc, State.RetailGoodsForSale)
    paidEnoughForProduct(_upc)
    returnChange(_upc)
    onlyConsumer {
      // Update the appropriate fields
      items[_upc].ownerID = msg.sender;
      items[_upc].consumerID = msg.sender;
      items[_upc].itemState = State.ReachedConsumer;
      // Emit the appropriate event
      emit ReachedConsumer(_upc);
  }

  function getItemInfo(uint _upc) public view returns (
    uint    _sku,  // Stock Keeping Unit (SKU)
    uint    _itemUpc, // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    address payable _ownerID,  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address payable _farmerID, // Metamask-Ethereum address of the Farmer
    string memory _farmName, // Farmer Name
    string memory _farmCountry, // Farm Location
    string memory _farmInformation,  // Farmer Information
    uint    _productID,  // Product ID potentially a combination of upc + sku
    uint    _productPrice, // Product Price
    string memory _productNotes, // Product Notes
    uint  _productMarketType, // Domestic or International
    uint   _itemState,  // Product State as represented in the enum above
    address payable _manufacturerID, // Metamask-Ethereum address of the Manufacturer
    address payable _distributorID,  // Metamask-Ethereum address of the Distributor
    address payable _retailerID, // Metamask-Ethereum address of the Retailer
    address payable _consumerID // Metamask-Ethereum address of the Consumer
  ) {
    _sku = items[_upc].sku;
    _itemUpc = items[_upc].upc;
    _ownerID = items[_upc].ownerID;
    _farmerID = items[_upc].farmerID;
    _farmName = items[_upc].farmName;
    _farmCountry = items[_upc].farmCountry;
    _farmInformation = items[_upc].farmInformation;
    _productID = items[_upc].productID;
    _productPrice = items[_upc].productPrice;
    _productNotes = items[_upc].productNotes;
    _productMarketType = uint(items[_upc].productMarketType);
    _itemState = uint(items[_upc].itemState);
    _manufacturerID = items[_upc].manufacturerID;
    _distributorID = items[_upc].distributorID;
    _retailerID = items[_upc].retailerID;
    _consumerID = items[_upc].consumerID;
  }

}
