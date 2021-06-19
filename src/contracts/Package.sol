pragma solidity ^0.5.0;

contract Package {
  string public name;
  uint256 trackingNum;
  address public manager;

  STATUSES public status;

  enum STATUSES {
    CREATED,
    SENT,
    RECEIVED
  }

  event State(
    string name,
    address account,
    address manager,
    uint256 timestamp
  );

  constructor(string memory _name, uint256 _trackingNum) public {
    name = _name;
    trackingNum = _trackingNum;

    // Make deployer manager
    manager = msg.sender;

    status = STATUSES.CREATED;

    // Log history
    emit State("CREATE", msg.sender, msg.sender, now);
  }

  function send(address _to) public {
    // Must be manager to send
    require(msg.sender == manager);

    // Cannot send to self
    require(_to != manager);

    // Can't be in "SENT" status
    // Must be "CREATED" or "RECEIVED"
    require(status != STATUSES.SENT);

    // Update status to "SENT"
    status = STATUSES.SENT;

    // Make _to new manager
    manager = _to;

    // Log history
    emit State("SEND", msg.sender, _to, now);
  }

  function receive() public {
    // Must be manager to receive
    require(msg.sender == manager);

    // Must be in "SENT" status
    // Cannot be "CREATED" or "RECEIVED"
    require(status == STATUSES.SENT);

    // Update status to "RECEIVED"
    status = STATUSES.RECEIVED;

    // Log history
    emit State("RECEIVE", msg.sender, msg.sender, now);
  }
}
