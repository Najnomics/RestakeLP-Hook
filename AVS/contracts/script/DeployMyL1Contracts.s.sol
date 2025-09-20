// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {IAllocationManager} from "@eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "@eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";

import {RestakeLPRegistrar} from "@project/l1-contracts/RestakeLPRegistrar.sol";
import {LiquidityManagerL1} from "@project/l1-contracts/LiquidityManagerL1.sol"; // Import your L1 custom contract

contract DeployMyL1Contracts is Script {
    using stdJson for string;

    struct Context {
        address avs;
        uint256 avsPrivateKey;
        uint256 deployerPrivateKey;
        IAllocationManager allocationManager;
        IKeyRegistrar keyRegistrar;
        RestakeLPRegistrar restakeLPRegistrar;
    }

    struct Output {
        string name;
        address contractAddress;
    }

    function run(string memory environment, string memory _context) public {
        // Read the context
        Context memory context = _readContext(environment, _context);

        vm.startBroadcast(context.deployerPrivateKey);
        console.log("Deployer address:", vm.addr(context.deployerPrivateKey));

        // Deploy RestakeLP L1 contracts
        LiquidityManagerL1 liquidityManagerL1 = new LiquidityManagerL1();
        console.log("LiquidityManagerL1 deployed to:", address(liquidityManagerL1));

        vm.stopBroadcast();

        vm.startBroadcast(context.avsPrivateKey);
        console.log("AVS address:", context.avs);

        //TODO: Implement any additional AVS setup

        vm.stopBroadcast();

        // Write to output file
        Output[] memory outputs = new Output[](1);
        outputs[0] = Output({name: "LiquidityManagerL1", contractAddress: address(liquidityManagerL1)});
        _writeOutputToJson(environment, outputs);
    }

    function _readContext(
        string memory environment,
        string memory _context
    ) internal view returns (Context memory) {
        // Parse the context
        Context memory context;
        context.avs = stdJson.readAddress(_context, ".context.avs.address");
        context.avsPrivateKey = uint256(stdJson.readBytes32(_context, ".context.avs.avs_private_key"));
        context.deployerPrivateKey = uint256(stdJson.readBytes32(_context, ".context.deployer_private_key"));
        context.allocationManager = IAllocationManager(stdJson.readAddress(_context, ".context.eigenlayer.l1.allocation_manager"));
        context.keyRegistrar = IKeyRegistrar(stdJson.readAddress(_context, ".context.eigenlayer.l1.key_registrar"));
        context.restakeLPRegistrar = RestakeLPRegistrar(_readAVSL1ConfigAddress(environment, "restakeLPRegistrar"));

        return context;
    }

    function _readAVSL1ConfigAddress(string memory environment, string memory key) internal view returns (address) {
        // Load the AVS L1 config file
        string memory avsL1ConfigFile = string.concat("script/", environment, "/output/deploy_avs_l1_output.json");
        string memory avsL1Config = vm.readFile(avsL1ConfigFile);

        // Parse and return the address
        return stdJson.readAddress(avsL1Config, string.concat(".addresses.", key));
    }

    function _writeOutputToJson(
        string memory environment,
        Output[] memory outputs
    ) internal {
        uint256 length = outputs.length;

        if (length > 0) {
            // Add the addresses object
            string memory addresses = "addresses";

            for (uint256 i = 0; i < outputs.length - 1; i++) {
                vm.serializeAddress(addresses, outputs[i].name, outputs[i].contractAddress);
            }
            addresses = vm.serializeAddress(addresses, outputs[length - 1].name, outputs[length - 1].contractAddress);

            // Add the chainInfo object
            string memory chainInfo = "chainInfo";
            chainInfo = vm.serializeUint(chainInfo, "chainId", block.chainid);

            // Finalize the JSON
            string memory finalJson = "final";
            vm.serializeString(finalJson, "addresses", addresses);
            finalJson = vm.serializeString(finalJson, "chainInfo", chainInfo);

            // Write to output file
            string memory outputFile = string.concat("script/", environment, "/output/deploy_custom_contracts_l1_output.json");
            vm.writeJson(finalJson, outputFile);
        }
    }
}
