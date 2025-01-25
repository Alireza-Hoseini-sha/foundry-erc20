// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract OurTokenTest is StdCheats, Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address public USER = makeAddr("user");
    address public RECIPIENT = makeAddr("recipient");

    uint256 public constant INITIAL_SUPPLY = 1000 ether;
    uint256 public constant TRANSFER_AMOUNT = 10 ether;
    uint256 public constant APPROVE_AMOUNT = 20 ether;

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(address(msg.sender));
        ourToken.transfer(USER, STARTING_BALANCE);
    }

    function testBobBalance() public {
        assertEq(ourToken.balanceOf(USER), STARTING_BALANCE);
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        // Bob Approves Alice to spend tokens on his behalf
        vm.prank(USER);
        ourToken.approve(RECIPIENT, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(RECIPIENT);
        ourToken.transferFrom(USER, RECIPIENT, transferAmount);

        assertEq(ourToken.balanceOf(RECIPIENT), transferAmount);
        assertEq(ourToken.balanceOf(USER), STARTING_BALANCE - transferAmount);
    }

    // Initial Supply Tests
    function testInitialSupply() public {
        assertEq(ourToken.totalSupply(), INITIAL_SUPPLY);
    }

    function testDeployerHasInitialSupply() public {
        assertEq(
            ourToken.balanceOf(msg.sender),
            INITIAL_SUPPLY - STARTING_BALANCE
        );
    }

    // Transfer Tests
    function testTransferTokens() public {
        uint256 initialSenderBalance = ourToken.balanceOf(USER);

        vm.prank(USER);
        ourToken.transfer(RECIPIENT, TRANSFER_AMOUNT);

        assertEq(
            ourToken.balanceOf(USER),
            initialSenderBalance - TRANSFER_AMOUNT
        );
        assertEq(ourToken.balanceOf(RECIPIENT), TRANSFER_AMOUNT);
    }

    function testTransferFailsWithInsufficientBalance() public {
        uint256 excessiveAmount = ourToken.balanceOf(USER) + 1;

        vm.startPrank(USER);
        vm.expectRevert();
        // Expecting a revert with specific error signature and parameters
        vm.expectRevert(IERC20Errors.ERC20InsufficientBalance.selector);
        ourToken.transfer(RECIPIENT, excessiveAmount);
        vm.stopPrank();
    }

    // Allowance and TransferFrom Tests
    function testApproveAllowance() public {
        vm.prank(USER);
        ourToken.approve(RECIPIENT, APPROVE_AMOUNT);

        assertEq(ourToken.allowance(USER, RECIPIENT), APPROVE_AMOUNT);
    }

    function testTransferFromWithinAllowance() public {
        vm.prank(USER);
        ourToken.approve(RECIPIENT, APPROVE_AMOUNT);

        uint256 initialUserBalance = ourToken.balanceOf(USER);

        vm.prank(RECIPIENT);
        ourToken.transferFrom(USER, RECIPIENT, TRANSFER_AMOUNT);

        assertEq(
            ourToken.balanceOf(USER),
            initialUserBalance - TRANSFER_AMOUNT
        );
        assertEq(ourToken.balanceOf(RECIPIENT), TRANSFER_AMOUNT);
        assertEq(
            ourToken.allowance(USER, RECIPIENT),
            APPROVE_AMOUNT - TRANSFER_AMOUNT
        );
    }

    // function testTransferFromExceedsAllowance() public {
    //     vm.prank(USER);
    //     ourToken.approve(RECIPIENT, APPROVE_AMOUNT);

    //     vm.prank(RECIPIENT);
    //     vm.expectRevert(IERC20Errors.ERC20InsufficientAllowance.selector);
    //     ourToken.transferFrom(USER, RECIPIENT, APPROVE_AMOUNT + 1);
    // }

    // Infinite Approval Test
    function testInfiniteApproval() public {
        vm.prank(USER);
        ourToken.approve(RECIPIENT, type(uint256).max);

        assertEq(ourToken.allowance(USER, RECIPIENT), type(uint256).max);
    }

    // Mint and Burn Prevention Tests
    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testOwnerCantMintAdditionally() public {
        vm.prank(msg.sender);
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(msg.sender, 1);
    }

    // Zero Address Transfer Tests
    // function testTransferToZeroAddressFails() public {
    //     vm.prank(USER);
    //     vm.expectRevert(IERC20Errors.ERC20InvalidReceiver.selector);
    //     ourToken.transfer(address(0), TRANSFER_AMOUNT);
    // }

    // function testTransferFromToZeroAddressFails() public {
    //     vm.prank(USER);
    //     ourToken.approve(RECIPIENT, APPROVE_AMOUNT);

    //     vm.prank(RECIPIENT);
    //     vm.expectRevert(0xec442f05);
    //     ourToken.transferFrom(USER, address(0), TRANSFER_AMOUNT);
    // }

    // Allowance Reset Test
    function testAllowanceReset() public {
        vm.prank(USER);
        ourToken.approve(RECIPIENT, APPROVE_AMOUNT);
        assertEq(ourToken.allowance(USER, RECIPIENT), APPROVE_AMOUNT);

        vm.prank(USER);
        ourToken.approve(RECIPIENT, 0);
        assertEq(ourToken.allowance(USER, RECIPIENT), 0);
    }
}

interface MintableToken {
    function mint(address, uint256) external;
}
