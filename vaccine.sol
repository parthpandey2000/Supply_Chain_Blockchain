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
        STATUSES batch_status;
    }
///////////////////////////////////////////////////
    struct Logistics {
        uint shipment_no;
        address custodian;
        address to;
        uint batch_id;
        //STATUSES batch_status;
    }
/////////////////////////////////////////////////
struct Hospital{
    address hospital_address;
    uint quantity;
    uint batch_id;
    uint sub_batch_id;
    HOSPITALS sub_batch_status;
}
//////////////////////////////////////////////////
struct Distributor{
   uint shipment_no;
   uint quantity_remaining;
   uint receiving_time;
   address custodian;
   uint batch_id;
   Hospital[] hospital;
  
}
    ////////////////////////////////////////////
    enum STATUSES {
    MANUFACTURED,
    M_SENT,
    L_RECEIVED,
    L_SENT,
    D_RECEIVED,
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
  Logistics[] public logistic;
  Logistics public ltemp;
  Manufacturer public mtemp;
  Distributor[] public distributor;
  Distributor public dtemp;
  Hospital public htemp;
  Hospital public htest;
  
   //call constructor when vaccines have been manufactured by the plant
   
   function create_vaccine_batch(uint _quantity, string memory _name, string memory _additional_info) public {
      //require(msg.sender ==0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
      name=_name;
      additional_info=_additional_info;
      quantity=_quantity;
      manufacturing_date=now;
      custodian=msg.sender;
      status = STATUSES.MANUFACTURED;
      mtemp=Manufacturer(quantity,name,additional_info,manufacturing_date,custodian,++batch_id,status);
      manufacturer.push(mtemp);
      emit ManufacturerAction(name,additional_info,quantity,custodian,manufacturing_date);     
   }
   
   function send_batch_from_manufacturer_to_logistics(uint _batch_id) public{
       require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 && manufacturer[_batch_id-1].batch_status==STATUSES.MANUFACTURED);
       manufacturer[_batch_id-1].batch_status = STATUSES.M_SENT;
       manufacturer[_batch_id-1].custodian = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
      
   }
   
    function receive_batch_at_logistics(uint _batch_id) public {
       require(msg.sender == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 && manufacturer[_batch_id-1].batch_status == STATUSES.M_SENT);
       ltemp.custodian=manufacturer[_batch_id-1].custodian;
       ltemp.batch_id=manufacturer[_batch_id-1].batch_id;
       manufacturer[_batch_id-1].batch_status=STATUSES.L_RECEIVED;
       //logistic[_batch_id-1].batch_status=STATUSES.L_RECEIVED;
       logistic.push(ltemp);
   }
   
   function send_batch_from_logistics_to_distributor (address _to, uint _shipment_no, uint _batch_id) public{
       require(msg.sender==0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 && manufacturer[_batch_id-1].batch_status==STATUSES.L_RECEIVED);
       logistic[_batch_id-1].to=_to;
       logistic[_batch_id-1].shipment_no=_shipment_no;
       //logistic[_batch_id-1].batch_status=STATUSES.L_SENT;
       manufacturer[_batch_id-1].batch_status=STATUSES.L_SENT;
   }
   function receive_batch_at_distributor(uint _batch_id) public{
       require(msg.sender==logistic[_batch_id-1].to && manufacturer[_batch_id-1].batch_status==STATUSES.L_SENT);
       dtemp.quantity_remaining=manufacturer[_batch_id-1].quantity;
       dtemp.shipment_no=logistic[_batch_id-1].shipment_no;
       dtemp.custodian=msg.sender;
       logistic[_batch_id-1].custodian=msg.sender;
       manufacturer[_batch_id-1].custodian=msg.sender;
       manufacturer[_batch_id-1].batch_status=STATUSES.D_RECEIVED;
       dtemp.batch_id=_batch_id;
       distributor.push(dtemp);
       
   }
   function find_index(uint _batch_id) public view returns(uint){
       uint i=0;
       for (i=0;i<distributor.length;i++){
           if (distributor[i].batch_id==_batch_id){
               return i;
           }
       }
       
   }
   function find_sub_index(uint _batch_id, uint _index) public view returns(uint){
       uint i=0;
       for (i=0;i<distributor[_index].hospital.length;i++){
           if (distributor[_index].hospital[i].sub_batch_id==_batch_id){
               return i;
           }
       }
       
   }
   
   function send_batch_from_distributor(address _to, uint _batch_id, uint _quantity , uint _sub_batch_id) public{
       uint index=find_index(_batch_id);
       require(msg.sender==distributor[index].custodian && manufacturer[_batch_id-1].batch_status==STATUSES.D_RECEIVED && _quantity<=distributor[index].quantity_remaining);
       
       htemp.hospital_address=_to;
       htemp.quantity=_quantity;
       htemp.batch_id=_batch_id;
       htemp.sub_batch_id=_sub_batch_id;
       distributor[index].quantity_remaining=distributor[index].quantity_remaining-_quantity;
       distributor[index].hospital.push(htemp);
       
       
       if (distributor[index].quantity_remaining==0){
           manufacturer[_batch_id-1].batch_status=STATUSES.D_SENT;
       }
   }
   
   function hospital_receive(HOSPITALS _condition, uint _batch_id, uint _sub_batch_id) public {
      
      uint index=find_index(_batch_id);
      uint sub_index=find_sub_index(_sub_batch_id,index);
      require(distributor[index].hospital[sub_index].sub_batch_status==HOSPITALS.NA);
      distributor[index].hospital[sub_index].sub_batch_status=_condition;
      htest=distributor[index].hospital[sub_index];
   }

}