public with sharing class PreviewChangeOrderController {
    
    @AuraEnabled
   public Static List<EmailTemplate> getTemplates(){
    List<Emailtemplate> temrec;
   
           temrec = [Select Id, Name, folder.name from Emailtemplate where folder.name = 'BT CO' and Name !=:'Change Order1'];
           
       return temrec;
   }
   
   @AuraEnabled
   public static string getChangeOrderLines(String recordId, String templateId){
        string templateBody = '';
       string templateBody1 = '';
       string templateBody2 = '';
       Contact con ;
      
           con = [select id, Email from Contact where email != null order by createddate desc limit 1 ];
           
       String[] toaddres;
       toaddres = new String[]{con.email};
       Savepoint sp = Database.setSavepoint();
       list<Messaging.SingleEmailMessage> msgList= new List<Messaging.SingleEmailMessage>(); 
       list<Messaging.SingleEmailMessage> msgList1= new List<Messaging.SingleEmailMessage>(); 
       List<String> templateList = new List<String>();
       Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
       
       string theTemplate = [SELECT Id FROM EmailTemplate WHERE Id =: templateId].Id; 
       email.setTemplateId(theTemplate);
       email.setWhatId(recordId);                        
       email.setTargetObjectId(con.Id);       
       email.setSaveAsActivity(true);
       email.setToAddresses(toaddres);
       msgList.add(email);
       
       Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
       System.debug('Email Results isSuccess = ' +  r[0].IsSuccess());
       Database.rollback(sp); 
       for (Messaging.SingleEmailMessage emailNew : msgList) {                   
           templateBody1 = emailNew.getHTMLBody(); 
       }
       templateBody = templateBody1 ;
       system.debug('Final templateBody ----------> '+templateBody);
       return templateBody;
       
   }
    
    private static Blob setAttachmentBody(String recordId, String templateId, String fileid){
       pagereference pdf;
       pdf = Page.buildertek__BT_GeneratePdf;
       pdf.getParameters().put('recordId',recordId);  
       pdf.getParameters().put('templateId',templateId);
       pdf.getParameters().put('fileId',fileId);
       pdf.setRedirect(true);
       
       Blob blobbody = !Test.isRunningTest() ? pdf.getContent() : Blob.ValueOf('dummy text');
       return blobbody;
   }
   
   @AuraEnabled
    public static string savedFile(String recId, String templateId){

        String fileid = '';
        string conversn;
        setAttachmentBody(recId, templateId,fileid);

        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
        conVer.PathOnClient = 'Change Order.pdf'; // The files name, extension is very important here which will help the file in preview.
        conVer.Title = 'Change Order'; // Display name of the files
        conVer.VersionData = setAttachmentBody(recId, templateId,fileid); // converting your binary string to Blog
        insert conVer;    //Insert ContentVersion
        system.debug('*******conVer*******'+conVer);
        // First get the Content Document Id from ContentVersion Object
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        //create ContentDocumentLink  record 
        ContentDocumentLink conDocLink = New ContentDocumentLink();
        conDocLink.LinkedEntityId = recId; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
        conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
        conDocLink.shareType = 'I';
        insert conDocLink;  
            
        String message = 'saved';
        return message;

   } 
   
}