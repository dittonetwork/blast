// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ProtocolModuleList, IProtocolModuleList} from "../src/ProtocolModuleList.sol";

import {IOwnable} from "../src/external/IOwnable.sol";

import {VaultLogic, IVaultLogic} from "../src/vault/logics/VaultLogic.sol";
import {TimeCheckerLogic, ITimeCheckerLogic} from "../src/vault/logics/Checkers/TimeCheckerLogic.sol";

contract ProtocolModuleListTest is Test {
    ProtocolModuleList protocolModuleList;

    address vaultLogicModule;
    address timeCheckerLogicModule;

    address owner = makeAddr("OWNER");
    address user = makeAddr("USER");

    function setUp() external {
        vm.prank(owner);

        protocolModuleList = new ProtocolModuleList();

        vaultLogicModule = address(new VaultLogic());
        timeCheckerLogicModule = address(new TimeCheckerLogic());
    }

    // =========================
    // addModule
    // =========================

    function test_protocolModuleList_addModule_accessControl() external {
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IOwnable.Ownable_SenderIsNotOwner.selector,
                user
            )
        );
        protocolModuleList.addModule(vaultLogicModule);
    }

    function test_protocolModuleList_addModule_shouldAddModules() external {
        vm.prank(owner);
        protocolModuleList.addModule(vaultLogicModule);

        assertTrue(protocolModuleList.listedModule(vaultLogicModule));
        assertFalse(protocolModuleList.isModuleInactive(vaultLogicModule));

        vm.prank(owner);
        protocolModuleList.addModule(timeCheckerLogicModule);

        assertTrue(protocolModuleList.listedModule(timeCheckerLogicModule));
        assertFalse(
            protocolModuleList.isModuleInactive(timeCheckerLogicModule)
        );
    }

    function test_protocolModuleList_addModule_shouldRevertIfModuleAlreadyAdded()
        external
    {
        vm.prank(owner);
        protocolModuleList.addModule(vaultLogicModule);

        assertTrue(protocolModuleList.listedModule(vaultLogicModule));

        vm.prank(owner);
        vm.expectRevert(
            IProtocolModuleList.ProtocolModuleList_ModuleAlreadyExists.selector
        );
        protocolModuleList.addModule(vaultLogicModule);
    }

    // =========================
    // Activation control
    // =========================

    function test_protocolModuleList_activationModule_accessControl() external {
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IOwnable.Ownable_SenderIsNotOwner.selector,
                user
            )
        );
        protocolModuleList.deactivateModule(vaultLogicModule);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IOwnable.Ownable_SenderIsNotOwner.selector,
                user
            )
        );
        protocolModuleList.activateModule(vaultLogicModule);
    }

    function test_protocolModuleList_activationModule_shouldRevertIfModuleDoesNotExists()
        external
    {
        vm.prank(owner);
        vm.expectRevert(
            IProtocolModuleList.ProtocolModuleList_ModuleDoesNotExists.selector
        );
        protocolModuleList.deactivateModule(vaultLogicModule);

        vm.prank(owner);
        vm.expectRevert(
            IProtocolModuleList.ProtocolModuleList_ModuleDoesNotExists.selector
        );
        protocolModuleList.activateModule(vaultLogicModule);
    }

    function test_protocolModuleList_activationModule_shouldDeactivateAndActivateModule()
        external
    {
        vm.prank(owner);
        protocolModuleList.addModule(vaultLogicModule);

        assertFalse(protocolModuleList.isModuleInactive(vaultLogicModule));

        vm.prank(owner);
        protocolModuleList.deactivateModule(vaultLogicModule);

        assertTrue(protocolModuleList.isModuleInactive(vaultLogicModule));

        vm.prank(owner);
        protocolModuleList.activateModule(vaultLogicModule);

        assertFalse(protocolModuleList.isModuleInactive(vaultLogicModule));
    }
}
