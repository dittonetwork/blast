// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "./external/Ownable.sol";
import {IProtocolModuleList} from "./IProtocolModuleList.sol";

/// @title ProtocolModuleList
/// @dev Manages the list of modules added to the protocol, their activation status, and associated selectors.
contract ProtocolModuleList is Ownable, IProtocolModuleList {
    // =========================
    // Storage
    // =========================

    /// @dev List of modules added to the protocol.
    mapping(address moduleAddress => Module) private _module;

    // =========================
    // Admin functions
    // =========================

    /// @inheritdoc IProtocolModuleList
    function addModule(address moduleAddress) external onlyOwner {
        if (_listedModule(moduleAddress)) {
            revert ProtocolModuleList_ModuleAlreadyExists();
        }

        _module[moduleAddress].moduleAddress = moduleAddress;
    }

    /// @inheritdoc IProtocolModuleList
    function deactivateModule(address moduleAddress) external onlyOwner {
        if (!_listedModule(moduleAddress)) {
            revert ProtocolModuleList_ModuleDoesNotExists();
        }

        _module[moduleAddress].inactive = true;
    }

    /// @inheritdoc IProtocolModuleList
    function activateModule(address moduleAddress) external onlyOwner {
        if (!_listedModule(moduleAddress)) {
            revert ProtocolModuleList_ModuleDoesNotExists();
        }

        _module[moduleAddress].inactive = false;
    }

    // =========================
    // Getters
    // =========================

    /// @inheritdoc IProtocolModuleList
    function listedModule(
        address moduleAddress
    ) external view returns (bool listed) {
        return _listedModule(moduleAddress);
    }

    /// @inheritdoc IProtocolModuleList
    function isModuleInactive(
        address moduleAddress
    ) external view returns (bool inactive) {
        return _module[moduleAddress].inactive;
    }

    // =========================
    // Private functions
    // =========================

    /// @dev Checks if a module is listed in the protocol.
    /// @param moduleAddress Address of the module to check.
    /// @return listed True if the module is listed, false otherwise.
    function _listedModule(
        address moduleAddress
    ) private view returns (bool listed) {
        assembly ("memory-safe") {
            mstore(0, moduleAddress)
            mstore(32, _module.slot)

            // bytes array length > 0
            listed := gt(sload(keccak256(0, 64)), 0)
        }
    }
}
