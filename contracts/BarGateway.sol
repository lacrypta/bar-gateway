//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "lacrypta-gateway/contracts/ERC20Gateway.sol";
import "hardhat/console.sol";

contract BarGateway is ERC20Gateway {
  constructor(address _token, string memory _name)
    ERC20Gateway(_token, _name)
  {}
}
