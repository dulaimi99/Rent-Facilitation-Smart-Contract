# @version ^0.2.4

#Owner of the service
owner: public(address)
#Service fee
fee: public(uint256)
#profit
profit: public(uint256)

#struct holding details about rent transaction
struct rent_item:
    transaction_id: uint256 #transaction id
    renter: address #renter address
    borrower: address #borrower address
    item_value: uint256 #value of item being rented
    return_date: uint256 #return date
    renter_returned: bool #item returned to renter? renter side
    borrower_returned: bool #item returned? borrower side
    rent_price: uint256
    active: bool #active transaction?


#list of rent transactions
transaction_list: public(rent_item[10])

#id generator
txn_id: public(uint256)

#constructor
@external
def __init__():
    self.owner = msg.sender
    self.fee = as_wei_value(1,"finney")
    self.txn_id = 0
    self.profit = 0

#check credentials.
@internal 
def check_credentials(_msg_sender:address,_id:uint256) -> bool:
    if _msg_sender == self.transaction_list[_id - 1].borrower:
        return True
    elif _msg_sender == self.transaction_list[_id - 1].renter:
        return True
    else:
        return False

#check if renter and borrower both confirmed return 
@internal 
def check_return(_id:uint256) -> bool:
    if self.transaction_list[_id - 1].borrower_returned == True:
        if self.transaction_list[_id - 1].renter_returned == True:
            return True
    
    return False

#borrower instantiate a rent transaction 
@external
@payable
def rent(_renter:address, _value:uint256, _return_in:uint256, _price:uint256):
    #check if fee amount is sufficient
    assert as_wei_value(msg.value,"ether") >= (self.fee + as_wei_value(_price,"finney")) , "Insufficient amount for transaction price"
    
    assert self.txn_id < 10, "Amount of transactions that can be handled has exceeded. Come back another time"
    
    #add fee to profit
    self.profit = self.profit + self.fee
    
    # set up a rent transaction
    self.transaction_list[self.txn_id].transaction_id = self.txn_id + 1
    self.transaction_list[self.txn_id].renter = _renter
    self.transaction_list[self.txn_id].borrower = msg.sender
    self.transaction_list[self.txn_id].item_value = as_wei_value(_value, "finney")
    self.transaction_list[self.txn_id].return_date = block.timestamp + _return_in
    self.transaction_list[self.txn_id].renter_returned = False
    self.transaction_list[self.txn_id].borrower_returned = False
    self.transaction_list[self.txn_id].rent_price = as_wei_value(_price,"finney")
    self.transaction_list[self.txn_id].active = True
    
    #increment txn_id
    self.txn_id = self.txn_id + 1 


#end transaction and pay renter
@internal
def end_transaction(_id:uint256):
    
    #transfer renter their money
    send(self.transaction_list[_id - 1].renter , self.transaction_list[_id - 1].rent_price)
    
    #change status of transaction
    self.transaction_list[_id - 1].active = False
    	
#only borrower or renter can access this function
@external
def return_item(_id:uint256):
    
    #assert id
    assert _id <= 10, "Invalid id"  
    assert _id >= 0, "Invalid id"
    
    #assert borrower or renter
    assert self.check_credentials(msg.sender,_id) , "Only a borrower and renter operation "
    
    if msg.sender == self.transaction_list[_id - 1].borrower:
        #change returned status for borrower
        self.transaction_list[_id - 1].borrower_returned = True
    elif msg.sender == self.transaction_list[_id - 1].renter:
        #change returned status for borrower
        self.transaction_list[_id - 1].renter_returned = True
    
    #check if both are confirmed 
    if self.check_return(_id) == True :
        self.end_transaction(_id)

#Transfer app profits back to owner
@external
def transfer_profit():
  assert msg.sender == self.owner, "Owner operation only"
  send(self.owner, self.profit)


@external
@payable
def __default__():
    pass
