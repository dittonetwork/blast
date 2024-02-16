// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {ProxyAdmin, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {DittoOracleV3} from "../src/DittoOracleV3.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Vault} from "../src/vault/Vault.sol";
import {UpgradeLogic} from "../src/vault/UpgradeLogic.sol";
import {VaultProxyAdmin} from "../src/VaultProxyAdmin.sol";

import {ProtocolFees} from "../src/ProtocolFees.sol";
import {ProtocolModuleList} from "../src/ProtocolModuleList.sol";

import {AccountAbstractionLogic} from "../src/vault/logics/AccountAbstractionLogic.sol";

import {VersionUpgradeLogic} from "../src/vault/logics/VersionUpgradeLogic.sol";
import {AccessControlLogic} from "../src/vault/logics/AccessControlLogic.sol";
import {EntryPointLogic} from "../src/vault/logics/EntryPointLogic.sol";
import {ExecutionLogic} from "../src/vault/logics/ExecutionLogic.sol";
import {VaultLogic} from "../src/vault/logics/VaultLogic.sol";
import {NativeWrapper} from "../src/vault/logics/OurLogic/helpers/NativeWrapper.sol";

import {UniswapLogic} from "../src/vault/logics/OurLogic/dexAutomation/UniswapLogic.sol";

import {DexCheckerLogicUniswap} from "../src/vault/logics/Checkers/DexCheckerLogicUniswap.sol";
import {PriceCheckerLogicUniswap} from "../src/vault/logics/Checkers/PriceCheckerLogicUniswap.sol";
import {PriceDifferenceCheckerLogicUniswap} from "../src/vault/logics/Checkers/PriceDifferenceCheckerLogicUniswap.sol";
import {TimeCheckerLogic} from "../src/vault/logics/Checkers/TimeCheckerLogic.sol";

import {DeployEngine} from "./DeployEngine.sol";
import {Registry} from "./Registry.sol";

