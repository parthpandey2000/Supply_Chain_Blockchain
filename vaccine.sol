pragma solidity ^0.6.0;
contract Vaccines{
    ///////////////////////////////////////////
    uint public quantity;
    string public name;
    string public additional_info;
    uint manufacturing_date;
    STATUSES public status;
    address public custodian;
    uint public batch_id=0;
    uint public batch_sent_from_manu;
    ///////////////////////////////////////////
    struct Manufacturer {
        uint quantity;
        string name;
        string additional_info;
        uint manufacturing_date;
        address custodian;
        uint batch_id;
        uint shipment_no;
        address distributor_address;
        uint distributor_quantity;
        uint logistics_receiving_time;
        uint distributor_receiving_time;
        STATUSES batch_status;
        
    }
    /////////////////////////////////////////////////
struct Hospital{
    address distributor_address;
    address hospital_address;
    address custodian;
    uint quantity;
    uint batch_id;
    uint sub_batch_id;
    HOSPITALS sub_batch_status;
}
///////////////////////////////////////////////////
    enum STATUSES {
    MANUFACTURED,
    M_SENT,
    L_RECEIVED,
    L_SENT,
    D_RECEIVED,
    D_REMAINING,
    D_SENT
  }
    enum HOSPITALS{
        NA,
        NOT_RECEIVED,
        DAMAGED,
        RECEIVED
    }
  ////////////////////////////////////////////////////
    //action for manufacturer for sending to a distributor
    event ManufacturerAction(
    string name,
    string additional_info,
    uint quantity,
    address custodian,
    uint manufacturing_date
  );
  
   
    
  
  ///////////////////////////////////////////////
  Manufacturer[] public manufacturer;
  Manufacturer public mtemp;
  Hospital public htemp;
  Hospital[] public hospital;
  
   
   function create_vaccine_batch(uint _quantity, string memory _name, string memory _additional_info) public {
      require(msg.sender ==0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
      mtemp.name=_name;
      mtemp.additional_info=_additional_info;
      mtemp.quantity=_quantity;
      mtemp.manufacturing_date=now;
      mtemp.custodian=msg.sender;
      mtemp.batch_status = STATUSES.MANUFACTURED;
      manufacturer.push(mtemp);
      emit ManufacturerAction(name,additional_info,quantity,custodian,manufacturing_date);     
   }
   
   function send_batch_from_manufacturer_to_logistics(uint _batch_id) public{
       require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 && manufacturer[_batch_id-1].batch_status==STATUSES.MANUFACTURED);
       manufacturer[_batch_id-1].batch_status = STATUSES.M_SENT;
      
   }
   
    function receive_batch_at_logistics(uint _batch_id) public {
       require(msg.sender == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 && manufacturer[_batch_id-1].batch_status == STATUSES.M_SENT);
       manufacturer[_batch_id-1].custodian = msg.sender;
       manufacturer[_batch_id-1].batch_status=STATUSES.L_RECEIVED;
       manufacturer[_batch_id-1].logistics_receiving_time=now;
   }
   
   function send_batch_from_logistics_to_distributor (address _to, uint _shipment_no, uint _batch_id) public{
       require(msg.sender==0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 && manufacturer[_batch_id-1].batch_status==STATUSES.L_RECEIVED);
       manufacturer[_batch_id-1].batch_status=STATUSES.L_SENT;
       manufacturer[_batch_id-1].shipment_no=_shipment_no;
       manufacturer[_batch_id-1].distributor_address=_to;
   }
   
   function receive_batch_at_distributor(uint _batch_id) public{
       require(msg.sender==manufacturer[_batch_id-1].distributor_address && manufacturer[_batch_id-1].batch_status==STATUSES.L_SENT);
       manufacturer[_batch_id-1].custodian=msg.sender;
       manufacturer[_batch_id-1].batch_status=STATUSES.D_RECEIVED;
       manufacturer[_batch_id-1].distributor_quantity=manufacturer[_batch_id-1].quantity;
       manufacturer[_batch_id-1].distributor_receiving_time=now;
       
   }
   
   function find_sub_index(uint _batch_id, uint _index) public view returns(uint){
       uint i=0;
       for (i=0;i<hospital.length;i++){
           if (hospital[i].sub_batch_id==_batch_id && hospital[i].batch_id == _index){
               return i;
           }
       }
       
   }
    
    function check(uint _batch_id, uint _sub_batch_id) public view returns(bool){
        uint i=0;
        for (i=0;i<hospital.length;i++){
            if (hospital[i].batch_id==_batch_id && hospital[i].sub_batch_id == _sub_batch_id && hospital[i].sub_batch_status == HOSPITALS.NA){
                return false;
            }
        }
        return true;
    }
   
   function send_batch_from_distributor(address _to, uint _batch_id, uint _quantity , uint _sub_batch_id) public{
       require(msg.sender==manufacturer[_batch_id-1].custodian && (manufacturer[_batch_id-1].batch_status==STATUSES.D_RECEIVED || manufacturer[_batch_id-1].batch_status==STATUSES.D_REMAINING) && _quantity<=manufacturer[_batch_id-1].distributor_quantity && check(_batch_id,_sub_batch_id));
       
       htemp.distributor_address = msg.sender;
       htemp.hospital_address=_to;
       htemp.quantity=_quantity;
       htemp.batch_id=_batch_id;
       htemp.sub_batch_id=_sub_batch_id;
       htemp.custodian=msg.sender;
       manufacturer[_batch_id-1].distributor_quantity=manufacturer[_batch_id-1].distributor_quantity-_quantity;
       hospital.push(htemp);
       manufacturer[_batch_id-1].batch_status=STATUSES.D_REMAINING;
       
       
       if (manufacturer[_batch_id-1].distributor_quantity==0){
           manufacturer[_batch_id-1].batch_status=STATUSES.D_SENT;
       }
   }
   
   function hospital_receive(HOSPITALS _condition, uint _batch_id, uint _sub_batch_id) public {
      uint sub_index=find_sub_index(_sub_batch_id,_batch_id);
      require(hospital[sub_index].sub_batch_status==HOSPITALS.NA);
      hospital[sub_index].sub_batch_status=_condition;
      hospital[sub_index].custodian=msg.sender;
   }

}
