// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBrevisVerifier} from "../interfaces/IBrevisVerifier.sol";

/// @title ComplianceData
/// @notice Library for handling compliance data and generating hashes
/// @dev This library helps create and validate compliance data structures
library ComplianceData {
    /// @notice Generate a hash of compliance data
    /// @param data The compliance data to hash
    /// @return hash The keccak256 hash of the compliance data
    function hashComplianceData(
        IBrevisVerifier.ComplianceData memory data
    ) internal pure returns (bytes32 hash) {
        return
            keccak256(
                abi.encodePacked(
                    data.kycPassed,
                    data.ageVerified,
                    data.locationAllowed,
                    data.notSanctioned,
                    data.age,
                    keccak256(bytes(data.countryCode))
                )
            );
    }

    /// @notice Validate compliance data against requirements
    /// @param data The compliance data to validate
    /// @param requireKYC Whether KYC is required
    /// @param requireAgeVerification Whether age verification is required
    /// @param requireLocationCheck Whether location check is required
    /// @param requireSanctionsCheck Whether sanctions check is required
    /// @param minAge Minimum age requirement
    /// @return isValid True if data meets all requirements
    function validateComplianceData(
        IBrevisVerifier.ComplianceData memory data,
        bool requireKYC,
        bool requireAgeVerification,
        bool requireLocationCheck,
        bool requireSanctionsCheck,
        uint256 minAge
    ) internal pure returns (bool isValid) {
        // Check KYC requirement
        if (requireKYC && !data.kycPassed) {
            return false;
        }

        // Check age requirement
        if (requireAgeVerification) {
            if (!data.ageVerified) {
                return false;
            }
            if (data.age < minAge) {
                return false;
            }
        }

        // Check location requirement
        if (requireLocationCheck && !data.locationAllowed) {
            return false;
        }

        // Check sanctions requirement
        if (requireSanctionsCheck && !data.notSanctioned) {
            return false;
        }

        return true;
    }

    /// @notice Create a default compliant data structure
    /// @return data A compliance data structure with all checks passing
    function createCompliantData()
        internal
        pure
        returns (IBrevisVerifier.ComplianceData memory data)
    {
        data.kycPassed = true;
        data.ageVerified = true;
        data.locationAllowed = true;
        data.notSanctioned = true;
        data.age = 25; // Default age
        data.countryCode = "US"; // Default country
    }

    /// @notice Create a non-compliant data structure (for testing)
    /// @return data A compliance data structure with checks failing
    function createNonCompliantData()
        internal
        pure
        returns (IBrevisVerifier.ComplianceData memory data)
    {
        data.kycPassed = false;
        data.ageVerified = false;
        data.locationAllowed = false;
        data.notSanctioned = false;
        data.age = 0;
        data.countryCode = "";
    }
}

