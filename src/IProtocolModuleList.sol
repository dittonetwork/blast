// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IProtocolModuleList - interface of ProtocolModuleList
interface IProtocolModuleList {
    /// @dev Struct representing a module and its details.
    struct Module {
        address moduleAddress;
        bool inactive;
    }

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when the provided selectors array is invalid.
    error ProtocolModuleList_InvalidSelectorsArray();

    /// @notice Thrown when attempting to add a module that already exists.
    error ProtocolModuleList_ModuleAlreadyExists();

    /// @notice Thrown when attempting to deactivate or activate a module that does not exist.
    error ProtocolModuleList_ModuleDoesNotExists();

    // =========================
    // Admin functions
    // =========================

    /// @notice Adds a module and its selectors to the protocol.
    /// @param moduleAddress Address to be added to the protocol.
    function addModule(address moduleAddress) external;

    /// @notice Deactivates a module in the protocol.
    /// @param moduleAddress Address of the module to be deactivated.
    function deactivateModule(address moduleAddress) external;

    /// @notice Activates a previously deactivated module in the protocol.
    /// @param moduleAddress Address of the module to be activated.
    function activateModule(address moduleAddress) external;

    // =========================
    // Getters
    // =========================

    /// @notice Checks if a module is listed in the protocol.
    /// @param moduleAddress Address of the module to check.
    /// @return listed True if the module is listed, false otherwise.
    function listedModule(
        address moduleAddress
    ) external view returns (bool listed);

    /// @notice Checks if a module is currently inactive in the protocol.
    /// @param moduleAddress Address of the module to check.
    /// @return inactive True if the module is inactive, false otherwise.
    function isModuleInactive(
        address moduleAddress
    ) external view returns (bool inactive);
}
