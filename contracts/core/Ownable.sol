// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

// Provides basic authorization control
contract Ownable {
  address private currentOwner;

  // Define an Event
  event TransferOwnership(address indexed prevOwner, address indexed newOwner);

  constructor () {
      currentOwner = msg.sender;
      emit TransferOwnership(address(0), currentOwner);
  }

  // Look up the address of the owner
  function owner() public view returns (address) {
      return currentOwner;
  }

  // Define a function modifier 'onlyOwner'
  modifier onlyOwner() {
      require(isOwner());
      _;
  }

  // Check if the calling address is the owner of the contract
  function isOwner() public view returns (bool) {
      return msg.sender == currentOwner;
  }

  // Define a function to renounce ownerhip
  function renounceOwnership() public onlyOwner {
      emit TransferOwnership(currentOwner, address(0));
      currentOwner = address(0);
  }

  // Define a public function to transfer ownership
  function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
  }

  // Define an internal function to transfer ownership
  function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0));
      emit TransferOwnership(currentOwner, newOwner);
      currentOwner = newOwner;
  }
}
