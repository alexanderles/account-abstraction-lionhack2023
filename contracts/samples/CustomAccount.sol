// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../core/BaseAccount.sol";
import "./callback/TokenCallbackHandler.sol";

/**
  * minimal account.
  *  this is sample minimal account.
  *  has execute, eth handling methods
  *  has a single signer that can send requests through the entryPoint.
  */
contract CustomAccount is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32;

    event CustomAccountInitialized(IEntryPoint indexed entryPoint, address[] indexed owner);
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    mapping(address => bool) public isOwner;
    mapping(uint => mapping(address => bool)) public approved;

    address[] public owners;
    Transaction[] public transactions;

    IEntryPoint private immutable i_entryPoint;

    uint public requiredSigners;

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return i_entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint _entryPoint, address[] memory _owners, uint _requiredSigners) {
        require(_owners.length > 0, "owners required");
        require(_requiredSigners > 0 && _requiredSigners <= _owners.length, "invalid number of signers");

        
        i_entryPoint = _entryPoint;
        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        requiredSigners = _requiredSigners;

        // TODO: Remove this?
        _disableInitializers();
    }

    
    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address,) then upgrading
      * the implementation by calling `upgradeTo(`
     */
    function initialize(address[] memory _owners) public virtual initializer {
        _initialize(_owners);
    }

    function _initialize(address[] memory _owners) internal virtual {

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        emit CustomAccountInitialized(i_entryPoint,owners);

    }

    modifier requireFromThisOrOwner() {
        // directly from this account or a signer
        require(isOwner[msg.sender] || msg.sender == address(this), "only owner");
        _;
    }

    // Require the function call went through EntryPoint or owner
    modifier requireFromEntryPointOrOwner() {
        require(msg.sender == address(entryPoint()) || isOwner[msg.sender], "account: not Owner or EntryPoint");
        _;
    }

    // Require a transaction exists
    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "transaction does not exist");
        _;
    }

    // Require a transaction has not been approved
    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "transaction has already been approved");
        _;
    }

    // Require a transaction has not been executed
    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "transaction has already been executed");
        _;
    }

    // Submits a transaction from a user
    function submit(address _to, uint _value, bytes calldata _data) external requireFromThisOrOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    // Approve a transaction
    function approve(uint _txId) external 
        requireFromThisOrOwner 
        txExists(_txId)
        notApproved(_txId) 
        notExecuted(_txId) { 
        
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    // Number of approvals for a transaction
    function _getApprovalCount(uint _txId) private view returns (uint) {
        uint approvals;
        for (uint i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                approvals++;
            }
        }
        return approvals;
    }
    
    // execute a transaction (called directly from owner, or by entryPoint)
    function execute(uint _txId) external requireFromEntryPointOrOwner  txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= requiredSigners, "not enough signers");

        Transaction storage txn = transactions[_txId];
        _call(txn.to, txn.value, txn.data);
        txn.executed = true;

        emit Execute(_txId);
    }

    // revoke approval for a transaction
    function revokeApproval(uint _txId) external requireFromThisOrOwner
        txExists(_txId)
        notExecuted(_txId) {

            require(approved[_txId][msg.sender], "transaction not approved");
            approved[_txId][msg.sender] = false;
            emit Revoke(msg.sender, _txId);
    }

    /// implement template method of BaseAccount
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal override virtual returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (!isOwner[hash.recover(userOp.signature)])
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value : msg.value}(address(this));
        emit Deposit(msg.sender, msg.value);
    }

    function _authorizeUpgrade(address newImplementation) internal view override requireFromThisOrOwner {
        (newImplementation);
    }
}

