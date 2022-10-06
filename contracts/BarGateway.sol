//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20Gateway} from "lacrypta-gateway/contracts/ERC20Gateway.sol";

contract BarGateway is ERC20Gateway {
    constructor(address _token) ERC20Gateway(_token) {}
}
