// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage _role, address _account) internal {
    require(_account != address(0));
    require(!has(_role, _account));
    _role.bearer[_account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage _role, address _account) internal {
    require(_account != address(0));
    require(has(_role, _account));
    _role.bearer[_account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage _role, address _account) internal view returns(bool){
    require(_account != address(0));
    return _role.bearer[_account];
  }
 }
