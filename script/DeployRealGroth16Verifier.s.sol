// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

/// @title DeployRealGroth16Verifier
/// @notice Deploy the real Groth16Verifier generated from snarkjs
/// @dev This reads the generated contract and deploys it
contract DeployRealGroth16Verifier is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);
        console.log("");

        // Read the generated verifier contract
        string memory verifierPath = "contracts/generated/Groth16Verifier.sol";
        
        try vm.readFile(verifierPath) returns (string memory contractCode) {
            console.log("Found generated Groth16Verifier.sol");
            console.log("");
            console.log("Contract size:", bytes(contractCode).length, "bytes");
            console.log("");
            console.log("To deploy the verifier:");
            console.log("  1. Use Remix: Copy contracts/generated/Groth16Verifier.sol");
            console.log("     Compile and deploy to your network");
            console.log("");
            console.log("  2. Or use Foundry (if contract is compilable):");
            console.log("     forge create src/verifiers/Groth16Verifier.sol:Groth16Verifier --rpc-url <RPC>");
            console.log("");
            console.log("  3. Update .env with deployed address:");
            console.log("     GROTH16_VERIFIER_ADDRESS=0x...");
            console.log("");
        } catch {
            console.log("ERROR: Groth16Verifier.sol not found!");
            console.log("Please run the generation script first.");
        }

        vm.stopBroadcast();
    }
}

