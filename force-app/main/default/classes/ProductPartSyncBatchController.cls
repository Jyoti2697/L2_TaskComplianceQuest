/**
* @description       : Batch class to sync the Parts and Products.
* @author            : Jyoti Chahal
* @last modified on  : 08-21-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ProductPartSyncBatchController implements Database.Batchable<SObject>,Database.Stateful{
    
    public List<String> failedRecord= new List<String>();
    
    /**
* @description: (Start) this method is used to query the active Parts.
* @author Jyoti Chahal | 08-05-2023 
* @param batchContext 
* @return Database.QueryLocator 
**/
    public Database.QueryLocator start(Database.BatchableContext batchContext){
        String query = 'SELECT Id, Name,Active__c,Part_Number__c, Product__c FROM SQX_Part__c WHERE Active__c = true';
        return Database.getQueryLocator(query);
    }
    /**
* @description: (Execute) this method is used to update the parts and insert the Product based on requirement.
* @author Jyoti Chahal | 08-05-2023 
* @param batchContext 
* @param partList 
**/
    public void execute(Database.BatchableContext batchContext,List<SQX_Part__c> partList){
        try{
            Set<String> partsName= new Set<String>();
            Set<String> partsNumber= new Set<String>();
            for(SQX_Part__c partObj: partList){
                partsName.add(partObj.Name);
                partsNumber.add(partObj.Part_Number__c);
            }
            List<SQX_Part__c> updateParts= new List<SQX_Part__c>();
            Map<Id,Product2> insertProduct= new Map<Id,Product2>();
            Map<String,Product2> existingProductMap= new Map<String,Product2>();
            //putting value in map with the same Product Name and code with Parts name and NUmber.
            for(Product2 productObj: [Select Id,Name,ProductCode From Product2 Where Name IN: partsName AND ProductCode IN: partsNumber LIMIT 10000]){
                existingProductMap.put(productObj.Name + productObj.ProductCode, productObj);
            }
            //Here getting the profile Name System Admin and Permission set CQ Product Admin
            String profileName=[Select Id,Name from Profile where Id=:UserInfo.getProfileId()].Name;
            system.debug('profileName:::'+profileName);
            List<PermissionSetAssignment> permissionSetAssList = [SELECT AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name = 'CQ_Product_Admin' AND AssigneeId=:UserInfo.getUserId() WITH SECURITY_ENFORCED];
            system.debug('permissionSetAssList:::'+permissionSetAssList);
            for(SQX_Part__c partOBj: partList){
                //Here checking the Profile name and Permission set according to the requirement.
                if(profileName == 'System Administrator' && !permissionSetAssList.isEmpty()){
                    if(existingProductMap.containsKey(partOBj.Name + partOBj.Part_Number__c)){
                        partOBj.Product__c= existingProductMap.get(partOBj.Name + partOBj.Part_Number__c).Id;
                        updateParts.add(partOBj);
                    }
                    else{
                        Product2 productObj= new Product2();
                        productObj.Name= partOBj.Name;
                        productObj.ProductCode= partOBj.Part_Number__c;
                        productObj.IsActive= partOBj.Active__c;
                        insertProduct.put(partOBj.Id,productObj);
                    }
                }
            }
            if(!insertProduct.isEmpty() && (Schema.sObjectType.Product2.isCreateable())){
                Database.SaveResult[] saveProductList= Database.insert(insertProduct.values());
                getFailedRecord(saveProductList);
                //Here getting the Product Id to set the associate products to parts
                for(Id eachPartId: insertProduct.keySet()){
                    updateParts.add(new SQX_Part__c(Id= eachPartId,Product__c = insertProduct.get(eachPartId).Id));
                }
            }
            if(!updateParts.isEmpty() && (Schema.sObjectType.SQX_Part__c.isUpdateable())){
                Database.SaveResult[] savePartList=  Database.update(updateParts);
                getFailedRecord(savePartList);
            }
            
            
        }
        catch(Exception ex){
            System.debug('Error::::'+ex.getMessage()+' line number:::'+ex.getLineNumber());
        }
    }
    /**
* @description: (finish) In this method sending the mail to user for the failed records.
* @author Jyoti Chahal | 08-05-2023 
* @param batchContext 
**/
    public void finish(Database.BatchableContext batchContext){
        //checking the failed Record list
        if(!failedRecord.isEmpty()){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {UserInfo.getUserEmail()};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Failed Records');
        mail.setPlainTextBody('Failed records while sync Parts and products'+failedRecord);
        Messaging.sendEmail(NEW Messaging.SingleEmailMessage[] { mail });
        }
    }
    /**
* @description: this method is to add the failed records while inserting and updating.
* @author Jyoti Chahal | 08-21-2023 
* @param SaveResult 
**/
    public void getFailedRecord(Database.SaveResult[] srList){
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
            }else{
                for(Database.Error err : sr.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    failedRecord.add(sr.getId()+ ', '+err.getMessage());
                }
            }
        }
    }
}