contract FullDeploy is Script {
    bytes32 constant salt = keccak256("DEV-1");

    bytes32 saltProd = keccak256("BETA-1");

    bool prod;

    function run(bool addImpl, bool _prod) external virtual {
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        prod = _prod;

        Registry.Contracts memory reg = deployFactory();
        reg = deploySystemContracts(false, reg);
        reg = deployAndAddModules(false, reg, deployer);

        if (addImpl) {
            addImplementation(reg, false, deployer);
        }

        vm.stopBroadcast();
    }

    function deployFactory() public returns (Registry.Contracts memory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        Registry.Contracts memory reg = Registry.contractsByChainId(
            block.chainid
        );

        if (address(reg.vaultFactoryProxyAdmin) == address(0)) {
            reg.vaultFactoryProxyAdmin = new ProxyAdmin();
        }

        if (
            prod
                ? address(reg.vaultFactoryProxyProd) == address(0)
                : address(reg.vaultFactoryProxy) == address(0)
        ) {
            if (reg.logics.vaultUpgradeLogic == address(0)) {
                // upgrade logic
                reg.logics.vaultUpgradeLogic = address(new UpgradeLogic());
            }

            if (prod) {
                if (address(reg.vaultProxyAdminProd) == address(0)) {
                    // proxy admin
                    // must be same on all networks (w/o salt)
                    reg.vaultProxyAdminProd = new VaultProxyAdmin(
                        0xaB5F025297E40bd5ECf340d1709008eFF230C6cA // <-- prod factory
                        // (put ur address here)
                    );
                }
            } else {
                if (address(reg.vaultProxyAdmin) == address(0)) {
                    // proxy admin
                    // must be same on all networks (w/o salt)
                    reg.vaultProxyAdmin = new VaultProxyAdmin(
                        0xF03C8CaB74b5721eB81210592C9B06f662e9951E // <-- dev factory
                        // (put ur address here)
                    );
                }
            }

            // vault factory
            VaultFactory _vaultFactory = new VaultFactory{
                salt: prod ? saltProd : salt
            }(
                reg.logics.vaultUpgradeLogic,
                prod
                    ? address(reg.vaultProxyAdminProd)
                    : address(reg.vaultProxyAdmin)
            );

            _vaultFactory.upgradeLogic();
            _vaultFactory.vaultProxyAdmin();

            if (prod) {
                reg.vaultFactoryProxyProd = ITransparentUpgradeableProxy(
                    address(
                        new TransparentUpgradeableProxy{salt: saltProd}(
                            address(_vaultFactory),
                            // make sure that the vaultFactoryProxyAdmin is not address(0)
                            // from dev
                            address(reg.vaultFactoryProxyAdmin),
                            abi.encodeCall(
                                VaultFactory.initialize,
                                (vm.addr(deployerPrivateKey))
                            )
                        )
                    )
                );

                VaultFactory vaultFactory_ = VaultFactory(
                    address(reg.vaultFactoryProxyProd)
                );

                if (vaultFactory_.entryPointCreator() == address(0)) {
                    vaultFactory_.setEntryPointCreatorAddress(
                        reg.entryPointCreator
                    );
                }

                if (vaultFactory_.entryPoint() == address(0)) {
                    vaultFactory_.setEntryPointAddress(reg.entryPoint);
                }

                vaultFactory_.addStake{value: 0.005e18}(type(uint32).max);
            } else {
                reg.vaultFactoryProxy = ITransparentUpgradeableProxy(
                    address(
                        new TransparentUpgradeableProxy(
                            address(_vaultFactory),
                            address(reg.vaultFactoryProxyAdmin),
                            abi.encodeCall(
                                VaultFactory.initialize,
                                (vm.addr(deployerPrivateKey))
                            )
                        )
                    )
                );

                VaultFactory vaultFactory_ = VaultFactory(
                    address(reg.vaultFactoryProxy)
                );

                if (vaultFactory_.entryPointCreator() == address(0)) {
                    vaultFactory_.setEntryPointCreatorAddress(
                        reg.entryPointCreator
                    );
                }

                if (vaultFactory_.entryPoint() == address(0)) {
                    vaultFactory_.setEntryPointAddress(reg.entryPoint);
                }

                vaultFactory_.addStake{value: 0.005e18}(type(uint32).max);
            }
        }

        if (prod) {
            if (address(reg.protocolFeesProd) == address(0)) {
                // prod protocol fees
                reg.protocolFeesProd = new ProtocolFees{salt: saltProd}(
                    vm.addr(deployerPrivateKey)
                );
            }
        } else {
            if (address(reg.protocolFees) == address(0)) {
                // dev protocol fees
                reg.protocolFees = new ProtocolFees{salt: salt}(
                    vm.addr(deployerPrivateKey)
                );
            }
        }

        return reg;
    }

    function addImplementation(
        Registry.Contracts memory reg,
        bool test,
        address owner
    ) public returns (VaultFactory vaultFactory, Vault vault) {
        (bytes4[] memory selectors, address[] memory logicAddresses) = _getData(
            reg.logics
        );

        if (address(reg.vaultFactoryProxyAdmin) == address(0) || test) {
            reg.vaultFactoryProxyAdmin = new ProxyAdmin();
        }

        if (address(reg.vaultFactoryProxy) == address(0) || test) {
            VaultFactory _vaultFactory = new VaultFactory(
                reg.logics.vaultUpgradeLogic,
                address(reg.vaultProxyAdmin)
            );

            reg.vaultFactoryProxy = ITransparentUpgradeableProxy(
                address(
                    new TransparentUpgradeableProxy(
                        address(_vaultFactory),
                        address(reg.vaultFactoryProxyAdmin),
                        abi.encodeCall(VaultFactory.initialize, (owner))
                    )
                )
            );
        }

        vaultFactory = VaultFactory(
            address(prod ? reg.vaultFactoryProxyProd : reg.vaultFactoryProxy)
        );

        if (prod) {
            console2.log("protocolModuleListProd", reg.protocolModuleListProd);
        } else {
            console2.log("protocolModuleList", reg.protocolModuleList);
        }

        vault = new Vault(
            selectors,
            logicAddresses,
            prod ? reg.protocolModuleListProd : reg.protocolModuleList
        );

        vaultFactory.addNewImplementation(address(vault));

        vaultFactory.versions();
    }

    function deploySystemContracts(
        bool test,
        Registry.Contracts memory reg
    ) public returns (Registry.Contracts memory) {
        if (address(reg.dittoOracle) == address(0)) {
            reg.dittoOracle = new DittoOracleV3();
        }

        if (prod) {
            if (reg.protocolModuleListProd == address(0)) {
                reg.protocolModuleListProd = address(new ProtocolModuleList());
            }
        } else {
            if (reg.protocolModuleList == address(0) || test) {
                reg.protocolModuleList = address(new ProtocolModuleList());
            }
        }

        // common logic
        reg.logics.vaultUpgradeLogic = reg.logics.vaultUpgradeLogic ==
            address(0) ||
            test
            ? address(new UpgradeLogic())
            : reg.logics.vaultUpgradeLogic;

        reg.logics.accountAbstractionLogic = reg
            .logics
            .accountAbstractionLogic ==
            address(0) ||
            test
            ? address(new AccountAbstractionLogic(reg.entryPoint))
            : reg.logics.accountAbstractionLogic;

        if (prod) {
            console.log(
                "vaultFactoryProxyProd",
                address(reg.vaultFactoryProxyProd)
            );
            reg.logics.versionUpgradeLogicProd = reg
                .logics
                .versionUpgradeLogicProd == address(0)
                ? address(
                    new VersionUpgradeLogic(
                        VaultFactory(address(reg.vaultFactoryProxyProd))
                    )
                )
                : reg.logics.versionUpgradeLogicProd;
        } else {
            console.log("vaultFactoryProxy", address(reg.vaultFactoryProxy));
            reg.logics.versionUpgradeLogic = reg.logics.versionUpgradeLogic ==
                address(0)
                ? address(
                    new VersionUpgradeLogic(
                        VaultFactory(address(reg.vaultFactoryProxy))
                    )
                )
                : reg.logics.versionUpgradeLogic;
        }

        reg.logics.accessControlLogic = reg.logics.accessControlLogic ==
            address(0) ||
            test
            ? address(new AccessControlLogic())
            : reg.logics.accessControlLogic;

        if (prod) {
            console.log("protocolFeesProd", address(reg.protocolFeesProd));
            reg.logics.entryPointLogicProd = reg.logics.entryPointLogicProd ==
                address(0)
                ? address(
                    new EntryPointLogic(
                        reg.automateGelato,
                        reg.protocolFeesProd
                    )
                )
                : reg.logics.entryPointLogicProd;

            reg.logics.executionLogicProd = reg.logics.executionLogicProd ==
                address(0)
                ? address(new ExecutionLogic(reg.protocolFeesProd))
                : reg.logics.executionLogicProd;
        } else {
            console.log("protocolFees", address(reg.protocolFees));
            reg.logics.entryPointLogic = reg.logics.entryPointLogic ==
                address(0) ||
                test
                ? address(
                    new EntryPointLogic(reg.automateGelato, reg.protocolFees)
                )
                : reg.logics.entryPointLogic;

            reg.logics.executionLogic = reg.logics.executionLogic ==
                address(0) ||
                test
                ? address(new ExecutionLogic(reg.protocolFees))
                : reg.logics.executionLogic;
        }

        reg.logics.vaultLogic = reg.logics.vaultLogic == address(0) || test
            ? address(new VaultLogic())
            : reg.logics.vaultLogic;

        reg.logics.nativeWrapper = reg.logics.nativeWrapper == address(0) ||
            (test && reg.logics.nativeWrapper != address(1))
            ? address(new NativeWrapper(reg.wrappedNative))
            : reg.logics.nativeWrapper;

        // uniswap
        reg.logics.uniswapLogic = reg.logics.uniswapLogic == address(0) || test
            ? address(
                new UniswapLogic(
                    reg.uniswapNFTPositionManager,
                    reg.uniswapRouter,
                    reg.uniswapFactory,
                    reg.wrappedNative
                )
            )
            : reg.logics.uniswapLogic;

        // time checker
        reg.logics.timeCheckerLogic = reg.logics.timeCheckerLogic ==
            address(0) ||
            test
            ? address(new TimeCheckerLogic())
            : reg.logics.timeCheckerLogic;

        // price checkers
        reg.logics.priceCheckerLogicUniswap = reg
            .logics
            .priceCheckerLogicUniswap ==
            address(0) ||
            test
            ? address(
                new PriceCheckerLogicUniswap(
                    reg.dittoOracle,
                    address(reg.uniswapFactory)
                )
            )
            : reg.logics.priceCheckerLogicUniswap;

        reg.logics.priceDifferenceCheckerLogicUniswap = reg
            .logics
            .priceDifferenceCheckerLogicUniswap ==
            address(0) ||
            test
            ? address(
                new PriceDifferenceCheckerLogicUniswap(
                    reg.dittoOracle,
                    address(reg.uniswapFactory)
                )
            )
            : reg.logics.priceDifferenceCheckerLogicUniswap;

        // uniswap dex checker
        reg.logics.uniswapDexCheckerLogic = reg.logics.uniswapDexCheckerLogic ==
            address(0) ||
            test
            ? address(
                new DexCheckerLogicUniswap(
                    reg.uniswapFactory,
                    reg.uniswapNFTPositionManager
                )
            )
            : reg.logics.uniswapDexCheckerLogic;

        return reg;
    }

    function deployAndAddModules(
        bool test,
        Registry.Contracts memory reg,
        address initialOwner
    ) public returns (Registry.Contracts memory) {
        test;
        initialOwner;

        prod = prod;

        if (prod) {} else {}

        return reg;
    }

    // -----------------------------

    function _getData(
        Registry.Logics memory logics
    ) internal view returns (bytes4[] memory, address[] memory) {
        bytes4[] memory selectors = new bytes4[](250);
        address[] memory logicAddresses = new address[](250);

        uint256 i;
        uint256 j;

        // AA
        selectors[i++] = AccountAbstractionLogic.entryPointAA.selector;
        selectors[i++] = AccountAbstractionLogic.validateUserOp.selector;
        selectors[i++] = AccountAbstractionLogic.getNonceAA.selector;
        selectors[i++] = AccountAbstractionLogic.getDepositAA.selector;
        selectors[i++] = AccountAbstractionLogic.executeViaEntryPoint.selector;
        selectors[i++] = AccountAbstractionLogic.addDepositAA.selector;
        selectors[i++] = AccountAbstractionLogic.withdrawDepositToAA.selector;
        console2.log("accountAbstractionLogic", logics.accountAbstractionLogic);
        for (uint256 k; k < 7; ++k) {
            logicAddresses[j++] = logics.accountAbstractionLogic;
        }

        // common logic
        selectors[i++] = VersionUpgradeLogic.upgradeVersion.selector;
        if (prod) {
            console2.log(
                "versionUpgradeLogicProd",
                logics.versionUpgradeLogicProd
            );
            logicAddresses[j++] = logics.versionUpgradeLogicProd;
        } else {
            console2.log("versionUpgradeLogic", logics.versionUpgradeLogic);
            logicAddresses[j++] = logics.versionUpgradeLogic;
        }

        selectors[i++] = AccessControlLogic.initializeCreatorAndId.selector;
        selectors[i++] = AccessControlLogic.transferOwnership.selector;
        selectors[i++] = AccessControlLogic
            .setCrossChainLogicInactiveStatus
            .selector;
        selectors[i++] = AccessControlLogic.crossChainLogicIsActive.selector;
        selectors[i++] = AccessControlLogic.hasRole.selector;
        selectors[i++] = AccessControlLogic.creatorAndId.selector;
        selectors[i++] = AccessControlLogic.owner.selector;
        selectors[i++] = AccessControlLogic.isValidSignature.selector;
        selectors[i++] = AccessControlLogic.grantRole.selector;
        selectors[i++] = AccessControlLogic.getVaultProxyAdminAddress.selector;
        selectors[i++] = AccessControlLogic.revokeRole.selector;
        selectors[i++] = AccessControlLogic.renounceRole.selector;
        console2.log("accessControlLogic", logics.accessControlLogic);
        for (uint256 k; k < 12; ++k) {
            logicAddresses[j++] = logics.accessControlLogic;
        }

        selectors[i++] = EntryPointLogic.activateVault.selector;
        selectors[i++] = EntryPointLogic.deactivateVault.selector;
        selectors[i++] = EntryPointLogic.activateWorkflow.selector;
        selectors[i++] = EntryPointLogic.deactivateWorkflow.selector;
        selectors[i++] = EntryPointLogic.isActive.selector;
        selectors[i++] = EntryPointLogic.addWorkflowAndGelatoTask.selector;
        selectors[i++] = EntryPointLogic.addWorkflow.selector;
        selectors[i++] = EntryPointLogic.getNextWorkflowKey.selector;
        selectors[i++] = EntryPointLogic.getWorkflow.selector;
        selectors[i++] = EntryPointLogic.run.selector;
        selectors[i++] = EntryPointLogic.runGelato.selector;
        selectors[i++] = EntryPointLogic.canExecWorkflowCheck.selector;
        selectors[i++] = EntryPointLogic.dedicatedMessageSender.selector;
        selectors[i++] = EntryPointLogic.createTask.selector;
        selectors[i++] = EntryPointLogic.cancelTask.selector;
        selectors[i++] = EntryPointLogic.getTaskId.selector;
        if (prod) {
            console2.log("entryPointLogicProd", logics.entryPointLogicProd);
            for (uint256 k; k < 16; ++k) {
                logicAddresses[j++] = logics.entryPointLogicProd;
            }
        } else {
            console2.log("entryPointLogic", logics.entryPointLogic);
            for (uint256 k; k < 16; ++k) {
                logicAddresses[j++] = logics.entryPointLogic;
            }
        }

        selectors[i++] = ExecutionLogic.onERC721Received.selector;
        selectors[i++] = ExecutionLogic.execute.selector;
        selectors[i++] = ExecutionLogic.multicall.selector;
        selectors[i++] = ExecutionLogic.taxedMulticall.selector;
        if (prod) {
            console2.log("executionLogicProd", logics.executionLogicProd);
            for (uint256 k; k < 4; ++k) {
                logicAddresses[j++] = logics.executionLogicProd;
            }
        } else {
            console2.log("executionLogic", logics.executionLogic);
            for (uint256 k; k < 4; ++k) {
                logicAddresses[j++] = logics.executionLogic;
            }
        }

        selectors[i++] = VaultLogic.depositNative.selector;
        selectors[i++] = VaultLogic.withdrawNative.selector;
        selectors[i++] = VaultLogic.withdrawTotalNative.selector;
        selectors[i++] = VaultLogic.withdrawERC20.selector;
        selectors[i++] = VaultLogic.withdrawTotalERC20.selector;
        selectors[i++] = VaultLogic.depositERC20.selector;
        console2.log("vaultLogic", logics.vaultLogic);
        for (uint256 k; k < 6; ++k) {
            logicAddresses[j++] = logics.vaultLogic;
        }

        if (logics.nativeWrapper != address(1)) {
            selectors[i++] = NativeWrapper.wrapNative.selector;
            selectors[i++] = NativeWrapper.wrapNativeFromVaultBalance.selector;
            selectors[i++] = NativeWrapper.unwrapNative.selector;
            console2.log("nativeWrapper", logics.nativeWrapper);
            for (uint256 k; k < 3; ++k) {
                logicAddresses[j++] = logics.nativeWrapper;
            }
        }

        if (logics.uniswapLogic != address(1)) {
            // dexes
            selectors[i++] = UniswapLogic.uniswapChangeTickRange.selector;
            selectors[i++] = UniswapLogic.uniswapMintNft.selector;
            selectors[i++] = UniswapLogic.uniswapAddLiquidity.selector;
            selectors[i++] = UniswapLogic.uniswapAutoCompound.selector;
            selectors[i++] = UniswapLogic.uniswapSwapExactInput.selector;
            selectors[i++] = UniswapLogic.uniswapSwapExactOutputSingle.selector;
            selectors[i++] = UniswapLogic.uniswapSwapToTargetR.selector;
            selectors[i++] = UniswapLogic
                .uniswapWithdrawPositionByShares
                .selector;
            selectors[i++] = UniswapLogic
                .uniswapWithdrawPositionByLiquidity
                .selector;
            selectors[i++] = UniswapLogic.uniswapCollectFees.selector;
            console2.log("uniswapLogic", logics.uniswapLogic);
            for (uint256 k; k < 10; ++k) {
                logicAddresses[j++] = logics.uniswapLogic;
            }
        }

        // time checker
        selectors[i++] = TimeCheckerLogic.timeCheckerInitialize.selector;
        selectors[i++] = TimeCheckerLogic.checkTime.selector;
        selectors[i++] = TimeCheckerLogic.checkTimeView.selector;
        selectors[i++] = TimeCheckerLogic.setTimePeriod.selector;
        selectors[i++] = TimeCheckerLogic.getLocalTimeCheckerStorage.selector;
        console2.log("timeCheckerLogic", logics.timeCheckerLogic);
        for (uint256 k; k < 5; ++k) {
            logicAddresses[j++] = logics.timeCheckerLogic;
        }

        if (logics.priceCheckerLogicUniswap != address(1)) {
            // price checker uni
            selectors[i++] = PriceCheckerLogicUniswap
                .priceCheckerUniswapInitialize
                .selector;
            selectors[i++] = PriceCheckerLogicUniswap
                .uniswapCheckGTTargetRate
                .selector;
            selectors[i++] = PriceCheckerLogicUniswap
                .uniswapCheckGTETargetRate
                .selector;
            selectors[i++] = PriceCheckerLogicUniswap
                .uniswapCheckLTTargetRate
                .selector;
            selectors[i++] = PriceCheckerLogicUniswap
                .uniswapCheckLTETargetRate
                .selector;
            selectors[i++] = PriceCheckerLogicUniswap
                .uniswapChangeTokensAndFeePriceChecker
                .selector;
            selectors[i++] = PriceCheckerLogicUniswap
                .uniswapChangeTargetRate
                .selector;
            selectors[i++] = PriceCheckerLogicUniswap
                .uniswapGetLocalPriceCheckerStorage
                .selector;
            console2.log(
                "priceCheckerLogicUniswap",
                logics.priceCheckerLogicUniswap
            );
            for (uint256 k; k < 8; ++k) {
                logicAddresses[j++] = logics.priceCheckerLogicUniswap;
            }
        }

        if (logics.priceDifferenceCheckerLogicUniswap != address(1)) {
            // price difference checker uni
            selectors[i++] = PriceDifferenceCheckerLogicUniswap
                .priceDifferenceCheckerUniswapInitialize
                .selector;
            selectors[i++] = PriceDifferenceCheckerLogicUniswap
                .uniswapCheckPriceDifference
                .selector;
            selectors[i++] = PriceDifferenceCheckerLogicUniswap
                .uniswapCheckPriceDifferenceView
                .selector;
            selectors[i++] = PriceDifferenceCheckerLogicUniswap
                .uniswapChangeTokensAndFeePriceDiffChecker
                .selector;
            selectors[i++] = PriceDifferenceCheckerLogicUniswap
                .uniswapChangePercentageDeviationE3
                .selector;
            selectors[i++] = PriceDifferenceCheckerLogicUniswap
                .uniswapGetLocalPriceDifferenceCheckerStorage
                .selector;
            console2.log(
                "priceDifferenceCheckerLogicUniswap",
                logics.priceDifferenceCheckerLogicUniswap
            );
            for (uint256 k; k < 6; ++k) {
                logicAddresses[j++] = logics.priceDifferenceCheckerLogicUniswap;
            }
        }

        if (logics.uniswapDexCheckerLogic != address(1)) {
            // dex checker uniswap
            selectors[i++] = DexCheckerLogicUniswap
                .uniswapDexCheckerInitialize
                .selector;
            selectors[i++] = DexCheckerLogicUniswap
                .uniswapCheckOutOfTickRange
                .selector;
            selectors[i++] = DexCheckerLogicUniswap
                .uniswapCheckInTickRange
                .selector;
            selectors[i++] = DexCheckerLogicUniswap
                .uniswapCheckFeesExistence
                .selector;
            selectors[i++] = DexCheckerLogicUniswap
                .uniswapGetLocalDexCheckerStorage
                .selector;
            console2.log(
                "uniswapDexCheckerLogic",
                logics.uniswapDexCheckerLogic
            );
            for (uint256 k; k < 5; ++k) {
                logicAddresses[j++] = logics.uniswapDexCheckerLogic;
            }
        }

        assembly {
            mstore(selectors, i)
            mstore(logicAddresses, j)
        }

        DeployEngine.quickSort(selectors, logicAddresses);

        return (selectors, logicAddresses);
    }
}
