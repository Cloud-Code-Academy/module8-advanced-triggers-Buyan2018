public with sharing class OpportunityTriggerHandler {
    
    public static void setDefaultType(List<Opportunity> oppoList){
        // Set default Type for new Opportunities
        for (Opportunity oppo : oppoList) {
            if (oppo.Type == null){
                oppo.Type = 'New Customer';
            }
        }
    }

    public static void createTasks(List<Opportunity> oppoList){
        List<Task> tasksToCreate = new List<Task>();
        for (Opportunity opp : oppoList){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            tasksToCreate.add(tsk);
        }
        insert tasksToCreate;
    }

    public static void setCEOTitle(List<Opportunity> oppoList){
            /*
    * When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
    * Trigger should only fire on update.
    */
        //Get contacts related to the opportunity account
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : oppoList){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : oppoList){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }

    public static void validateAmountAndUpdateDescription(List<Opportunity> oppoList, Map<Id, Opportunity>oldMap){
        for (Opportunity oppRec : oppoList){
            if (oppRec.StageName != oldMap.get(oppRec.Id).StageName && oppRec.StageName!= null) {
                oppRec.Description = 'Stage Change:' + oppRec.StageName + ':' + DateTime.now().format();
            }
            if (oppRec.Amount != oldMap.get(oppRec.Id).Amount && oppRec.Amount < 5000) {
                oppRec.addError('Opportunity amount must be greater than 5000');
            }              
        }
    }

    public static void preventDelete(List<Opportunity> oppoList){
        /*
        * When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
        * Trigger should only fire on delete.
        */
            //Account related to the opportunities 
            Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :oppoList)]);
            for(Opportunity opp : oppoList){
                if (opp.isClosed == true) {
                        opp.addError('Cannot delete closed opportunity');
                    }
                }
            }

    /*
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> oldOpps) {
        Map<Id, Id> oppoToUserMap = new Map<Id, Id>();
        for (Opportunity oppoRec : [SELECT Id, OwnerId FROM Opportunity WHERE Id IN : oldOpps]) {
            oppoToUserMap.put(oppoRec.Id, oppoRec.OwnerId);
        }
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : oldOpps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(oppoToUserMap.get(opp.Id));
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }
        /*
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    public static void assignPrimaryContact(List<Opportunity> oppoList) {
        //Get contacts related to the opportunity account
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : oppoList){
            accountIds.add(opp.AccountId);
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'VP Sales' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }
        List<Opportunity> opposToUpdate = new List<Opportunity>();
        List<Opportunity> newOppoList = [SELECT Id, Primary_Contact__c, AccountId FROM Opportunity WHERE Id IN : oppoList];
        for(Opportunity opp : newOppoList){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                    opposToUpdate.add(opp);
                }
            }
        }
        update opposToUpdate;
    }
}