//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20PermitGateway} from "@lacrypta/gateway/contracts/ERC20PermitGateway.sol";

import {IBarGateway} from "./IBarGateway.sol";

contract BarGateway is ERC20PermitGateway, IBarGateway {
    constructor(address _peronio) ERC20PermitGateway(_peronio) {}
}
