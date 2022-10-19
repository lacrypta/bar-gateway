//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20PermitGateway} from "@lacrypta/gateway/contracts/ERC20PermitGateway.sol";

contract BarGateway is ERC20PermitGateway {
    constructor(address _peronio) ERC20PermitGateway(_peronio) {}
}
