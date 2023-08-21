/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 08-05-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class Test_ScheduleProductPartSync {
    @testsetup static void setupProductPart(){
        Product2 productObj= new Product2();
        productObj.Name= 'Test Part';
        productObj.ProductCode= '1234RT';
        productObj.IsActive= true;
        insert productObj;
        
        List<SQX_Part__c> partList= new List<SQX_Part__c>();
        SQX_Part__c partObj= new SQX_Part__c();
        partObj.Name = 'Test Part';
        partObj.Part_Number__c = '1234RT';
        partObj.Active__c= True;
        partList.add(partObj);
        
        SQX_Part__c partObj2= new SQX_Part__c();
        partObj2.Name = 'Test Part1';
        partObj2.Part_Number__c = '1234RT111';
        partObj2.Active__c = True;
        partObj2.Product__c = productObj.Id;
        partList.add(partObj2);
        
        insert partList;
    }
    @isTest
    public static void testProductPart(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        User newUser= new User();
        newUser.Email= 'testsystem@gmail.com';
        newUser.Alias= 'testS12';
        newUser.ProfileId= p.Id;
        newUser.Username= 'testUser@info.com';
        newUser.EmailEncodingKey='UTF-8';
        newUser.LastName='Testing';
        newUser.LanguageLocaleKey='en_US';
        newUser.LocaleSidKey='en_US';
        newUser.TimeZoneSidKey='America/Los_Angeles';
        insert newUser;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CQ_Product_Admin'];
        PermissionSetAssignment psa= new PermissionSetAssignment();
        psa.AssigneeId= newUser.Id;
        psa.PermissionSetId= ps.Id;
        insert psa;
        system.runAs(newUser){
             
            Test.startTest();  
            String success= ScheduleProductPartSync.schedulePartSync();
            system.Assert.isFalse(success== 'Not schedule');
            ProductPartSyncScheduler schClass= new ProductPartSyncScheduler();
            SchedulableContext schContext;
            schClass.execute(schContext);
            
            List<Product2> productList= [Select Id,Name,ProductCode,IsActive From Product2 LIMIT 1];
            system.Assert.isFalse(productList.size() == 0, 'Product not found');
            List<SQX_Part__c> partList= [Select Id,Name,Part_Number__c,Active__c,Product__c From SQX_Part__c WHERE Active__c = True];
            system.Assert(partList.size() > 0, 'Part Test');
            Product2 prodObj= productList.get(0);
            List<SQX_Part__c> partsList= [Select Id,Product__c From SQX_Part__c WHERE Active__c = True AND Product__c =: prodObj.Id];
            system.Assert.isFalse(partsList.size()== 0, 'Part not found');
            
            Test.stopTest();
        }       
    }
    
}