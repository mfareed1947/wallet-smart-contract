// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract simpleWallet {
    address public owner;
    bool public stop;

    struct Transaction {
        address from;
        address to;
        uint256 timestamp;
        uint256 amount;
    }

    Transaction[] public transactionHistory;

    event Transfer(address receiver, uint256 amount);
    event Receive(address sender, uint256 amonut);
    event ReceiveUser(address sender, address receiver, uint256 amount);

    mapping(address => uint256) suspiciousUser;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you don't have access");
        _;
    }

    modifier getSuspiciousUser(address _sender) {
        require(
            suspiciousUser[_sender] < 5,
            "Activity found suspicious, Try later"
        );
        _;
    }

    modifier isEmergencyDeclared() {
        require(stop == false, "Emergency declared");
        _;
    }

    function toggleStop() external onlyOwner {
        stop = !stop;
    }

    function changOwner(address newOwner) public onlyOwner isEmergencyDeclared {
        owner = newOwner;
    }

    function transferToContract()
        external
        payable
        getSuspiciousUser(msg.sender)
    {
        transactionHistory.push(
            Transaction({
                from: msg.sender,
                to: address(this),
                timestamp: block.timestamp,
                amount: msg.value
            })
        );
    }

    function transferToUserViaContract(address payable _to, uint256 _weiAmount)
        external
        onlyOwner
    {
        require(address(this).balance >= _weiAmount, "Insufficient Balance");
        require(_to != address(0), "Adress format incorrect");
        _to.transfer(_weiAmount);
        transactionHistory.push(
            Transaction({
                from: msg.sender,
                to: _to,
                timestamp: block.timestamp,
                amount: _weiAmount
            })
        );
        emit Transfer(_to, _weiAmount);
    }

    function withdrawFromContract(uint256 _weiAmount) external onlyOwner {
        require(address(this).balance >= _weiAmount, "Insuffficient balance");
        payable(owner).transfer(_weiAmount);
        transactionHistory.push(
            Transaction({
                from: address(this),
                to: owner,
                timestamp: block.timestamp,
                amount: _weiAmount
            })
        );
    }

    function transferToUserViaMsgValue(address _to) external payable {
        require(address(this).balance >= msg.value, "Insufficient Balance");
        require(_to != address(0), "Adress format incorrect");
        payable(_to).transfer(msg.value);
        transactionHistory.push(
            Transaction({
                from: msg.sender,
                to: _to,
                timestamp: block.timestamp,
                amount: msg.value
            })
        );
    }

    function receiveFromUser() external payable {
        require(msg.value > 0, "Wei Value must be greater than zero");
        payable(owner).transfer(msg.value);
        emit ReceiveUser(msg.sender, owner, msg.value);
        transactionHistory.push(
            Transaction({
                from: msg.sender,
                to: owner,
                timestamp: block.timestamp,
                amount: msg.value
            })
        );
    }

    function getContractBlanceInWei() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        transactionHistory.push(
            Transaction({
                from: msg.sender,
                to: address(this),
                timestamp: block.timestamp,
                amount: msg.value
            })
        );
        emit Receive(msg.sender, msg.value);
    }

    function suspiciousActivity(address _sender) public {
        suspiciousUser[_sender] += 1;
    }

    fallback() external {
        suspiciousActivity(msg.sender);
    }

    function getTransactionHistory()
        external
        view
        returns (Transaction[] memory)
    {
        return transactionHistory;
    }

    function emergencyWithdrawl() external {
        require(stop == true, "Emergency not declared");
        payable(owner).transfer(address(this).balance);
    }
}
