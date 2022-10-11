//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20PermitGateway} from "lacrypta-gateway/contracts/ERC20PermitGateway.sol";


contract BarGateway is ERC20PermitGateway {

    constructor(address _peronio) ERC20PermitGateway(_peronio) {}

    // To obtain message to be signed from voucher: stringifyVoucher(voucher)
    //   The signing procedure _should_ sign the _hash_ of this message
    //
    // To serve a voucher (1): serveVoucher(voucher, r, s, v)
    // To serve a voucher (2): serveVoucher(voucher, sig)
}
