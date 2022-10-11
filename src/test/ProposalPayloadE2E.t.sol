// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {ProposalPayload} from "../ProposalPayload.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {AaveV2Helpers, ReserveConfig} from "./utils/AaveV2Helpers.sol";

contract ProposalPayloadE2ETest is Test {
    address public constant AAVE_WHALE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    uint256 public proposalId;

    string public constant MARKET_NAME = "AaveV2Ethereum";

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));

        // Deploy Payload
        ProposalPayload proposalPayload = new ProposalPayload();

        // Create Proposal
        vm.prank(AAVE_WHALE);
        proposalId = DeployMainnetProposal._deployMainnetProposal(
            address(proposalPayload),
            0x344d3181f08b3186228b93bac0005a3a961238164b8b06cbb5f0428a9180b8a7 // TODO: Replace with actual IPFS Hash
        );
    }

    function testExecute() public {
        ReserveConfig[] memory allConfigsBefore = AaveV2Helpers._getReservesConfigs(false, MARKET_NAME);
        ReserveConfig memory feiConfigBefore = AaveV2Helpers._findReserveConfig(allConfigsBefore, "FEI", true);
        assertEq(feiConfigBefore.reserveFactor, 10_000);

        // Pass vote and execute proposal
        GovHelpers.passVoteAndExecute(vm, proposalId);

        ReserveConfig[] memory allConfigsAfter = AaveV2Helpers._getReservesConfigs(false, MARKET_NAME);
        ReserveConfig memory feiConfigAfter = AaveV2Helpers._findReserveConfig(allConfigsAfter, "FEI", true);
        assertEq(feiConfigAfter.reserveFactor, 9_900);
    }
}
