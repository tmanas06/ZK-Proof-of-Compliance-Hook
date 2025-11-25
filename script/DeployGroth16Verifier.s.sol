// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Groth16Verifier} from "../contracts/generated/Groth16Verifier.sol";

contract DeployGroth16Verifier is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Groth16Verifier...");
        Groth16Verifier verifier = new Groth16Verifier();
        
        console.log("Groth16Verifier deployed at:");
        console.logAddress(address(verifier));
        console.log("Deployment complete!");

        vm.stopBroadcast();
    }
}
