// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'ConsumerRole' to manage this role - add, remove, check
contract ConsumerRole {

  using Roles for Roles.Role;

  // Define 2 events, one for Adding, and other for Removing
  event ConsumerAdded(address indexed account);
  event ConsumerRemoved(address indexed account);

  // Define a struct 'Consumers' by inheriting from 'Roles' library, struct Role
  Roles.Role private Consumers;

  // In the constructor make the address that deploys this contract the 1st Consumer
  constructor() {
    _addConsumer(msg.sender);
  }

  // Define a modifier that checks to see if msg.sender has the appropriate role
  modifier onlyConsumer() {
    require(isConsumer(msg.sender));
    _;
  }

  // Define a function 'isConsumer' to check this role
  function isConsumer(address _account) public view returns (bool) {
    return Consumers.has(_account);
  }

  // Define a function 'addConsumer' that adds this role
  function addConsumer(address _account) public onlyConsumer {
    _addConsumer(_account);
  }

  // Define a function 'renounceConsumer' to renounce this role
  function renounceConsumer() public {
    _removeConsumer(msg.sender);
  }

  // Define an internal function '_addConsumer' to add this role, called by 'addConsumer'
  function _addConsumer(address _account) internal {
    Consumers.add(_account);
    emit ConsumerAdded(_account);
  }

  // Define an internal function '_removeConsumer' to remove this role, called by 'removeConsumer'
  function _removeConsumer(address _account) internal {
    Consumers.remove(_account);
    emit ConsumerRemoved(_account);
  }
}
