// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProxyAdmin, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {IDittoOracleV3} from "../src/vault/interfaces/IDittoOracleV3.sol";

import {ProtocolFees} from "../src/ProtocolFees.sol";

import {IAutomate} from "@gelato/contracts/integrations/Types.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import {VaultProxyAdmin} from "../src/VaultProxyAdmin.sol";
import {UpgradeLogic} from "../src/vault/UpgradeLogic.sol";
import {IWETH9} from "../src/vault/interfaces/external/IWETH9.sol";
import {IV3SwapRouter} from "../src/vault/interfaces/external/IV3SwapRouter.sol";
import {AaveLogicLens} from "../src/lens/AaveLogicLens.sol";
import {DexLogicLens} from "../src/lens/DexLogicLens.sol";

library Registry {
    struct Contracts {
        ProxyAdmin vaultFactoryProxyAdmin;
        address vaultFactoryImplementation;
        address vaultFactoryImplementationProd;
        ITransparentUpgradeableProxy vaultFactoryProxy;
        ITransparentUpgradeableProxy vaultFactoryProxyProd;
        VaultProxyAdmin vaultProxyAdmin;
        VaultProxyAdmin vaultProxyAdminProd;
        IDittoOracleV3 dittoOracle;
        ProtocolFees protocolFees;
        ProtocolFees protocolFeesProd;
        address protocolModuleList;
        address protocolModuleListProd;
        IWETH9 wrappedNative;
        IV3SwapRouter uniswapRouter;
        IUniswapV3Factory uniswapFactory;
        INonfungiblePositionManager uniswapNFTPositionManager;
        IAutomate automateGelato;
        address entryPoint;
        address entryPointCreator;
        Logics logics;
        Modules modules;
    }

    struct Logics {
        address vaultUpgradeLogic;
        address accountAbstractionLogic;
        address versionUpgradeLogic;
        address versionUpgradeLogicProd;
        address accessControlLogic;
        address entryPointLogic;
        address entryPointLogicProd;
        address executionLogic;
        address executionLogicProd;
        address vaultLogic;
        address nativeWrapper;
        address uniswapLogic;
        address timeCheckerLogic;
        address priceCheckerLogicUniswap;
        address priceDifferenceCheckerLogicUniswap;
        address uniswapDexCheckerLogic;
    }

    struct Modules {
        address a;
    }

    error InvalidChainId();

    // Blast sepolia
    function _168587773() internal pure returns (Contracts memory reg) {
        Logics memory logics;

        logics.vaultUpgradeLogic = 0xB5047973F9922d04d7d69dC5A2DCd350A51A1833; //
        logics
            .accountAbstractionLogic = 0x162eE1F1b1d15c8908344f9991A34E526E888c75; //
        logics.versionUpgradeLogic = 0x14880E9AB3D81C6e9E45aF30A690073472E49cfc; //
        logics.accessControlLogic = 0xBC2DDDa755178Ce1f0AB78590744ee65ebF76b35; //
        logics.entryPointLogic = 0x81536efF4B03B468D1f6F37621Ec0a96E51052b4; //
        logics.executionLogic = 0xd7713E7525476b938E889A93e38025e26F5C51cd; //
        logics.vaultLogic = 0xCf0fbDECd154E0a60b5b521b434DD4aF6dA57D1E; //
        logics.nativeWrapper = 0x93926188A0C4c681193470Dd36f468D30a5705C2; //
        logics.timeCheckerLogic = 0xC097f59bfD97C6FC667F4ba4Bed780e2f9d10eCf; //
        logics.uniswapLogic = 0x0e94C81e95e9809F5d718E41029225856845E8dA; //
        logics
            .priceCheckerLogicUniswap = 0x4F9eEaf6bceFF1951d280BBC60B412510616ff5e; //
        logics
            .priceDifferenceCheckerLogicUniswap = 0x627e775F9866a3F953037CE771cB9e5957556111; //
        logics
            .uniswapDexCheckerLogic = 0x181061Ad3d55376E3D0822F3F6f55e5d3a565501; //

        // Prod
        logics.versionUpgradeLogicProd = address(0); //
        logics.entryPointLogicProd = address(0); //
        logics.executionLogicProd = address(0); //

        Modules memory modules;

        return
            Contracts({
                vaultFactoryProxyAdmin: ProxyAdmin(
                    0x2D75C403384C6Ce374ba8B27451eF0F4BcD77c2E //
                ),
                vaultFactoryImplementation: 0x26381eBe9388a4C8a8c90875f38Fe9b5abfA06A4,
                vaultFactoryImplementationProd: address(0),
                vaultFactoryProxy: ITransparentUpgradeableProxy(
                    0xF03C8CaB74b5721eB81210592C9B06f662e9951E //
                ),
                vaultFactoryProxyProd: ITransparentUpgradeableProxy(
                    address(0) //
                ),
                vaultProxyAdmin: VaultProxyAdmin(
                    0x0F320AF6CC51b1a64aab6a9f75C505CB7d9791Cc //
                ),
                vaultProxyAdminProd: VaultProxyAdmin(
                    address(0) //
                ),
                dittoOracle: IDittoOracleV3(
                    0x9596D9BE211Bd9cf93c18bA3E7c19694f01B34A0 //
                ),
                protocolFees: ProtocolFees(
                    0x812c21E8B128B25661A431cd09237938A51136d8 //
                ),
                protocolFeesProd: ProtocolFees(
                    address(0) //
                ),
                protocolModuleList: 0xb2e04b05bff12eE15e47B6eA767A61995c50F509, //
                protocolModuleListProd: address(0), //
                wrappedNative: IWETH9(
                    0x4200000000000000000000000000000000000023
                ),
                uniswapRouter: IV3SwapRouter(
                    0xF339F231678e738c4D553e6b60305b852a4C526B
                ),
                uniswapFactory: IUniswapV3Factory(
                    0xbAB2F66B5B3Be3cC158E3aC1007A8DF0bA5d67F4
                ),
                uniswapNFTPositionManager: INonfungiblePositionManager(
                    0xa4b568bCdeD46bB8F84148fcccdeA37e262A3848
                ),
                automateGelato: IAutomate(
                    0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0
                ),
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                entryPointCreator: 0x7fc98430eAEdbb6070B35B39D798725049088348,
                logics: logics,
                modules: modules
            });
    }

    function contractsByChainId(
        uint256 chainId
    ) internal pure returns (Contracts memory) {
        if (chainId == 168587773) {
            return _168587773();
        } else {
            revert InvalidChainId();
        }
    }
}
