// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./CustomAccount.sol";

// ZKaptcha anti-bot 
interface ZKaptchaInterface {
	function verifyZkProof(bytes calldata zkProof) external view returns (bool);
}


/**
 * A sample factory contract for SimpleAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract CustomAccountFactory {
    CustomAccount public accountImplementation;
    IEntryPoint public entryPoint;
    ZKaptchaInterface public zkaptcha;
    event ContractCreated(address indexed contractAddress);

    constructor(IEntryPoint _entryPoint) {
        // accountImplementation = new CustomAccount(_entryPoint, _owners, _requiredSigners);
        entryPoint = _entryPoint;
        zkaptcha = ZKaptchaInterface(0xf5DCa59461adFFF5089BE5068364eC10B86c2a88); 
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(
        address[] memory owners,
        uint requiredSigners,
        uint256 salt,
        bytes32[] memory proof
    ) public returns (address contractAddr) {

        // CHECK IF THE CAPTCHA IS VALID 
        require(zkaptcha.verifyZkProof(abi.encodePacked(proof)), "invalid zkaptcha proof");

        address addr = getAddress(owners, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return address(CustomAccount(payable(addr)));
        }
        accountImplementation = new CustomAccount(
            entryPoint,
            owners,
            requiredSigners
        );
        CustomAccount ret = CustomAccount(
            payable(
                new ERC1967Proxy{salt: bytes32(salt)}(
                    address(accountImplementation),
                    abi.encodeCall(CustomAccount.initialize, (owners))
                )
            )
        );

        emit ContractCreated(address(ret));
        contractAddr = address(ret);
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(
        address[] memory owners,
        uint256 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(salt),
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode,
                        abi.encode(
                            address(accountImplementation),
                            abi.encodeCall(CustomAccount.initialize, (owners))
                        )
                    )
                )
            );
    }
}
