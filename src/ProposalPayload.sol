// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title Aave FEI Reserve Factor Update
 * @author Llama
 * @notice This payload sets the reserve factor to 99% for FEI in Aave v2 pool on mainnet
 * Governance Forum Post:
 * Snapshot:
 */
contract ProposalPayload {
    address public constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveFactor(FEI, 9_900);
    }
}
