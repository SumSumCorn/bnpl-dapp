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

  constructor(address _manager, string memory _name, uint256 _trackingNum) public {
    name = _name;
    trackingNum = _trackingNum;

    // Make deployer manager
    manager = _manager;

    status = STATUSES.CREATED;

    // Log history
    emit State("CREATE", _manager, _manager, now);
  }

  function send(address _from, address _to) public {
    // Must be manager to send
    require(_from == manager);

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
    emit State("SEND", _from, _to, now);
  }

  function receive(address _to) public {
    // Must be manager to receive
    require(_to == manager);

    // Must be in "SENT" status
    // Cannot be "CREATED" or "RECEIVED"
    require(status == STATUSES.SENT);

    // Update status to "RECEIVED"
    status = STATUSES.RECEIVED;

    // Log history
    emit State("RECEIVE", _to, _to, now);
  }
}
