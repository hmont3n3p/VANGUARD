public class EventController {

    private static final DateTime TODAY =  System.Today();
    private static final INTEGER MAX_ENTRY_TIME = 7;
    private static final INTEGER MAX_EXIT_TIME = 20;
    private static final String DEFAULT_COMPANY = 'VANGUARD COMPANY';


    private static final Map<Integer, DateTime> availableDateTimes = new Map<Integer, DateTime>{
         7 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 7, 0, 0),
         8 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 8, 0, 0),
         9 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 9, 0, 0),
         10 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 10, 0, 0),
         11 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 11, 0, 0),
         12 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 12, 0, 0),
         13 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 13, 0, 0),
         14 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 14, 0, 0),
         15 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 15, 0, 0),
         16 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 16, 0, 0),
         17 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 17, 0, 0),
         18 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 18, 0, 0),
         19 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 19, 0, 0),
         20 => DateTime.newInstance(TODAY.year(), TODAY.month(), TODAY.day(), 20, 0, 0)};
    

    @AuraEnabled(cacheable=true)
    public static List<Event> getEvents() {
        return [SELECT Id, Subject, StartDateTime, IsAllDayEvent, EndDateTime 
                FROM Event 
                ORDER BY CreatedDate DESC
                LIMIT 100];
    }
    @AuraEnabled(cacheable=true)
    public static List<Event> getEventsWithWhoId(String WhoId) {
        return [SELECT Id, Subject, StartDateTime, IsAllDayEvent, EndDateTime 
                FROM Event
                Where WhoId =:WhoId AND  StartDateTime <>NULL
                ORDER BY CreatedDate DESC
                LIMIT 100];
    }
    @AuraEnabled(cacheable=true)
    public static Boolean findByInteger(Integer hour,Event event) {
        if(event!=null){
            if(event.StartDateTime!=null){
                return (event.StartDateTime.hour()==hour);
            }            
        }
        return false;
    }
    @AuraEnabled(cacheable=true)
    public static List<Event> getSyncEventMessage(String DateAppointment,String Center,String WhoId) {
        List<Event> result=new List<Event>();
       Set<Integer> toRemove=new Set<Integer>();
       Event[] currentEvents =EventController.getEventsWithWhoId(WhoId);
       if(currentEvents.size()>0){
            for(Event tmp:currentEvents){
                if(tmp.StartDateTime.hour()>=MAX_ENTRY_TIME || tmp.StartDateTime.hour()<=MAX_EXIT_TIME ){
                    toRemove.add((tmp.StartDateTime.hour()));
                }
            
            }        
        }
        for(Integer remove:toRemove){
            availableDateTimes.remove(remove);
        }
        for (Integer key : availableDateTimes.keySet()) {           
            result.add(new Event(StartDateTime=availableDateTimes.get(key),EndDateTime=availableDateTimes.get(key).addHours(1)));                    
        }        
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContact(String IdContact) {
        return [SELECT Id, Name, Title, Phone, Email FROM Contact WHERE Id =:IdContact];
    }
    @AuraEnabled(cacheable=true)
    public static List<Lead> getLead(String IdLead) {
        return [SELECT Id, Name, Title, Phone, Email FROM Lead WHERE Id =:IdLead];
    }
    @AuraEnabled(cacheable=true)
    public static SObject getLeadOrContact(String IdRecord) {
        Lead[] leads =[SELECT Id, Name, Title, Phone, Email FROM Lead WHERE Id =:IdRecord];
        Contact[] contacts =[SELECT Id, Name, Title, Phone, Email FROM Contact WHERE Id =:IdRecord];
        if (leads.size() > 0){
            return leads[0];
        }
        if (contacts.size() > 0){
            return contacts[0];
        }
        return null;    
    }
    @AuraEnabled(cacheable=true)
    public static List<VAN_Centro__c > getCentro(String IdCentro) {
        return [SELECT Id, Name, VAN_Name__c, VAN_IsActive__c  FROM VAN_Centro__c  WHERE Id =:IdCentro];
    }

    @AuraEnabled 
    public static String buildMedAptment(String fechaCita,String nombreCliente,String apellidoCliente,String email,String movil,String observaciones,String IdEspecialista,String IdCentro) {
        SObject customer=EventController.buildSObjectClient( nombreCliente, apellidoCliente, email, movil);
        upsert  customer;
        Boolean IsLeadRecord=customer instanceof Lead;
        Boolean IsContactRecord=customer instanceof Contact;     
      
        DateTime dateTimeCita= DateTime.valueOfGMT(((fechaCita.split('\\.',2).get(0)).split('T',2)).get(0)+' '+((fechaCita.split('\\.',2).get(0)).split('T',2)).get(1));
      
        VAN_Citas__c newRecord1=new VAN_Citas__c (VAN_Fecha_Cita__c=dateTimeCita,VAN_Centro__c=IdCentro,VAN_Especialista__c=IdEspecialista);
       
        if(IsContactRecord){
            newRecord1.VAN_Contact__c=customer.Id;
        }
        if (IsLeadRecord){
            newRecord1.VAN_Lead__c=customer.Id;
        }
        
        insert newRecord1;
        insert new Event(WhoId=IdEspecialista,Subject='CITA MEDICA'+'-'+newRecord1.Id+'-'+IdEspecialista+'-'+IdCentro, StartDateTime=dateTimeCita, IsAllDayEvent=false, EndDateTime= dateTimeCita.addHours(1));       
        return 'OK'; 
    }
    @AuraEnabled(cacheable=true)
    public static SObject buildSObjectClient(String nombreCliente,String apellidoCliente,String email,String movil) {
        Boolean existAsLead=false;
        Boolean existAsContact=false;

        Lead leadObj = new Lead();
        leadObj.FirstName = nombreCliente;
        leadObj.LastName = apellidoCliente;
        leadObj.Email = email;
        leadObj.MobilePhone = movil;
        leadObj.Company = DEFAULT_COMPANY;              
        List<Lead> leadsList = new List<Lead>();
        leadsList.add(leadObj); 
         
        Contact contactObj = new Contact();
        contactObj.FirstName = nombreCliente;
        contactObj.LastName = apellidoCliente;
        contactObj.Email = email;
        contactObj.MobilePhone = movil;                
        List<Contact> contactsList = new List<Contact>();
        contactsList.add(contactObj);
        String existingRecordId;
        String leadDupRecordId;
        DuplicateRecordCheck.Input input1 =new DuplicateRecordCheck.Input();
        input1.record=leadObj;

        List<DuplicateRecordCheck.Input> inputs1 =new List<DuplicateRecordCheck.Input>{input1};        
        List<DuplicateRecordCheck.Duplicate> duplicates1= DuplicateRecordCheck.findDuplicates(inputs1);
        for(DuplicateRecordCheck.Duplicate tmp:duplicates1){
            if(tmp.isDuplicate){
                existingRecordId=tmp.duplicateRecordId;
                existAsLead=true;
                break;
            }            
        }

        String contactDupRecordId;
        DuplicateRecordCheck.Input input2 =new DuplicateRecordCheck.Input();
        input2.record=contactObj;

        List<DuplicateRecordCheck.Input> inputs2 =new List<DuplicateRecordCheck.Input>{input2};        
        List<DuplicateRecordCheck.Duplicate> duplicates2= DuplicateRecordCheck.findDuplicates(inputs2);
        for(DuplicateRecordCheck.Duplicate tmp:duplicates2){
            if(tmp.isDuplicate){
                existingRecordId=tmp.duplicateRecordId;
                existAsContact=true;
                break;
            }            
        }
        
       
        if(existAsContact||existAsLead){
            return EventController.getLeadOrContact(existingRecordId);
        }
    return leadObj ; 
    } 
}