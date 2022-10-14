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
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract ProposalPayloadE2ETest is Test {
    address public constant AAVE_WHALE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    uint256 public proposalId;

    string public constant MARKET_NAME = "AaveV2Ethereum";

    address public constant FEI_TOKEN = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    address public constant FEI_WHALE = 0x86f6ff8479c69E0cdEa641796b0D3bB1D40761Db;
    address public constant VARIABLE_DEBT_FEI_WHALE = 0x26bdDe6506bd32bD7B5Cc5C73cd252807fF18568;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15745470);

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

    function testPoolActionsPostExecution() public {
        // Pass vote and execute proposal
        GovHelpers.passVoteAndExecute(vm, proposalId);

        uint256 amount = 1000e18;

        vm.startPrank(FEI_WHALE);
        IERC20(FEI_TOKEN).transfer(VARIABLE_DEBT_FEI_WHALE, amount);
        vm.stopPrank();

        // Moving ahead 10000s
        skip(10000);

        uint128 initialVariableBorrowIndex = AaveV2Ethereum.POOL.getReserveData(FEI_TOKEN).variableBorrowIndex;

        // FEI Variable Debt token
        address debtToken = 0xC2e10006AccAb7B45D9184FcF5b7EC7763f5BaAe;
        uint256 debtBefore = IERC20(debtToken).balanceOf(VARIABLE_DEBT_FEI_WHALE);

        vm.startPrank(VARIABLE_DEBT_FEI_WHALE);
        AaveV2Ethereum.POOL.repay(FEI_TOKEN, amount, 2, VARIABLE_DEBT_FEI_WHALE);
        vm.stopPrank();

        uint256 debtAfter = IERC20(debtToken).balanceOf(VARIABLE_DEBT_FEI_WHALE);
        assertEq(debtAfter, ((debtBefore > amount) ? debtBefore - amount : 0));

        // Moving ahead 10000s
        skip(10000);

        uint128 finalVariableBorrowIndex = AaveV2Ethereum.POOL.getReserveData(FEI_TOKEN).variableBorrowIndex;
        // Variable Borrow Index seems to be staying the same
        assertGt(finalVariableBorrowIndex, initialVariableBorrowIndex);
    }
}
