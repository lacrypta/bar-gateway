//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20PermitGateway} from "lacrypta-gateway/contracts/ERC20PermitGateway.sol";


address constant PERONIO_ADDRESS = 0x78a486306D15E7111cca541F2f1307a1cFCaF5C4;

contract BarGateway is ERC20PermitGateway {

    constructor() ERC20PermitGateway(PERONIO_ADDRESS) {}

    // To obtain message to be signed from voucher: stringifyVoucher(voucher)
    //   The signing procedure _should_ sign the _hash_ of this message
    //
    // To serve a voucher (1): serveVoucher(voucher, r, s, v)
    // To serve a voucher (2): serveVoucher(voucher, sig)
}
