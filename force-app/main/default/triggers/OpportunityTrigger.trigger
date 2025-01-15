/*
OpportunityTrigger Overview

This class defines the trigger logic for the Opportunity object in Salesforce. It focuses on three main functionalities:
1. Ensuring that the Opportunity amount is greater than $5000 on update.
2. Preventing the deletion of a 'Closed Won' Opportunity if the related Account's industry is 'Banking'.
3. Setting the primary contact on an Opportunity to the Contact with the title 'CEO' when updating.

Usage Instructions:
For this lesson, students have two options:
1. Use the provided `OpportunityTrigger` class as is.
2. Use the `OpportunityTrigger` from you created in previous lessons. If opting for this, students should:
    a. Copy over the code from the previous lesson's `OpportunityTrigger` into this file.
    b. Save and deploy the updated file into their Salesforce org.

Remember, whichever option you choose, ensure that the trigger is activated and tested to validate its functionality.
*/
trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    switch on Trigger.operationType {
        when BEFORE_INSERT{
            OpportunityTriggerHandler.setDefaultType(Trigger.new);
        } 
        when AFTER_INSERT{
            OpportunityTriggerHandler.createTasks(Trigger.new);
        }
        when BEFORE_UPDATE {
            OpportunityTriggerHandler.setCEOTitle(Trigger.new);
            OpportunityTriggerHandler.validateAmountAndUpdateDescription(Trigger.new, Trigger.oldMap);
        }
        when BEFORE_DELETE{
            OpportunityTriggerHandler.preventDelete(Trigger.old);
        }
        when AFTER_DELETE{
            OpportunityTriggerHandler.notifyOwnersOpportunityDeleted(Trigger.old);
        }
        when AFTER_UNDELETE{
            OpportunityTriggerHandler.assignPrimaryContact(Trigger.new);
        }
    }    
}