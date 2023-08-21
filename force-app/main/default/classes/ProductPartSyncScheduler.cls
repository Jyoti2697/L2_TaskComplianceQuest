/**
 * @description       : Scheduler class to sync the Part and Product at 6 am.
 * @author            : Jyoti Chahal
 * @group             : 
 * @last modified on  : 08-05-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ProductPartSyncScheduler implements Schedulable{
    /**
    * @description: this method used to execute the batch class and check the profile and permission set.
    * @author Jyoti Chahal | 08-05-2023 
    * @param context 
    **/
    public void execute(SchedulableContext context) {
            ProductPartSyncBatchController syncBatch= new ProductPartSyncBatchController();   // Batch class
            Database.executeBatch(syncBatch);
    }
}